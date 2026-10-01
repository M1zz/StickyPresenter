import Foundation
import CoreGraphics

// 스티키 노트를 디스크에 남기는 곳.
//
// 1.0.9 까지 노트는 메모리에만 있었다 — 앱을 끄거나, 업데이트하거나, Mac 을 재시동하면
// 적어 둔 대본이 전부 사라졌다. 여기서는 노트를 JSON 한 파일로 저장하고 다음 실행에 되살린다.
//
// AppKit 에 기대지 않는다. 테스트 타겟이 이 파일을 직접 컴파일해 인코딩·복구·화면 자리
// 계산을 검사한다 (StickyPresenterTests/NoteStoreTests.swift).

// MARK: - Record

/// 노트 한 장의 저장 형태. `StickyNote`(화면에 붙은 살아 있는 객체)와 나눈 이유는
/// 패널 참조나 `@Published` 같은 실행 중 상태를 파일 형식에 섞지 않기 위해서다.
struct NoteRecord: Codable, Equatable, Identifiable {
    var id: UUID
    var text: String
    var color: NoteColorKey
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var opacity: Double
    var fontSize: Double
    var isLocked: Bool

    /// 저장 파일에 없는 칸은 기본값으로 채운다. 나중에 칸을 늘려도 옛 파일이 그대로 열리고,
    /// 한 칸이 이상하다고 노트 전체를 잃지 않는다.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id       = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        text     = (try? c.decode(String.self, forKey: .text)) ?? ""
        color    = (try? c.decode(NoteColorKey.self, forKey: .color)) ?? .yellow
        x        = (try? c.decode(Double.self, forKey: .x)) ?? 200
        y        = (try? c.decode(Double.self, forKey: .y)) ?? 200
        width    = (try? c.decode(Double.self, forKey: .width)) ?? 280
        height   = (try? c.decode(Double.self, forKey: .height)) ?? 220
        opacity  = (try? c.decode(Double.self, forKey: .opacity)) ?? 0.92
        fontSize = (try? c.decode(Double.self, forKey: .fontSize)) ?? 14
        isLocked = (try? c.decode(Bool.self, forKey: .isLocked)) ?? false
        sanitize()
    }

    init(id: UUID = UUID(), text: String, color: NoteColorKey = .yellow,
         x: Double = 200, y: Double = 200, width: Double = 280, height: Double = 220,
         opacity: Double = 0.92, fontSize: Double = 14, isLocked: Bool = false) {
        self.id = id; self.text = text; self.color = color
        self.x = x; self.y = y; self.width = width; self.height = height
        self.opacity = opacity; self.fontSize = fontSize; self.isLocked = isLocked
        sanitize()
    }

    /// 손으로 고친 파일이나 옛 버전 값이 화면에서 말썽을 부리지 않도록 범위를 맞춘다.
    /// (투명도 0 인 노트는 보이지도 잡히지도 않는다. NaN 좌표는 창을 아예 못 띄운다.)
    private mutating func sanitize() {
        func finite(_ v: Double, _ fallback: Double) -> Double { v.isFinite ? v : fallback }
        x = finite(x, 200); y = finite(y, 200)
        width = min(max(finite(width, 280), 200), 4000)
        height = min(max(finite(height, 220), 150), 4000)
        opacity = min(max(finite(opacity, 0.92), 0.2), 1.0)
        fontSize = min(max(finite(fontSize, 14), 10), 32)
    }
}

/// 노트 색의 저장용 이름. 모르는 이름(다음 버전에서 추가된 색 등)은 노란색으로 읽는다 —
/// `NoteColor` 를 그대로 디코딩하면 모르는 값 하나 때문에 파일 전체가 열리지 않는다.
enum NoteColorKey: String, Codable, CaseIterable {
    case yellow, pink, green, blue, purple, orange

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = NoteColorKey(rawValue: raw) ?? .yellow
    }
}

// MARK: - Archive

/// 파일 한 개에 담기는 전부.
struct NoteArchive: Codable, Equatable {
    static let currentVersion = 1
    /// 되살리기 목록에 남겨 두는 최대 장 수. 끝없이 쌓이지 않게 오래된 것부터 버린다.
    static let recentlyClosedLimit = 20

    var version: Int = NoteArchive.currentVersion
    var notes: [NoteRecord] = []
    /// 닫은 노트 — 최근 것이 맨 뒤. 메뉴의 "닫은 노트 다시 열기"가 여기서 꺼낸다.
    var recentlyClosed: [NoteRecord] = []

    init(notes: [NoteRecord] = [], recentlyClosed: [NoteRecord] = []) {
        self.notes = notes
        self.recentlyClosed = recentlyClosed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = (try? c.decode(Int.self, forKey: .version)) ?? NoteArchive.currentVersion
        // 최상위가 이 형태가 아니면(엉뚱한 JSON) 깨진 파일로 본다 — 빈 목록으로 읽고 넘어가면
        // 다음 저장이 원본을 덮어써 복구할 기회가 사라진다.
        notes = try c.decode([NoteRecord].self, forKey: .notes)
        recentlyClosed = (try? c.decode([NoteRecord].self, forKey: .recentlyClosed)) ?? []
    }

