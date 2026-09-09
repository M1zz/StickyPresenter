import Foundation
import MultipeerConnectivity
import AppKit

// MARK: - Remote Control Host (Mac 쪽)
//
// iOS 리모컨 앱이 붙을 수 있도록 자신을 광고하고, 들어온 명령을 실제 타이머에 적용한다.
// 상태는 1초마다 전체를 브로드캐스트한다 — 델타 동기화는 타이머가 몇 개 없는 이 앱에서
// 복잡도만 늘리고, 패킷을 하나 놓쳐도 다음 초에 저절로 복구되는 편이 훨씬 튼튼하다.
//
// 샌드박스 앱이라 entitlements 에 network.client / network.server 가,
// Info.plist 에 NSBonjourServices 와 NSLocalNetworkUsageDescription 이 있어야 동작한다.
//
// ## 아무 리모컨이나 받지 않는다
//
// 회의실처럼 같은 Wi-Fi 에 Mac 이 여러 대 있으면, 예전 구현은 들어온 초대를 전부 자동
// 수락해서 발표자 A 의 리모컨이 B 의 Mac 타이머까지 같이 움직였다. 이제는 리모컨이 초대장에
// 4자리 코드(`pairingCode`, 메뉴 막대에 떠 있다)를 실어 보내야 하고, 코드가 맞은 리모컨만
// `pairedRemotes` 에 기록해 다음부터는 코드 없이 받아준다. 규약은 `PairingRequest` 참고.
//
// 리모컨 **여러 대**가 한 Mac 에 붙는 건 그대로 허용한다 (발표자 + 진행 스태프).
// 격리는 페어링 단계에서 이미 끝났으므로 붙은 뒤에 더 나눌 이유가 없다.

@MainActor
final class RemoteControlHost: NSObject, ObservableObject {
    static let shared = RemoteControlHost()

    /// 지금 붙어 있는 리모컨 수 — 메뉴/UI에서 연결 상태를 보여주는 데 쓴다.
    @Published private(set) var connectedCount = 0

    /// 메뉴 막대에 띄우는 4자리 연결 코드. 리모컨이 이걸 맞춰야 처음 붙을 수 있다.
    @Published private(set) var pairingCode: String

    /// 코드 없이 붙어도 되는 리모컨 (`remoteID` → 마지막으로 본 기기 이름).
    private var pairedRemotes: [String: String]

    /// 이 Mac 을 가리키는 바뀌지 않는 식별자. 컴퓨터 이름을 바꿔도 리모컨이 짝을 놓치지 않도록,
    /// 이름이 아니라 이 값을 광고에 실어 보낸다.
    private let hostID: String

    private let peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var broadcastTimer: Foundation.Timer?

    private enum Keys {
        static let hostID = "remote.hostID"
        static let pairingCode = "remote.pairingCode"
        static let pairedRemotes = "remote.pairedRemotes"
    }

    private override init() {
        let defaults = UserDefaults.standard

        let name = Host.current().localizedName ?? "Mac"
        // MCPeerID displayName 은 63바이트 제한이 있다. 긴 컴퓨터 이름에서 터진다.
        self.peerID = MCPeerID(displayName: String(name.prefix(30)))

        // 셋 다 재실행·이름 변경을 건너 살아남아야 한다. 하나라도 매번 새로 뽑으면
        // 리모컨이 기억해 둔 짝을 잃고 발표 직전에 코드를 다시 물어보게 된다.
        if let saved = defaults.string(forKey: Keys.hostID) {
            self.hostID = saved
        } else {
            let generated = UUID().uuidString
            defaults.set(generated, forKey: Keys.hostID)
            self.hostID = generated
        }

        if let saved = defaults.string(forKey: Keys.pairingCode), PairingCode.isComplete(saved) {
            self.pairingCode = saved
        } else {
            let generated = PairingCode.random()
            defaults.set(generated, forKey: Keys.pairingCode)
            self.pairingCode = generated
        }

        self.pairedRemotes = defaults.dictionary(forKey: Keys.pairedRemotes) as? [String: String] ?? [:]

        super.init()
    }

    // MARK: 페어링

    /// 기억해 둔 리모컨 수 — 메뉴에 "3대 지우기" 처럼 보여주는 데 쓴다.
    var pairedCount: Int { pairedRemotes.count }

    /// 코드를 새로 뽑는다 (남에게 코드를 보여준 뒤 되돌리고 싶을 때).
    /// 이미 페어링된 리모컨은 코드 없이 붙으므로 그대로 남는다 — 같이 끊으려면 `unpairAll()`.
    func regeneratePairingCode() {
        pairingCode = PairingCode.random()
        UserDefaults.standard.set(pairingCode, forKey: Keys.pairingCode)
    }

