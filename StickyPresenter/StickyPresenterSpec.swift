import Foundation
import LeeoKit

enum StickyPresenterSpec: LeeoAppSpec {
    static let appName = "StickyPresenter"
    static let developerEmail = "mizzking75@gmail.com"
    static let feedback = LeeoFeedbackConfig(containerIdentifier: "iCloud.com.Ysoup.FeedbackHub", appIdentifier: "com.leeo.StickyPresenter")
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/StickyPresenter/privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/StickyPresenter/support.html")!)
    static let monetization = LeeoMonetization.free
}
