import Foundation

// MARK: - 칸 (무료 · Plus · Pro)
//
// 앱과 위젯이 함께 컴파일한다. StoreKit 은 여기 없다 — 영수증은 앱의 `Purchases` 가 읽고,
// 그 답을 App Group 에 적어 둔다. 위젯은 그 두 값만 읽는다.

/// 칸. 값이 클수록 더 많이 연다. Pro 는 Plus 를 전부 포함한다.
enum PlanTier: Int, Comparable, CaseIterable {
    case free = 0
    case plus = 1
    case pro = 2

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    /// 리모컨과 나누는 이름 (`RemoteState.hostTier`). ⚠️ 리모컨 앱과의 약속이라 바꾸지 않는다.
    var wireName: String {
        switch self {
        case .free: return "free"
        case .plus: return "plus"
        case .pro:  return "pro"
        }
    }
}

/// 앱이 적고 위젯이 읽는 칸.
enum SharedPlanStore {
    private static let tierKey = "plan.tier"
    private static let gatesKey = "plan.gatesActive"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: SharedTimerStore.appGroupID) }

    /// 마지막으로 확인한 칸. **nil 은 '무료'가 아니라 '아직 App Store 에 묻지 않았다'** 이다.
    static var tier: PlanTier? {
        (defaults?.object(forKey: tierKey) as? Int).flatMap(PlanTier.init(rawValue:))
    }

    /// 이 기기가 App Store 에서 유료 칸 상품을 한 번이라도 불러왔는가.
    /// 상품을 만들기 전에 빌드가 나가도, 살 수 없는데 막히는 사람이 없게 — 그때까지는 잠그지 않는다.
    static var gatesActive: Bool { defaults?.bool(forKey: gatesKey) ?? false }

    static func save(tier: PlanTier, gatesActive: Bool) {
        guard let defaults else { return }
        guard self.tier != tier || self.gatesActive != gatesActive else { return }
        defaults.set(tier.rawValue, forKey: tierKey)
        defaults.set(gatesActive, forKey: gatesKey)
        SharedTimerStore.reloadWidgets()
    }

    /// 알림 센터 위젯은 Pro 에서 열린다. 칸을 아직 모르거나 상품이 없으면 잠그지 않는다.
    static var widgetLocked: Bool {
        guard gatesActive, let tier else { return false }
        return tier < .pro
    }
}
