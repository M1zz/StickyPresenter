import Foundation
import Combine
import StoreKit
import SwiftUI
import LeeoKit

// MARK: - Purchases

/// StickyPresenter Plus · Pro 를 파는 자리. **속은 전부 `LeeoStore` 다.**
/// 이 클래스는 LeeoStore 의 값을 칸으로 바꾸고, 그 답을 위젯과 나눈다.
@MainActor
final class Purchases: ObservableObject {
    static let shared = Purchases()

    let store: LeeoStore

    /// 산 것으로 정해진 칸 (상품이 없어 잠그지 않는 것과는 따로).
    @Published private(set) var tier: PlanTier = SharedPlanStore.tier ?? .free
    @Published private(set) var products: [Product] = []
    @Published private(set) var ownedProductIDs: Set<String> = []
    /// 지금 살아 있는 구독. 있으면 설정에 '구독 관리 열기' 가 선다.
    @Published private(set) var subscription: LeeoGraduation.Subscription?
    @Published private(set) var isWorking = false
    @Published private(set) var failureMessage: String?
    /// 유료 칸 상품을 한 번이라도 불러왔는가. 그 전에는 아무것도 잠그지 않는다.
    @Published private(set) var gatesActive = SharedPlanStore.gatesActive
    @Published private(set) var isEarlyUser = false

    /// ⚠️ 이번 실행에서 영수증을 실제로 읽기 전에는 칸을 정하지 않는다.
    ///    LeeoStore 는 불러오는 중에도 바뀌었다고 알려 오는데, 그때 빈 권한을 적으면 산 사람이 '무료'로 못박힌다.
    private var entitlementsChecked = false
    private var observation: AnyCancellable?

    let remoteTrial = RemoteTrial()

