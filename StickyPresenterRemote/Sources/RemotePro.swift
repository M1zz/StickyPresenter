import Combine
import Foundation
import LeeoKit
import StoreKit

// MARK: - Pro
//
// 칸은 둘이다: 무료 · Pro.
//
// **Pro 는 Mac 의 StickyPresenter Pro 와 같은 상품이다.** 이 앱은 Mac 앱과 번들 ID 가 같은
// (`com.leeo.StickyPresenter`) 한 레코드의 iPhone · Watch 판이라, 어느 기기에서 사든 양쪽 영수증에 선다.
// 그래서 상품 ID 는 `Plan.swift`(Mac 레포)의 Pro 상품과 글자 하나까지 같다. Plus 는 리모컨에서 여는 것이 없다.
//
// **발표를 넘기는 조작은 언제나 무료다.** 연결 · 시작 · 멈춤 · 30초 조정 · 초기화 · 새 타이머 ·
// Siri · 단축어 · 감추기 · 정렬 · 지우기는 잠그지 않는다. 연단에서 타이머를 못 멈추게 하면
// 그건 파는 게 아니라 발표를 망치는 것이다.
// Pro 는 그 위에 얹는 것만 판다: 타이머 창 꾸미기(크기 · 테마), 끌어서 옮기기, Apple Watch.
//
// ⚠️ 스토어에서 Pro 상품을 **한 번도** 불러온 적이 없는 기기는 잠그지 않는다(`allows`).
//    App Store Connect 에 상품을 만들기 전에 빌드가 나가도, 살 수 없는데 막히는 사람이 없게.

/// Pro 에서 열리는 것. 페이월 비교표와 잠금 안내가 이 목록 하나를 읽는다.
enum RemoteProFeature: String, CaseIterable, Identifiable {
    /// 타이머 창 크기(S · M · L)와 테마
    case appearance
    /// 위치 판을 끌어 Mac 의 타이머 창 옮기기 (여러 화면 사이로도)
    case position
    /// Apple Watch: 남은 시간 · 5분/1분/끝 손목 진동 · 손목 조작
    case watch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance: String(localized: "타이머 창 크기 · 테마")
        case .position:   String(localized: "끌어서 옮기기 · 다른 화면으로")
        case .watch:      String(localized: "Apple Watch 남은 시간 · 손목 진동")
        }
    }

    var systemImage: String {
        switch self {
        case .appearance: "paintpalette"
        case .position:   "hand.draw"
        case .watch:      "applewatch.radiowaves.left.and.right"
        }
    }
}

enum RemoteProducts {
    private static let prefix = "com.leeo.StickyPresenter.mac.pro"

    // ⚠️ App Store Connect · Config/RemoteProducts.storekit · Mac 레포의 `PlanEntitlement` 와 글자 하나까지 같아야 한다.
    static let yearly = "\(prefix).yearly"
    static let monthly = "\(prefix).monthly"
    static let weekly = "\(prefix).weekly"
    /// 평생 (비소모성)
    static let lifetime = "\(prefix).lifetime"
    /// 구독 졸업: 구독 중인 사람만 보는 평생가 (비소모성, `LeeoGraduation`). 열면 평생과 같다.
    static let graduate = "\(prefix).graduate"
    /// Plus 평생을 가진 사람만 보는 Pro 평생 올리기 (비소모성). 열면 평생과 같다.
    static let upgrade = "\(prefix).upgrade"
    /// Mac 에서 산 Plus 평생. 리모컨에서는 아무것도 열지 않고, 평생 단추를 올리기 값으로 바꿀 뿐이다.
    static let plusLifetime = "com.leeo.StickyPresenter.mac.plus.lifetime"

    /// 페이월이 불러올 상품. 연 구독이 기본이다.
    /// ⚠️ 팁 상품은 넣지 않는다 — 넣으면 팁을 낸 사람이 Pro 가 된다.
    static let all = [yearly, lifetime, monthly, weekly, graduate, upgrade]

