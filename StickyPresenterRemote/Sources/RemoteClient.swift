import Foundation
import MultipeerConnectivity
import UIKit
import LeeoKit

// MARK: - Remote Client (iOS 쪽)
//
// 주변에서 StickyPresenter 를 광고하는 Mac 을 찾아, **사용자가 고른 한 대**에만 붙는다.
// Mac 쪽(RemoteControlHost)이 광고자(advertiser), 이쪽이 탐색자(browser) 역할이다.
//
// ## 왜 자동으로 붙지 않나
//
// 예전에는 발견하는 Mac 마다 초대장을 보냈다. 회의실에 Mac 이 두 대만 있어도 리모컨이 둘 다에
// 붙고, 명령을 `connectedPeers` 전체에 보내던 탓에 옆 사람 타이머가 같이 움직였다. 상태 패킷도
// 두 Mac 이 번갈아 보내와 화면이 1초마다 뒤바뀌었다.
//
// 그래서 지금은
//   1. 발견한 Mac 을 목록(`discovered`)으로만 쌓아 두고,
//   2. 사용자가 고른 한 대에 Mac 메뉴 막대의 4자리 코드를 실어 초대장을 보내고,
//   3. 붙은 뒤에는 그 한 대(`connectedPeer`)와만 주고받는다.
// 한 번 통과한 Mac 은 `pairedHostID` 로 기억해 다음 실행부터 코드 없이 자동으로 붙는다.

@MainActor
final class RemoteClient: NSObject, ObservableObject {

    /// 주변에서 찾은 Mac 한 대.
    struct DiscoveredHost: Identifiable, Equatable {
        let peerID: MCPeerID
        /// Mac 의 바뀌지 않는 식별자. nil 이면 페어링을 모르는 옛 Mac 앱이라 붙을 수 없다.
        let hostID: String?

        var id: MCPeerID { peerID }
        var name: String { peerID.displayName }
        var isPairable: Bool { hostID != nil }
    }

    enum Status: Equatable {
        case searching
        case connecting(String)
        case connected(String)
        case failed(String)

        var label: String {
            switch self {
            case .searching:            return String(localized: "Mac 찾는 중…")
            case .connecting(let name): return String(localized: "\(name)에 연결 중…")
            case .connected(let name):  return name
            case .failed(let message):  return message
            }
        }
    }

    @Published private(set) var status: Status = .searching
    @Published private(set) var timers: [RemoteTimer] = []
    /// Mac 의 화면 배치 — 위치 판을 실제 배치(확장 디스플레이 포함) 그대로 그리는 데 쓴다.
    @Published private(set) var desktop: RemoteDesktop?

    /// 주변에서 찾은 Mac 들. 사용자가 여기서 하나를 고른다.
    @Published private(set) var discovered: [DiscoveredHost] = []
    /// 짝으로 기억해 둔 Mac. 이 Mac 을 찾으면 코드를 묻지 않고 바로 붙는다.
    @Published private(set) var pairedHostID: String?
    /// 코드가 틀렸을 때처럼 화면에 한 번 보여주고 지울 메시지. 뷰에서 비울 수 있게 열어 둔다.
    @Published var pairingError: String?
    /// 찾기 시작하고 한참이 지나도 Mac 이 하나도 안 보인다.
    /// iPhone 의 로컬 네트워크 권한이 꺼져 있으면 검색은 **오류 없이** 아무것도 못 찾는다 —
    /// 시간으로라도 알아채지 않으면 "찾는 중" 이 끝없이 돌아간다.
    @Published private(set) var isSearchSlow = false

    var isConnected: Bool {
        if case .connected = status { return true }
        return false
    }

    /// 이 리모컨을 가리키는 바뀌지 않는 식별자. Mac 이 이걸로 "이미 허락한 기기" 를 알아본다.
    /// 기기 이름은 사용자가 언제든 바꾸므로 기준이 되지 못한다.
    private let remoteID: String
    /// 찾기를 새로 시작할 때마다 새로 만든다. 같은 peer ID 로 다시 초대하면 Mac 에 남은
    /// 죽은 연결(백그라운드에 다녀오기 전의 것)과 겹쳐 코드가 맞아도 연결이 맺어지지 않는 일이 있었다.
    /// Mac 은 이 리모컨을 peer ID 가 아니라 `remoteID` 로 알아보므로 바꿔도 짝은 그대로다.
    private var peerID: MCPeerID
    private var session: MCSession?
    private var browser: MCNearbyServiceBrowser?

