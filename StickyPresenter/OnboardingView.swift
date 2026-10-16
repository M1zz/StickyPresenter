import SwiftUI
import AppKit
import ServiceManagement

// MARK: - Onboarding
// 처음 켰을 때 한 번 뜨는 안내. 기능 설명서(GuideView)와 하는 일이 다르다.
//
// 메뉴 막대 앱은 처음 켠 순간이 가장 위험하다 — Dock 아이콘도 창도 없어서 "켜졌는데 아무것도
// 안 보인다" 로 끝나기 쉽다. 그래서 여기서는 세 가지만 한다.
//   1. 앱이 어디 사는지 (메뉴 막대의 노트 아이콘)
//   2. 발표 중에 쓰는 단축키 세 개 (Keynote 위에서도 듣는다)
//   3. 로그인할 때 자동으로 켤지 — 발표 직전에 앱을 찾아 켜는 일을 없앤다
// 나머지는 마지막 장의 "사용 가이드 보기" 로 넘긴다.

struct OnboardingView: View {
    /// 안내를 끝까지 봤는지. 첫 실행 판정(hasLaunchedBefore)과 따로 둔다 —
    /// 안내가 생기기 전부터 쓰던 사람은 AppDelegate 가 이 값을 미리 켜 둔다.
    static let seenKey = "hasSeenOnboarding"

    let onShowGuide: () -> Void
    let onFinish: () -> Void

    @State private var page = 0
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchError: String?

    private let pageCount = 3

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch page {
                case 0:  menuBarPage
                case 1:  hotkeysPage
                default: launchPage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 32)
            .padding(.top, 28)

            Divider()
            footer
        }
        .frame(width: 480, height: 400)
    }

    // MARK: Pages

    private var menuBarPage: some View {
        VStack(spacing: 16) {
            Image(systemName: "menubar.arrow.up.rectangle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text(L("onboarding.menubar.title"))
                .font(.system(size: 20, weight: .bold))
                .multilineTextAlignment(.center)
            Text(L("onboarding.menubar.body"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .font(.system(size: 15))
                    .accessibilityHidden(true)
                Text(L("onboarding.menubar.icon"))
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.06)))
        }
    }

    private var hotkeysPage: some View {
        VStack(spacing: 16) {
            Image(systemName: "command")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text(L("onboarding.hotkeys.title"))
                .font(.system(size: 20, weight: .bold))
                .multilineTextAlignment(.center)
            Text(L("onboarding.hotkeys.body"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 10) {
                ForEach([HotKeyAction.timers, .newNote, .teleprompter], id: \.self) { action in
                    HStack(spacing: 14) {
                        Text(action.display)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .frame(width: 64, alignment: .leading)
                        Text(action.title)
                            .font(.system(size: 13))
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.05)))
        }
    }

    private var launchPage: some View {
        VStack(spacing: 16) {
            Image(systemName: "power.circle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text(L("onboarding.launch.title"))
                .font(.system(size: 20, weight: .bold))
                .multilineTextAlignment(.center)
            Text(L("onboarding.launch.body"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Toggle(L("settings.launchAtLogin"), isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .onChange(of: launchAtLogin) { _, on in setLaunchAtLogin(on) }
            if let launchError {
                Text(launchError)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(L("onboarding.launch.later"))
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            if page > 0 {
                Button(L("onboarding.back")) { page -= 1 }
            }
            Spacer()
            pageDots
            Spacer()
            if page < pageCount - 1 {
                Button(L("guide.next")) { page += 1 }
                    .keyboardShortcut(.defaultAction)
            } else {
                Button(L("onboarding.openGuide")) { finish(showGuide: true) }
                Button(L("onboarding.start")) { finish(showGuide: false) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { i in
                Circle()
                    .fill(i == page ? Color.accentColor : Color.primary.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L("onboarding.page", page + 1, pageCount))
    }

    private func finish(showGuide: Bool) {
        UserDefaults.standard.set(true, forKey: Self.seenKey)
        showGuide ? onShowGuide() : onFinish()
    }

    /// 설정 창의 같은 토글과 같은 규칙 — 실패하면 실제 상태로 되돌리고 이유를 보여 준다.
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
