import SwiftUI

// 타이머의 순수 로직 — 창·패널·소리에 기대지 않는 계산만 모았다.
// 테스트 타겟(StickyPresenterTests)이 앱을 띄우지 않고 이 파일을 직접 컴파일해 검사한다.
// 그러니 여기에는 AppKit 창이나 싱글턴(NoteManager 등)을 부르는 코드를 넣지 말 것.

// MARK: - Time Limits

/// 타이머 한 개가 가질 수 있는 가장 긴 시간 — 99:59:59.
///
/// 상한이 없으면 입력창에 숫자를 길게 치는 것만으로 앱이 죽는다.
/// `Int(t)` 는 `Int.max` 를 넘는 Double 을 만나면 트랩하는데, 미리보기 문구가
/// 타이핑하는 동안 매번 그 변환을 하기 때문이다 ("99999999999999999999" → 분 → 6e21초).
let maxTimerSeconds: TimeInterval = 99 * 3600 + 59 * 60 + 59

// MARK: - Short Label

/// 프리셋 버튼·뽀모도로 라벨에 쓰는 짧은 시간 표기.
func shortTimeLabel(_ t: TimeInterval) -> String {
    let total = Int(min(max(0, t), maxTimerSeconds).rounded())
    if total >= 3600 {
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        if m == 0 && s == 0 { return "\(h)h" }
        if s == 0 { return "\(h)h \(m)m" }
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    if total > 0 && total % 60 == 0 { return "\(total / 60)m" }
    return total >= 60 ? String(format: "%d:%02d", total / 60, total % 60) : "\(total)s"
}

// MARK: - Pomodoro
/// 뽀모도로 구간 — 집중과 휴식 둘뿐이며 서로를 무한히 오간다.
enum PomodoroPhase {
    case focus
    case rest

    var title: String { self == .focus ? L("pomodoro.focus") : L("pomodoro.break") }
    var icon: String { self == .focus ? "brain.head.profile" : "cup.and.saucer.fill" }
    var next: PomodoroPhase { self == .focus ? .rest : .focus }

    /// 집중은 토마토색, 휴식은 민트색 — 위젯을 흘깃 봐도 지금이 어느 구간인지 알 수 있게.
    var color: Color {
        self == .focus
            ? Color(red: 0.91, green: 0.30, blue: 0.24)
            : Color(red: 0.16, green: 0.68, blue: 0.53)
    }
}

/// 집중 ↔ 휴식 길이. 이 설정을 가진 타이머는 완료 없이 두 구간을 계속 반복한다.
struct PomodoroConfig: Equatable {
    var focusSeconds: TimeInterval
    var breakSeconds: TimeInterval

    func seconds(for phase: PomodoroPhase) -> TimeInterval {
        max(1, phase == .focus ? focusSeconds : breakSeconds)
    }

    /// "25m/5m" 형태의 짧은 이름 (행·위젯 제목용)
    var label: String { "\(Self.shortUnit(focusSeconds))/\(Self.shortUnit(breakSeconds))" }

    private static func shortUnit(_ t: TimeInterval) -> String {
        let total = Int(min(max(0, t), maxTimerSeconds).rounded())
        if total % 60 == 0 { return "\(total / 60)m" }
        return total >= 60 ? String(format: "%d:%02d", total / 60, total % 60) : "\(total)s"
    }

    /// 메뉴바 · ⌘⌃B로 시작하는 기본값 (25분 집중 / 5분 휴식)
    static let classic = PomodoroConfig(focusSeconds: 25 * 60, breakSeconds: 5 * 60)
}

// MARK: - Parse input text → seconds
/// 입력창 문구를 초로 바꾼다. 읽을 수 없거나 `maxTimerSeconds` 를 넘으면 0.
func parseTimerInput(_ raw: String) -> TimeInterval {
    let seconds = parseTimerInputUnbounded(raw)
    return seconds.isFinite && seconds <= maxTimerSeconds ? seconds : 0
}

private func parseTimerInputUnbounded(_ raw: String) -> TimeInterval {
    let text = raw.trimmingCharacters(in: .whitespaces).lowercased()
    guard !text.isEmpty else { return 0 }

    // 1. 콜론 형식: M:SS 또는 H:MM:SS
    let colonRegex = try? NSRegularExpression(pattern: "^(\\d+):(\\d{1,2})(?::(\\d{1,2}))?$")
    if let match = colonRegex?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
        let vals = (1...3).compactMap { i -> Double? in
            guard let r = Range(match.range(at: i), in: text) else { return nil }
            return Double(text[r])
        }
        if vals.count == 2 { return vals[0] * 60 + vals[1] }
        if vals.count == 3 { return vals[0] * 3600 + vals[1] * 60 + vals[2] }
    }

    // 2. 단어/축약 형식
    var total: TimeInterval = 0
    let patterns: [(String, TimeInterval)] = [
        ("(\\d+)\\s*hours?",     3600),
        ("(\\d+)\\s*hr",         3600),
        ("(\\d+)\\s*h(?![a-z])", 3600),
        ("(\\d+)\\s*minutes?",   60),
        ("(\\d+)\\s*mins?",      60),
        ("(\\d+)\\s*m(?![a-z])", 60),
        ("(\\d+)\\s*seconds?",   1),
        ("(\\d+)\\s*secs?",      1),
        ("(\\d+)\\s*s(?![a-z])", 1),
    ]
    for (pattern, mul) in patterns {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
        for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let r = Range(match.range(at: 1), in: text), let v = Double(text[r]) {
                total += v * mul
            }
        }
    }
    if total > 0 { return total }

    // 3. 순수 숫자 → 분
    if let v = Double(text), v > 0 { return v * 60 }

    return 0
}

