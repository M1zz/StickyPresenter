import Foundation
import LeeoKit

enum StickyPresenterSpec: LeeoAppSpec {
    static let appName = "StickyPresenter"
    static let developerEmail = "leeo@kakao.com"
    static let feedback = LeeoFeedbackConfig(containerIdentifier: "iCloud.com.Ysoup.FeedbackHub", appIdentifier: "com.leeo.StickyPresenter")
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/StickyPresenter/privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/StickyPresenter/support.html")!)
    /// App Store 숫자 ID — 설정의 친구에게 소개하기·리뷰 남기기 링크가 쓴다.
    static let appStoreID: String? = "6778457299"
    /// 수익모델 — 무료 다운로드 + 무료 · Plus · Pro. 칸마다 주 · 월 · 연 구독과 평생.
    /// 무엇이 어느 칸에서 열리는지는 `PlanFeature.tier` 한 곳, 상품은 `PlanEntitlement` 에 있다 (Purchases.swift).
    static let monetization = LeeoMonetization.freemiumSubscription(
        LeeoSubscriptionConfig(
            productIDs: PlanEntitlement.productIDs,
            // 자체 약관이 없으므로 애플 표준 사용권 계약(EULA)을 건다. 구독을 파는 앱의 심사 필수 항목이다.
            termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
            entitlementIDs: PlanEntitlement.entitlementIDs,
            gate: LeeoGatePolicy(
                // 한도는 새로 만들 때만 막는다. 이미 띄운 노트 · 타이머는 그대로 쓴다.
                freeLimits: [PlanFeature.notes.rawValue: PlanEntitlement.freeNotes,
                             PlanFeature.timers.rawValue: PlanEntitlement.freeTimers],
                proOnly: Set(PlanFeature.allCases.filter { $0 != .notes && $0 != .timers }.map(\.rawValue))),
            // 개발자 응원하기(팁, 소모성 셋). 기능을 열지 않는다. LeeoStore 가 결제 리스너를 함께 쓴다.
            tipJar: LeeoTipJarConfig(productIDs: PlanEntitlement.tipProductIDs)))
    /// 백업 금고가 함께 담는 앱 그룹.
    static let appGroups = ["QGAQ3AY3R3.group.com.leeo.StickyPresenter"]
    /// 개발자 응원하기(팁). 기능을 열지 않는다. 엔진은 Plus · Pro 와 같은 LeeoStore 안에 있다.
    @MainActor static var tipJar: LeeoTipJar {
        guard let tipJar = Purchases.shared.store.tipJar else { preconditionFailure("계약에 팁이 없다") }
        return tipJar
    }
    // 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: StickyPresenterSpec.self)
}
