import Foundation

// MARK: - Remote Control Protocol
// Mac 앱(StickyPresenter)과 iOS 리모컨 앱이 MultipeerConnectivity 로 주고받는 규약.
// **이 파일은 두 프로젝트가 같은 파일을 참조한다.** 한쪽만 고치면 디코딩이 깨지므로
// 필드를 바꿀 때는 반드시 양쪽을 같이 빌드해 확인할 것.

public enum RemoteService {
    /// MultipeerConnectivity 서비스 타입.
    /// 1~15자, 소문자·숫자·하이픈만 허용된다는 제약이 있어 짧게 잡았다.
    /// Info.plist 의 NSBonjourServices 에도 `_sp-timer._tcp` / `._udp` 로 같이 올라가 있어야 한다.
    public static let type = "sp-timer"

    /// Mac 이 광고(`discoveryInfo`)에 싣는 키.
    /// MultipeerConnectivity 는 discoveryInfo 전체를 400바이트로 제한하므로 키를 짧게 잡았다.
    public enum DiscoveryKey {
        /// Mac 을 가리키는 **바뀌지 않는** 식별자.
        /// 컴퓨터 이름은 바뀌기도 하고 겹치기도 해서("MacBook Pro" 가 회의실에 셋)
        /// 짝을 기억하는 기준으로 쓸 수 없다.
        public static let hostID = "hid"
    }
}

// MARK: - 페어링
//
// 같은 Wi-Fi 에 Mac 이 여러 대면 리모컨은 그 전부를 발견한다. 예전에는 발견하는 족족 초대장을
// 보내고 Mac 도 오는 대로 다 받아서, 발표자 A 의 리모컨이 B 의 Mac 타이머까지 같이 움직였다.
//
// 이제 리모컨은 **사용자가 고른 Mac 한 대**에만 초대장을 보내고, 그 초대장에 Mac 메뉴 막대에
// 떠 있는 4자리 코드를 실어 보낸다. Mac 은 코드가 맞는 초대만 받는다.
// 한 번 통과하면 Mac 이 그 리모컨의 `remoteID` 를 기억하므로 다음부터는 코드 없이 붙는다.
//
// ⚠️ 이 규약이 들어오면서 **컨텍스트 없는 초대는 거절**된다. 페어링을 모르는 옛 리모컨 앱은
//    새 Mac 앱에 붙지 못한다 — 두 앱을 같은 릴리즈로 함께 올려야 하는 이유다.

/// 리모컨이 초대장(`invitePeer(_:to:withContext:timeout:)`)에 싣는 신원.
/// 초대 컨텍스트는 작아야 하므로 필드를 최소로 유지한다.
public struct PairingRequest: Codable, Sendable {
    /// 리모컨을 가리키는 바뀌지 않는 식별자. Mac 이 이걸로 "이미 허락한 기기" 를 알아본다.
    public var remoteID: String
    /// Mac 쪽 기록에 남길 이름 (예: "leeo의 iPhone").
    public var remoteName: String
    /// Mac 메뉴 막대의 4자리 코드. 이미 페어링된 기기는 nil 로 두고 `remoteID` 만으로 붙는다.
    public var code: String?

    public init(remoteID: String, remoteName: String, code: String?) {
        self.remoteID = remoteID
        self.remoteName = remoteName
        self.code = code
    }

    public func encoded() throws -> Data { try JSONEncoder().encode(self) }
    public static func decode(_ data: Data) throws -> PairingRequest {
        try JSONDecoder().decode(PairingRequest.self, from: data)
    }
}

/// 4자리 연결 코드. 앞자리가 0 이어도 자릿수를 잃지 않도록 정수가 아니라 문자열로 다룬다.
public enum PairingCode {
    public static let length = 4

    public static func random() -> String {
        (0..<length).map { _ in String(Int.random(in: 0...9)) }.joined()
    }

    /// 숫자만 남기고 4자리로 자른다 — 숫자 패드에도 붙여넣기가 들어온다.
    /// `isNumber` 는 "½" 이나 아라비아 숫자까지 참이라, 코드로 쓸 0~9 만 남긴다.
    public static func normalized(_ input: String) -> String {
        String(input.filter(isDigit).prefix(length))
    }

