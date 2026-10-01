import SwiftUI
import AppKit

// MARK: - Guide
// 기능 설명서. 첫 실행 때 한 번 뜨고, 메뉴 막대 ▸ 도움말 ▸ 사용 가이드에서 언제든 다시 연다.
//
// 이 앱의 기능은 대부분 "보이지 않는" 자리에 있다 — 마우스를 올려야 나타나는 노트 버튼,
// 입력창만 아는 "25/5" 뽀모도로 문법, 메뉴 깊숙이 있는 리모컨 코드, 다른 앱 위에서만
// 쓸모 있는 ⌘⌃ 단축키. 안내 노트 한 장으로는 다 전하지 못해 주제별로 나눈 창을 둔다.

/// 가이드 본문 한 줄.
struct GuidePoint: Identifiable {
    let icon: String
    let key: String
    var id: String { key }
}

enum GuideTopic: String, CaseIterable, Identifiable {
    case welcome, notes, timers, pomodoro, teleprompter, remote, shortcuts

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .welcome:      return "hand.wave"
        case .notes:        return "note.text"
        case .timers:       return "timer"
        case .pomodoro:     return "arrow.triangle.2.circlepath"
        case .teleprompter: return "text.alignleft"
        case .remote:       return "iphone"
        case .shortcuts:    return "command"
        }
    }

    var title: String { L("guide.\(rawValue).title") }
    /// 한 줄 요약 — 제목 아래에 굵지 않게.
    var summary: String { L("guide.\(rawValue).summary") }

    /// 본문 항목 (아이콘, 문장). 문장은 `guide.<topic>.<n>` 키에서 읽는다.
    var points: [GuidePoint] {
        let icons: [String]
        switch self {
        case .welcome:      icons = ["macwindow.on.rectangle", "menubar.arrow.up.rectangle", "internaldrive", "questionmark.circle"]
        case .notes:        icons = ["hand.draw", "cursorarrow.rays", "lock", "arrow.uturn.backward", "doc.on.clipboard"]
        case .timers:       icons = ["keyboard", "hand.tap", "eye", "rectangle.on.rectangle", "eyedropper.halffull", "music.note"]
        case .pomodoro:     icons = ["character.cursor.ibeam", "bell", "pause.circle"]
        case .teleprompter: icons = ["doc.on.clipboard", "play.circle", "arrow.left.arrow.right", "memorychip"]
        case .remote:       icons = ["arrow.down.app", "number.square", "wifi", "person.2"]
        case .shortcuts:    icons = []
        }
        return icons.enumerated().map {
            GuidePoint(icon: $0.element, key: "guide.\(rawValue).\($0.offset + 1)")
        }
    }
}

struct GuideView: View {
    @State private var topic: GuideTopic = .welcome
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            VStack(spacing: 0) {
                ScrollView {
                    content
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(28)
                }
                Divider()
                footer
            }
        }
        .frame(width: 680, height: 480)
    }

    // MARK: Sidebar
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(GuideTopic.allCases) { t in
                Button(action: { topic = t }) {
                    Label(t.title, systemImage: t.icon)
                        .font(.system(size: 13, weight: topic == t ? .semibold : .regular))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 6)
                            .fill(topic == t ? Color.accentColor.opacity(0.15) : .clear))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(topic == t ? .isSelected : [])
            }
            Spacer()
        }
        .padding(12)
        .frame(width: 190)
        .background(Color.primary.opacity(0.03))
    }

    // MARK: Content
    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Label(topic.title, systemImage: topic.icon)
                    .font(.system(size: 22, weight: .bold))
                Text(topic.summary)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if topic == .shortcuts {
                shortcutTable
            } else {
                ForEach(topic.points) { point in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: point.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 22)
                        Text(L(point.key))
                            .font(.system(size: 13))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var shortcutTable: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(HotKeyAction.allCases, id: \.self) { action in
                HStack {
                    Text(action.display)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .frame(width: 70, alignment: .leading)
                    Text(action.title)
                        .font(.system(size: 13))
                    if GlobalHotKeys.shared.failed.contains(action) {
                        Text(L("guide.shortcuts.taken"))
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                    }
                }
            }
            Text(L("guide.shortcuts.note"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
    }

    // MARK: Footer
    private var footer: some View {
        HStack {
            Button(L("guide.support")) {
                if let url = URL(string: "https://m1zz.github.io/StickyPresenter/support.html") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.link)
            Spacer()
            if let next = nextTopic {
                Button(L("guide.next")) { topic = next }
                    .keyboardShortcut(.defaultAction)
            } else {
                Button(L("guide.done"), action: onClose)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var nextTopic: GuideTopic? {
        let all = GuideTopic.allCases
        guard let i = all.firstIndex(of: topic), i + 1 < all.count else { return nil }
        return all[i + 1]
    }
}
