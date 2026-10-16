import AppIntents
import Foundation

// MARK: - App Shortcuts (단축어 · Spotlight · Siri)
// 발표 직전에 "Remote Controller 로 10분 타이머 시작" 한 마디로 Mac 에 타이머를 띄운다.
// 리모컨은 Mac 과 붙어야 일을 하므로 앱을 열고(openAppWhenRun), 명령은 붙는 순간 보낸다.

@MainActor
final class RemoteIntentInbox: ObservableObject {
    static let shared = RemoteIntentInbox()
    @Published private(set) var queue = PendingCommandQueue()

    func enqueue(_ command: RemoteCommand) { queue.enqueue(command) }
    func drain() -> [RemoteCommand] { queue.drain() }
    func cancel() { queue.removeAll() }
}

struct StartMacTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Mac에서 타이머 시작"
    static var description = IntentDescription("Mac의 StickyPresenter에 카운트다운 타이머를 띄웁니다. 연결되는 즉시 시작합니다.")
    static var openAppWhenRun = true

    @Parameter(title: "분", default: 5, inclusiveRange: (1, 600))
    var minutes: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Mac에서 \(\.$minutes)분 타이머 시작")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        RemoteIntentInbox.shared.enqueue(
            .addPreset(seconds: Double(minutes * 60), name: timerName(minutes: minutes)))
        return .result()
    }
}

struct RemoteShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartMacTimerIntent(),
            phrases: [
                "Start a timer with \(.applicationName)",
                "Start a Mac timer with \(.applicationName)",
            ],
            shortTitle: "Mac 타이머",
            systemImageName: "timer"
        )
    }
}