    /// 닫은 노트를 되살리기 목록에 넣는다. 빈 노트는 되살릴 가치가 없어 넣지 않는다.
    mutating func stashClosed(_ records: [NoteRecord]) {
        let worth = records.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        recentlyClosed.removeAll { r in worth.contains { $0.id == r.id } }
        recentlyClosed.append(contentsOf: worth)
        if recentlyClosed.count > Self.recentlyClosedLimit {
            recentlyClosed.removeFirst(recentlyClosed.count - Self.recentlyClosedLimit)
        }
    }

    /// 가장 최근에 닫은 노트를 꺼낸다.
    mutating func popClosed() -> NoteRecord? {
        recentlyClosed.popLast()
    }
}

// MARK: - File Store

/// `notes.json` 을 읽고 쓴다.
///
/// - 쓰기는 원자적(`.atomic`)이다. 쓰는 도중 앱이 죽어도 옛 파일이 반쯤 덮이지 않는다.
/// - 읽다가 깨진 파일을 만나면 **지우지 않고** 옆에 옮겨 둔다. 빈 목록으로 덮어쓰면
///   고칠 수 있었던 사용자 글이 영영 사라진다.
struct NoteFileStore {
    let fileURL: URL

    /// 기본 위치 — `~/Library/Application Support/StickyPresenter/notes.json`
    /// (샌드박스 앱이라 실제로는 앱 컨테이너 안이다. 배경음악 폴더와 같은 부모 폴더.)
    static var `default`: NoteFileStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return NoteFileStore(fileURL: base
            .appendingPathComponent("StickyPresenter", isDirectory: true)
            .appendingPathComponent("notes.json"))
    }

    enum LoadResult: Equatable {
        /// 파일이 아직 없다 — 첫 실행이거나 1.0.9 이하에서 올라온 경우.
        case empty
        case loaded(NoteArchive)
        /// 읽을 수 없어 `movedTo` 로 옮겨 두었다.
        case recovered(movedTo: URL)
    }

    func load() -> LoadResult {
        guard let data = try? Data(contentsOf: fileURL) else { return .empty }
        if let archive = try? JSONDecoder().decode(NoteArchive.self, from: data) {
            return .loaded(archive)
        }
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let backup = fileURL.deletingLastPathComponent()
            .appendingPathComponent("notes.corrupt-\(stamp).json")
        try? FileManager.default.moveItem(at: fileURL, to: backup)
        return .recovered(movedTo: backup)
    }

    func save(_ archive: NoteArchive) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(archive).write(to: fileURL, options: .atomic)
    }
}

// MARK: - Placement

/// 저장해 둔 자리가 지금 붙은 화면 어디에도 없으면(외장 모니터를 뺐을 때 등) 노트를
/// 기본 화면 안으로 데려온다. 그대로 두면 노트가 보이지 않는 곳에 떠서 "사라진" 것처럼 된다.
///
/// 조금이라도(`minVisible` 이상) 걸쳐 보이는 노트는 사용자가 일부러 둔 자리로 보고 건드리지 않는다.
func visibleNoteFrame(_ frame: CGRect, screens: [CGRect], fallback: CGRect,
                      minVisible: CGFloat = 60) -> CGRect {
    let visible = screens.contains { screen in
        let overlap = screen.intersection(frame)
        return !overlap.isNull && overlap.width >= minVisible && overlap.height >= minVisible
    }
    if visible || fallback.isEmpty { return frame }

    let w = min(frame.width, fallback.width)
    let h = min(frame.height, fallback.height)
    let x = max(fallback.minX, min(frame.minX, fallback.maxX - w))
    let y = max(fallback.minY, min(frame.minY, fallback.maxY - h))
    return CGRect(x: x, y: y, width: w, height: h)
}

/// 새 노트를 놓을 무작위 자리. 화면이 노트보다 작거나 화면 정보를 못 얻었을 때도 죽지 않는다.
///
/// 예전 코드는 `random(in: minX + 50 ... maxX - 300)` 를 바로 썼는데, 화면을 못 읽어
/// `.zero` 가 들어오거나 화면이 아주 작으면 하한이 상한보다 커져 앱이 트랩했다.
func randomNoteOrigin(in screen: CGRect, noteSize: CGSize, margin: CGFloat = 50) -> CGPoint {
    guard screen.width > 0, screen.height > 0 else { return CGPoint(x: 200, y: 200) }
    let loX = screen.minX + margin, hiX = screen.maxX - noteSize.width - margin
    let loY = screen.minY + margin, hiY = screen.maxY - noteSize.height - margin
    let x = hiX > loX ? CGFloat.random(in: loX...hiX) : screen.minX
    let y = hiY > loY ? CGFloat.random(in: loY...hiY) : screen.minY
    return CGPoint(x: x, y: y)
}
