import XCTest
// 심사용 화면 녹화 대본 — 실기기에서 사람이 쓰는 속도로 앱의 주 흐름을 처음부터 끝까지 돈다.
final class Record: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "com.leeo.StickyPresenter")
    let sb = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let code = ProcessInfo.processInfo.environment["PAIR_CODE"] ?? "0000"
    let mac = ProcessInfo.processInfo.environment["MAC_PREFIX"] ?? "hyunho"

    func pause(_ s: Double = 1.6) { Thread.sleep(forTimeInterval: s) }
    func tap(_ e: XCUIElement, wait: Double = 10, after: Double = 1.6) {
        XCTAssertTrue(e.waitForExistence(timeout: wait), "missing \(e)")
        e.tap(); pause(after)
    }
    func okWelcome() { if app.alerts.buttons["OK"].exists { app.alerts.buttons["OK"].tap(); pause(1) } }
    func allowSystem() {
        for l in ["Allow", "OK"] where sb.alerts.buttons[l].exists { pause(1.2); sb.alerts.buttons[l].tap(); pause(1.2) }
    }

    func testRecordReviewDemo() {
        continueAfterFailure = false
        XCUIDevice.shared.press(.home); pause(2.5)
        app.activate(); pause(3)
        okWelcome()
        // 첫 실행 안내 세 장
        tap(app.buttons["Next"], after: 2.5)
        tap(app.buttons["Next"], after: 2.5)
        tap(app.buttons["Find My Mac"], after: 2)
        // 로컬 네트워크 허용
        for _ in 0..<6 { allowSystem(); okWelcome(); pause(1) }
        // Mac 고르고 코드 넣기
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", mac)).firstMatch
        tap(row, wait: 20, after: 2)
        for ch in code { app.typeText(String(ch)); pause(0.5) }
        pause(1)
        tap(app.buttons["Connect"], after: 4)
        okWelcome()
        // 무료 조작: 새 타이머 · 멈춤 · 30초 · 다시 시작 · 초기화
        tap(app.buttons["5 min"], wait: 20, after: 4)
        tap(app.buttons["Pause"], after: 2)
        tap(app.buttons["Add 30 Seconds"], after: 2)
        tap(app.buttons["Add 30 Seconds"], after: 2)
        tap(app.buttons["Subtract 30 Seconds"], after: 2)
        tap(app.buttons["Start"], after: 4)
        tap(app.buttons["Reset"], after: 3)
        // Pro: 잠긴 기능을 누르면 페이월
        tap(app.buttons["Timer window size · Theme"], after: 4)
        app.swipeUp(); pause(2.5)
        tap(app.buttons["Get Pro"], after: 4)
        // App Store 결제 창(이 기기는 샌드박스 계정이 없어 로그인 창) — 취소
        if sb.buttons["Cancel"].waitForExistence(timeout: 8) { pause(1.5); sb.buttons["Cancel"].tap(); pause(2) }
        tap(app.buttons["Restore Purchases"], after: 4)
        if sb.buttons["Cancel"].waitForExistence(timeout: 6) { pause(1.5); sb.buttons["Cancel"].tap(); pause(2) }
        if app.alerts.buttons["OK"].exists { pause(1.5); app.alerts.buttons["OK"].tap(); pause(1.5) }
        tap(app.buttons["Close"], after: 2)
        // 설정: Pro 둘러보기 · 구매 복원 · 도움말
        tap(app.buttons["Settings"], after: 3)
        app.swipeUp(); pause(2.5)
        app.swipeDown(); pause(1.5)
        let done = app.buttons["Done"]
        if done.exists { done.tap(); pause(2) }
        // 정리: 타이머 지우기
        if app.buttons["Delete"].exists { app.buttons["Delete"].tap(); pause(3) }
    }
}
