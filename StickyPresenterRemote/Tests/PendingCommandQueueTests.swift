import XCTest

/// 단축어가 맡겨 둔 명령 — 붙는 순간 보낼 것과 버릴 것을 가르는 규칙.
final class PendingCommandQueueTests: XCTestCase {
    private let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)

    func testDrainReturnsCommandsInOrderAndEmptiesQueue() {
        var queue = PendingCommandQueue()
        queue.enqueue(.addPreset(seconds: 300, name: "5m"), at: t0)
        queue.enqueue(.requestState, at: t0)

        let drained = queue.drain(now: t0.addingTimeInterval(5))

        XCTAssertEqual(drained.count, 2)
        guard case .addPreset(let seconds, let name) = drained[0] else {
            return XCTFail("첫 명령은 넣은 순서대로 addPreset 이어야 한다")
        }
        XCTAssertEqual(seconds, 300)
        XCTAssertEqual(name, "5m")
        guard case .requestState = drained[1] else { return XCTFail("두 번째 명령 순서가 바뀌었다") }
        XCTAssertTrue(queue.isEmpty)
        XCTAssertTrue(queue.drain(now: t0).isEmpty, "한 번 꺼낸 명령을 두 번 보내면 타이머가 둘 생긴다")
    }

    func testStaleCommandsAreDropped() {
        var queue = PendingCommandQueue()
        queue.enqueue(.addPreset(seconds: 600, name: "10m"), at: t0)
        queue.enqueue(.addPreset(seconds: 180, name: "3m"), at: t0.addingTimeInterval(100))

        let drained = queue.drain(now: t0.addingTimeInterval(PendingCommandQueue.maxAge + 1))

        XCTAssertEqual(drained.count, 1, "maxAge 를 넘긴 명령은 다른 발표 중에 튀어나오면 안 된다")
        guard case .addPreset(_, let name) = drained.first else { return XCTFail() }
        XCTAssertEqual(name, "3m")
        XCTAssertTrue(queue.isEmpty, "버린 명령도 큐에 남지 않아야 한다")
    }

    func testCommandAtExactlyMaxAgeIsStillSent() {
        var queue = PendingCommandQueue()
        queue.enqueue(.requestState, at: t0)
        XCTAssertEqual(queue.drain(now: t0.addingTimeInterval(PendingCommandQueue.maxAge)).count, 1)
    }

    func testRemoveAllCancelsPending() {
        var queue = PendingCommandQueue()
        queue.enqueue(.requestState, at: t0)
        queue.removeAll()
        XCTAssertTrue(queue.isEmpty)
        XCTAssertTrue(queue.drain(now: t0).isEmpty)
    }

    /// Mac 앱 프리셋과 같은 표기여야 목록·위젯에 "5m" 과 "5분" 이 섞이지 않는다.
    func testTimerNameMatchesMacPresetLabels() {
        XCTAssertEqual(timerName(minutes: 5), "5m")
        XCTAssertEqual(timerName(minutes: 59), "59m")
        XCTAssertEqual(timerName(minutes: 60), "1h")
        XCTAssertEqual(timerName(minutes: 90), "1h 30m")
        XCTAssertEqual(timerName(minutes: 600), "10h")
    }
}
