import SwiftUI
import TipKit

// MARK: - 사용 팁 (TipKit)
// 팁은 광고가 아니라 도움이어야 한다 — 몇 번 써 본 뒤에만, 이미 쓰는 기능이면 뜨지 않는다.

/// 위치 판을 **끌면** Mac 의 타이머 창이 움직인다는 것.
///
/// 판은 그림처럼 보여서 손가락을 대 볼 생각을 못 한다. 그런데 발표 중 슬라이드를 가린 타이머를
/// 비켜 놓는 일은 이 앱이 Mac 보다 잘하는 몇 안 되는 일이다.
struct MoveWidgetTip: Tip {
    /// 리모컨으로 타이머를 조작한 순간 (시작·정지·시간 더하기 등).
    static let controlled = Event(id: "tip.remoteControlled")

    /// 판을 한 번이라도 끌었으면 다시 뜨지 않는다.
    @Parameter static var hasMovedWidget: Bool = false

    var title: Text { Text("끌어서 타이머 옮기기") }
    var message: Text? { Text("이 판은 Mac 화면을 줄여 그린 것입니다. 사각형을 끌면 Mac의 타이머 창이 따라 움직이고, 화면이 여러 대면 옆 화면으로도 넘어갑니다.") }
    var image: Image? { Image(systemName: "hand.draw") }

    var rules: [Rule] {
        #Rule(Self.$hasMovedWidget) { $0 == false }
        #Rule(Self.controlled) { $0.donations.count >= 2 }
    }
}