    public static func isComplete(_ code: String) -> Bool {
        code.count == length && code.allSatisfy(isDigit)
    }

    private static func isDigit(_ character: Character) -> Bool {
        character.isASCII && character.isNumber
    }
}

// MARK: - 상태 (Mac → iOS)

// MARK: 좌표계
//
// 위치와 관련된 모든 값은 **데스크탑 전체**(붙어 있는 모든 화면을 감싸는 사각형)를
// 1×1 로 놓고 잰 비율이다. 화면 한 대를 기준으로 삼으면 확장 디스플레이에서
// 옆 화면으로 넘어갈 방법이 없어진다 — 노트북 + 빔프로젝터가 오히려 기본이라
// 처음부터 여러 대를 담을 수 있는 기준계를 쓴다.
//
// y 는 **위에서 아래로** 자란다. AppKit 은 반대지만 뒤집는 일을 Mac 쪽 한 곳
// (`ScreenMap`)에 몰아넣고, 규약 자체는 리모컨(iOS) 관례를 따른다.

/// 화면 한 대의 자리. 좌표는 데스크탑 전체 사각형 안의 비율이다.
public struct RemoteScreen: Codable, Equatable, Sendable, Identifiable {
    /// `NSScreen.screens` 안에서의 순서. 배치를 바꾸면 달라질 수 있는 표시용 값이다.
    public var id: Int
    /// 화면 **좌상단**의 위치와 크기 (0…1).
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    /// 메뉴 막대가 있는 화면. 리모컨이 위아래를 알려주는 데 쓴다.
    public var isMain: Bool

    public init(id: Int, x: Double, y: Double, width: Double, height: Double, isMain: Bool) {
        self.id = id; self.x = x; self.y = y
        self.width = width; self.height = height; self.isMain = isMain
    }
}

/// Mac 의 화면 배치 전체. 리모컨은 이걸로 미니 화면 판을 실제 배치 그대로 그린다.
public struct RemoteDesktop: Codable, Equatable, Sendable {
    /// 전체를 감싸는 사각형의 가로/세로 비 — 판의 모양.
    public var aspect: Double
    /// 왼쪽 화면부터 순서대로.
    public var screens: [RemoteScreen]

    public init(aspect: Double, screens: [RemoteScreen]) {
        self.aspect = aspect
        self.screens = screens
    }
}

/// 위젯 창이 데스크탑 어디에 놓여 있는지 — 리모컨의 미니 화면을 그리는 데 쓴다.
/// 픽셀 값을 그대로 보내지 않는 이유: 리모컨은 Mac 해상도를 알 필요가 없고,
/// 정규화해 두면 해상도가 바뀌거나 화면을 더 붙여도 판이 그대로 맞는다.
public struct RemotePlacement: Codable, Equatable, Sendable {
    /// 창 **중심**의 가로 위치 (0 = 데스크탑 왼쪽 끝, 1 = 오른쪽 끝).
    public var x: Double
    /// 창 **중심**의 세로 위치 (0 = 위, 1 = 아래).
    public var y: Double
    /// 창이 데스크탑 전체에서 차지하는 비율 — 판 안 사각형 크기.
    public var widthRatio: Double
    public var heightRatio: Double
    /// 지금 올라가 있는 화면 (`RemoteScreen.id`). 리모컨이 "2번 화면" 이라고 알려주는 데 쓴다.
    public var screenID: Int

    public init(x: Double, y: Double, widthRatio: Double, heightRatio: Double, screenID: Int) {
        self.x = x; self.y = y
        self.widthRatio = widthRatio; self.heightRatio = heightRatio
        self.screenID = screenID
    }
}

