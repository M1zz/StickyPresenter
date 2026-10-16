import SwiftUI
import LeeoKit

// MARK: - 설정
// 리모컨 화면 왼쪽 위 톱니바퀴에서 연다. 앱 자체에는 바꿀 설정이 거의 없어서
// 도움말 · 의견 보내기 · 문의를 모아 두는 자리다.

struct RemoteSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let onShowIntro: () -> Void

    var body: some View {
        NavigationStack {
            List {
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
                }

                Section("의견 보내기") {
                    LeeoSupportSection<RemoteSpec>()
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
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
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
