// App Store 스크린샷 합성기 — 언어별로 캡처한 창 이미지를 2880×1800 캔버스에 배치한다.
//
// 창 캡처는 사람이 미리 떠 둔다 (`screencapture -o -l<windowid>`):
//   ko_panel · ko_guide · ko_note · ko_prompter · ko_pomo · ko_widget · ko_menu
//   en_* 도 같은 이름으로.
//
// 실행:
//   swift Tools/MakeScreenshots.swift <캡처폴더> <출력폴더>
//
// 배경·문구만 여기서 정하고, 앱 화면은 손대지 않는다 — 스토어에 올라가는 그림과
// 실제 앱이 어긋나지 않도록.

import AppKit
import Foundation

// MARK: - 입력

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("usage: MakeScreenshots.swift <shots-dir> <out-dir>\n".data(using: .utf8)!)
    exit(1)
}
let shotsDir = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])

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
    let headline: [String: String]   // 언어 → 문구
    let subhead: [String: String]
    let items: [Placement]
}

let shots: [Shot] = [
    Shot(
        name: "01-sticky-notes",
        headline: [
            "ko": "슬라이드 위에 그대로 붙는 메모",
            "en": "Notes that stay on your slides",
        ],
        subhead: [
            "ko": "키노트 전체 화면 위에서도 노트는 사라지지 않습니다",
            "en": "Sticky notes float above Keynote’s full screen — they never disappear",
        ],
        items: [
            Placement(file: "guide",  center: CGPoint(x: 760,  y: 1120), scale: 1.25),
            Placement(file: "note",   center: CGPoint(x: 1780, y: 800),  scale: 1.30),
            Placement(file: "pomo",   center: CGPoint(x: 1600, y: 1420), scale: 1.30),
            Placement(file: "widget", center: CGPoint(x: 2420, y: 1300), scale: 1.30),
        ]
    ),
    Shot(
        name: "02-timers",
        headline: [
            "ko": "발표 시간을 한눈에",
            "en": "Keep an eye on the clock",
        ],
        subhead: [
            "ko": "타이머와 뽀모도로를 화면 어디에나 띄워 두세요",
            "en": "Put timers and Pomodoro sessions anywhere on screen",
        ],
        items: [
            Placement(file: "panel",  center: CGPoint(x: 1000, y: 1140), scale: 1.50),
            Placement(file: "pomo",   center: CGPoint(x: 2050, y: 830),  scale: 1.30),
            Placement(file: "widget", center: CGPoint(x: 2250, y: 1450), scale: 1.30),
        ]
    ),
    Shot(
        name: "03-teleprompter",
        headline: [
            "ko": "대본은 알아서 흘러갑니다",
            "en": "Your script scrolls itself",
        ],
        subhead: [
            "ko": "속도와 글자 크기를 맞추고, 좌우 반전도 한 번에",
            "en": "Set the speed and type size — mirror it for teleprompter glass",
        ],
        items: [
            Placement(file: "prompter", center: CGPoint(x: 1250, y: 1120), scale: 1.45),
            Placement(file: "note",     center: CGPoint(x: 2450, y: 1300), scale: 1.15),
        ]
    ),
    Shot(
        name: "04-menu-bar",
        headline: [
            "ko": "메뉴 막대에서 바로",
            "en": "Everything from the menu bar",
        ],
        subhead: [
            "ko": "노트 · 타이머 · 텔레프롬프터 · 리모컨까지 단축키 하나로",
            "en": "Notes, timers, teleprompter and the iPhone remote — one shortcut away",
        ],
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
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: style,
    ]
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

for lang in ["ko", "en"] {
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
        drawText(shot.headline[lang] ?? "", size: 106, weight: .bold, color: ink, centerY: 152)
        drawText(shot.subhead[lang] ?? "", size: 48, weight: .regular, color: inkSoft, centerY: 318)

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
