#if DEBUG
import AppKit
import SwiftUI

// MARK: - App Store 스크린샷 무대 (Debug 빌드 전용)
//
// Tools/capture-screenshots.sh 가 언어마다 앱을 이렇게 띄운다:
//   StickyPresenter -SPScreenshotStage YES -SPDemoChecklist <노트 글> -SPDemoScript <대본>
//     -AppleLanguages "(<로케일>)"
//
// 깨끗한 상태에서 사용 가이드 노트 · 리허설 노트 · 뽀모도로 · 10분 타이머 · 텔레프롬프터를 띄우고,
// 각 창의 window number 를 표준 출력에 `SPSHOT windows {json}` 으로 찍는다. 스크립트가 그 번호로
// `screencapture -l` 해 창만 찍는다. 마지막에 메뉴 막대 메뉴를 열고(`SPSHOT menu`) 스스로 끝난다.
// (앱은 샌드박스라 파일로 주고받지 않는다.)
//
// 대본 · 리허설 노트 문구는 Tools/screenshot-demo.json 에 언어별로 있다 — 앱 문자열표에 넣지 않는다.
// Release 빌드에는 이 파일이 들어가지 않는다.

enum ScreenshotStage {
    static var isActive: Bool { UserDefaults.standard.bool(forKey: "SPScreenshotStage") }

    /// applicationDidFinishLaunching 맨 앞에서 부른다 — 지난 상태를 지우고 첫 실행 안내를 건너뛴다.
    static func prepare() {
        guard isActive, let id = Bundle.main.bundleIdentifier else { return }
        // 실행 인자(-SPScreenshotStage …)는 argument 도메인이라 지워지지 않는다.
        UserDefaults.standard.removePersistentDomain(forName: id)
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        UserDefaults.standard.set(true, forKey: OnboardingView.seenKey)
        try? FileManager.default.removeItem(at: NoteFileStore.default.fileURL)
    }

    /// applicationDidFinishLaunching 끝에서 부른다.
    static func run(_ app: AppDelegate) {
        guard isActive else { return }
        let defaults = UserDefaults.standard
        let demo = ["checklist": defaults.string(forKey: "SPDemoChecklist") ?? "",
                    "script": defaults.string(forKey: "SPDemoScript") ?? ""]
        let manager = NoteManager.shared
        let frame = ScreenMap.mainVisibleFrame()

        manager.addNote(text: L("guide.note"), color: .yellow,
                        position: CGPoint(x: frame.minX + 60, y: frame.minY + 80),
                        size: CGSize(width: 320, height: 470))
        manager.addNote(text: demo["checklist"] ?? "", color: .yellow,
                        position: CGPoint(x: frame.minX + 420, y: frame.minY + 80),
                        size: CGSize(width: 280, height: 220))

        // 뽀모도로를 먼저 — 그래야 "25/5" 사용 팁이 패널 위에 뜨지 않는다.
        manager.startPomodoro()
        let ten = TimerEntry(name: shortTimeLabel(600), targetSeconds: 600)
        ten.setRunning(true)
        manager.timerListManager.add(ten)

        manager.openTeleprompter(with: demo["script"] ?? "")

        // 24:17 · 09:15 쯤 — 시작 직후의 25:00 · 10:00 보다 도는 타이머로 보인다.
        // 숫자가 넘어가는 애니메이션 한가운데를 그리지 않도록 초의 중간(.55)에 맞춘다.
        let started = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 44) {
            let frac = Date().timeIntervalSince(started).truncatingRemainder(dividingBy: 1)
            Thread.sleep(forTimeInterval: (1.55 - frac).truncatingRemainder(dividingBy: 1))
            printWindows()
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                openMenu(app)
            }
        }
    }

    private static func say(_ line: String) {
        print("SPSHOT " + line)
        fflush(stdout)
    }

    private static func printWindows() {
        let manager = NoteManager.shared
        var map: [String: NSWindow] = [:]
        if manager.notes.count >= 2 {
            map["guide"] = manager.notes[0].panel
            map["note"] = manager.notes[1].panel
        }
        let entries = manager.timerListManager.entries
        if let pomo = entries.first(where: { $0.pomodoro != nil }) { map["pomo"] = pomo.widgetPanel }
        if let plain = entries.first(where: { $0.pomodoro == nil }) { map["widget"] = plain.widgetPanel }
        for window in NSApp.windows where window.isVisible {
            if window.contentView is NSHostingView<TeleprompterView> { map["prompter"] = window }
            if window.contentView is NSHostingView<TimerListView> { map["panel"] = window }
        }
        // 화면 녹화 권한 없이 앱이 자기 창을 직접 그린다 — 창 틀(제목 막대 포함)째로.
        for (key, window) in map.sorted(by: { $0.key < $1.key }) {
            guard let view = window.contentView?.superview ?? window.contentView,
                  let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { continue }
            view.cacheDisplay(in: view.bounds, to: rep)
            guard let png = rep.representation(using: .png, properties: [:]) else { continue }
            say("png \(key) " + png.base64EncodedString())
        }
        say("windows done")
    }

    /// 메뉴 막대 메뉴를 열어 둔다. 메뉴가 도는 동안은 메인 런루프가 이벤트 추적 모드라
    /// 닫기 · 종료는 .common 모드 타이머로 건다.
    private static func openMenu(_ app: AppDelegate) {
        let close = Timer(timeInterval: 8, repeats: false) { _ in
            app.statusItem?.menu?.cancelTracking()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { NSApp.terminate(nil) }
        }
        RunLoop.main.add(close, forMode: .common)
        say("menu")
        app.statusItem?.button?.performClick(nil)
    }
}
#endif
