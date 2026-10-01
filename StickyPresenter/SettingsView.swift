import SwiftUI
import AppKit
import ServiceManagement
import LeeoKit

// MARK: - Settings
// 메뉴 막대 ▸ 설정… (⌘,) 에서 여는 창.
//
// 예전에는 SwiftUI `Settings` 장면에 지원 섹션만 있었는데, 이 앱은 Dock 도 앱 메뉴도 없는
// 메뉴 막대 앱이라 그 창을 여는 길이 아예 없었다. 창은 AppDelegate 가 직접 띄운다.

struct SettingsView: View {
    @ObservedObject private var notes = NoteManager.shared
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchError: String?
    let onShowGuide: () -> Void

    var body: some View {
        Form {
            Section(L("settings.general")) {
                Toggle(L("settings.launchAtLogin"), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in setLaunchAtLogin(on) }
                if let launchError {
                    Text(launchError)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                }
                Picker(L("settings.defaultColor"), selection: $notes.defaultColor) {
                    ForEach(NoteColor.allCases, id: \.self) { color in
                        Text(color.localizedName).tag(color)
                    }
                }
            }

            Section(L("settings.help")) {
                Button(L("settings.showGuide"), action: onShowGuide)
                Button(L("settings.openSupport")) {
                    if let url = URL(string: "https://m1zz.github.io/StickyPresenter/support.html") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button(L("settings.revealNotes")) {
                    NSWorkspace.shared.activateFileViewerSelecting([NoteFileStore.default.fileURL])
                }
                .help(L("settings.revealNotes.help"))
            }

            Section {
                LeeoSupportSection<StickyPresenterSpec>()
            } header: {
                Text(L("settings.support"))
            }

            Section {
                LabeledContent(L("settings.version"), value: Self.versionString)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .frame(minHeight: 460)
    }

    /// "1.0.10 (12)" — 문의 메일에 적어 달라고 할 때 사용자가 찾을 수 있는 자리.
    static var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    /// 로그인 항목 등록. 실패하면 토글을 실제 상태로 되돌리고 이유를 보여 준다 —
    /// 켜진 것처럼 보이는데 다음 로그인에 안 켜지면 사용자는 알 방법이 없다.
    private func setLaunchAtLogin(_ on: Bool) {
        let service = SMAppService.mainApp
        do {
            if on, service.status != .enabled {
                try service.register()
            } else if !on, service.status == .enabled {
                try service.unregister()
            }
            launchError = nil
        } catch {
            launchError = L("settings.launchAtLogin.failed", error.localizedDescription)
        }
        let actual = service.status == .enabled
        if actual != launchAtLogin { launchAtLogin = actual }
        if service.status == .requiresApproval {
            launchError = L("settings.launchAtLogin.approval")
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}