    /// 초대장을 보내 놓고 답을 기다리는 상대. 거절과 정상 종료를 구분하는 데 쓴다.
    private var pendingPeer: MCPeerID?
    /// 그 초대에 코드를 실었는지 — 실패했을 때 안내 문구를 나누는 기준.
    private var pendingUsedCode = false
    /// 초대장을 보낸 시각. 실패까지 걸린 시간으로 "거절" 과 "무응답" 을 나눈다.
    private var pendingSince: Date?
    /// 성공하면 짝으로 기억할 Mac 식별자.
    private var pendingHostID: String?
    /// 자동 재연결을 기다리는 사이 사용자가 넣은 코드. 보낸 초대는 거둘 수 없으므로,
    /// 그 답이 실패로 오면 곧바로 이 코드로 다시 보낸다 — 맞는 코드를 넣고도 무시당하지 않게.
    private var queuedInvite: (host: DiscoveredHost, code: String)?
    /// 실제로 붙어 있는 Mac. 상태 패킷도 명령도 오직 이 상대와만 주고받는다.
    private var connectedPeer: MCPeerID?
    /// 자동 재연결을 시도해 본 상대. 거절당한 Mac 에 계속 초대장을 던지지 않도록 막는다.
    private var autoAttempted = Set<MCPeerID>()
    /// `isSearchSlow` 를 켜는 지연 작업. 다시 찾기 시작하면 처음부터 잰다.
    private var slowSearchTask: Task<Void, Never>?

    /// 초대 시간 제한. Mac 이 끝내 답하지 않으면 이만큼 뒤에 `.notConnected` 가 온다.
    private static let inviteTimeout: TimeInterval = 15
    /// Mac 이 거절하면 1초 안팎에 답이 온다. 이보다 늦게 실패했다면 거절이 아니라
    /// 초대장이 Mac 에 닿지 못했거나 Mac 이 답할 수 없던 것이다 (잠자기·VPN·네트워크 차단).
    private static let rejectWindow: TimeInterval = 8
    /// 이만큼 찾아도 Mac 이 없으면 점검표를 보라고 말한다. 보통은 1~2초 안에 보인다.
    private static let slowSearchDelay: Duration = .seconds(10)

    private enum Keys {
        static let remoteID = "remote.remoteID"
        static let pairedHostID = "remote.pairedHostID"
    }

    override init() {
        let defaults = UserDefaults.standard
        if let saved = defaults.string(forKey: Keys.remoteID) {
            self.remoteID = saved
        } else {
            let generated = UUID().uuidString
            defaults.set(generated, forKey: Keys.remoteID)
            self.remoteID = generated
        }
        self.pairedHostID = defaults.string(forKey: Keys.pairedHostID)
        self.peerID = MCPeerID(displayName: String(UIDevice.current.name.prefix(30)))
        super.init()
    }

    // MARK: 수명주기

    func start() {
        guard session == nil else { return }
        #if DEBUG
        if let scene = UserDefaults.standard.string(forKey: "screenshotDemo") {
            showScreenshotDemo(scene)
            return
        }
        #endif

        peerID = MCPeerID(displayName: String(UIDevice.current.name.prefix(30)))
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: RemoteService.type)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser

