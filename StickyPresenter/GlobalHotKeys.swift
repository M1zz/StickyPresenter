import AppKit
import Carbon.HIToolbox

// MARK: - Hot Key Actions
/// 앱 전역 단축키의 **단일 출처**. 메뉴 막대·사용 가이드·설정의 단축키 표가 모두 이 목록을 읽는다.
/// 여기서 하나를 고치면 세 군데가 함께 바뀌어, 안내 문구와 실제 동작이 어긋날 일이 없다.
///
/// 모두 ⌘⌃ 조합이다 — 발표 중 다른 앱(Keynote 등)의 단축키와 겹치지 않는 조합.
enum HotKeyAction: UInt32, CaseIterable {
    case newNote = 1
    case noteFromClipboard
    case teleprompter
    case timers
    case pomodoro
    case showNotes
    case hideNotes

    /// 가상 키 코드 (ANSI 배열 기준 — 한글 자판에서도 같은 물리 키다).
    var keyCode: UInt32 {
        switch self {
        case .newNote:           return UInt32(kVK_ANSI_N)
        case .noteFromClipboard: return UInt32(kVK_ANSI_V)
        case .teleprompter:      return UInt32(kVK_ANSI_P)
        case .timers:            return UInt32(kVK_ANSI_T)
        case .pomodoro:          return UInt32(kVK_ANSI_B)
        case .showNotes:         return UInt32(kVK_ANSI_S)
        case .hideNotes:         return UInt32(kVK_ANSI_H)
        }
    }

    /// 메뉴 항목의 `keyEquivalent` 이자 표에 찍히는 글자.
    var key: String {
        switch self {
        case .newNote:           return "n"
        case .noteFromClipboard: return "v"
        case .teleprompter:      return "p"
        case .timers:            return "t"
        case .pomodoro:          return "b"
        case .showNotes:         return "s"
        case .hideNotes:         return "h"
        }
    }

    /// 표에 찍는 사람이 읽는 조합 (⌘⌃N).
    var display: String { "⌘⌃" + key.uppercased() }

    /// 무엇을 하는지 — 메뉴 문구와 달리 이모지 없이 짧게.
    var title: String {
        switch self {
        case .newNote:           return L("hotkey.newNote")
        case .noteFromClipboard: return L("hotkey.noteFromClipboard")
        case .teleprompter:      return L("hotkey.teleprompter")
        case .timers:            return L("hotkey.timers")
        case .pomodoro:          return L("hotkey.pomodoro")
        case .showNotes:         return L("hotkey.showNotes")
        case .hideNotes:         return L("hotkey.hideNotes")
        }
    }
}

// MARK: - Global Hot Keys
/// Carbon `RegisterEventHotKey` 로 등록하는 전역 단축키.
///
/// 예전에는 `NSEvent.addGlobalMonitorForEvents(.keyDown)` 를 썼다. 그 방식은
/// **손쉬운 사용(접근성) 권한이 있어야만** 다른 앱이 앞에 있을 때 키를 받는다. 권한을 묻는
/// 화면도 없어서, 사용자는 "Keynote 에서 ⌘⌃T 가 안 먹는다"는 것만 겪고 이유를 알 길이 없었다.
/// 또 모니터는 이벤트를 엿볼 뿐 가로채지 못해, 앞에 있는 앱에도 같은 키가 그대로 전달됐다.
///
/// `RegisterEventHotKey` 는 권한 없이 샌드박스 안에서 동작하고, 키를 가로채 우리만 받는다.
/// 다른 앱이 같은 조합을 먼저 차지하고 있으면 등록이 실패하는데, 그 목록은 `failed` 에 남겨
/// 설정의 단축키 표에서 알려 준다.
final class GlobalHotKeys {
    static let shared = GlobalHotKeys()
    private init() {}

    /// 등록에 실패한 단축키 — 다른 앱이 이미 쓰고 있는 조합.
    private(set) var failed: Set<HotKeyAction> = []

    private var refs: [EventHotKeyRef] = []
    private var handler: ((HotKeyAction) -> Void)?
    private var eventHandlerRef: EventHandlerRef?

    /// 'SPrs' — 이 앱의 단축키임을 표시하는 서명.
    private static let signature: OSType = 0x5350_7273

    /// 모든 단축키를 등록한다. 두 번 불러도 이전 등록을 지우고 다시 건다.
    func register(_ handler: @escaping (HotKeyAction) -> Void) {
        unregisterAll()
        self.handler = handler
        installEventHandlerIfNeeded()

        let modifiers = UInt32(cmdKey | controlKey)
        for action in HotKeyAction.allCases {
            var ref: EventHotKeyRef?
            let id = EventHotKeyID(signature: Self.signature, id: action.rawValue)
            let status = RegisterEventHotKey(action.keyCode, modifiers, id,
                                             GetApplicationEventTarget(), 0, &ref)
            if status == noErr, let ref {
                refs.append(ref)
            } else {
                failed.insert(action)
            }
        }
    }

    func unregisterAll() {
        refs.forEach { UnregisterEventHotKey($0) }
        refs.removeAll()
        failed.removeAll()
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        // C 콜백이라 캡처를 못 한다 — 공유 인스턴스를 거쳐 되돌아온다.
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event,
                                           EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID),
                                           nil,
                                           MemoryLayout<EventHotKeyID>.size,
                                           nil,
                                           &hotKeyID)
            guard status == noErr,
                  hotKeyID.signature == GlobalHotKeys.signature,
                  let action = HotKeyAction(rawValue: hotKeyID.id) else {
                return OSStatus(eventNotHandledErr)
            }
            // 이벤트 처리 중에 창을 만들고 닫으면 AppKit 이벤트 루프와 엉킬 수 있다 — 다음 턴으로.
            DispatchQueue.main.async { GlobalHotKeys.shared.handler?(action) }
            return noErr
        }, 1, &spec, nil, &eventHandlerRef)
    }
}
