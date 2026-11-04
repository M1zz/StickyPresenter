import AppIntents
import AppKit
import CoreSpotlight

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

    @Parameter(title: "intent.timer.minutes", description: "intent.timer.minutes.description",
               default: 5, inclusiveRange: (1, 600))
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

// MARK: - 스티키 노트 (Siri · Spotlight)
// 화면에 붙인 노트를 Siri · Spotlight 가 글로 찾는다. 누르면 그 노트가 맨 앞으로 온다.
// 읽기는 저장 파일(notes.json)을 바로 읽는다 — 저장할 때마다 다시 색인하므로 늘 같은 내용이다.
// 색인(IndexedEntity)은 macOS 15 부터라 그 부분만 나눠 둔다.

struct NoteEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "entity.note.type")
    static let defaultQuery = NoteQuery()

    let id: UUID
    let text: String

    var displayRepresentation: DisplayRepresentation {
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
        return DisplayRepresentation(title: "\(String(firstLine.prefix(60)))")
    }
}

@available(macOS 15.0, *)
extension NoteEntity: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let set = defaultAttributeSet
        set.textContent = text
        return set
    }
}

struct NoteQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [NoteEntity] {
        let wanted = Set(identifiers)
        return NoteLibrary.all().filter { wanted.contains($0.id) }
    }

    /// 노트 글에서 찾는다(대소문자 · 악센트 무시).
    func entities(matching string: String) async throws -> [NoteEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return NoteLibrary.all().filter { $0.text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    func suggestedEntities() async throws -> [NoteEntity] {
        NoteLibrary.all()
    }
}

/// 노트를 맨 앞으로 가져온다. Spotlight · Siri 결과를 누르면 여기로 온다.
struct OpenNoteIntent: OpenIntent {
    static var title: LocalizedStringResource = "intent.openNote.title"
    static var description = IntentDescription("intent.openNote.description")

    @Parameter(title: "intent.openNote.note", description: "intent.openNote.note.description")
    var target: NoteEntity

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        let manager = NoteManager.shared
        if let note = manager.notes.first(where: { $0.id == target.id }) {
            manager.showNote(note)
            note.panel?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        return .result()
    }
}

enum NoteLibrary {
    /// 글이 있는 노트만. 닫은 노트(되살리기 목록)는 넣지 않는다.
    static func all() -> [NoteEntity] {
        guard case .loaded(let archive) = NoteFileStore.default.load() else { return [] }
        return entities(archive.notes)
    }

    static func entities(_ records: [NoteRecord]) -> [NoteEntity] {
        records
            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { NoteEntity(id: $0.id, text: $0.text) }
    }

    /// 저장할 때마다 부른다. 지운 노트가 남지 않게 통째로 다시 싣는다.
    static func reindex(_ records: [NoteRecord]) {
        guard #available(macOS 15.0, *) else { return }
        let notes = entities(records)
        Task {
            let index = CSSearchableIndex.default()
            try? await index.deleteAppEntities(ofType: NoteEntity.self)
            try? await index.indexAppEntities(notes)
        }
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
