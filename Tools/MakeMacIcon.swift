import AppKit
import CoreGraphics

// StickyPresenter Mac 앱 아이콘 생성기.
// 모티프는 리모컨(iOS) 아이콘과 같은 "둥근 사각형 진행 표시 + 1/4 지점 점".
// 타이머 위젯이 원형에서 둥근 사각형으로 바뀌면서, 예전의 동그란 시계 아이콘 대신
// 두 앱이 같은 도형을 쓰도록 맞춘 것이다. 비율은 StickyPresenterRemote/MakeIcon.swift 와 동일하되,
// macOS 아이콘은 스스로 모서리를 깎고 여백을 둬야 하므로 그 여백(840/1024) 안쪽 기준으로 잡는다.
//
//   swift Tools/MakeMacIcon.swift <출력폴더>
//
// 지정한 폴더에 icon_16 … icon_1024 를 각 크기로 직접 렌더링해서 넣는다. (축소본이 아니라 원본 렌더)

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

// MARK: 색 — 기존 Mac 아이콘의 그라데이션 양 끝을 그대로 이어받는다.
// 리모컨 아이콘 생성기는 이 파일이 만든 결과에서 색을 다시 샘플링하므로, 여기가 두 앱의 색 원본이다.
let topColor = CGColor(srgbRed: 1.0, green: 0.8588, blue: 0.3686, alpha: 1)   // #FFDB5E
let bottomColor = CGColor(srgbRed: 1.0, green: 0.6824, blue: 0.0627, alpha: 1) // #FFAE10

func lerpColor(_ t: CGFloat) -> CGColor {
    let a = topColor.components!, b = bottomColor.components!
    return CGColor(srgbRed: a[0] + (b[0] - a[0]) * t,
                   green: a[1] + (b[1] - a[1]) * t,
                   blue: a[2] + (b[2] - a[2]) * t, alpha: 1)
}

func rad(_ d: CGFloat) -> CGFloat { d * .pi / 180 }

func makeIcon(_ S: CGFloat) -> CGImage {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8,
                        bytesPerRow: 0, space: space,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high

    // 아이콘 몸통 — 캔버스의 840/1024 를 차지하고 모서리 반지름은 그 폭의 0.2214.
    // (예전 아이콘에서 실측한 값. macOS 독에서 형제 앱들과 크기가 어긋나지 않게 유지한다.)
    let shapeInset = S * (92.0 / 1024.0)
    let shape = CGRect(x: shapeInset, y: shapeInset,
                       width: S - shapeInset * 2, height: S - shapeInset * 2)
    let shapeRadius = shape.width * 0.22143

    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: shape, cornerWidth: shapeRadius,
                       cornerHeight: shapeRadius, transform: nil))
    ctx.clip()
    let gradient = CGGradient(colorsSpace: space, colors: [topColor, bottomColor] as CFArray,
                              locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: shape.maxY),
                           end: CGPoint(x: 0, y: shape.minY), options: [])
    ctx.restoreGState()

    // 진행 표시 — 앱 안의 RoundedRectProgress 와 같은 구조.
    // 좌상단 꼭짓점에서 출발해 시계방향, 절반(우하단 꼭짓점)까지 차 있는 모습.
    let inset = shape.width * 0.205
    let rect = shape.insetBy(dx: inset, dy: inset)
    let radius = rect.width * 0.235
    let lineWidth = shape.width * 0.078

    let left = rect.minX + radius, right = rect.maxX - radius
    let bottom = rect.minY + radius, top = rect.maxY - radius
    func apex(_ cx: CGFloat, _ cy: CGFloat, _ deg: CGFloat) -> CGPoint {
        CGPoint(x: cx + radius * cos(rad(deg)), y: cy + radius * sin(rad(deg)))
    }

    // 트랙 — 닫힌 윤곽. 닫혀 있어야 "무엇의 일부인지"가 한눈에 읽힌다.
    ctx.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.34))
    ctx.setLineWidth(lineWidth)
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.strokePath()

    // 진행분 — 좌상단 꼭짓점(135°)에서 우하단 꼭짓점(-45°)까지 정확히 절반.
    // CoreGraphics 는 y축이 위로 향하므로 각도가 줄어드는 방향이 화면상 시계방향이다.
    let progress = CGMutablePath()
    progress.move(to: apex(left, top, 135))
    progress.addArc(center: CGPoint(x: left, y: top), radius: radius,
                    startAngle: rad(135), endAngle: rad(90), clockwise: true)
    progress.addLine(to: CGPoint(x: right, y: rect.maxY))
    progress.addArc(center: CGPoint(x: right, y: top), radius: radius,
                    startAngle: rad(90), endAngle: rad(0), clockwise: true)
    progress.addLine(to: CGPoint(x: rect.maxX, y: bottom))
    progress.addArc(center: CGPoint(x: right, y: bottom), radius: radius,
                    startAngle: rad(0), endAngle: rad(-45), clockwise: true)

    ctx.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    ctx.setLineWidth(lineWidth)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.addPath(progress)
    ctx.strokePath()

    // 1/4 지점 점 — 앱에서 25% 를 지날 때 튀는 그 점. 우상단 꼭짓점에 놓는다.
    // 획 위에 겹치므로 배경색 링을 한 겹 깔아 분리한다. 안 그러면 뭉쳐서 혹처럼 보인다.
    let dot = apex(right, top, 45)
    let dotRadius = lineWidth * 0.80
    let ringPad = lineWidth * 0.20
    ctx.setFillColor(lerpColor((shape.maxY - dot.y) / shape.height))
    ctx.fillEllipse(in: CGRect(x: dot.x - dotRadius - ringPad, y: dot.y - dotRadius - ringPad,
                               width: (dotRadius + ringPad) * 2, height: (dotRadius + ringPad) * 2))
    ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    ctx.fillEllipse(in: CGRect(x: dot.x - dotRadius, y: dot.y - dotRadius,
                               width: dotRadius * 2, height: dotRadius * 2))

    guard let image = ctx.makeImage() else { fatalError("이미지 생성 실패 (\(Int(S))px)") }
    return image
}

for size in [16, 32, 64, 128, 256, 512, 1024] {
    let image = makeIcon(CGFloat(size))
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("PNG 인코딩 실패 (\(size)px)")
    }
    let path = "\(outDir)/icon_\(size).png"
    try! data.write(to: URL(fileURLWithPath: path))
    print("생성: \(path)")
}
