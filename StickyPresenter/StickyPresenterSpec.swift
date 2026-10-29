import Foundation
import LeeoKit

enum StickyPresenterSpec: LeeoAppSpec {
    static let appName = "StickyPresenter"
    static let developerEmail = "mizzking75@gmail.com"
    static let feedback = LeeoFeedbackConfig(containerIdentifier: "iCloud.com.Ysoup.FeedbackHub", appIdentifier: "com.leeo.StickyPresenter")
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/StickyPresenter/privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/StickyPresenter/support.html")!)
    /// App Store 숫자 ID — 설정의 친구에게 소개하기·리뷰 남기기 링크가 쓴다.
    static let appStoreID: String? = "6778457299"
    static let monetization = LeeoMonetization.free
    /// 개발자 응원하기(팁, 소모성 세 가지 — 작은 것부터). 기능을 열지 않는다.
    /// 무료 앱이라 LeeoStore 가 없다 — 앱이 뜰 때 `startStandalone()` 으로 혼자 선다.
    @MainActor static let tipJar = LeeoTipJar(config: LeeoTipJarConfig(productIDs: [
        "com.leeo.StickyPresenter.tip.small",
        "com.leeo.StickyPresenter.tip.medium",
        "com.leeo.StickyPresenter.tip.large"
    ]))
    // 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: StickyPresenterSpec.self)
}
