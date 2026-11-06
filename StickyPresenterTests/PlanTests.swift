import XCTest

/// 무료 · Plus · Pro 의 판정 (→ Plan.swift, Shared/PlanTier.swift).
/// 상품마다 여는 칸, 기능마다 필요한 칸, 먼저 쓰던 사람, 리모컨 체험, 리모컨과의 약속.
final class PlanTests: XCTestCase {

    private typealias E = PlanEntitlement

    // MARK: 상품 → 칸

    func testProductIDsMatchStoreConsole() {
        let base = "com.leeo.StickyPresenter"
        XCTAssertEqual(E.plusYearlyID, base + ".plus.yearly")
        XCTAssertEqual(E.plusLifetimeID, base + ".plus.lifetime")
        XCTAssertEqual(E.proWeeklyID, base + ".pro.weekly")
        XCTAssertEqual(E.upgradeID, base + ".pro.upgrade")
        XCTAssertEqual(E.graduateID, base + ".pro.graduate")
    }

    func testEverySoldProductOpensATier() {
        XCTAssertEqual(Set(E.productIDs), Set(E.tierByProduct.keys))
        XCTAssertEqual(E.productIDs.count, 10)
        // 연 구독이 칸마다 맨 앞이다 — 페이월의 기본 선택.
        XCTAssertEqual(E.productIDs.first, E.plusYearlyID)
    }

    func testTipsAndPassOpenNothing() {
        for tip in E.tipProductIDs { XCTAssertNil(E.tierByProduct[tip]) }
        XCTAssertEqual(E.tier(owning: Set(E.tipProductIDs)), .free)
        XCTAssertFalse(E.productIDs.contains { $0.contains(".forever") }, "언제나 평생 패스는 팔지 않는다")
    }

    func testHighestOwnedTierWins() {
        XCTAssertEqual(E.tier(owning: []), .free)
        XCTAssertEqual(E.tier(owning: [E.plusMonthlyID]), .plus)
        XCTAssertEqual(E.tier(owning: [E.plusLifetimeID, E.proWeeklyID]), .pro)
        XCTAssertEqual(E.tier(owning: [E.plusLifetimeID, E.upgradeID]), .pro)
        XCTAssertEqual(E.tier(owning: [E.plusYearlyID, E.graduateID]), .pro)
    }

    func testLifetimeOwnership() {
        XCTAssertTrue(E.ownsLifetime(.plus, in: [E.plusLifetimeID]))
        XCTAssertFalse(E.ownsLifetime(.plus, in: [E.plusYearlyID]), "구독은 평생이 아니다")
        XCTAssertTrue(E.ownsLifetime(.pro, in: [E.upgradeID]))
        XCTAssertTrue(E.ownsLifetime(.pro, in: [E.graduateID]))
        XCTAssertTrue(E.subscriptionIDs.isDisjoint(with: E.lifetimeIDs))
    }

    // MARK: 기능 → 칸

    func testFeatureTiersMatchTheSpec() {
        XCTAssertEqual(Set(PlanFeature.allCases.filter { $0.tier == .plus }),
                       [.notes, .timers, .chameleon, .presets, .music, .mirror])
        XCTAssertEqual(Set(PlanFeature.allCases.filter { $0.tier == .pro }),
                       [.remote, .timerWindow, .shortcuts, .widget])
        XCTAssertEqual(E.freeNotes, 5)
        XCTAssertEqual(E.freeTimers, 2)
        XCTAssertEqual(E.freeRemoteTalks, 3)
    }

    // MARK: 먼저 쓰던 사람

    func testEarlyUsersAreThoseBeforeThePaywall() {
        XCTAssertTrue(E.isBeforePaywall("1.0"))
        XCTAssertTrue(E.isBeforePaywall("1.0.10"))
        XCTAssertTrue(E.isBeforePaywall("1.1.1"))
        XCTAssertFalse(E.isBeforePaywall("1.1.2"))
        XCTAssertFalse(E.isBeforePaywall("1.2.0"))
        XCTAssertFalse(E.isBeforePaywall("1.10"))
    }

    // MARK: 리모컨 체험

    private func freshDefaults() -> UserDefaults {
        let name = "PlanTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }

    func testThreeTalksThenLocked() {
        let trial = RemoteTrial(defaults: freshDefaults())
        var now = Date(timeIntervalSince1970: 0)
        for left in [2, 1, 0] {
            XCTAssertTrue(trial.admit(now: now))
            XCTAssertEqual(trial.left, left)
            now += RemoteTrial.sameTalkWindow + 1
        }
        XCTAssertFalse(trial.admit(now: now), "네 번째 발표는 Pro 에서")
        XCTAssertFalse(trial.isActive(now: now))
    }

    func testReconnectDuringTheSameTalkIsFree() {
        let trial = RemoteTrial(defaults: freshDefaults())
        let start = Date(timeIntervalSince1970: 0)
        XCTAssertTrue(trial.admit(now: start))
        XCTAssertTrue(trial.admit(now: start + 600), "iPhone 이 잠들었다 다시 붙음")
        XCTAssertEqual(trial.used, 1)
        // 명령이 오는 동안에는 발표가 이어진다.
        trial.touch(start + 3 * 60 * 60)
        XCTAssertTrue(trial.isActive(now: start + 4 * 60 * 60))
    }

    // MARK: 리모컨과의 약속

    func testWireNamesAreTheContract() {
        XCTAssertEqual(PlanTier.free.wireName, "free")
        XCTAssertEqual(PlanTier.plus.wireName, "plus")
        XCTAssertEqual(PlanTier.pro.wireName, "pro")
        XCTAssertLessThan(PlanTier.free, .plus)
        XCTAssertLessThan(PlanTier.plus, .pro)
    }
}
