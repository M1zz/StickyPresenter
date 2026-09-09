import Foundation
import MultipeerConnectivity
import UIKit

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
            case .searching:            return "Mac 찾는 중…"
            case .connecting(let name): return "\(name)에 연결 중…"
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

    var isConnected: Bool {
        if case .connected = status { return true }
        return false
    }

    /// 이 리모컨을 가리키는 바뀌지 않는 식별자. Mac 이 이걸로 "이미 허락한 기기" 를 알아본다.
    /// 기기 이름은 사용자가 언제든 바꾸므로 기준이 되지 못한다.
    private let remoteID: String
    private let peerID: MCPeerID
    private var session: MCSession?
    private var browser: MCNearbyServiceBrowser?

    /// 초대장을 보내 놓고 답을 기다리는 상대. 거절과 정상 종료를 구분하는 데 쓴다.
    private var pendingPeer: MCPeerID?
    /// 그 초대에 코드를 실었는지 — 실패했을 때 안내 문구를 나누는 기준.
    private var pendingUsedCode = false
    /// 성공하면 짝으로 기억할 Mac 식별자.
    private var pendingHostID: String?
    /// 실제로 붙어 있는 Mac. 상태 패킷도 명령도 오직 이 상대와만 주고받는다.
    private var connectedPeer: MCPeerID?
    /// 자동 재연결을 시도해 본 상대. 거절당한 Mac 에 계속 초대장을 던지지 않도록 막는다.
    private var autoAttempted = Set<MCPeerID>()

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

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: RemoteService.type)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser

        status = .searching
    }

    func stop() {
        browser?.stopBrowsingForPeers(); browser = nil
        session?.disconnect(); session = nil
        discovered = []
        autoAttempted.removeAll()
        pendingPeer = nil
        pendingHostID = nil
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
            pairingError = "연결 코드 \(PairingCode.length)자리를 모두 입력해 주세요."
            return
        }
        guard host.isPairable else {
            pairingError = "이 Mac 은 StickyPresenter 업데이트가 필요합니다."
            return
        }
        // 보낸 초대는 도로 거둘 수 없다. 답(수락·거절·시간 초과)이 올 때까지 기다려야
        // 하는데, 아무 말 없이 무시하면 버튼이 먹지 않는 것처럼 보인다.
        if let pending = pendingPeer, pending != host.peerID {
            pairingError = "\(pending.displayName)에 보낸 연결 요청을 아직 기다리는 중입니다. 잠시 후 다시 시도해 주세요."
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
        pendingHostID = host.hostID
        status = .connecting(host.name)
        browser.invitePeer(host.peerID, to: session, withContext: context, timeout: 15)
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
            if let index = self.discovered.firstIndex(where: { $0.peerID == peerID }) {
                self.discovered[index] = host
            } else {
                self.discovered.append(host)
            }

            // 짝으로 기억해 둔 Mac 이면 코드를 묻지 않는다.
            // `autoAttempted` 로 한 번만 시도한다 — 거절당한 Mac 에 계속 던지면
            // 사용자가 목록에서 다른 Mac 을 고를 틈도 없이 초대만 반복된다.
            guard let hostID = host.hostID, hostID == self.pairedHostID,
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
                self.pendingHostID = nil
                self.status = .searching
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            // 로컬 네트워크 권한을 거부하면 여기로 떨어진다.
            self.status = .failed("검색 실패 — 설정 > 개인정보 보호에서 로컬 네트워크 권한을 확인하세요")
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

        let wasAutomatic = !pendingUsedCode
        pendingPeer = nil
        pendingHostID = nil
        status = .searching

        // 자동 재연결이 막힌 경우 짝을 지우지는 않는다. Mac 을 그냥 껐을 때도 여기로 떨어지는데,
        // 그걸 페어링 해제로 읽으면 발표 직전에 멀쩡한 짝을 잃는다. 목록에 그대로 두면
        // 사용자가 눌러서 코드를 다시 넣을 수 있고, 그 편이 되돌리기 쉽다.
        pairingError = wasAutomatic
            ? "\(peerID.displayName)에 자동으로 연결하지 못했습니다. 목록에서 다시 골라 주세요."
            : "연결 코드가 맞지 않거나 Mac 이 응답하지 않았습니다. Mac 메뉴 막대의 코드를 확인해 주세요."
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