    /// 기억해 둔 리모컨을 모두 잊고, 지금 붙어 있는 연결도 끊는다.
    func unpairAll() {
        pairedRemotes.removeAll()
        UserDefaults.standard.set(pairedRemotes, forKey: Keys.pairedRemotes)
        // MCSession 은 피어 하나만 골라 끊을 수 없다. 세션을 새로 열어 전부 떨군다.
        guard session != nil else { return }
        stop()
        start()
    }

    /// 코드가 맞았을 때 그 리모컨을 기억해 둔다 — 다음부터는 코드를 묻지 않는다.
    private func remember(_ request: PairingRequest) {
        pairedRemotes[request.remoteID] = request.remoteName
        UserDefaults.standard.set(pairedRemotes, forKey: Keys.pairedRemotes)
    }

    // MARK: 수명주기

    func start() {
        guard session == nil else { return }

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        // 리모컨이 "지난번 그 Mac" 을 알아볼 수 있도록 식별자를 광고에 싣는다.
        // 이름(peerID.displayName)은 바뀌거나 겹칠 수 있어 짝의 기준이 되지 못한다.
        let advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: [RemoteService.DiscoveryKey.hostID: hostID],
            serviceType: RemoteService.type
        )
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser

        // 1초 주기 — 타이머 표시가 초 단위라 그보다 자주 보낼 이유가 없다.
        let timer = Foundation.Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.broadcastState() }
        }
        RunLoop.main.add(timer, forMode: .common)
        broadcastTimer = timer
    }

    func stop() {
        broadcastTimer?.invalidate(); broadcastTimer = nil
        advertiser?.stopAdvertisingPeer(); advertiser = nil
        session?.disconnect(); session = nil
        connectedCount = 0
    }

    // MARK: 상태 송신

    /// 타이머가 바뀌는 즉시 반영하고 싶을 때 호출 (1초 주기를 기다리지 않도록).
    func pushStateNow() { broadcastState() }

    private func broadcastState() {
        guard let session, !session.connectedPeers.isEmpty else { return }

        let timers = NoteManager.shared.timerListManager.entries.map { entry in
            RemoteTimer(
                id: entry.id,
                name: entry.name,
                remaining: entry.remaining,
                target: entry.targetSeconds,
                isRunning: entry.isRunning,
                isFinished: entry.isFinished,
                isHidden: entry.isWidgetHidden,
                isPomodoro: entry.isPomodoro,
                phaseTitle: entry.isPomodoro ? entry.phase.title : nil,
                cycleNumber: entry.cycleNumber,
                size: entry.widgetSize.rawValue,
                theme: entry.theme.rawValue,
                placement: placement(of: entry.widgetPanel)
            )
        }
        let packet = RemotePacket.state(
            RemoteState(hostName: peerID.displayName, timers: timers, desktop: ScreenMap.desktop())
        )
        send(packet, to: session.connectedPeers)
    }

    /// 위젯 창의 위치를 리모컨이 그릴 수 있는 정규화 값으로 옮겨 담는다.
    /// 기준계는 `ScreenMap` — 명령을 적용하는 `NoteManager.moveWidget` 과 **같은 곳**을 쓴다.
    /// 그래야 리모컨에서 놓은 자리와 창이 멈추는 자리가 맞는다.
    private func placement(of panel: NSWindow?) -> RemotePlacement? {
        guard let panel else { return nil }
        let bounds = ScreenMap.desktopBounds()
        guard bounds.width > 0, bounds.height > 0 else { return nil }

        let frame = panel.frame
        let x = (frame.midX - bounds.minX) / bounds.width
        // AppKit 은 y 가 위로 자란다. 규약대로 위에서 아래로 뒤집어 보낸다.
        let y = (bounds.maxY - frame.midY) / bounds.height
        let screenID = NSScreen.screens.firstIndex(where: { $0 == panel.screen }) ?? 0

        // 창이 데스크탑 밖으로 나가 있어도 판 안에는 그려져야 한다 (되찾을 수 있게).
        return RemotePlacement(
            x: Double(max(0, min(1, x))),
            y: Double(max(0, min(1, y))),
            widthRatio: Double(min(1, frame.width / bounds.width)),
            heightRatio: Double(min(1, frame.height / bounds.height)),
            screenID: screenID
        )
    }

    private func send(_ packet: RemotePacket, to peers: [MCPeerID]) {
        guard let session, !peers.isEmpty, let data = try? packet.encoded() else { return }
        // .unreliable — 매초 전체 상태를 다시 보내므로 유실돼도 다음 패킷이 덮어쓴다.
        // 재전송을 기다리다 밀리는 것보다 최신 상태가 빨리 도착하는 편이 낫다.
        try? session.send(data, toPeers: peers, with: .unreliable)
    }

    // MARK: 명령 적용

    private func apply(_ command: RemoteCommand) {
        let manager = NoteManager.shared
        let entries = manager.timerListManager.entries
        func entry(_ id: UUID) -> TimerEntry? { entries.first { $0.id == id } }

        switch command {
        case .requestState:
            broadcastState()

        case .toggleRun(let id):
            guard let e = entry(id) else { return }
            // 완료된 타이머를 다시 누르면 되감고 시작 — 패널의 재생 버튼과 같은 동작.
            if e.isFinished { e.reset() }
            e.toggleRunning()

        case .addSeconds(let id):      entry(id)?.addSeconds()
        case .subtractSeconds(let id): entry(id)?.subtractSeconds()
        case .reset(let id):           entry(id)?.reset()

        case .setSize(let id, let raw):
            guard let e = entry(id), let size = WidgetSize(rawValue: raw) else { return }
            manager.setWidgetSize(size, for: e)

        case .cycleTheme(let id):
            guard let e = entry(id) else { return }
            e.theme = e.theme.next

        case .toggleHidden(let id):
            guard let e = entry(id) else { return }
            if e.isWidgetHidden {
                e.widgetPanel?.orderFront(nil)
                e.isWidgetHidden = false
            } else {
                e.widgetPanel?.orderOut(nil)
                e.isWidgetHidden = true
            }

        case .align(let id):
            guard let e = entry(id) else { return }
            manager.snapWidgetToPanel(for: e)

        case .moveWidget(let id, let x, let y):
            guard let e = entry(id) else { return }
            manager.moveWidget(for: e, normalizedX: CGFloat(x), normalizedY: CGFloat(y))

        case .remove(let id):
            guard let e = entry(id) else { return }
            manager.timerListManager.remove(e)

        case .addPreset(let seconds, let name):
            let e = TimerEntry(name: name, targetSeconds: seconds)
            e.setRunning(true)
            manager.timerListManager.add(e)
        }

        // 명령 결과가 리모컨에 곧바로 보이도록 즉시 되돌려준다.
        broadcastState()
    }
}

