import SwiftUI
import LeeoKit

// MARK: - 설정
// 리모컨 화면 왼쪽 위 톱니바퀴에서 연다. 앱 자체에는 바꿀 설정이 거의 없어서
// 도움말 · 의견 보내기 · 문의를 모아 두는 자리다.

struct RemoteSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var pro = RemotePro.shared
    @State private var showsPaywall = false
    @State private var showsGraduation = false
    @State private var showsManage = false
    let onShowIntro: () -> Void

    var body: some View {
        NavigationStack {
            List {
                // 응원 부탁은 이미 Pro 를 가진 사람에게만, 리모컨을 자주 연 뒤 드물게 — 발표 중 화면이 아니라 설정에서.
                if pro.hasPro {
                    LeeoTipAskSlot<RemoteSpec>(tipJar: RemoteSpec.tipJar, reached: RemoteTipMoments.reachedNow)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                proSection

                Section("도움말") {
                    Button {
                        dismiss()
                        onShowIntro()
                    } label: {
                        Label("처음 안내 다시 보기", systemImage: "sparkles")
                    }
                    Link(destination: RemoteSpec.legal.supportURL) {
                        Label("지원 페이지", systemImage: "questionmark.circle")
                    }
                    Link(destination: RemoteSpec.macAppURL) {
                        Label("Mac 앱 받기", systemImage: "arrow.down.app")
                    }
                    NavigationLink(LeeoRoadmapText.entry) { LeeoRoadmapView<RemoteSpec>() }
                }

                Section("의견 보내기") {
                    LeeoSupportSection<RemoteSpec>()
                    // 판매 중인 팁이 있어야 선다
                    LeeoTipJarLink<RemoteSpec>(tipJar: RemoteSpec.tipJar)
                }

                Section("문의") {
                    if let mail = URL(string: "mailto:\(RemoteSpec.developerEmail)") {
                        Link(destination: mail) {
                            Label("이메일로 문의", systemImage: "envelope")
                        }
                    }
                    Link(destination: RemoteSpec.instagramURL) {
                        Label("인스타그램 DM", systemImage: "camera")
                    }
                }

                Section {
                    LabeledContent("버전", value: Self.versionString)
                }
            }
            .sheet(isPresented: $showsPaywall) { RemotePaywallView() }
            .sheet(isPresented: $showsGraduation) {
                // 졸업가가 아직 스토어에 없으면 평생을 그대로 판다.
                LeeoGraduationOfferView(graduate: pro.product(RemoteProducts.graduate)
                                                  ?? pro.product(RemoteProducts.lifetime)) {
                    await pro.didPurchase()
                }
            }
            .manageSubscriptionsSheet(isPresented: $showsManage)
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Label("완료", systemImage: "checkmark") }
                }
            }
        }
    }

    // MARK: Pro

    @ViewBuilder
    private var proSection: some View {
        Section {
            if pro.hasPro {
                Label("Pro 사용 중", systemImage: "checkmark.seal.fill")
                if pro.subscription != nil {
                    Button(LeeoLadderText.manageSubscription) { showsManage = true }
                    // 구독 중이면 언제든 평생으로 옮겨 갈 길을 둔다.
                    Button(LeeoLadderText.switchToLifetimeEntry) { showsGraduation = true }
                }
            } else {
                Button { showsPaywall = true } label: {
                    Label("Pro 둘러보기", systemImage: "sparkles")
                }
                Button("구매 복원") { Task { await pro.store.restore(); await pro.didPurchase() } }
                    .disabled(pro.store.isRestoring)
            }
        } header: {
            Text(verbatim: "Pro")
        }
    }

    /// "1.0.9 (3)" — 문의 메일에 적어 달라고 할 때 사용자가 찾을 수 있는 자리.
    static var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

// MARK: - 응원 부탁 순간

/// 팁을 부탁할 순간 — 리모컨을 연 횟수(`LeeoEngagement` 가 센다). 큰 것부터.
enum RemoteTipMoments {
    static let launches = [100, 30, 10]

    static func reached(launches count: Int) -> [LeeoTipMoment] {
        launches.filter { count >= $0 }.map {
            LeeoTipMoment(id: "launches.\($0)", message: String(localized: "리모컨을 \($0)번 열었어요"))
        }
    }

    static var reachedNow: [LeeoTipMoment] { reached(launches: LeeoEngagement.shared.launchCount) }
}
