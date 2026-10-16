import SwiftUI

// MARK: - 첫 실행 안내
// 이 앱은 혼자서는 아무것도 못 한다 — Mac 앱이 켜져 있고, 같은 Wi‑Fi 이고, 로컬 네트워크를
// 허용해야 비로소 쓸모가 생긴다. 이걸 모른 채 열면 "Mac을 찾는 중" 만 보다 지우게 된다.
//
// 그래서 첫 실행에는 찾기를 시작하기 **전에** 세 가지를 알려 준다. 로컬 네트워크 허용 질문은
// 찾기를 시작할 때 뜨므로, 안내를 마친 뒤에 찾기를 시작해야 사용자가 왜 묻는지 안다.

struct RemoteOnboardingView: View {
    /// 안내를 끝까지 봤는지. 안내가 생기기 전에 이미 Mac 과 짝을 맺은 사람은 앱이 미리 켜 둔다.
    static let seenKey = "hasSeenOnboarding"

    let onFinish: () -> Void

    @State private var page = 0

    private struct Page {
        let symbol: String
        let title: LocalizedStringKey
        let body: LocalizedStringKey
    }

    private let pages: [Page] = [
        Page(symbol: "laptopcomputer.and.iphone",
             title: "Mac 앱의 리모컨이에요",
             body: "Mac에서 StickyPresenter가 켜져 있어야 합니다. 발표 중 손이 닿지 않는 Mac의 타이머를 iPhone에서 다룹니다."),
        Page(symbol: "wifi",
             title: "같은 Wi‑Fi에서 찾아요",
             body: "두 기기가 같은 Wi‑Fi에 있어야 서로를 찾습니다. 곧 로컬 네트워크 접근을 묻는데, 허용해야 Mac을 찾을 수 있습니다."),
        Page(symbol: "number.square",
             title: "코드는 처음 한 번만",
             body: "목록에서 내 Mac을 고르고, Mac 메뉴 막대의 타이머 아이콘 → Remote에 뜬 네 자리 코드를 넣으세요. 다음부터는 저절로 연결됩니다."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                if page == 0 {
                    Link(destination: RemoteSpec.macAppURL) {
                        Label("Mac 앱 받기", systemImage: "arrow.down.app")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                }
                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        UserDefaults.standard.set(true, forKey: Self.seenKey)
                        onFinish()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "다음" : "Mac 찾기 시작")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func pageView(_ page: Page) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: page.symbol)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                    .padding(.top, 64)
                Text(page.title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .frame(maxWidth: .infinity)
        }
    }
}
