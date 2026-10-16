import SwiftUI
import TipKit

// MARK: - Feature Tips
// "이런 것도 있어요" 를 **써 본 뒤에만** 알려주는 TipKit 팁.
//
// 원칙 — 팁은 광고가 아니라 도움이어야 한다.
//   • 첫 화면에서 쏟아내지 않는다. 타이머를 몇 번 만들어 본 사람에게만 뜬다.
//   • 이미 그 기능을 쓰고 있으면 뜨지 않는다 (`hasUsedPomodoro`).
//   • 표시 빈도·닫힘 기억은 TipKit 이 맡는다 (StickyPresenterApp 의 Tips.configure).

/// 타이머 입력창의 숨은 문법 "25/5" 를 알려준다.
///
/// 뽀모도로는 이 앱의 큰 기능인데 입력창은 "5:30 · 1h 20m" 같은 시간만 보여 준다.
/// 물음표 버튼을 눌러 보지 않으면 슬래시 문법이 있는 줄 모른다.
struct PomodoroInputTip: Tip {
    /// 뽀모도로가 아닌 타이머를 하나 만든 순간.
    static let timerAdded = Event(id: "tip.timerAdded")

    /// 뽀모도로를 한 번이라도 만들었으면 다시 뜨지 않는다 (입력창 · 단축키 · 메뉴 어느 쪽이든).
    @Parameter static var hasUsedPomodoro: Bool = false

    /// 팁의 "해 보기" — 입력창에 예시를 채운다.
    static let tryActionID = "try"

    var title: Text { Text(L("tip.pomodoro.title")) }
    var message: Text? { Text(L("tip.pomodoro.message")) }
    var image: Image? { Image(systemName: "arrow.triangle.2.circlepath") }

    var actions: [Action] {
        Action(id: Self.tryActionID, title: L("tip.pomodoro.try"))
    }

    var rules: [Rule] {
        #Rule(Self.$hasUsedPomodoro) { $0 == false }
        #Rule(Self.timerAdded) { $0.donations.count >= 2 }
    }

    /// 타이머가 새로 생길 때마다 부른다. 어디서 만들었든 같은 규칙으로 센다.
    static func record(isPomodoro: Bool) {
        if isPomodoro {
            hasUsedPomodoro = true
        } else {
            Task { await timerAdded.donate() }
        }
    }
}
