import XCTest

/// Mac 앱과 리모컨이 **같은 파일**(Shared/RemoteProtocol.swift)로 주고받는 규약.
/// 한쪽만 고쳐 디코딩이 조용히 깨지는 일을 여기서 먼저 잡는다.
final class RemoteProtocolTests: XCTestCase {

    // MARK: 연결 코드

    func testNormalizedKeepsOnlyAsciiDigitsUpToFour() {
        XCTAssertEqual(PairingCode.normalized("12 34"), "1234")
        XCTAssertEqual(PairingCode.normalized("123456"), "1234")
        XCTAssertEqual(PairingCode.normalized("0a0b1"), "001", "앞자리 0 을 잃으면 안 된다")
        XCTAssertEqual(PairingCode.normalized("½١٢3"), "3", "½ · 아라비아 숫자는 코드 숫자가 아니다")
    }

    func testIsCompleteRequiresExactlyFourAsciiDigits() {
        XCTAssertTrue(PairingCode.isComplete("0042"))
        XCTAssertFalse(PairingCode.isComplete("042"))
        XCTAssertFalse(PairingCode.isComplete("00421"))
        XCTAssertFalse(PairingCode.isComplete("12a4"))
    }

    func testRandomCodeIsAlwaysComplete() {
        for _ in 0..<200 {
            XCTAssertTrue(PairingCode.isComplete(PairingCode.random()))
        }
    }

    // MARK: 봉투

    func testCommandPacketRoundTrip() throws {
        let id = UUID()
        let data = try RemotePacket.command(.moveWidget(id, x: 0.25, y: 0.75)).encoded()
        guard case .command(.moveWidget(let gotID, let x, let y)) = try RemotePacket.decode(data) else {
            return XCTFail("moveWidget 명령이 그대로 돌아와야 한다")
        }
        XCTAssertEqual(gotID, id)
        XCTAssertEqual(x, 0.25)
        XCTAssertEqual(y, 0.75)
    }

    func testStateWithoutDesktopStillDecodes() throws {
        // 화면 배치(desktop)를 모르는 옛 Mac 앱이 보낸 상태도 읽혀야 한다.
        let data = try RemotePacket.state(RemoteState(hostName: "Mac", timers: [])).encoded()
        guard case .state(let state) = try RemotePacket.decode(data) else { return XCTFail() }
        XCTAssertEqual(state.hostName, "Mac")
        XCTAssertNil(state.desktop)
    }

    func testPairingRequestRoundTripKeepsNilCode() throws {
        let request = PairingRequest(remoteID: "abc", remoteName: "iPhone", code: nil)
        let decoded = try PairingRequest.decode(request.encoded())
        XCTAssertEqual(decoded.remoteID, "abc")
        XCTAssertNil(decoded.code, "이미 짝인 리모컨은 코드 없이 붙는다")
    }
}
