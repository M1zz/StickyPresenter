// App Store 스크린샷 합성기 — 언어별로 캡처한 창 이미지를 2880×1800 캔버스에 배치한다.
//
// 창 그림은 Tools/capture-screenshots.sh 가 언어마다 만든다:
//   <로케일>_panel · _guide · _note · _prompter · _pomo · _widget · _menu
//
// 실행:
//   swift Tools/MakeScreenshots.swift docs/screenshots/raw docs/screenshots/marketing Tools/screenshot-headlines.json <로케일...>
//
// 헤드라인 · 부제는 Tools/screenshot-headlines.json 에 언어별로 있다.
//
// 배경·문구만 여기서 정하고, 앱 화면은 손대지 않는다 — 스토어에 올라가는 그림과
// 실제 앱이 어긋나지 않도록.

import AppKit
import Foundation

// MARK: - 입력

let args = CommandLine.arguments
guard args.count >= 5 else {
    FileHandle.standardError.write("usage: MakeScreenshots.swift <shots-dir> <out-dir> <headlines.json> <locale...>\n".data(using: .utf8)!)
    exit(1)
}
let shotsDir = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])
let headlines = (try? JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: args[3]))))
    as? [String: [String: [String: String]]] ?? [:]
let locales = Array(args[4...])

let canvas = CGSize(width: 2880, height: 1800)

// MARK: - 배치 규격

/// 캔버스에 얹을 창 하나. `center` 는 캔버스 좌표(좌상단 원점), `scale` 은 캡처 픽셀 대비 배율.
struct Placement {
    let file: String        // 언어 접두사를 뺀 이름 ("panel", "guide", …)
    let center: CGPoint
    let scale: CGFloat
}

struct Shot {
    let name: String
    let items: [Placement]
}

let shots: [Shot] = [
    Shot(
        name: "01-sticky-notes",
        items: [
            Placement(file: "guide",  center: CGPoint(x: 760,  y: 1120), scale: 1.25),
            Placement(file: "note",   center: CGPoint(x: 1780, y: 800),  scale: 1.30),
            Placement(file: "pomo",   center: CGPoint(x: 1600, y: 1420), scale: 1.30),
            Placement(file: "widget", center: CGPoint(x: 2420, y: 1300), scale: 1.30),
        ]
    ),
    Shot(
        name: "02-timers",
        items: [
            Placement(file: "panel",  center: CGPoint(x: 1000, y: 1140), scale: 1.50),
            Placement(file: "pomo",   center: CGPoint(x: 2050, y: 830),  scale: 1.30),
            Placement(file: "widget", center: CGPoint(x: 2250, y: 1450), scale: 1.30),
        ]
    ),
    Shot(
        name: "03-teleprompter",
        items: [
            Placement(file: "prompter", center: CGPoint(x: 1250, y: 1120), scale: 1.45),
            Placement(file: "note",     center: CGPoint(x: 2450, y: 1300), scale: 1.15),
        ]
    ),
    Shot(
        name: "04-menu-bar",
        items: [
            Placement(file: "menu",  center: CGPoint(x: 880,  y: 1150), scale: 1.45),
            Placement(file: "panel", center: CGPoint(x: 2000, y: 1150), scale: 1.35),
        ]
    ),
]

// MARK: - 그리기

func loadImage(_ url: URL) -> NSImage? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return NSImage(data: data)
}