// MARK: - Parse pomodoro input ("25/5", "50m / 10m", "1:30/5")
/// 슬래시로 나뉜 두 시간을 각각 집중·휴식으로 읽는다. 한쪽이라도 해석되지 않으면 nil.
func parsePomodoroInput(_ raw: String) -> PomodoroConfig? {
    let parts = raw.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
    guard parts.count == 2 else { return nil }
    let focus = parseTimerInput(String(parts[0]))
    let rest  = parseTimerInput(String(parts[1]))
    guard focus > 0, rest > 0 else { return nil }
    return PomodoroConfig(focusSeconds: focus, breakSeconds: rest)
}

// MARK: - Tick Clock
/// 1초 틱마다 "실제로 몇 초가 흘렀는지"를 벽시계로 센다.
///
/// 틱 한 번에 1초씩 더하면 타이머가 실제 시간보다 느려진다.
/// `Foundation.Timer` 는 늦게 온 발화를 몰아서 주지 않고 건너뛰기 때문에,
/// 메인 스레드가 잠깐 막히거나(모달 알림·무거운 렌더) Mac 이 잠들었다 깨면
/// 그 사이의 초가 통째로 사라진다. 발표 타이머가 조용히 늦게 끝나는 셈이다.
///
/// 기준 시각(`anchor`)을 **정확히 센 만큼만** 앞으로 옮기므로 반올림 오차가 쌓이지 않는다.
struct TickClock {
    private(set) var anchor: Date

    init(start: Date = Date()) { anchor = start }

    /// 기준 시각 이후 흐른 온전한 초 수. 센 만큼 기준 시각을 옮긴다.
    /// 발화가 조금 늦거나 이른 흔들림은 가장 가까운 초로 반올림해 흡수한다.
    mutating func consume(now: Date = Date()) -> Int {
        let passed = now.timeIntervalSince(anchor)
        guard passed.isFinite, passed > 0 else { return 0 }
        let whole = Int(min(passed, maxTimerSeconds * 2).rounded())
        anchor = anchor.addingTimeInterval(TimeInterval(whole))
        return whole
    }
}

// MARK: - Timer Activity (App Nap)
/// 타이머가 도는 동안 App Nap 에 들지 않게 붙잡는다.
///
/// 이 앱은 Dock 아이콘이 없는 메뉴 막대 앱이고, 발표 중에는 Keynote 가 앞에 있다.
/// macOS 는 그런 "안 보이는" 앱의 타이머를 몰아서 늦게 깨운다(App Nap·타이머 병합).
/// 남은 시간은 `TickClock` 덕에 벽시계와 맞지만, **화면 갱신과 종료 알림이 늦게 오는** 것까지는
/// 막지 못하므로 도는 동안만 활동을 선언한다. 시스템 잠자기는 막지 않는다.
enum TimerActivity {
    private static var token: NSObjectProtocol?

    static func update(anyRunning: Bool) {
        if anyRunning, token == nil {
            token = ProcessInfo.processInfo.beginActivity(
                options: [.userInitiatedAllowingIdleSystemSleep, .latencyCritical],
                reason: "Presentation timer is running"
            )
        } else if !anyRunning, let current = token {
            ProcessInfo.processInfo.endActivity(current)
            token = nil
        }
    }
}
