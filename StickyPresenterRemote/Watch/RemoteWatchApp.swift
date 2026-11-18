import SwiftUI
import UserNotifications
import WatchKit

// MARK: - Apple Watch: 발표 중 손목 위 한 화면
//
// 발표하는 동안 화면을 보지 않고 남은 시간을 안다 — 5분 · 1분 남았을 때와 끝날 때 손목이 울린다.
// 한 화면: 남은 시간을 크게, 시작·일시정지 하나. Digital Crown 한 칸이 30초 더하기 · 빼기.
// 시작·일시정지는 두 번 두드리기(watchOS 11+) · 동작 버튼(ToggleTimerIntent)으로도 된다.
// 명령은 iPhone 리모컨을 거쳐 Mac 에 닿는다(Shared/WatchSnapshot.swift).

@main
struct RemoteWatchApp: App {
    @WKApplicationDelegateAdaptor private var delegate: WatchAppDelegate

    var body: some Scene {
        WindowGroup {
            RemoteWatchView(link: .shared)
        }
        // iPhone 이 컴플리케이션을 깨우면 앱이 잠깐 깨어 새 장을 받고 컴플리케이션 · 손목 알림을 맞춘다.
        .backgroundTask(.watchConnectivity) { await WatchLink.shared.drain() }
    }
}

final class WatchAppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        // 스크린샷용 데모에서는 권한 창이 화면을 가리지 않게 묻지 않는다.
        #if DEBUG
        let demo = WatchDemo.snapshot != nil
        #else
        let demo = false
        #endif
        if !demo { center.requestAuthorization(options: [.alert, .sound]) { _, _ in } }
        Task { @MainActor in WatchLink.shared.activate() }
    }

    /// 앱을 띄워 둔 채(손목을 내려 화면이 어두워진 채)여도 손목은 울린다.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions { [.banner, .sound] }
}

// MARK: - 한 화면

struct RemoteWatchView: View {
    @ObservedObject var link: WatchLink
    @State private var crown = 0.0
    @State private var crownStep = 0
    @FocusState private var crownFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if let timer = link.snapshot?.timer {
                    TimerFace(timer: timer, connected: link.snapshot?.connected == true, notice: link.notice)
                } else {
                    waiting
                }
            }
            .navigationTitle(link.snapshot?.host ?? "Remote Controller")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 조종이 안 될 때(iPhone 이 Mac 과 끊김)는 버튼을 감추고 그 자리에 이유를 둔다.
                if link.canControl, let timer = link.snapshot?.timer {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button { Task { await link.send(.minus) } } label: {
                            Image(systemName: "gobackward.30")
                        }
                        .accessibilityLabel(Text("30초 빼기"))
                        PlayPauseButton(isRunning: timer.isRunning) {
                            Task { await link.send(.toggle) }
                        }
                        Button { Task { await link.send(.plus) } } label: {
                            Image(systemName: "goforward.30")
                        }
                        .accessibilityLabel(Text("30초 더하기"))
                    }
                }
            }
        }
        // Digital Crown 한 칸 = 30초. 위로 돌리면 더하고 아래로 돌리면 뺀다.
        .focusable()
        .focused($crownFocused)
        .focusEffectDisabled()
        .digitalCrownRotation($crown, from: -10_000, through: 10_000, by: 1,
                              sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
        .onChange(of: crown) { _, value in
            let step = Int(value.rounded())
            let delta = step - crownStep
            crownStep = step
            guard delta != 0, link.canControl else { return }
            for _ in 0..<abs(delta) {
                Task { await link.send(delta > 0 ? .plus : .minus) }
            }
        }
        .onAppear { crownFocused = true }
    }

    private var waiting: some View {
        VStack(spacing: 8) {
            let locked = link.snapshot?.locked == true
            Image(systemName: locked ? "lock.fill" : "timer")
                .font(.title)
                .foregroundStyle(WatchTheme.accent)
            Text(locked ? LocalizedStringKey("iPhone 리모컨에서 Pro를 열면 손목에서 남은 시간을 볼 수 있어요")
                        : LocalizedStringKey("iPhone 리모컨이 Mac에 연결되면 남은 시간이 여기 보여요"))
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }
}

/// 남은 시간을 크게. 돌고 있으면 시스템이 세는 타이머 글자라 손목을 내려도 그대로 줄어든다.
struct TimerFace: View {
    let timer: WatchTimer
    let connected: Bool
    let notice: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(timer.phase.map { "\(timer.name) · \($0)" } ?? timer.name)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(WatchTheme.accent)
                .lineLimit(1)

            Group {
                if timer.isRunning, let end = timer.endsAt, end > .now {
                    Text(timerInterval: Date.now...end, countsDown: true)
                } else {
                    Text(verbatim: clockText(timer.remaining()))
                        .foregroundStyle(timer.isRunning ? .primary : .secondary)
                }
            }
            .font(.system(size: 48, weight: .semibold, design: .rounded).monospacedDigit())
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .accessibilityLabel(Text(spokenRemaining))

            progress
                .tint(WatchTheme.accent)

            footer
                .font(.footnote)
                .foregroundStyle(.secondary)
                // 버튼이 떠 있으면 한 줄만 — 길면 줄여서라도 버튼 위로 넘치지 않게.
                .lineLimit(connected ? 1 : nil)
                .minimumScaleFactor(connected ? 0.7 : 1)
                .fixedSize(horizontal: false, vertical: !connected)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var progress: some View {
        if timer.isRunning, let end = timer.endsAt, end > .now, timer.target > 0 {
            ProgressView(timerInterval: end.addingTimeInterval(-timer.target)...end, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
        } else {
            ProgressView(value: timer.fractionLeft())
        }
    }

    /// 아래 한 줄: 못 전한 말 › 조종이 안 되는 이유 › 다음에 손목이 울릴 때 › 일시정지됨.
    @ViewBuilder
    private var footer: some View {
        if let notice {
            Text(notice)
        } else if !connected {
            Text("iPhone에서 리모컨을 열어 두면 손목으로 조종할 수 있어요")
        } else if timer.isRunning {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                if let next = WatchMilestone.next(for: timer, at: context.date) {
                    Label(next.hint, systemImage: "applewatch.radiowaves.left.and.right")
                }
            }
        } else if timer.remaining() > 0 {
            Label("일시정지됨", systemImage: "pause.fill")
        } else {
            Label("시간이 다 됐어요", systemImage: "checkmark")
        }
    }

    private var spokenRemaining: String {
        Duration.seconds(Int(timer.remaining().rounded(.up)))
            .formatted(.units(allowed: [.hours, .minutes, .seconds], width: .wide))
    }
}

/// 시작·일시정지 — 손가락 두 번 두드리기로도 누른다(watchOS 11+).
struct PlayPauseButton: View {
    let isRunning: Bool
    let action: () -> Void

    var body: some View {
        let button = Button(action: action) {
            Image(systemName: isRunning ? "pause.fill" : "play.fill")
        }
        .controlSize(.large)
        .tint(WatchTheme.accent)
        .accessibilityLabel(isRunning ? Text("일시정지") : Text("시작"))
        if #available(watchOS 11.0, *) {
            button.handGestureShortcut(.primaryAction)
        } else {
            button
        }
    }
}

enum WatchTheme {
    /// 앱 아이콘의 호박색.
    static let accent = Color(red: 1.0, green: 0.76, blue: 0.2)
}