/// 창 하나를 그림자와 함께 얹는다.
///
/// 캡처는 이미 둥근 모서리 + 투명 여백을 갖고 있으므로 따로 오려내지 않는다.
/// 그림자는 이미지의 알파를 따라 드리워지므로 창 모양 그대로 앉는다 —
/// 사각형 판을 깔면 텔레프롬프터처럼 여백이 넓은 창에서 흰 띠가 비어져 나온다.
func draw(_ image: NSImage, at placement: Placement) {
    let px = image.representations.first.map { CGSize(width: $0.pixelsWide, height: $0.pixelsHigh) } ?? image.size
    // `scale` 은 캡처 **픽셀** 대비 배율이다 (캡처는 Retina 2x 이므로 1.0 이 이미 또렷하다).
    let size = CGSize(width: px.width * placement.scale, height: px.height * placement.scale)
    let rect = NSRect(
        x: placement.center.x - size.width / 2,
        y: canvas.height - placement.center.y - size.height / 2,
        width: size.width, height: size.height
    )

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.30)
    shadow.shadowBlurRadius = 54
    shadow.shadowOffset = NSSize(width: 0, height: -20)
    shadow.set()
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
}

func drawText(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, centerY: CGFloat) {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    style.lineBreakMode = .byWordWrapping
    // 한 줄에 들어가지 않으면 들어갈 때까지 글자를 줄인다 — 언어마다 길이가 다르다.
    var fontSize = size
    func attributes(_ s: CGFloat) -> [NSAttributedString.Key: Any] {
        [.font: NSFont.systemFont(ofSize: s, weight: weight), .foregroundColor: color, .paragraphStyle: style]
    }
    while fontSize > size * 0.6,
          (text as NSString).size(withAttributes: attributes(fontSize)).width > canvas.width - 400 {
        fontSize -= 2
    }
    let attrs = attributes(fontSize)
    let box = NSRect(x: 200, y: canvas.height - centerY - size, width: canvas.width - 400, height: size * 2.2)
    (text as NSString).draw(in: box, withAttributes: attrs)
}

/// 위에서 아래로 아주 옅게 흐르는 배경. 창 그림자가 앉을 자리만 만들어 주면 된다.
func drawBackground() {
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.94, green: 0.95, blue: 0.98, alpha: 1),
        NSColor(calibratedRed: 0.87, green: 0.90, blue: 0.96, alpha: 1),
    ])!
    gradient.draw(in: NSRect(origin: .zero, size: canvas), angle: -90)

    // 노란 스티키를 은은하게 되받는 원 두 개
    NSColor(calibratedRed: 1.0, green: 0.93, blue: 0.62, alpha: 0.28).setFill()
    NSBezierPath(ovalIn: NSRect(x: -280, y: -320, width: 1100, height: 1100)).fill()
    NSColor(calibratedRed: 0.62, green: 0.74, blue: 1.0, alpha: 0.22).setFill()
    NSBezierPath(ovalIn: NSRect(x: canvas.width - 700, y: canvas.height - 620, width: 1000, height: 1000)).fill()
}

let ink = NSColor(calibratedRed: 0.13, green: 0.16, blue: 0.24, alpha: 1)
let inkSoft = NSColor(calibratedRed: 0.30, green: 0.35, blue: 0.45, alpha: 1)

for lang in locales {
    let langDir = outDir.appendingPathComponent(lang)
    try? FileManager.default.createDirectory(at: langDir, withIntermediateDirectories: true)

    for shot in shots {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(canvas.width), pixelsHigh: Int(canvas.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { continue }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

        drawBackground()
        let copy = headlines[lang]?[shot.name] ?? [:]
        drawText(copy["headline"] ?? "", size: 106, weight: .bold, color: ink, centerY: 152)
        drawText(copy["subhead"] ?? "", size: 48, weight: .regular, color: inkSoft, centerY: 318)

        for item in shot.items {
            let url = shotsDir.appendingPathComponent("\(lang)_\(item.file).png")
            guard let image = loadImage(url) else {
                FileHandle.standardError.write("missing: \(url.path)\n".data(using: .utf8)!)
                continue
            }
            draw(image, at: item)
        }

        NSGraphicsContext.restoreGraphicsState()

        let out = langDir.appendingPathComponent("\(shot.name).png")
        if let data = bitmap.representation(using: .png, properties: [:]) {
            try? data.write(to: out)
            print("wrote \(out.path)")
        }
    }
}