    private init() {
        guard let config = StickyPresenterSpec.paywall else {
            preconditionFailure("계약에 페이월이 없다. StickyPresenterSpec.monetization 을 확인할 것")
        }
        store = LeeoStore(config: config, grandfather: { await PlanEntitlement.isEarlyUser() })
        // objectWillChange 는 바뀌기 **직전**에 온다. 다음 차례로 미뤄 읽는다.
        observation = store.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in self?.pull() }
        }
    }

    // MARK: 판정

    /// 이 기능이 지금 열려 있는가.
    func allows(_ feature: PlanFeature) -> Bool { !gatesActive || tier >= feature.tier }

    func canAddNote(having count: Int) -> Bool { allows(.notes) || count < PlanEntitlement.freeNotes }
    func canAddTimer(having count: Int) -> Bool { allows(.timers) || count < PlanEntitlement.freeTimers }

    /// 리모컨 명령을 받아도 되는가. 체험 중이면 그 발표를 이어 가고, 붙은 채 오래 쉬었다면 남은 체험 한 번을 쓴다.
    func remoteControlAllowed() -> Bool {
        allows(.remote) || remoteTrial.admit()
    }

    /// 리모컨이 지금 명령을 보낼 수 없는가 (체험을 다 썼고 체험 중인 발표도 없다).
    var remoteLocked: Bool {
        !allows(.remote) && remoteTrial.left == 0 && !remoteTrial.isActive()
    }

    /// 리모컨에 보내는 본체 칸. 상품이 없어 잠그지 않을 때는 Pro 처럼 다 연다.
    var effectiveTier: PlanTier { gatesActive ? tier : .pro }

    func ownsLifetime(_ tier: PlanTier) -> Bool { PlanEntitlement.ownsLifetime(tier, in: ownedProductIDs) }
    func product(_ id: String) -> Product? { products.first { $0.id == id } }

    // MARK: 상태 맞추기

    /// 영수증을 다시 읽어 칸을 정한다. 앱이 켜질 때 부른다.
    func refresh() async {
        await store.refreshEntitlements()
        entitlementsChecked = true
        await store.loadProducts()
        subscription = await LeeoGraduation.currentSubscription(among: PlanEntitlement.subscriptionIDs)
        pull()
    }

    func loadProducts() async {
        await store.loadProducts()
        pull()
    }

    /// 구독 졸업을 제안할 때인가. 6개월째와 갱신 7일 전에 한 번씩.
    var graduationIsDue: Bool {
        guard let subscription, product(PlanEntitlement.graduateID) != nil, !ownsLifetime(.pro) else { return false }
        return LeeoGraduation.isDue(subscription, lastOffered: LeeoGraduation.lastOffered())
    }

    // MARK: 사기 / 되찾기

    func purchase(_ product: Product, using action: PurchaseAction) async {
        _ = await store.purchase(product) { try await action($0) }
        await afterTransaction()
    }

    /// 구독 졸업처럼 LeeoKit 화면이 직접 산 뒤에 부른다.
    func afterTransaction() async {
        await store.refreshEntitlements()
        entitlementsChecked = true
        subscription = await LeeoGraduation.currentSubscription(among: PlanEntitlement.subscriptionIDs)
        pull()
    }

    func restore() async {
        await store.restore()
        entitlementsChecked = true
        pull()
        if tier == .free, failureMessage == nil {
            failureMessage = L("plan.restore.none")
        }
    }

    // MARK: 발표 시간을 지킨 횟수

    nonisolated private static let talksKey = "plan.finishedTalks"
    private static let talksOfferedKey = "plan.talksOffered"
    static let talksMoment = 5

    nonisolated static var finishedTalks: Int { UserDefaults.standard.integer(forKey: talksKey) }

    /// 일반 타이머가 끝까지 돌았다.
    nonisolated static func recordFinishedTalk() {
        UserDefaults.standard.set(finishedTalks + 1, forKey: talksKey)
    }

    /// '지금까지 5번 발표 시간을 지켰어요' 를 한 번 보일 때인가. 무료로 쓰는 사람에게만.
    func takeTalksMoment() -> Bool {
        let d = UserDefaults.standard
        guard gatesActive, tier == .free, Self.finishedTalks >= Self.talksMoment,
              !d.bool(forKey: Self.talksOfferedKey) else { return false }
        d.set(true, forKey: Self.talksOfferedKey)
        return true
    }

    // MARK: -

    private func pull() {
        if entitlementsChecked {
            tier = store.isGrandfathered ? .pro : PlanEntitlement.tier(owning: store.purchasedProductIDs)
            isEarlyUser = store.isGrandfathered
        }
        products = store.products
        ownedProductIDs = store.purchasedProductIDs
        if !gatesActive, products.contains(where: { PlanEntitlement.tierByProduct[$0.id] != nil }) {
            gatesActive = true
        }
        isWorking = store.purchasingProductID != nil || store.isRestoring
        failureMessage = store.lastError
        if entitlementsChecked { SharedPlanStore.save(tier: tier, gatesActive: gatesActive) }
    }
}

// MARK: - 잠긴 자리에서 부르는 한 줄

/// 막혔으면 그 기능의 페이월을 띄우고 false 를 돌려준다.
/// 노트 · 타이머 모델과 AppKit 콜백은 MainActor 표시가 없지만 늘 메인 스레드에서 돈다 — 그 자리에서 부른다.
enum Gate {
    /// 열려 있는가 (페이월 없이 묻기만).
    static func isOpen(_ feature: PlanFeature) -> Bool {
        MainActor.assumeIsolated { Purchases.shared.allows(feature) }
    }

    /// 써도 되는가. 막혔으면 페이월.
    static func open(_ feature: PlanFeature) -> Bool {
        MainActor.assumeIsolated {
            guard Purchases.shared.allows(feature) else {
                Paywall.present(.feature(feature))
                return false
            }
            return true
        }
    }

    /// 노트를 한 장 더 붙여도 되는가 (`count` = 지금 붙은 노트 수). 막혔으면 페이월.
    static func admitsNote(having count: Int) -> Bool {
        MainActor.assumeIsolated {
            guard Purchases.shared.canAddNote(having: count) else {
                Paywall.present(.feature(.notes))
                return false
            }
            return true
        }
    }

    /// 타이머를 하나 더 띄워도 되는가 (`count` = 지금 타이머 수). `offering` 이 false 면 페이월 없이 묻기만.
    static func admitsTimer(having count: Int, offering: Bool = true) -> Bool {
        MainActor.assumeIsolated {
            guard Purchases.shared.canAddTimer(having: count) else {
                if offering { Paywall.present(.feature(.timers)) }
                return false
            }
            return true
        }
    }
}
