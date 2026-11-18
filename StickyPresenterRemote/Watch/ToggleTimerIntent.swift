import AppIntents

// MARK: - 동작 버튼 · Siri · 단축어
// 화면을 보지 않고 발표 타이머를 시작하거나 멈춘다.
// (Apple Watch Ultra: 설정 ▸ 동작 버튼 ▸ 단축어 ▸ Remote Controller 시작·일시정지)

struct ToggleTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "발표 타이머 시작·일시정지"
    // ⚠️ 설명에 iPhone 같은 기기 이름을 적으면 업로드가 막힌다(ITMS-90626, 1.1.1 빌드 10). Mac 은 통과했다.
    static var description = IntentDescription("리모컨을 거쳐 Mac의 타이머를 시작하거나 일시정지합니다.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let link = WatchLink.shared
        link.activate()
        guard let timer = link.snapshot?.timer else {
            return .result(dialog: "시작하거나 멈출 타이머가 없어요")
        }
        guard await link.send(.toggle) else {
            return .result(dialog: "iPhone에서 리모컨을 열어 주세요")
        }
        return .result(dialog: timer.isRunning ? "일시정지했어요" : "시작했어요")
    }
}

struct RemoteWatchShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleTimerIntent(),
            phrases: ["Start or pause \(.applicationName)"],
            shortTitle: "시작·일시정지",
            systemImageName: "playpause.fill"
        )
    }
}
