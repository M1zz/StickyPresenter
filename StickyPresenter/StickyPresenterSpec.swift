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
    // 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: StickyPresenterSpec.self)
}
