import Foundation
import LeeoKit

// MARK: - 앱 계약 (LeeoKit)
// 피드백 · 리뷰 요청 · 익명 사용 통계 · 크래시 진단 · 원격 킬스위치가 이 계약 하나로 켜진다.
// Mac 앱(StickyPresenterSpec)과 같은 FeedbackHub 컨테이너를 쓰고, appIdentifier 로 갈라 센다.

enum RemoteSpec: LeeoAppSpec {
    /// 식별 이름 — 피드백·통계 기록이 이 값으로 묶인다. 화면에 보이는 이름은 CFBundleDisplayName.
    static let appName = "StickyPresenterRemote"
    static let developerEmail = "mizzking75@gmail.com"
    static let feedback = LeeoFeedbackConfig(containerIdentifier: "iCloud.com.Ysoup.FeedbackHub",
                                             appIdentifier: "com.leeo.StickyPresenter.Remote")
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/StickyPresenter/remote-privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/StickyPresenter/remote.html")!)
    static let monetization = LeeoMonetization.free
    static let appStoreID: String? = "6803358945"
    // 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: RemoteSpec.self)

    /// 짝이 되는 Mac 앱 — 리모컨만으로는 아무것도 할 수 없어서 첫 실행 안내와 설정에서 권한다.
    static let macAppURL = URL(string: "https://apps.apple.com/app/id6778457299")!
    static let instagramURL = URL(string: "https://instagram.com/lee25_ios")!
}

// MARK: - 원격 킬스위치
// ⚠️ rawValue = CloudKit 필드명 계약 — 바꾸면 아무리 꺼도 켜진 채로 도는 조용한 실패. 바꾸지 말 것.
// ⚠️ 조회 실패 = 켬. 갱신은 6시간 쓰로틀 + 백그라운드라 **다음 실행부터** 반영된다.
// Dashboard (1회): 레코드 타입 RemoteFlags, recordName "flags_com.leeo.StickyPresenter.Remote",
// 플래그마다 Int64 필드(1=켬 · 0=끔), Production 배포. 필드가 없으면 켬으로 동작한다.

enum RemoteFlag: String, LeeoRemoteFlag, CaseIterable {
    /// 지난번에 짝을 맺은 Mac 이 보이면 코드 없이 저절로 붙는 동작.
    /// 사람 손을 거치지 않고 네트워크 너머로 초대를 보내는 유일한 자리라, Mac 쪽 짝 판정에 문제가
    /// 드러나거나 재접속이 되풀이되는 일이 생기면 이것만 끈다. 끄면 목록에서 Mac 을 직접 골라
    /// 코드를 넣는 길만 남는다 (코드 입력 연결은 그대로).
    case autoReconnectEnabled
}
