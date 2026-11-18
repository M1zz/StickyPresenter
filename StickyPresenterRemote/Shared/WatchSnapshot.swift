import Foundation

// MARK: - iPhone ↔ Apple Watch 규약
//
// 워치는 Mac 과 직접 이야기하지 않는다. watchOS 에서 로컬 네트워크(MultipeerConnectivity)는
// 쓸 수 없거나 제약이 커서, iPhone 리모컨이 가운데서 전해 준다(WatchConnectivity).
//
//   iPhone → 워치: 지금 볼 타이머 한 장(`WatchSnapshot`). 남은 시간이 아니라 **끝나는 시각**을 실어
//                  보내므로, iPhone 이 주머니에서 잠겨도 워치가 혼자 세고 혼자 진동한다.
//   워치 → iPhone: 시작·일시정지 · 30초 더하기 · 빼기 (`WatchCommand`). iPhone 이 Mac 에 붙어 있을 때만 통한다.
//
// iPhone 앱 · 워치 앱 · 컴플리케이션이 이 파일 하나를 같이 컴파일한다.

/// 워치에 띄울 타이머 하나. Mac 의 `RemoteTimer` 에서 워치에 필요한 것만 옮겨 담는다.
struct WatchTimer: Codable, Equatable, Sendable {
    var id: UUID
    var name: String
    /// 뽀모도로 구간 이름 ("Focus" / "Break"). Mac 이 자기 언어로 보낸 값 그대로.
    var phase: String?
    /// 처음 맞춘 길이 — 진행 막대와 "이 타이머에 5분 알림이 의미 있는가" 를 가르는 데 쓴다.
    var target: TimeInterval
    var isRunning: Bool
    /// 돌고 있으면 끝나는 시각. 멈춰 있으면 nil.
    var endsAt: Date?
    /// 멈춰 있을 때 남은 시간. 돌고 있을 때는 `endsAt` 이 기준이다.
    var pausedRemaining: TimeInterval

    func remaining(at now: Date = .now) -> TimeInterval {
        guard isRunning, let endsAt else { return pausedRemaining }
        return max(0, endsAt.timeIntervalSince(now))
    }

    /// 남은 몫 (1 → 0). 막대 · 게이지는 시간이 갈수록 줄어든다.
    func fractionLeft(at now: Date = .now) -> Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, remaining(at: now) / target))
    }

    /// 워치가 먼저 그려 보는 다음 모습 — 버튼을 누르자마자 손목이 답하게. 진짜 값은 곧 iPhone 이 보낸다.
    func applying(_ command: WatchCommand, now: Date = .now) -> WatchTimer {
        var next = self
        let left = remaining(at: now)
        switch command {
        case .toggle:
            next.isRunning.toggle()
            next.pausedRemaining = left
            next.endsAt = next.isRunning ? now.addingTimeInterval(left) : nil
        case .plus, .minus:
            let moved = max(0, left + (command == .plus ? WatchCommand.step : -WatchCommand.step))
            next.pausedRemaining = moved
            if isRunning { next.endsAt = now.addingTimeInterval(moved) }
        }
        return next
    }
}

/// iPhone 이 워치에 보내는 한 장.
struct WatchSnapshot: Codable, Equatable, Sendable {
    /// Mac 이름 (예: "MacBook Pro").
    var host: String?
    /// 지금 iPhone 이 Mac 에 붙어 있는가 — 워치 버튼이 통하는지 가른다.
    /// 끊겨도 `timer` 는 마지막 값 그대로 둔다. Mac 의 타이머는 그대로 돌고 있으니 손목은 계속 센다.
    var connected: Bool
    var timer: WatchTimer?
    /// iPhone 리모컨에 Pro 가 없어 손목에 타이머를 보내지 않는다. 그때 `timer` 는 nil.
    /// 옵셔널이라 이 필드를 모르는 옛 장도 그대로 읽힌다.
    var locked: Bool? = nil

    static let key = "snapshot"

    func encoded() -> Data? { try? JSONEncoder().encode(self) }
    static func decode(_ data: Data?) -> WatchSnapshot? {
        data.flatMap { try? JSONDecoder().decode(WatchSnapshot.self, from: $0) }
    }
}

/// 워치 → iPhone. Mac 의 `addSeconds` · `subtractSeconds` 는 30초씩 움직인다.
enum WatchCommand: String, Codable, Sendable {
    case toggle, plus, minus

    static let step: TimeInterval = 30
    static let key = "command"
    static let timerKey = "timer"
    /// 답장: iPhone 이 Mac 에 전했는가.
    static let okKey = "ok"
}

/// 손목이 울리는 때: 5분 · 1분 남았을 때, 그리고 끝날 때.
enum WatchMilestone: Int, CaseIterable, Sendable {
    case fiveMinutes = 300
    case oneMinute = 60
    case end = 0

    var secondsLeft: TimeInterval { TimeInterval(rawValue) }

    /// 이 타이머에서 이 순간이 울릴 만한가 — 3분짜리 타이머에 "5분 남음" 은 없다.
    func applies(to timer: WatchTimer) -> Bool {
        self == .end || secondsLeft < timer.target
    }
}
