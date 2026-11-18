import Foundation
import LeeoKit

// MARK: - 앱 계약 (LeeoKit)
// 피드백 · 리뷰 요청 · 익명 사용 통계 · 크래시 진단 · 원격 킬스위치가 이 계약 하나로 켜진다.
// Mac 앱(StickyPresenterSpec)과 같은 FeedbackHub 컨테이너를 쓰고, appIdentifier 로 갈라 센다.
// ⚠️ appIdentifier 는 번들 ID 가 아니라 허브의 이름표다. 번들 ID 는 Mac 앱과 같은 `com.leeo.StickyPresenter` 로
//    옮겼지만(한 레코드 · 유니버설 구매) 리모컨의 피드백 · 통계 · 원격 스위치는 이 이름표로 계속 갈린다.

enum RemoteSpec: LeeoAppSpec {
    /// 식별 이름 — 피드백·통계 기록이 이 값으로 묶인다. 화면에 보이는 이름은 CFBundleDisplayName.
    static let appName = "StickyPresenterRemote"
    static let developerEmail = "leeo@kakao.com"
    static let feedback = LeeoFeedbackConfig(containerIdentifier: "iCloud.com.Ysoup.FeedbackHub",
                                             appIdentifier: "com.leeo.StickyPresenter.Remote")
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/StickyPresenter/remote-privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/StickyPresenter/remote.html")!)
    /// 무료 · Pro 두 칸. 발표를 넘기는 조작은 무료, 꾸미고 옮기고 손목으로 받는 것이 Pro (→ RemotePro.swift).
    /// Pro 는 Mac 의 StickyPresenter Pro 와 같은 상품이다 — 한 번 사면 양쪽에서 열린다.
    /// 판정은 `RemotePro.allows` 가 한다 — 상품을 불러온 적 없는 기기는 잠그지 않는다.
    static let monetization = LeeoMonetization.freemiumSubscription(
        LeeoSubscriptionConfig(
            productIDs: RemoteProducts.all,
            // 자체 약관이 없으므로 애플 표준 사용권 계약(EULA)을 건다. 구독을 파는 앱의 심사 필수 항목이다.
            termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
            gate: LeeoGatePolicy(proOnly: Set(RemoteProFeature.allCases.map(\.rawValue))),
            // 개발자 응원하기(팁, 소모성 세 가지 — 작은 것부터). 기능을 열지 않는다.
            // ⚠️ productIDs 에 넣지 않는다 — 넣으면 팁을 낸 사람이 Pro 가 된다.
            tipJar: LeeoTipJarConfig(productIDs: [
                "com.leeo.StickyPresenter.tip.small",
                "com.leeo.StickyPresenter.tip.medium",
                "com.leeo.StickyPresenter.tip.large"
            ])))
    /// 팁 엔진은 Pro 스토어가 함께 들고 있다(결제 리스너가 하나여야 팁이 두 번 끝나지 않는다).
    @MainActor static var tipJar: LeeoTipJar { RemotePro.shared.store.tipJar! }
    // 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: RemoteSpec.self)

    /// 짝이 되는 Mac 앱 — 리모컨만으로는 아무것도 할 수 없어서 첫 실행 안내와 설정에서 권한다.
    static let macAppURL = URL(string: "https://apps.apple.com/app/id6778457299")!
    static let instagramURL = URL(string: "https://instagram.com/lee25_ios")!

    /// **앞으로 만들 것**의 원본. 설정 ▸ 앞으로 만들 기능(`LeeoRoadmapView`)이 이 목록을 그대로 보여 준다.
    /// 개발하다 "이건 다음에" 가 생기면 여기에 한 줄을 더한다(코드의 TODO 주석으로만 남기지 않는다).
    /// 새 항목 `.planned` → 손대기 시작 `.building` → 내보냄 `.shipped("버전")`. id 는 바꾸지 않는다.
    /// 문구는 사용자 말로, 24개 언어 모두 Sources/<언어>.lproj/Localizable.strings 에.
    static var roadmap: [LeeoRoadmapItem] {[
        .init(id: "watch", status: .shipped("1.1.0"),
              title: String(localized: "Apple Watch"),
              detail: String(localized: "발표 중 남은 시간을 손목 진동으로 알려 주고, 손목에서 시작·일시정지와 30초 조정을 해요.")),
        // Mac 앱과 한 레코드가 되면서 풀렸다 — 같은 상품이라 어느 쪽에서 열든 양쪽에서 열린다.
        .init(id: "host-pro", status: .shipped("1.2.0"),
              title: String(localized: "Mac과 함께 열기"),
              detail: String(localized: "Mac의 StickyPresenter에서 연 Pro가 리모컨에도 그대로 열려요. 한 번만 고르면 돼요.")),
    ]}
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
