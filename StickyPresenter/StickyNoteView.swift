import SwiftUI
import AppKit

// MARK: - Sticky Note View
struct StickyNoteView: View {
    @ObservedObject var note: StickyNote
    let onClose: () -> Void
    let onColorChange: (NoteColor) -> Void
    
    @State private var showColorPicker = false
    @State private var showOpacitySlider = false
    @State private var isHovered = false
    /// 이 노트 창이 키보드 입력을 받고 있는지.
    @State private var isKey = false
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    // 팝오버가 열려 있는 동안에는 마우스가 벗어나도 버튼 유지.
    // 마우스를 올릴 수 없는 사람(VoiceOver·음성 명령·키보드)도 쓸 수 있도록
    // 이 노트를 누르거나 글을 쓰는 중(창이 키), 또는 VoiceOver 가 켜져 있으면 보인다.
    // 다른 앱을 누르면 노트 창이 키를 놓아 버튼이 다시 숨는다 — 발표 화면을 가리지 않게.
    private var showControls: Bool {
        isHovered || showColorPicker || showOpacitySlider || isKey || voiceOverEnabled
    }

    /// 노트 종이 위의 보조 글자·아이콘 색. 0.3~0.6 은 파스텔 위에서 대비가 2:1 남짓이라 읽기 어렵다.
    private var secondaryInk: Color { note.color.textColor.opacity(0.75) }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            contentArea
            footerBar
        }
        .background(note.color.background.opacity(0.97))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(note.color.headerColor.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) {
            if $0.object as? NSWindow === note.panel { isKey = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) {
            if $0.object as? NSWindow === note.panel { isKey = false }
        }
    }
    
    // MARK: - Header
    private var headerBar: some View {
        HStack(spacing: 6) {
            if showControls {
                // Close button
                Button(action: onClose) {
                    Circle()
                        .fill(Color.red.opacity(0.85))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                        )
                }
                .buttonStyle(.plain)
                .help(L("note.close.help"))
                .accessibilityLabel(L("note.close"))
                .accessibilityInputLabels([L("note.close"), L("Close")])

                // Color picker button
                Button(action: { showColorPicker.toggle() }) {
                    Circle()
                        .fill(note.color.headerColor)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .help(L("note.color.help"))
                .accessibilityLabel(L("note.color.help"))
                .accessibilityValue(note.color.localizedName)
                .accessibilityInputLabels([L("a11y.input.color"), L("note.color.help")])
                .popover(isPresented: $showColorPicker) {
                    colorPickerPopover
                }

                // Opacity button
                Button(action: { showOpacitySlider.toggle() }) {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.system(size: 7))
                                .foregroundColor(.white.opacity(0.9))
                        )
                }
                .buttonStyle(.plain)
                .help(L("note.opacity.help"))
                .accessibilityLabel(L("note.opacity.help"))
                .accessibilityValue("\(Int(note.opacity * 100))%")
                .accessibilityInputLabels([L("a11y.input.opacity"), L("note.opacity.help")])
                .popover(isPresented: $showOpacitySlider) {
                    opacityPopover
                }
            }

            Spacer()

            if showControls {
                // Font size controls
                Button(action: { note.fontSize = max(10, note.fontSize - 1) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(secondaryInk)
                        .frame(width: 16, height: 16)
                        .background(RoundedRectangle(cornerRadius: 3).fill(note.color.headerColor.opacity(0.4)))
                }
                .buttonStyle(.plain)
                .help(L("note.fontSmaller"))
                .accessibilityLabel(L("note.fontSmaller"))
                .accessibilityInputLabels([L("a11y.input.smaller"), L("note.fontSmaller")])

                Text("\(Int(note.fontSize))")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(secondaryInk)
                    .frame(width: 20)

                Button(action: { note.fontSize = min(32, note.fontSize + 1) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(secondaryInk)
                        .frame(width: 16, height: 16)
                        .background(RoundedRectangle(cornerRadius: 3).fill(note.color.headerColor.opacity(0.4)))
                }
                .buttonStyle(.plain)
                .help(L("note.fontLarger"))
                .accessibilityLabel(L("note.fontLarger"))
                .accessibilityInputLabels([L("a11y.input.larger"), L("note.fontLarger")])

                // Lock toggle
                Button(action: { note.isLocked.toggle() }) {
                    Image(systemName: note.isLocked ? "lock.fill" : "lock.open")
                        .font(.system(size: 10))
                        .foregroundColor(secondaryInk)
                }
                .buttonStyle(.plain)
                .help(note.isLocked ? L("Unlock editing") : L("Lock editing"))
                .accessibilityLabel(note.isLocked ? L("Unlock editing") : L("Lock editing"))
                .accessibilityInputLabels(note.isLocked
                    ? [L("a11y.input.unlock"), L("Unlock editing")]
                    : [L("a11y.input.lock"), L("Lock editing")])
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(note.color.headerColor.opacity(0.35))
        .animation(.easeInOut(duration: 0.15), value: showControls)
    }
    
    // MARK: - Content
    private var contentArea: some View {
        Group {
            if note.isLocked {
                ScrollView {
                    Text(note.text.isEmpty ? L("Empty note") : note.text)
                        .font(.system(size: note.fontSize))
                        .foregroundColor(note.color.textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .textSelection(.enabled)
                }
            } else {
                TextEditor(text: $note.text)
                    .font(.system(size: note.fontSize))
                    .foregroundColor(note.color.textColor)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 노트는 다크 모드에서도 밝은 종이다. 시스템 외형을 따르면 입력 커서·선택 색이
        // 흰색이 되어 파스텔 위에서 보이지 않는다.
        .environment(\.colorScheme, .light)
    }
    
    // MARK: - Footer
    private var footerBar: some View {
        HStack {
            Text(L("note.charCount", note.text.count))
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(secondaryInk)
            
            Spacer()
            
            // Drag handle indicator
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 8))
                .foregroundColor(note.color.textColor.opacity(0.2))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(note.color.headerColor.opacity(0.15))
    }
    
    // MARK: - Color Picker Popover
    private var colorPickerPopover: some View {
        HStack(spacing: 8) {
            ForEach(NoteColor.allCases, id: \.self) { color in
                Button(action: {
                    onColorChange(color)
                    showColorPicker = false
                }) {
                    Circle()
                        .fill(color.background)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(color == note.color ? Color.black.opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                        .overlay(
                            color == note.color ?
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black.opacity(0.6))
                            : nil
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(color.localizedName)
                .accessibilityAddTraits(color == note.color ? .isSelected : [])
            }
        }
        .padding(12)
    }
    
    // MARK: - Opacity Popover
    private var opacityPopover: some View {
        VStack(spacing: 8) {
            Text(L("note.opacity", Int(note.opacity * 100)))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Slider(value: $note.opacity, in: 0.2...1.0, step: 0.05)
                .frame(width: 150)
                .accessibilityLabel(L("a11y.input.opacity"))
                .accessibilityValue("\(Int(note.opacity * 100))%")
                .onChange(of: note.opacity) { _, newValue in
                    note.panel?.alphaValue = newValue
                }
            
            HStack {
                Button("30%") { setOpacity(0.3) }
                Button("50%") { setOpacity(0.5) }
                Button("70%") { setOpacity(0.7) }
                Button("100%") { setOpacity(1.0) }
            }
            .font(.system(size: 10))
        }
        .padding(12)
    }
    
    private func setOpacity(_ value: Double) {
        note.opacity = value
        note.panel?.alphaValue = value
    }
}
