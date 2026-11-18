import Foundation

// MARK: - 연결되면 보낼 명령
// 단축어("Remote Controller 로 5분 타이머 시작")는 앱을 연 순간 실행되지만, 그때는 아직 Mac 과
// 붙기 전이다(찾고 → 붙는 데 1~2초). 명령을 여기 맡겨 두고, 붙는 순간 RemoteRootView 가 꺼내 보낸다.
//
// 오래된 명령은 버린다 — 강의실 밖에서 눌러 둔 단축어가 한참 뒤 다른 발표 중에 타이머를
// 띄우면 안 된다. 순수 값 타입이라 시험에서 시간을 주입해 확인한다.

struct PendingCommandQueue {
    /// 이보다 오래 기다린 명령은 보내지 않는다.
    static let maxAge: TimeInterval = 120

    private(set) var items: [(command: RemoteCommand, queuedAt: Date)] = []

    var isEmpty: Bool { items.isEmpty }

    mutating func enqueue(_ command: RemoteCommand, at date: Date = Date()) {
        items.append((command, date))
    }

    /// 아직 유효한 명령을 넣은 순서대로 꺼내고 큐를 비운다.
    mutating func drain(now: Date = Date(), maxAge: TimeInterval = Self.maxAge) -> [RemoteCommand] {
        defer { items.removeAll() }
        return items
            .filter { now.timeIntervalSince($0.queuedAt) <= maxAge }
            .map(\.command)
    }

    mutating func removeAll() { items.removeAll() }
}

/// 분 단위 타이머 이름. Mac 앱 프리셋과 **같은 표기**("5m", "1h 30m")를 쓴다 —
/// 다르게 지으면 Mac 목록과 알림 센터 위젯에 표기가 섞여 보인다 (PresetRow 의 주석과 같은 이유).
func timerName(minutes: Int) -> String {
    let h = minutes / 60, m = minutes % 60
    switch (h, m) {
    case (0, _): return "\(m)m"
    case (_, 0): return "\(h)h"
    default:     return "\(h)h \(m)m"
    }
}
