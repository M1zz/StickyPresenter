import Combine
import Foundation
import WatchConnectivity

// MARK: - Apple Watch 중계
//
// 워치는 Mac 에 직접 붙지 않는다. 이 iPhone 리모컨이 Mac 에서 받은 상태를 워치로 넘기고,
// 워치의 시작·일시정지 · ±30초를 Mac 으로 넘긴다. 규약은 Shared/WatchSnapshot.swift.
//
// - 보내는 것은 **끝나는 시각**이다. 그래서 1초마다 오는 Mac 상태를 그대로 넘기지 않고,
//   시작·일시정지 · 시간 조정처럼 끝나는 시각이 바뀔 때만 보낸다(같으면 건너뜀).
// - iPhone 이 백그라운드로 가면 Mac 과의 연결이 끊긴다(RemoteClient.stop). 그때도 타이머는 지우지 않고
//   `connected = false` 만 알린다 — Mac 의 타이머는 그대로 돌고, 손목은 마지막 끝나는 시각으로 계속 센다.

@MainActor
final class WatchRelay: NSObject {
    static let shared = WatchRelay()

    private weak var client: RemoteClient?
    private var subscription: AnyCancellable?
    private var proSubscription: AnyCancellable?
    /// 지금 워치에 보여 주는 타이머. 여러 개가 돌아도 손목의 타이머가 1초마다 바뀌지 않게 붙잡는다.
    private var shownID: UUID?
    private var lastTimer: WatchTimer?
    private var lastSent: WatchSnapshot?

    func start(with client: RemoteClient) {
        guard self.client == nil, WCSession.isSupported() else { return }
        self.client = client
        WCSession.default.delegate = self
        WCSession.default.activate()

        // 끊길 때는 timers 가 먼저 비고 status 가 뒤따라 바뀐다. 잠깐 기다려 둘을 한 번에 본다 —
        // 그러지 않으면 '연결됨 + 타이머 없음' 이 끼어들어 손목의 타이머가 지워진다.
        subscription = client.$status.combineLatest(client.$timers)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, timers in self?.publish(timers) }
        // Pro 를 사거나 구독이 끝나면 손목도 곧바로 따라간다.
        proSubscription = RemotePro.shared.objectWillChange
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.resend() }
    }

    /// Apple Watch 는 Pro 에서 열린다. 잠겨 있으면 타이머 없이 '잠김' 한 장만 보낸다.
    private var watchAllowed: Bool { RemotePro.shared.allows(.watch) }

    // MARK: 보내기

    private func publish(_ timers: [RemoteTimer]) {
        guard let client else { return }
        let connected = client.isConnected
        guard watchAllowed else {
            lastTimer = nil
            shownID = nil
            send(WatchSnapshot(host: nil, connected: connected, timer: nil, locked: true))
            return
        }
        if connected {
            lastTimer = pick(timers).map(Self.watchTimer)
            shownID = lastTimer?.id
        }
        let host: String? = if case .connected(let name) = client.status { name } else { lastSent?.host }
        send(WatchSnapshot(host: host, connected: connected, timer: lastTimer))
    }

    private func send(_ snapshot: WatchSnapshot) {
        if let lastSent, Self.sameMoment(lastSent, snapshot) { return }
        let wc = WCSession.default
        guard wc.activationState == .activated, wc.isPaired, wc.isWatchAppInstalled,
              let data = snapshot.encoded() else { return }
        lastSent = snapshot
        let payload = [WatchSnapshot.key: data]
        try? wc.updateApplicationContext(payload)
        // 컴플리케이션은 하루에 깨울 수 있는 횟수가 정해져 있다. 끝나는 시각이 바뀔 때만 오므로 넉넉하다.
        if wc.isComplicationEnabled, wc.remainingComplicationUserInfoTransfers > 0 {
            wc.transferCurrentComplicationUserInfo(payload)
        }
    }

    /// 손목 쪽에서 보면 같은 장인가 — 1초마다 오는 남은 시간의 흔들림(1초 안쪽)은 같다고 본다.
    private static func sameMoment(_ a: WatchSnapshot, _ b: WatchSnapshot) -> Bool {
        guard a.host == b.host, a.connected == b.connected, a.locked == b.locked else { return false }
        switch (a.timer, b.timer) {
        case (nil, nil): return true
        case let (x?, y?):
            guard x.id == y.id, x.name == y.name, x.phase == y.phase, x.target == y.target,
                  x.isRunning == y.isRunning, abs(x.pausedRemaining - y.pausedRemaining) < 1 else { return false }
            switch (x.endsAt, y.endsAt) {
            case (nil, nil): return true
            case let (e1?, e2?): return abs(e1.timeIntervalSince(e2)) < 1.5
            default: return false
            }
        default: return false
        }
    }

    /// 손목에 띄울 타이머 하나: 보던 것이 돌고 있으면 그대로, 아니면 가장 먼저 끝나는 것,
    /// 아무것도 안 돌면 보던 것 · 아직 안 끝난 것 순서.
    private func pick(_ timers: [RemoteTimer]) -> RemoteTimer? {
        let shown = timers.first { $0.id == shownID }
        if let shown, shown.isRunning { return shown }
        return timers.filter(\.isRunning).min { $0.remaining < $1.remaining }
            ?? shown
            ?? timers.first { !$0.isFinished }
            ?? timers.first
    }

    private static func watchTimer(_ t: RemoteTimer) -> WatchTimer {
        let running = t.isRunning && !t.isFinished
        return WatchTimer(id: t.id, name: t.name, phase: t.phaseTitle, target: t.target,
                          isRunning: running,
                          endsAt: running ? Date.now.addingTimeInterval(t.remaining) : nil,
                          pausedRemaining: t.isFinished ? 0 : t.remaining)
    }

    // MARK: 받기

    /// 워치의 버튼 하나를 Mac 명령으로. Mac 에 붙어 있지 않으면 보내지 않고 "못 했다" 고 답한다 —
    /// 나중에 붙었을 때 지난 명령이 뒤늦게 타이머를 멈추면 발표 중에 더 곤란하다.
    fileprivate func handle(_ message: [String: Any]) -> Bool {
        guard let client, client.isConnected, watchAllowed,
              let raw = message[WatchCommand.key] as? String, let command = WatchCommand(rawValue: raw),
              let idString = message[WatchCommand.timerKey] as? String, let id = UUID(uuidString: idString),
              client.timers.contains(where: { $0.id == id }) else { return false }
        switch command {
        case .toggle: client.send(.toggleRun(id))
        case .plus:   client.send(.addSeconds(id))
        case .minus:  client.send(.subtractSeconds(id))
        }
        return true
    }

    /// 워치가 새로 짝지어졌거나 앱이 깔리면 같은 장이라도 다시 보낸다.
    fileprivate func resend() {
        lastSent = nil
        if let client { publish(client.timers) }
    }
}

extension WatchRelay: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {
        Task { @MainActor in self.resend() }
    }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.resend() }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                             replyHandler: @escaping ([String: Any]) -> Void) {
        let message = message.compactMapValues { $0 as? String }
        Task { @MainActor in
            let ok = self.handle(message)
            replyHandler([WatchCommand.okKey: ok])
        }
    }
}
