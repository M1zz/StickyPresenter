import Foundation
import StoreKit

// MARK: - 무료 · Plus · Pro
//
//   · 무료: 노트 5장 · 타이머 2개, 뽀모도로, 시스템 · 밝게 · 어둡게 테마, 끝날 때 알림,
//           텔레프롬프터, 단축키, 노트 내보내기 · 불러오기, iPhone 리모컨 3번 체험
//   · Plus: 노트 · 타이머 무제한, 카멜레온 테마, 빠른 시간 프리셋 편집, 배경음악, 텔레프롬프터 좌우 반전
//   · Pro:  Plus 전부 + iPhone 리모컨, 타이머 별도 창(화면 공유 · AirPlay), 단축어 · Siri, 알림 센터 위젯
//
// ⚠️ 절대 잠그지 않는 것: 이미 띄운 노트 · 타이머(한도를 넘어도 그대로 쓴다), 보기 · 지우기,
//    내보내기, 접근성, 끝날 때의 알림음 · 깜빡임.

/// 값을 받고 여는 것. 페이월 · 잠금 자리가 모두 이 목록만 읽는다.
enum PlanFeature: String, Identifiable, CaseIterable {
    case notes, timers, chameleon, presets, music, mirror
    case remote, timerWindow, shortcuts, widget

    var id: String { rawValue }

    /// 이 기능을 여는 가장 낮은 칸.
    var tier: PlanTier {
        switch self {
        case .notes, .timers, .chameleon, .presets, .music, .mirror: return .plus
        case .remote, .timerWindow, .shortcuts, .widget:             return .pro
        }
    }
}

enum PlanEntitlement {

    // MARK: 무료 한도

    static let freeNotes = 5
    static let freeTimers = 2
    /// iPhone 리모컨을 써 볼 수 있는 발표 수.
    static let freeRemoteTalks = 3

    // MARK: 상품 ID
    //
    // ⚠️ App Store Connect · StickyPresenter.storekit 과 글자 하나까지 같아야 한다.
    //    주 · 월 · 연 구독 여섯은 한 구독 그룹에 넣고 Pro 를 위 단계로 둔다(서로 갈아탈 때 남은 기간이 정산된다).

    private static let base = "com.leeo.StickyPresenter"
    /// 유료 상품은 `.mac` 을 붙인다. `com.leeo.StickyPresenter.plus.*` 는 리모컨 앱 쪽에 한 번 만들어졌다가
    /// 지워져 다시 쓸 수 없다(App Store Connect 는 지운 상품 ID 를 돌려주지 않는다).
    private static let paid = base + ".mac"

    static let plusWeeklyID   = paid + ".plus.weekly"
    static let plusMonthlyID  = paid + ".plus.monthly"
    static let plusYearlyID   = paid + ".plus.yearly"
    static let plusLifetimeID = paid + ".plus.lifetime"
    static let proWeeklyID    = paid + ".pro.weekly"
    static let proMonthlyID   = paid + ".pro.monthly"
    static let proYearlyID    = paid + ".pro.yearly"
    static let proLifetimeID  = paid + ".pro.lifetime"
    /// Plus 평생을 산 사람만 보는 Pro 평생 올리기.
    static let upgradeID      = paid + ".pro.upgrade"
    /// 구독 중인 사람의 졸업가 Pro 평생 (→ LeeoGraduation).
    static let graduateID     = paid + ".pro.graduate"

    /// 개발자 응원 팁. 아무것도 열지 않는다 — `tierByProduct` 에 넣지 않는다.
    static let tipProductIDs = [base + ".tip.small", base + ".tip.medium", base + ".tip.large"]

    static let tierByProduct: [String: PlanTier] = [
        plusWeeklyID: .plus, plusMonthlyID: .plus, plusYearlyID: .plus, plusLifetimeID: .plus,
        proWeeklyID: .pro, proMonthlyID: .pro, proYearlyID: .pro, proLifetimeID: .pro,
        upgradeID: .pro, graduateID: .pro,
    ]