        status = .searching
        watchForSlowSearch()
    }

    private func watchForSlowSearch() {
        slowSearchTask?.cancel()
        isSearchSlow = false
        slowSearchTask = Task { [weak self] in
            try? await Task.sleep(for: Self.slowSearchDelay)
            guard !Task.isCancelled, let self, self.discovered.isEmpty else { return }
            self.isSearchSlow = true
        }
    }

    func stop() {
        browser?.stopBrowsingForPeers(); browser = nil
        session?.disconnect(); session = nil
        slowSearchTask?.cancel(); slowSearchTask = nil
        isSearchSlow = false
        discovered = []
        autoAttempted.removeAll()
        pendingPeer = nil
        pendingHostID = nil
        queuedInvite = nil
        connectedPeer = nil
        timers = []
        desktop = nil
        status = .searching
    }

    /// 끊긴 세션은 다시 쓸 수 없다 — 통째로 새로 연다.
    /// 브라우저도 같이 새로 돌아서 짝인 Mac 을 다시 발견하면 자동으로 붙는다.
    private func restart() {
        stop()
        start()
    }

    // MARK: 페어링

    /// 목록에서 고른 Mac 에 코드를 실어 초대장을 보낸다.
    func connect(to host: DiscoveredHost, code: String) {
        let code = PairingCode.normalized(code)
        guard PairingCode.isComplete(code) else {
            pairingError = String(localized: "연결 코드 \(PairingCode.length)자리를 모두 입력해 주세요.")
            return
        }
        guard host.isPairable else {
            pairingError = String(localized: "이 Mac 은 StickyPresenter 업데이트가 필요합니다.")
            return
        }
        // 보낸 초대는 도로 거둘 수 없다. 답(수락·거절·시간 초과)이 올 때까지 기다려야
        // 하는데, 아무 말 없이 무시하면 버튼이 먹지 않는 것처럼 보인다.
        if let pending = pendingPeer {
            if pending == host.peerID, !pendingUsedCode {
                // 같은 Mac 에 코드 없이 보낸 자동 재연결이 아직 답을 기다린다.
                // 붙으면 코드는 필요 없고, 거절되면 이 코드로 곧바로 다시 보낸다.
                pairingError = nil
                queuedInvite = (host, code)
            } else {
                pairingError = String(localized: "\(pending.displayName)에 보낸 연결 요청을 아직 기다리는 중입니다. 잠시 후 다시 시도해 주세요.")
            }
            return
        }
        pairingError = nil
        invite(host, code: code)
    }

    /// 짝을 잊고 다시 고른다 — 다른 Mac 으로 옮기거나 리모컨을 남에게 넘길 때.
    func unpair() {
        pairedHostID = nil
        UserDefaults.standard.removeObject(forKey: Keys.pairedHostID)
        pairingError = nil
        restart()
    }

    private func invite(_ host: DiscoveredHost, code: String?) {
        guard let session, let browser else { return }
        // 한 번에 한 대만. 이 조건이 없으면 예전처럼 여러 Mac 에 동시에 붙는다.
        guard connectedPeer == nil, pendingPeer == nil else { return }

        let request = PairingRequest(
            remoteID: remoteID,
            remoteName: String(UIDevice.current.name.prefix(30)),
            code: code
        )
        guard let context = try? request.encoded() else { return }

        pendingPeer = host.peerID
        pendingUsedCode = (code != nil)
        pendingSince = Date()
        pendingHostID = host.hostID
        status = .connecting(host.name)
        browser.invitePeer(host.peerID, to: session, withContext: context, timeout: Self.inviteTimeout)
    }

    private func rememberPairedHost(_ hostID: String) {
        pairedHostID = hostID
        UserDefaults.standard.set(hostID, forKey: Keys.pairedHostID)
    }

    private func clearSessionState() {
        timers = []
        desktop = nil
    }

    // MARK: 명령 송신

    func send(_ command: RemoteCommand) {
        // 붙어 있는 그 Mac 한 대에만 보낸다. `session.connectedPeers` 를 그대로 쓰면
        // 어쩌다 둘이 붙었을 때 옆 사람 타이머까지 같이 움직인다.
        guard let session, let peer = connectedPeer,
              let data = try? RemotePacket.command(command).encoded() else { return }
        // 명령은 유실되면 안 된다 — 상태와 달리 재전송해 주는 후속 패킷이 없다.
        try? session.send(data, toPeers: [peer], with: .reliable)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension RemoteClient: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
                             withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            let host = DiscoveredHost(peerID: peerID, hostID: info?[RemoteService.DiscoveryKey.hostID])
            // Mac 앱을 다시 켜면 peer ID 가 새로 생긴다. 예전 것이 아직 사라지지 않았으면 같은 Mac 이
            // 목록에 둘 뜨고, 예전 쪽을 누르면 아무 답도 오지 않는다. 같은 Mac 이면 새것만 남긴다.
            if let hostID = host.hostID {
                self.discovered.removeAll { $0.hostID == hostID && $0.peerID != peerID && $0.peerID != self.pendingPeer }
            }
            if let index = self.discovered.firstIndex(where: { $0.peerID == peerID }) {
                self.discovered[index] = host
            } else {
                self.discovered.append(host)
            }
            self.isSearchSlow = false

            // 짝으로 기억해 둔 Mac 이면 코드를 묻지 않는다.
            // `autoAttempted` 로 한 번만 시도한다 — 거절당한 Mac 에 계속 던지면
            // 사용자가 목록에서 다른 Mac 을 고를 틈도 없이 초대만 반복된다.
            // 원격 킬스위치로 꺼져 있으면 저절로 붙지 않는다 — 목록에서 골라 코드를 넣는 길은 남는다.
            guard LeeoRemoteFlags.isEnabled(RemoteFlag.autoReconnectEnabled),
                  let hostID = host.hostID, hostID == self.pairedHostID,
                  !self.autoAttempted.contains(peerID) else { return }
            self.autoAttempted.insert(peerID)
            self.invite(host, code: nil)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.discovered.removeAll { $0.peerID == peerID }
            // 사라졌다 다시 나타나면 자동 재연결을 한 번 더 시도할 수 있게 풀어 준다.
            self.autoAttempted.remove(peerID)

            if self.pendingPeer == peerID {
                self.pendingPeer = nil
                self.pendingSince = nil
                self.pendingHostID = nil
                self.queuedInvite = nil
                self.status = .searching
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            // 로컬 네트워크 권한을 거부하면 여기로 떨어진다.
            self.status = .failed(String(localized: "검색 실패 — 설정 > 개인정보 보호에서 로컬 네트워크 권한을 확인하세요"))
        }
    }
}

