import Foundation

/// 워치 앱과 컴플리케이션이 함께 보는 '마지막으로 받은 한 장'. iPhone 이 멀어져도 이것으로 센다.
enum WatchStore {
    static let group = "group.com.leeo.StickyPresenter.Remote"
    private static let savedAtKey = "savedAt"
    private static var defaults: UserDefaults { UserDefaults(suiteName: group) ?? .standard }

    static func load() -> WatchSnapshot? {
        // 반나절 지난 장은 버린다 — 발표는 끝났고, iPhone 이 '끝' 을 못 보낸 채 멀어진 것이다.
        guard defaults.double(forKey: savedAtKey) > Date.now.addingTimeInterval(-12 * 3600).timeIntervalSince1970
        else { return nil }
        return WatchSnapshot.decode(defaults.data(forKey: WatchSnapshot.key))
    }

    static func save(_ snapshot: WatchSnapshot?) {
        defaults.set(snapshot?.encoded(), forKey: WatchSnapshot.key)
        defaults.set(Date.now.timeIntervalSince1970, forKey: savedAtKey)
    }
}

/// "8:42" · "1:02:30" (언어마다 시스템 타이머 글자와 같은 모양). 멈춰 있을 때의 남은 시간 —
/// 돌고 있을 때는 시스템 타이머 글자가 센다.
func clockText(_ seconds: TimeInterval) -> String {
    let total = Int(seconds.rounded(.up))
    return Duration.seconds(total)
        .formatted(.time(pattern: total >= 3600 ? .hourMinuteSecond : .minuteSecond))
}
