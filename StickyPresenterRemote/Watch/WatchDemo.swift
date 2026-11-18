// 스크린샷용 데모 (DEBUG 전용): `-watchDemo running` · `-watchDemo paused` (확인용 `offline` · `empty`)
// 언어마다 찍어야 하는데 Mac · iPhone 과 붙여 24개 언어를 찍을 수는 없다. Mac 없이 남은 시간을 채운다.
// 타이머 이름 "15m" · "10m" 은 Mac 이 프리셋에 붙이는 이름 그대로다(언어와 무관).

#if DEBUG
import Foundation

enum WatchDemo {
    static var snapshot: WatchSnapshot? {
        switch UserDefaults.standard.string(forKey: "watchDemo") {
        case "running":
            return WatchSnapshot(host: "MacBook Pro", connected: true,
                                 timer: WatchTimer(id: UUID(), name: "15m", phase: nil, target: 900, isRunning: true,
                                                   endsAt: .now.addingTimeInterval(522), pausedRemaining: 522))
        case "paused":
            return WatchSnapshot(host: "MacBook Pro", connected: true,
                                 timer: WatchTimer(id: UUID(), name: "10m", phase: nil, target: 600, isRunning: false,
                                                   endsAt: nil, pausedRemaining: 258))
        case "offline":   // iPhone 이 잠겨 Mac 과 끊긴 때 — 손목은 계속 센다(확인용, 스토어에는 안 씀)
            return WatchSnapshot(host: "MacBook Pro", connected: false,
                                 timer: WatchTimer(id: UUID(), name: "15m", phase: nil, target: 900, isRunning: true,
                                                   endsAt: .now.addingTimeInterval(41), pausedRemaining: 41))
        case "empty":
            return WatchSnapshot(host: nil, connected: false, timer: nil)
        default:
            return nil
        }
    }
}
#endif
