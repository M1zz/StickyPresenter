import Foundation
import LeeoKit

// MARK: - 원격 킬스위치
// LeeoKit(LeeoRemoteFlags)이 FeedbackHub 컨테이너의 RemoteFlags 레코드에서 읽는다.
//
// ⚠️ rawValue = CloudKit 필드명 계약이다 — 다르면 아무리 꺼도 켜진 채로 도는 조용한 실패. 바꾸지 말 것.
// ⚠️ 조회 실패 = 켬(가용성 우선). 갱신은 6시간 쓰로틀 + 백그라운드라 **다음 실행부터** 반영된다.
//
// CloudKit Dashboard (1회): 레코드 타입 RemoteFlags, recordName "flags_com.leeo.StickyPresenter",
// 플래그마다 Int64 필드(1=켬 · 0=끔)를 만들고 Production 배포. 필드가 없으면 켬으로 동작한다.

enum StickyPresenterFlag: String, LeeoRemoteFlag, CaseIterable {
    /// iPhone 리모컨 호스트(Bonjour 광고 + MultipeerConnectivity 세션).
    /// 이 앱에서 유일하게 **네트워크 너머의 기기에게 문을 여는** 기능이다. 짝 맺기에 허점이 드러나거나
    /// 특정 macOS 에서 광고가 앱을 붙잡는 일이 생기면, 심사를 기다리지 않고 이것만 끈다.
    /// 끄면 다음 실행부터 광고를 시작하지 않고, 메뉴 막대 ▸ Remote 에 잠시 쓸 수 없다고 적는다.
    case remoteControlEnabled
}