    /// 구독 졸업을 제안할 구독. 주 · 월 구독에 졸업가를 주면 한 주 값으로 평생이 싸지므로 연만.
    static let graduationSubscriptions: Set<String> = [yearly]
}

@MainActor
final class RemotePro: ObservableObject {
    static let shared = RemotePro()

    let store: LeeoStore

    /// 지금 살아 있는 연 구독. 있으면 설정에 '평생으로 바꾸기' 가 서고, 때가 되면 졸업가를 보인다.
    @Published private(set) var subscription: LeeoGraduation.Subscription?

    /// 잠긴 조작을 눌러 띄운 페이월. 루트 화면이 시트로 띄운다.
    @Published var paywall: RemoteProFeature?

    /// 이 기기가 스토어에서 Pro 상품을 한 번이라도 받아 봤는가.
    /// 네트워크가 잠깐 끊겨 못 불러온 것과 "아직 상품이 없다" 를 가르는 기준이다.
    @Published private(set) var hasSeenProducts: Bool
    private static let seenKey = "remote.pro.productsSeen"

    private var observation: AnyCancellable?

    private init() {
        guard let config = RemoteSpec.paywall else {
            preconditionFailure("RemoteSpec.monetization 에 페이월이 없다")
        }
        store = LeeoStore(config: config)
        hasSeenProducts = UserDefaults.standard.bool(forKey: Self.seenKey)
        // 스토어의 변화(구매 · 환불 · 만료 · 상품 도착)를 이 객체를 보는 화면에 그대로 흘린다.
        observation = store.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
            Task { @MainActor in self?.noteProducts() }
        }
    }

    var hasPro: Bool { store.hasPro }

    /// 이 기능을 지금 써도 되는가.
    func allows(_ feature: RemoteProFeature) -> Bool { hasPro || !hasSeenProducts }

    /// 잠겨 있으면 페이월을 띄우고 false.
    func check(_ feature: RemoteProFeature) -> Bool {
        if allows(feature) { return true }
        paywall = feature
        return false
    }

    func product(_ id: String) -> Product? { store.products.first { $0.id == id } }

    /// Mac 에서 Plus 평생을 샀는가. 그러면 평생 단추가 올리기 상품을 판다.
    @Published private(set) var ownsPlusLifetime = false

    /// 페이월의 평생 자리에 설 상품.
    var lifetimeProductID: String { ownsPlusLifetime ? RemoteProducts.upgrade : RemoteProducts.lifetime }

    private func readPlusLifetime() async {
        var owns = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement, transaction.revocationDate == nil,
               transaction.productID == RemoteProducts.plusLifetime { owns = true }
        }
        ownsPlusLifetime = owns
    }

    /// 앱이 켜지고 앞으로 나올 때마다 영수증을 다시 읽는다.
    func refresh() async {
        await store.refreshEntitlements()
        await store.loadProducts()
        noteProducts()
        await readPlusLifetime()
        subscription = await LeeoGraduation.currentSubscription(among: RemoteProducts.graduationSubscriptions)
    }

    /// 산 뒤 · 졸업가를 산 뒤.
    func didPurchase() async {
        await store.refreshEntitlements()
        subscription = await LeeoGraduation.currentSubscription(among: RemoteProducts.graduationSubscriptions)
    }

    /// 구독 졸업을 제안할 때인가 (6개월째 · 갱신 7일 전에 한 번씩).
    var graduationIsDue: Bool {
        guard let subscription, product(RemoteProducts.graduate) != nil else { return false }
        return LeeoGraduation.isDue(subscription, lastOffered: LeeoGraduation.lastOffered())
    }

    private func noteProducts() {
        guard !hasSeenProducts, !store.products.isEmpty else { return }
        hasSeenProducts = true
        UserDefaults.standard.set(true, forKey: Self.seenKey)
    }
}