// MARK: - MCSessionDelegate

extension RemoteControlHost: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            self.connectedCount = session.connectedPeers.count
            if state == .connected { self.broadcastState() }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let packet = try? RemotePacket.decode(data) else { return }
        // 리모컨이 상태를 보내오는 일은 없다. 명령만 처리한다.
        guard case .command(let command) = packet else { return }
        Task { @MainActor in self.apply(command) }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream,
                             withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension RemoteControlHost: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?,
                                invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // 같은 로컬 네트워크에 있고 서비스 타입까지 맞으면 **누구든** 여기 도달한다.
        // 옆자리 발표자의 리모컨도 마찬가지라, 자동 수락하면 남의 타이머가 같이 움직인다.
        // 그래서 신원(`PairingRequest`)을 확인해 아는 리모컨과 코드가 맞은 리모컨만 받는다.
        //
        // 발표 직전에 Mac 을 만지게 만드는 수락 다이얼로그는 여전히 띄우지 않는다 —
        // 확인은 리모컨 쪽에서 코드를 한 번 입력하는 것으로 끝난다.
        Task { @MainActor in
            guard let context, let request = try? PairingRequest.decode(context) else {
                // 컨텍스트가 없는 초대 = 페어링을 모르는 옛 리모컨 앱. 두 앱을 함께 올려야 한다.
                NSLog("[Remote] 신원이 없는 초대를 거절함 (리모컨 앱 업데이트 필요)")
                invitationHandler(false, nil)
                return
            }

            if self.pairedRemotes[request.remoteID] != nil {
                self.remember(request)   // 기기 이름이 바뀌었을 수 있으니 갱신해 둔다
                invitationHandler(true, self.session)
                return
            }

            guard request.code == self.pairingCode else {
                NSLog("[Remote] 코드가 맞지 않아 거절함: \(request.remoteName)")
                invitationHandler(false, nil)
                return
            }

            self.remember(request)
            invitationHandler(true, self.session)
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                                didNotStartAdvertisingPeer error: Error) {
        NSLog("[Remote] 광고 시작 실패: \(error.localizedDescription)")
    }
}
