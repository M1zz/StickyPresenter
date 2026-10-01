import SwiftUI

// MARK: - Teleprompter View
struct TeleprompterView: View {
    @State private var text: String
    @State private var isScrolling = false
    // 속도·글자 크기·거울 모드는 사람마다(그리고 무대마다) 한 번 맞추면 거의 안 바뀐다.
    // 열 때마다 기본값으로 돌아가면 발표 직전에 다시 맞춰야 해서 기억해 둔다.
    @AppStorage("teleprompter.speed") private var scrollSpeed: Double = 30.0 // pixels per second
    @AppStorage("teleprompter.fontSize") private var fontSize: Double = 24
    @AppStorage("teleprompter.mirrored") private var isMirrored = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isEditing = false
    /// 대본 전체 높이와 보이는 영역 높이 — 끝에 닿았는지 판단하는 데 쓴다.
    @State private var contentHeight: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    /// 재생 중에만 도는 60Hz 틱. 멈춰 있을 때까지 초당 60번 깨어나면 배터리만 닳는다.
    @State private var ticker: Timer?

    let onClose: () -> Void

    /// 마지막 줄이 화면 위쪽 40% 지점에 닿으면 끝난 것으로 본다 — 끝까지 밀어 올리면
    /// 빈 화면만 남아 발표자가 대본이 끝났는지 잠깐 헷갈린다.
    private var maxOffset: CGFloat {
        max(0, contentHeight - viewportHeight * 0.4)
    }
    
    init(initialText: String, onClose: @escaping () -> Void) {
        _text = State(initialValue: initialText)
        self.onClose = onClose
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            teleprompterHeader
            
            // Content
            teleprompterContent
            
            // Controls
            teleprompterControls
        }
        .background(Color.black.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Header
    private var teleprompterHeader: some View {
        HStack {
            Button(action: onClose) {
                Circle()
                    .fill(Color.red.opacity(0.8))
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
            .help(L("teleprompter.close"))
            .accessibilityLabel(L("teleprompter.close"))
            
            Spacer()
            
            Text(L("📺 TELEPROMPTER"))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            Button(action: { isEditing.toggle() }) {
                Image(systemName: isEditing ? "eye" : "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help(isEditing ? L("Preview mode") : L("Edit text"))
            .accessibilityLabel(isEditing ? L("Preview mode") : L("Edit text"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Content
    private var teleprompterContent: some View {
        Group {
            if isEditing {
                TextEditor(text: $text)
                    .font(.system(size: CGFloat(fontSize)))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(12)
            } else {
                GeometryReader { viewport in
                    ScrollView {
                        Text(text)
                            .font(.system(size: CGFloat(fontSize), weight: .medium))
                            .foregroundColor(.white)
                            .lineSpacing(CGFloat(fontSize) * 0.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
                            .background(GeometryReader { g in
                                Color.clear
                                    .onAppear { contentHeight = g.size.height }
                                    .onChange(of: g.size.height) { _, h in contentHeight = h }
                            })
                            .offset(y: -scrollOffset)
                    }
                    .onAppear { viewportHeight = viewport.size.height }
                    .onChange(of: viewport.size.height) { _, h in viewportHeight = h }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: isScrolling) { _, scrolling in
            scrolling ? startTicker() : stopTicker()
        }
        .onDisappear {
            isScrolling = false
            stopTicker()
        }
        // Gradient overlay for readability
        .overlay(
            VStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.6), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)
                
                Spacer()
                
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)
            }
            .allowsHitTesting(false)
        )
    }
    
    // MARK: - Controls
    private var teleprompterControls: some View {
        VStack(spacing: 8) {
            // Play/Pause + Reset
            HStack(spacing: 16) {
                Button(action: { scrollOffset = 0 }) {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(L("teleprompter.rewind"))
                .accessibilityLabel(L("teleprompter.rewind"))
                
                Button(action: togglePlayback) {
                    Image(systemName: isScrolling ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
                .help(isScrolling ? L("teleprompter.pause") : L("teleprompter.play"))
                .accessibilityLabel(isScrolling ? L("teleprompter.pause") : L("teleprompter.play"))
                
                Button(action: { isMirrored.toggle() }) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14))
                        .foregroundColor(isMirrored ? .yellow : .white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(L("Mirror text (for teleprompter glass)"))
                .accessibilityLabel(L("Mirror text (for teleprompter glass)"))
            }
            
            // Speed slider
            HStack(spacing: 8) {
                Image(systemName: "tortoise")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                
                Slider(value: $scrollSpeed, in: 5...120, step: 5)
                    .tint(.green)
                    .help(L("teleprompter.speed"))
                    .accessibilityLabel(L("teleprompter.speed"))
                
                Image(systemName: "hare")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                
                Text("\(Int(scrollSpeed))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 24)
            }
            
            // Font size
            HStack(spacing: 8) {
                Text(L("Font"))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))

                Button(action: { fontSize = max(14, fontSize - 2) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 22, height: 22)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L("note.fontSmaller"))

                Text("\(Int(fontSize))pt")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 34)

                Button(action: { fontSize = min(48, fontSize + 2) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 22, height: 22)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L("note.fontLarger"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
    }

    // MARK: - Playback

    /// 끝에서 재생을 누르면 처음부터 다시 — 끝난 자리에서 눌러도 아무 일 없으면 고장 난 것처럼 보인다.
    private func togglePlayback() {
        if !isScrolling, scrollOffset >= maxOffset, maxOffset > 0 {
            scrollOffset = 0
        }
        isScrolling.toggle()
    }

    private func startTicker() {
        stopTicker()
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { _ in
            DispatchQueue.main.async {
                scrollOffset = min(scrollOffset + scrollSpeed / 60.0, maxOffset)
                if scrollOffset >= maxOffset { isScrolling = false }
            }
        }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }
}
