// 주어진 프로세스가 띄운 팝업 메뉴 창의 window number 를 찍는다 (capture-screenshots.sh 용).
//   swiftc Tools/FindMenuWindow.swift -o <bin> && <bin> <pid>
import CoreGraphics
import Foundation

guard CommandLine.arguments.count > 1, let pid = Int(CommandLine.arguments[1]) else { exit(2) }
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
let menus = list.filter {
    ($0[kCGWindowOwnerPID as String] as? Int) == pid &&
    ($0[kCGWindowLayer as String] as? Int) == Int(CGWindowLevelForKey(.popUpMenuWindow))
}
// 가장 큰 것 — 메뉴 본체
let best = menus.max { a, b in
    let ra = a[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
    let rb = b[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
    return (ra["Height"] ?? 0) * (ra["Width"] ?? 0) < (rb["Height"] ?? 0) * (rb["Width"] ?? 0)
}
guard let id = best?[kCGWindowNumber as String] as? Int else { exit(1) }
print(id)
