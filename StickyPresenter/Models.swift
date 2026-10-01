import SwiftUI
import AppKit

// MARK: - Note Color
enum NoteColor: String, CaseIterable, Codable {
    case yellow, pink, green, blue, purple, orange
    
    var background: Color {
        switch self {
        case .yellow: return Color(red: 1.0, green: 0.95, blue: 0.70)
        case .pink:   return Color(red: 1.0, green: 0.82, blue: 0.86)
        case .green:  return Color(red: 0.78, green: 0.95, blue: 0.78)
        case .blue:   return Color(red: 0.78, green: 0.88, blue: 1.0)
        case .purple: return Color(red: 0.88, green: 0.80, blue: 1.0)
        case .orange: return Color(red: 1.0, green: 0.88, blue: 0.72)
        }
    }
    
    var headerColor: Color {
        switch self {
        case .yellow: return Color(red: 0.95, green: 0.85, blue: 0.40)
        case .pink:   return Color(red: 0.95, green: 0.60, blue: 0.70)
        case .green:  return Color(red: 0.50, green: 0.82, blue: 0.50)
        case .blue:   return Color(red: 0.50, green: 0.70, blue: 0.95)
        case .purple: return Color(red: 0.70, green: 0.55, blue: 0.95)
        case .orange: return Color(red: 0.95, green: 0.70, blue: 0.40)
        }
    }
    
    /// 접근성 라벨·메뉴에 쓰는 이름 (이모지 없이).
    var localizedName: String { L("colorName.\(rawValue)") }

    var textColor: Color {
        return Color(red: 0.2, green: 0.2, blue: 0.2)
    }
    
    var nsBackground: NSColor {
        switch self {
        case .yellow: return NSColor(red: 1.0, green: 0.95, blue: 0.70, alpha: 1.0)
        case .pink:   return NSColor(red: 1.0, green: 0.82, blue: 0.86, alpha: 1.0)
        case .green:  return NSColor(red: 0.78, green: 0.95, blue: 0.78, alpha: 1.0)
        case .blue:   return NSColor(red: 0.78, green: 0.88, blue: 1.0, alpha: 1.0)
        case .purple: return NSColor(red: 0.88, green: 0.80, blue: 1.0, alpha: 1.0)
        case .orange: return NSColor(red: 1.0, green: 0.88, blue: 0.72, alpha: 1.0)
        }
    }
}

// MARK: - Sticky Note Model
class StickyNote: ObservableObject, Identifiable {
    let id: UUID
    @Published var text: String
    @Published var color: NoteColor
    // 자리·크기는 창이 들고 있고, 여기는 저장용 사본이다. 화면이 이 값을 그리지 않으므로
    // `@Published` 로 두면 창을 끄는 매 순간 노트 뷰가 쓸데없이 다시 그려진다.
    var position: CGPoint
    var size: CGSize
    @Published var opacity: Double
    @Published var fontSize: CGFloat
    @Published var isLocked: Bool
    @Published var isPinned: Bool
    
    var panel: NSPanel?
    
    init(
        id: UUID = UUID(),
        text: String = "",
        color: NoteColor = .yellow,
        position: CGPoint = CGPoint(x: 200, y: 200),
        size: CGSize = CGSize(width: 280, height: 220),
        opacity: Double = 0.92,
        fontSize: CGFloat = 14,
        isLocked: Bool = false,
        isPinned: Bool = true
    ) {
        self.id = id
        self.text = text
        self.color = color
        self.position = position
        self.size = size
        self.opacity = opacity
        self.fontSize = fontSize
        self.isLocked = isLocked
        self.isPinned = isPinned
    }
}

// MARK: - Persistence bridge

extension NoteColor {
    init(_ key: NoteColorKey) { self = NoteColor(rawValue: key.rawValue) ?? .yellow }
    var key: NoteColorKey { NoteColorKey(rawValue: rawValue) ?? .yellow }
}

extension StickyNote {
    convenience init(record r: NoteRecord) {
        self.init(
            id: r.id,
            text: r.text,
            color: NoteColor(r.color),
            position: CGPoint(x: r.x, y: r.y),
            size: CGSize(width: r.width, height: r.height),
            opacity: r.opacity,
            fontSize: CGFloat(r.fontSize),
            isLocked: r.isLocked
        )
    }

    /// 지금 모습 그대로의 저장 형태. 창이 떠 있으면 창의 실제 자리를 쓴다 —
    /// 사용자가 끌어 옮긴 뒤 아직 `position` 이 갱신되지 않았을 수 있어서다.
    var record: NoteRecord {
        let frame = panel?.frame ?? CGRect(origin: position, size: size)
        return NoteRecord(
            id: id, text: text, color: color.key,
            x: frame.minX, y: frame.minY, width: frame.width, height: frame.height,
            opacity: opacity, fontSize: Double(fontSize), isLocked: isLocked
        )
    }
}
