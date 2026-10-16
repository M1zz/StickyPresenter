import AppIntents
import AppKit

// MARK: - App Shortcuts (단축어 · Spotlight · Siri)
// 메뉴 막대 단축키(⌘⌃)와 같은 동작을 단축어 앱에서도 부른다.
// 발표 준비 단축어("Keynote 열기 → 15분 타이머 시작") 처럼 다른 동작과 엮을 수 있는 게 핵심이다.
//
// 동작은 메뉴·단축키가 부르는 것과 **같은 함수**를 부른다 — 단축어만 다르게 움직이지 않도록.
// 메뉴 막대 앱이라 꺼져 있으면 켜야 하므로 모두 openAppWhenRun = true.
// 문구 번역: 제목은 Localizable.strings, 호출 문장은 AppShortcuts.strings.

struct StartTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.timer.title"
    static var description = IntentDescription("intent.timer.description")
    static var openAppWhenRun = true

    @Parameter(title: "intent.timer.minutes", default: 5, inclusiveRange: (1, 600))
    var minutes: Int

    static var parameterSummary: some ParameterSummary {
        Summary("intent.timer.summary \(\.$minutes)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let seconds = TimeInterval(minutes * 60)
        let manager = NoteManager.shared
        manager.openTimerList()
        let entry = TimerEntry(name: shortTimeLabel(seconds), targetSeconds: seconds)
        entry.setRunning(true)
        manager.timerListManager.add(entry)
        PomodoroInputTip.record(isPomodoro: false)
        return .result()
    }
}

struct StartPomodoroIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.pomodoro.title"
    static var description = IntentDescription("intent.pomodoro.description")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NoteManager.shared.startPomodoro()
        return .result()
    }
}

struct NewStickyNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.note.title"
    static var description = IntentDescription("intent.note.description")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NoteManager.shared.addNoteAtRandomPosition()
        return .result()
    }
}

struct ShowTimersIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.timers.title"
    static var description = IntentDescription("intent.timers.description")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NoteManager.shared.openTimerList()
        return .result()
    }
}

struct StickyPresenterShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTimerIntent(),
            phrases: [
                "Start a timer in \(.applicationName)",
                "Start a \(.applicationName) timer",
            ],
            shortTitle: "intent.timer.short",
            systemImageName: "timer"
        )
        AppShortcut(
            intent: StartPomodoroIntent(),
            phrases: [
                "Start a Pomodoro in \(.applicationName)",
                "Start focusing with \(.applicationName)",
            ],
            shortTitle: "intent.pomodoro.short",
            systemImageName: "arrow.triangle.2.circlepath"
        )
        AppShortcut(
            intent: NewStickyNoteIntent(),
            phrases: [
                "New sticky note in \(.applicationName)",
                "Add a note in \(.applicationName)",
            ],
            shortTitle: "intent.note.short",
            systemImageName: "note.text.badge.plus"
        )
        AppShortcut(
            intent: ShowTimersIntent(),
            phrases: [
                "Show timers in \(.applicationName)",
            ],
            shortTitle: "intent.timers.short",
            systemImageName: "list.bullet"
        )
    }
}
