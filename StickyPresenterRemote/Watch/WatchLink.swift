import Foundation
import UserNotifications
import WatchConnectivity
import WatchKit
import WidgetKit

// MARK: - iPhone 과 잇기
//
// iPhone 리모컨이 보낸 한 장(WatchSnapshot)을 받아 두고, 버튼 · Crown · 동작 버튼의 명령을 iPhone 으로 보낸다.
// 받은 장마다 '5분 · 1분 남음 · 끝' 손목 알림을 워치가 직접 건다 — iPhone 이 잠겨 Mac 과 끊겨도 울린다.

@MainActor
final class WatchLink: NSObject, ObservableObject {
    static let shared = WatchLink()

    /// 지금 보여 주는 장. 버튼을 누르면 iPhone 의 답보다 먼저 바뀐다(아래 `confirmed` 가 진짜 값).
    @Published private(set) var snapshot: WatchSnapshot? = WatchStore.load()
    /// 명령이 iPhone · Mac 에 닿지 못했을 때 잠깐 보여 줄 말.
    @Published private(set) var notice: String?

    private var confirmed: WatchSnapshot? = WatchStore.load()
    private var noticeTask: Task<Void, Never>?

    var canControl: Bool { snapshot?.connected == true && snapshot?.timer != nil }

    func activate() {
        #if DEBUG
        if let demo = WatchDemo.snapshot { snapshot = demo; return }
        #endif
        guard WCSession.isSupported(), WCSession.default.activationState != .activated else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// 백그라운드로 깨어났을 때 받을 것이 다 들어올 때까지 잠깐 기다린다.
    func drain() async {
        activate()
        for _ in 0..<25 where WCSession.default.hasContentPending {
            try? await Task.sleep(for: .milliseconds(200))
        }
    }

    // MARK: 보내기

    /// 명령 하나를 iPhone 으로. Mac 에 닿았으면 true.
    @discardableResult
    func send(_ command: WatchCommand) async -> Bool {
        guard let current = snapshot, let timer = current.timer, current.connected else {
            say(String(localized: "iPhone에서 리모컨을 열어 두면 손목으로 조종할 수 있어요"))
            WKInterfaceDevice.current().play(.failure)
            return false
        }
        WKInterfaceDevice.current().play(.click)
        var guess = current
        guess.timer = timer.applying(command)
        show(guess)

        activate()
        for _ in 0..<15 where WCSession.default.activationState != .activated {
            try? await Task.sleep(for: .milliseconds(200))
        }
        let message = [WatchCommand.key: command.rawValue, WatchCommand.timerKey: timer.id.uuidString]
        let ok = await withCheckedContinuation { (done: CheckedContinuation<Bool, Never>) in
            WCSession.default.sendMessage(message, replyHandler: { reply in
                done.resume(returning: reply[WatchCommand.okKey] as? Bool ?? false)
            }, errorHandler: { _ in
                done.resume(returning: false)
            })
        }
        if !ok {
            show(confirmed)
            say(String(localized: "Mac에 닿지 않았어요"))
            WKInterfaceDevice.current().play(.failure)
        }
        return ok
    }

    private func say(_ text: String) {
        notice = text
        noticeTask?.cancel()
        noticeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.notice = nil
        }
    }

    // MARK: 받기

    fileprivate func receive(_ info: [String: Any]) {
        guard let data = info[WatchSnapshot.key] as? Data, let new = WatchSnapshot.decode(data) else { return }
        confirmed = new
        show(new)
    }

    /// 화면 · 컴플리케이션 · 손목 알림을 이 장에 맞춘다.
    private func show(_ new: WatchSnapshot?) {
        WatchStore.save(new)
        guard new != snapshot else { return }
        let timerChanged = new?.timer != snapshot?.timer
        snapshot = new
        if timerChanged {
            WidgetCenter.shared.reloadAllTimelines()
            scheduleMilestones(new?.timer)
        }
    }

    private func scheduleMilestones(_ timer: WatchTimer?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: WatchMilestone.allCases.map(\.notificationID))
        guard let timer, timer.isRunning, let end = timer.endsAt else { return }
        for milestone in WatchMilestone.allCases where milestone.applies(to: timer) {
            let fire = end.addingTimeInterval(-milestone.secondsLeft)
            guard fire > .now.addingTimeInterval(1) else { continue }
            let content = UNMutableNotificationContent()
            content.title = milestone.title
            content.body = timer.phase ?? timer.name
            // 무음 모드면 진동만 온다. 소리를 아예 빼면 손목도 조용해질 수 있어 기본 소리를 둔다.
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fire.timeIntervalSinceNow, repeats: false)
            center.add(UNNotificationRequest(identifier: milestone.notificationID, content: content, trigger: trigger))
        }
    }
}

extension WatchMilestone {
    var notificationID: String { "milestone.\(rawValue)" }

    var title: String {
        switch self {
        case .fiveMinutes: String(localized: "5분 남았어요")
        case .oneMinute:   String(localized: "1분 남았어요")
        case .end:         String(localized: "시간이 다 됐어요")
        }
    }

    /// 화면 아래 한 줄 — 다음에 손목이 언제 울리는지.
    var hint: String {
        switch self {
        case .fiveMinutes: String(localized: "5분 남으면 진동")
        case .oneMinute:   String(localized: "1분 남으면 진동")
        case .end:         String(localized: "끝나면 진동")
        }
    }

    /// 지금부터 다음에 울릴 순간.
    static func next(for timer: WatchTimer, at now: Date = .now) -> WatchMilestone? {
        let left = timer.remaining(at: now)
        return allCases.first { $0.applies(to: timer) && $0.secondsLeft < left }
    }
}

extension WatchLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {
        let context = session.receivedApplicationContext
        Task { @MainActor in self.receive(context) }
    }
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        Task { @MainActor in self.receive(context) }
    }
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in self.receive(userInfo) }
    }
}
