import XCTest

/// 노트 저장 형식과 복구 — `StickyPresenter/NoteStore.swift` 를 직접 컴파일해 검사한다.
final class NoteStoreTests: XCTestCase {
    private var dir: URL!
    private var store: NoteFileStore!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NoteStoreTests-\(UUID().uuidString)", isDirectory: true)
        store = NoteFileStore(fileURL: dir.appendingPathComponent("notes.json"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func testMissingFileIsEmpty() {
        XCTAssertEqual(store.load(), .empty)
    }

    func testRoundTrip() throws {
        let archive = NoteArchive(
            notes: [NoteRecord(text: "대본 첫 줄\n두 번째 줄", color: .pink, x: 10, y: 20,
                               width: 300, height: 240, opacity: 0.5, fontSize: 18, isLocked: true)],
            recentlyClosed: [NoteRecord(text: "닫은 노트")]
        )
        try store.save(archive)
        XCTAssertEqual(store.load(), .loaded(archive))
    }

    /// 깨진 파일은 지우지 않고 옆으로 옮겨 둔다 — 다음 저장이 원본을 덮어쓰지 않게.
    func testCorruptFileIsMovedAsideNotDeleted() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let garbage = Data("{ not json".utf8)
        try garbage.write(to: store.fileURL)

        guard case .recovered(let backup) = store.load() else {
            return XCTFail("깨진 파일을 복구 경로로 처리해야 한다")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL.path))
        XCTAssertEqual(try Data(contentsOf: backup), garbage)
    }

    /// 형태가 다른 JSON 도 빈 목록으로 읽지 않는다 (덮어쓰기 방지).
    func testWrongShapeJSONIsTreatedAsCorrupt() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("[1, 2, 3]".utf8).write(to: store.fileURL)
        guard case .recovered = store.load() else { return XCTFail() }
    }

    /// 모르는 색·빠진 칸·이상한 값이 있어도 노트를 잃지 않는다.
    func testLenientDecoding() throws {
        let json = """
        {"notes": [
          {"text": "hello", "color": "rainbow", "opacity": 0, "fontSize": 999, "x": 5},
          {"id": "not-a-uuid"}
        ]}
        """
        let archive = try JSONDecoder().decode(NoteArchive.self, from: Data(json.utf8))
        XCTAssertEqual(archive.notes.count, 2)
        let first = archive.notes[0]
        XCTAssertEqual(first.text, "hello")
        XCTAssertEqual(first.color, .yellow)
        XCTAssertEqual(first.opacity, 0.2)
        XCTAssertEqual(first.fontSize, 32)
        XCTAssertEqual(first.x, 5)
        XCTAssertEqual(first.width, 280)
        XCTAssertEqual(archive.recentlyClosed, [])
    }

    // MARK: Recently closed

    func testStashSkipsEmptyNotesAndCaps() {
        var archive = NoteArchive()
        archive.stashClosed([NoteRecord(text: "  \n ")])
        XCTAssertTrue(archive.recentlyClosed.isEmpty)

        for i in 0..<(NoteArchive.recentlyClosedLimit + 5) {
            archive.stashClosed([NoteRecord(text: "note \(i)")])
        }
        XCTAssertEqual(archive.recentlyClosed.count, NoteArchive.recentlyClosedLimit)
        XCTAssertEqual(archive.popClosed()?.text, "note \(NoteArchive.recentlyClosedLimit + 4)")
    }

    func testStashSameNoteTwiceKeepsOneCopy() {
        var archive = NoteArchive()
        let note = NoteRecord(text: "a")
        archive.stashClosed([note])
        archive.stashClosed([note])
        XCTAssertEqual(archive.recentlyClosed.count, 1)
    }

    // MARK: Placement

    func testFrameOnScreenIsKept() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let frame = CGRect(x: 100, y: 100, width: 280, height: 220)
        XCTAssertEqual(visibleNoteFrame(frame, screens: [screen], fallback: screen), frame)
    }

    /// 외장 모니터를 뺀 뒤 그 자리에 저장된 노트는 기본 화면으로 데려온다.
    func testFrameOnMissingScreenIsBroughtBack() {
        let laptop = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let offscreen = CGRect(x: 3000, y: 200, width: 280, height: 220)
        let moved = visibleNoteFrame(offscreen, screens: [laptop], fallback: laptop)
        XCTAssertTrue(laptop.contains(moved))
        XCTAssertEqual(moved.size, offscreen.size)
    }

    func testRandomOriginNeverTraps() {
        _ = randomNoteOrigin(in: .zero, noteSize: CGSize(width: 280, height: 220))
        let tiny = CGRect(x: 0, y: 0, width: 200, height: 150)
        XCTAssertEqual(randomNoteOrigin(in: tiny, noteSize: CGSize(width: 280, height: 220)), tiny.origin)

        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        for _ in 0..<100 {
            let p = randomNoteOrigin(in: screen, noteSize: CGSize(width: 280, height: 220))
            XCTAssertTrue(screen.contains(CGRect(origin: p, size: CGSize(width: 280, height: 220))))
        }
    }
}