/// 리모컨 화면에 타이머 하나를 그리는 데 필요한 값 전부.
/// Mac 의 `TimerEntry` 를 그대로 보내지 않고 납작한 값 타입으로 옮겨 담는다 —
/// `TimerEntry` 는 창·티커 같은 로컬 자원을 들고 있어 직렬화 대상이 아니다.
public struct RemoteTimer: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var remaining: TimeInterval
    public var target: TimeInterval
    public var isRunning: Bool
    public var isFinished: Bool
    public var isHidden: Bool
    public var isPomodoro: Bool
    /// 뽀모도로일 때만 채워진다 ("Focus" / "Break").
    public var phaseTitle: String?
    public var cycleNumber: Int
    /// `WidgetSize.rawValue` — "S" / "M" / "L"
    public var size: String
    /// `WidgetTheme.rawValue` — "system" / "light" / "dark" / "chameleon"
    public var theme: String
    /// 위젯 창의 화면상 위치. 창이 아직 없으면 nil (리모컨은 그때 위치 조작을 잠근다).
    /// 옵셔널이라 옛 버전이 보낸 패킷에도 그대로 디코딩된다.
    public var placement: RemotePlacement?

    public init(id: UUID, name: String, remaining: TimeInterval, target: TimeInterval,
                isRunning: Bool, isFinished: Bool, isHidden: Bool, isPomodoro: Bool,
                phaseTitle: String?, cycleNumber: Int, size: String, theme: String,
                placement: RemotePlacement? = nil) {
        self.id = id; self.name = name
        self.remaining = remaining; self.target = target
        self.isRunning = isRunning; self.isFinished = isFinished; self.isHidden = isHidden
        self.isPomodoro = isPomodoro; self.phaseTitle = phaseTitle; self.cycleNumber = cycleNumber
        self.size = size; self.theme = theme
        self.placement = placement
    }

    public var progress: Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, (target - remaining) / target))
    }
}

/// Mac 이 주기적으로(그리고 변화가 있을 때마다) 뿌리는 전체 상태.
/// 델타가 아니라 전체를 보낸다 — 타이머가 몇 개 없어서 비용이 무의미하고,
/// 패킷을 하나 놓쳐도 다음 갱신에서 저절로 복구된다.
public struct RemoteState: Codable, Sendable {
    public var hostName: String
    public var timers: [RemoteTimer]
    /// 화면 배치. 타이머마다 같은 값이라 타이머가 아니라 상태에 한 번만 싣는다.
    /// 옵셔널이라 이 필드를 모르는 옛 패킷도 그대로 디코딩된다.
    public var desktop: RemoteDesktop?

    public init(hostName: String, timers: [RemoteTimer], desktop: RemoteDesktop? = nil) {
        self.hostName = hostName
        self.timers = timers
        self.desktop = desktop
    }
}

// MARK: - 명령 (iOS → Mac)

public enum RemoteCommand: Codable, Sendable {
    /// 재생/일시정지. 완료된 타이머면 Mac 쪽에서 reset 후 시작한다 (패널 버튼과 동일 동작).
    case toggleRun(UUID)
    case addSeconds(UUID)
    case subtractSeconds(UUID)
    case reset(UUID)
    /// `WidgetSize.rawValue`
    case setSize(UUID, String)
    /// 테마를 다음 것으로 순환
    case cycleTheme(UUID)
    /// 위젯 창 감추기/보이기
    case toggleHidden(UUID)
    /// 위젯을 패널 옆으로 정렬 (화면 밖으로 나갔을 때 되찾기)
    case align(UUID)
    /// 위젯 창을 데스크탑 어디로 옮길지. 좌표 규약은 `RemotePlacement` 와 같다 —
    /// 창 **중심**의 정규화 위치, y 는 위에서 아래로, 기준은 데스크탑 전체.
    /// 다른 화면 영역을 가리키면 그 화면으로 넘어간다.
    case moveWidget(UUID, x: Double, y: Double)
    case remove(UUID)
    /// 프리셋으로 새 타이머 추가 (3m/5m/10m/15m)
    case addPreset(seconds: Double, name: String)
    /// 연결 직후 현재 상태를 즉시 달라는 요청
    case requestState
}

// MARK: - 봉투
// 명령과 상태를 한 채널로 흘려보내기 위한 최소한의 구분자.

public enum RemotePacket: Codable, Sendable {
    case state(RemoteState)
    case command(RemoteCommand)

    public func encoded() throws -> Data { try JSONEncoder().encode(self) }
    public static func decode(_ data: Data) throws -> RemotePacket {
        try JSONDecoder().decode(RemotePacket.self, from: data)
    }
}
