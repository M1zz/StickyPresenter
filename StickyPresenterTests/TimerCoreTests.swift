import XCTest

/// 타이머 입력 해석과 벽시계 틱 — `StickyPresenter/TimerCore.swift` 를 직접 컴파일해 검사한다.
final class TimerCoreTests: XCTestCase {

    // MARK: parseTimerInput

    func testPlainNumberIsMinutes() {
        XCTAssertEqual(parseTimerInput("10"), 600)
        XCTAssertEqual(parseTimerInput("  3 "), 180)
    }

    func testColonFormats() {
        XCTAssertEqual(parseTimerInput("5:30"), 330)
        XCTAssertEqual(parseTimerInput("1:15:00"), 4500)
    }

    func testUnitFormats() {
        XCTAssertEqual(parseTimerInput("1h 20m"), 4800)
        XCTAssertEqual(parseTimerInput("45s"), 45)
        XCTAssertEqual(parseTimerInput("2 hours"), 7200)
        XCTAssertEqual(parseTimerInput("10 mins"), 600)
        XCTAssertEqual(parseTimerInput("1 hr"), 3600)
        XCTAssertEqual(parseTimerInput("5 sec"), 5)
        XCTAssertEqual(parseTimerInput("1min 30sec"), 90)
    }

    func testUnreadableInputIsZero() {
        XCTAssertEqual(parseTimerInput(""), 0)
        XCTAssertEqual(parseTimerInput("abc"), 0)
        XCTAssertEqual(parseTimerInput("0"), 0)
        XCTAssertEqual(parseTimerInput("-5"), 0)
    }

    /// 긴 숫자를 치면 예전엔 미리보기의 Int 변환에서 앱이 죽었다.
    func testHugeInputIsRejectedInsteadOfOverflowing() {
        XCTAssertEqual(parseTimerInput("99999999999999999999"), 0)
        XCTAssertEqual(parseTimerInput("100h"), 0)
        XCTAssertEqual(parseTimerInput("99:59:59"), maxTimerSeconds)
    }

    func testShortTimeLabelNeverTraps() {
        XCTAssertEqual(shortTimeLabel(180), "3m")
        XCTAssertEqual(shortTimeLabel(90), "1:30")
        XCTAssertEqual(shortTimeLabel(4800), "1h 20m")
        XCTAssertEqual(shortTimeLabel(45), "45s")
        _ = shortTimeLabel(.greatestFiniteMagnitude)
        _ = shortTimeLabel(-10)
    }

    // MARK: parsePomodoroInput

    func testPomodoroInput() {
        XCTAssertEqual(parsePomodoroInput("25/5"), PomodoroConfig(focusSeconds: 1500, breakSeconds: 300))
        XCTAssertEqual(parsePomodoroInput("50m / 10m"), PomodoroConfig(focusSeconds: 3000, breakSeconds: 600))
        XCTAssertEqual(parsePomodoroInput("1:30/5"), PomodoroConfig(focusSeconds: 90, breakSeconds: 300))
        XCTAssertNil(parsePomodoroInput("25"))
        XCTAssertNil(parsePomodoroInput("25/"))
        XCTAssertNil(parsePomodoroInput("x/5"))
    }

    func testPomodoroLabel() {
        XCTAssertEqual(PomodoroConfig.classic.label, "25m/5m")
    }

    // MARK: TickClock

    func testTickClockCountsOnTimeTicks() {
        let start = Date(timeIntervalSinceReferenceDate: 1000)
        var clock = TickClock(start: start)
        XCTAssertEqual(clock.consume(now: start.addingTimeInterval(1.002)), 1)
        XCTAssertEqual(clock.consume(now: start.addingTimeInterval(2.004)), 1)
    }

    /// 발화가 늦게 오거나(메인 스레드 지연) 건너뛰어도 흐른 초를 잃지 않는다.
    func testTickClockCatchesUpAfterStall() {
        let start = Date(timeIntervalSinceReferenceDate: 1000)
        var clock = TickClock(start: start)
        XCTAssertEqual(clock.consume(now: start.addingTimeInterval(5.1)), 5)
        XCTAssertEqual(clock.consume(now: start.addingTimeInterval(6.0)), 1)
    }

    /// 조금 이른 발화(앵커와 타이머 예약 사이의 흔들림)에서도 한 틱을 빠뜨리지 않는다.
    func testTickClockAbsorbsJitterWithoutDrift() {
        let start = Date(timeIntervalSinceReferenceDate: 1000)
        var clock = TickClock(start: start)
        var total = 0
        for i in 1...600 {
            let jitter = (i % 2 == 0) ? -0.01 : 0.02
            total += clock.consume(now: start.addingTimeInterval(Double(i) + jitter))
        }
        XCTAssertEqual(total, 600)
    }

    func testTickClockIgnoresClockGoingBackwards() {
        let start = Date(timeIntervalSinceReferenceDate: 1000)
        var clock = TickClock(start: start)
        XCTAssertEqual(clock.consume(now: start.addingTimeInterval(-30)), 0)
        XCTAssertEqual(clock.anchor, start)
    }
}