// MARK: - MCSessionDelegate

extension RemoteClient: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.connectedPeer = peerID
                self.pendingPeer = nil
                // 코드가 통과했다는 뜻 — 다음부터는 코드 없이 붙도록 짝을 기억한다.
                if let hostID = self.pendingHostID { self.rememberPairedHost(hostID) }
                self.pendingHostID = nil
                self.pendingSince = nil
                self.queuedInvite = nil
                self.autoAttempted.remove(peerID)
                self.pairingError = nil
                self.status = .connected(peerID.displayName)
                self.send(.requestState)   // 1초 주기를 기다리지 않고 즉시 첫 상태를 받는다

            case .connecting:
                self.status = .connecting(peerID.displayName)

            case .notConnected:
                self.handleDisconnect(peerID)

            @unknown default:
                break
            }
        }
    }

    /// `.notConnected` 는 두 가지를 한 상태로 뭉뚱그린다 — **거절당했거나**, 붙어 있다 **끊겼거나**.
    /// MultipeerConnectivity 가 이유를 알려주지 않으므로 우리가 들고 있던 문맥으로 나눈다.
    private func handleDisconnect(_ peerID: MCPeerID) {
        if peerID == connectedPeer {
            // 붙어 있다 끊긴 경우 — Mac 앱이 꺼졌거나 네트워크가 흔들렸다.
            // 짝은 그대로 두고 세션만 새로 열어, 그 Mac 이 다시 보이면 저절로 붙게 한다.
            connectedPeer = nil
            clearSessionState()
            restart()
            return
        }

        guard peerID == pendingPeer else { return }

        if let queued = queuedInvite, queued.host.peerID == peerID {
            queuedInvite = nil
            pendingPeer = nil
            pendingSince = nil
            pendingHostID = nil
            invite(queued.host, code: queued.code)
            return
        }

        let wasAutomatic = !pendingUsedCode
        let elapsed = pendingSince.map { Date().timeIntervalSince($0) } ?? Self.inviteTimeout
        pendingPeer = nil
        pendingSince = nil
        pendingHostID = nil
        status = .searching

        // 자동 재연결이 막힌 경우 짝을 지우지는 않는다. Mac 을 그냥 껐을 때도 여기로 떨어지는데,
        // 그걸 페어링 해제로 읽으면 발표 직전에 멀쩡한 짝을 잃는다. 목록에 그대로 두면
        // 사용자가 눌러서 코드를 다시 넣을 수 있고, 그 편이 되돌리기 쉽다.
        pairingError = Self.failureMessage(host: peerID.displayName,
                                           usedCode: !wasAutomatic, elapsed: elapsed)
    }

    /// "안 된다" 대신 **무엇을 하면 되는지**를 말한다.
    ///
    /// Mac 은 초대를 거절할 때 이유를 실어 보낼 수 없다 (MultipeerConnectivity 에 그런 길이 없다).
    /// 대신 답이 온 시간으로 나눈다 — 거절은 곧바로 오고, 초대장이 닿지 못하면 시간 제한까지 간다.
    /// 그리고 Mac 이 곧바로 거절하는 이유는 둘뿐이다: 코드가 틀렸거나, 이 리모컨을 모르거나.
    static func failureMessage(host: String, usedCode: Bool, elapsed: TimeInterval) -> String {
        guard elapsed < rejectWindow else {
            return String(localized: "\(host)에서 응답이 없습니다. Mac이 잠자기 상태가 아닌지, 두 기기가 같은 Wi-Fi인지, VPN이 꺼져 있는지 확인해 주세요.")
        }
        if usedCode {
            return String(localized: "연결 코드가 다릅니다. Mac 메뉴 막대의 타이머 아이콘 → Remote 에 지금 떠 있는 4자리를 넣어 주세요. 코드를 새로 만들었다면 새 코드여야 합니다.")
        }
        // 짝이었던 Mac 이 코드 없는 초대를 곧바로 거절했다 = Mac 이 이 리모컨을 잊었다
        // (메뉴의 "기억한 리모컨 지우기", 또는 Mac 앱을 지웠다 다시 깔았다).
        return String(localized: "\(host)에서 이 iPhone을 기억하지 못합니다. 목록에서 Mac을 눌러 연결 코드를 다시 넣어 주세요.")
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let packet = try? RemotePacket.decode(data),
              case .state(let state) = packet else { return }
        Task { @MainActor in
            // 붙어 있는 Mac 이 보낸 것만 받는다. 이 조건이 없으면 다른 Mac 의 상태가 섞여
            // 화면이 1초마다 뒤바뀐다.
            guard peerID == self.connectedPeer else { return }
            self.timers = state.timers
            self.desktop = state.desktop
            self.status = .connected(state.hostName)
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream,
                             withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - 스토어 스크린샷용 데모 (DEBUG 전용)
//
// 스크린샷은 언어마다 찍어야 하는데, 실제 Mac 과 붙여 24개 언어를 찍을 수는 없다.
// `-screenshotDemo timer|pomodoro|choose` 로 띄우면 Mac 없이 그 화면을 채운다.
// 뽀모도로 구간 이름은 Mac 이 자기 언어로 보내 주는 값이라 `-demoFocus <글자>` 로 받는다.

#if DEBUG
extension RemoteClient {
    func showScreenshotDemo(_ scene: String) {
        let mac = "MacBook Pro"
        // 노트북(왼쪽) + 큰 외장 화면(오른쪽, 메뉴 막대). 발표장에서 흔한 배치.
        desktop = RemoteDesktop(aspect: 2.84, screens: [
            RemoteScreen(id: 0, x: 0, y: 0.143, width: 0.37, height: 0.68, isMain: false),
            RemoteScreen(id: 1, x: 0.37, y: 0, width: 0.63, height: 1, isMain: true),
        ])
        switch scene {
        case "choose":
            desktop = nil
            discovered = [DiscoveredHost(peerID: MCPeerID(displayName: mac), hostID: "demo")]
            status = .searching
        case "pomodoro":
            let focus = UserDefaults.standard.string(forKey: "demoFocus") ?? "Focus"
            timers = [RemoteTimer(id: UUID(), name: "25/5", remaining: 1013, target: 1500,
                                  isRunning: true, isFinished: false, isHidden: false, isPomodoro: true,
                                  phaseTitle: focus, cycleNumber: 2, size: "M", theme: "system",
                                  placement: RemotePlacement(x: 0.319, y: 0.24, widthRatio: 0.055,
                                                             heightRatio: 0.12, screenID: 0))]
            status = .connected(mac)
        default:
            timers = [RemoteTimer(id: UUID(), name: "15m", remaining: 522, target: 900,
                                  isRunning: true, isFinished: false, isHidden: false, isPomodoro: false,
                                  phaseTitle: nil, cycleNumber: 1, size: "L", theme: "system",
                                  placement: RemotePlacement(x: 0.879, y: 0.098, widthRatio: 0.074,
                                                             heightRatio: 0.11, screenID: 1))]
            status = .connected(mac)
        }
    }
}
#endif