    /// 페이월이 불러올 상품. 스토어에 아직 없는 상품은 불러와지지 않고, 그 단추는 서지 않는다.
    static let productIDs: [String] = [
        plusYearlyID, plusLifetimeID, plusMonthlyID, plusWeeklyID,
        proYearlyID, proLifetimeID, proMonthlyID, proWeeklyID,
        upgradeID, graduateID,
    ]

    static var entitlementIDs: Set<String> { Set(tierByProduct.keys) }

    static let subscriptionIDs: Set<String> = [
        plusWeeklyID, plusMonthlyID, plusYearlyID, proWeeklyID, proMonthlyID, proYearlyID,
    ]

    static let lifetimeIDs: Set<String> = [plusLifetimeID, proLifetimeID, upgradeID, graduateID]

    static func tier(owning productIDs: Set<String>) -> PlanTier {
        productIDs.compactMap { tierByProduct[$0] }.max() ?? .free
    }

    static func ownsLifetime(_ tier: PlanTier, in productIDs: Set<String>) -> Bool {
        productIDs.contains { lifetimeIDs.contains($0) && tierByProduct[$0] == tier }
    }

    // MARK: 먼저 쓰던 사람

    /// 페이월이 생기기 전 마지막 마케팅 버전. 그때까지 받은 사람은 Pro 를 그대로 쓴다 —
    /// 리모컨 · 단축어 · 별도 창을 쓰던 사람이 다음 발표에서 막히지 않게.
    /// ⚠️ 페이월이 든 빌드는 이보다 높은 마케팅 버전(1.2.0 이상)으로 낸다.
    static let lastVersionBeforePaywall = "1.1.1"

    /// App Store 에서 처음 받은 버전이 페이월 전인가. macOS 의 `originalAppVersion` 은 마케팅 버전이다.
    /// 샌드박스 · Xcode 는 실제 처음 받은 버전을 돌려주지 않으므로 실제 App Store 만 본다.
    static func isEarlyUser() async -> Bool {
        guard case .verified(let app)? = try? await AppTransaction.shared,
              app.environment == .production else { return false }
        return isBeforePaywall(app.originalAppVersion)
    }

    static func isBeforePaywall(_ version: String) -> Bool {
        version.compare(lastVersionBeforePaywall, options: .numeric) != .orderedDescending
    }
}

// MARK: - 리모컨 체험

/// iPhone 리모컨 3번 체험. **발표 한 번 = 한 번**이다 — 발표 중 iPhone 이 잠들었다 다시 붙는 것은 세지 않는다.
/// 마지막으로 리모컨을 쓴 뒤 2시간 안에 다시 붙으면 같은 발표로 본다.
struct RemoteTrial {
    static let sameTalkWindow: TimeInterval = 2 * 60 * 60

    private let defaults: UserDefaults
    private static let usedKey = "remote.trial.used"
    private static let lastKey = "remote.trial.lastActive"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var used: Int { defaults.integer(forKey: Self.usedKey) }
    var left: Int { max(0, PlanEntitlement.freeRemoteTalks - used) }

    /// 지금 체험 중인 발표가 있는가.
    func isActive(now: Date = Date()) -> Bool {
        guard let last = defaults.object(forKey: Self.lastKey) as? Date else { return false }
        return now.timeIntervalSince(last) < Self.sameTalkWindow
    }

    /// 리모컨이 새로 붙었다. 체험으로 받을 수 있으면 true (필요하면 한 번을 쓴다).
    func admit(now: Date = Date()) -> Bool {
        if isActive(now: now) { touch(now); return true }
        guard used < PlanEntitlement.freeRemoteTalks else { return false }
        defaults.set(used + 1, forKey: Self.usedKey)
        touch(now)
        return true
    }

    /// 체험 중인 발표를 이어 간다 (명령이 올 때마다).
    func touch(_ now: Date = Date()) { defaults.set(now, forKey: Self.lastKey) }
}
