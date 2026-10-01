import SwiftUI
import AppKit
import LeeoKit

// MARK: - App Entry Point
@main
struct StickyPresenterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        LeeoEngagement.shared.registerLaunch()
    }

    var body: some Scene {
        // 메뉴 막대 앱이라 이 장면을 여는 길은 없다 — App 에 장면이 하나는 있어야 해서 둔다.
        // 실제 설정 창은 AppDelegate.showSettings() 가 띄운다.
        Settings {
            SettingsView(onShowGuide: { (NSApp.delegate as? AppDelegate)?.showGuide() })
                .leeoSatisfactionCheck(StickyPresenterSpec.self)
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var noteManager = NoteManager.shared
    var settingsWindow: NSWindow?
    var guideWindow: NSWindow?
    /// 리모컨 하위 메뉴. 연결 코드와 연결 수가 계속 바뀌므로 열릴 때마다 다시 그린다.
    var remoteMenu: NSMenu?
    
    // 앱이 이미 실행 중인 상태에서 Finder/Launchpad로 다시 열 때 호출
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        noteManager.openTimerList()
        if !flag { noteManager.showAllNotes() }
        return true
    }

    // 창이 모두 닫혀도 메뉴바 앱으로 계속 실행
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupGlobalHotkey()

        // iOS 리모컨이 붙을 수 있도록 광고 시작.
        // 로컬 네트워크 권한 프롬프트는 실제로 상대를 찾을 때 처음 뜬다.
        RemoteControlHost.shared.start()

        // Hide dock icon — menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // 지난 실행의 노트를 되살린다. 노트는 바뀔 때마다 notes.json 에 저장된다 (NoteStore.swift).
        noteManager.restoreNotes()

        // 최초 실행 시에만 사용법 스티키 노트와 사용 가이드 창을 띄운다.
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            let screenFrame = ScreenMap.mainVisibleFrame()
            noteManager.addNote(
                text: L("guide.note"),
                color: .yellow,
                position: CGPoint(x: screenFrame.minX + 60, y: screenFrame.midY - 100)
            )
            // 패널·노트가 자리 잡은 뒤에 띄워야 가이드 창이 맨 앞에 온다.
            DispatchQueue.main.async { [weak self] in self?.showGuide() }
        }

        // 앱 시작 시 타이머 항상 열기
        noteManager.openTimerList()

        // 지난 실행에서 남은 스냅샷을 현재 상태로 덮어쓴다.
        // 타이머가 돌아가는 중에 앱이 종료되면 위젯이 끝나지 않는 카운트다운을 계속 그리기 때문.
        WidgetSync.refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 예약해 둔 저장(0.6초 뒤)을 기다릴 수 없다 — 방금 친 글자까지 지금 쓴다.
        noteManager.saveNow()
        // 앱이 없으면 타이머도 멈춘 것 — 위젯에 남은 카운트다운을 정리한다.
        SharedTimerStore.save(nil)
    }

    // MARK: - Global Hotkeys (⌘⌃ prefix for all)
    /// Carbon 전역 단축키로 등록한다 (GlobalHotKeys.swift). 예전의 NSEvent 전역 모니터는
    /// 손쉬운 사용 권한이 없으면 Keynote 가 앞에 있을 때 키를 받지 못했다.
    private func setupGlobalHotkey() {
        GlobalHotKeys.shared.register { [weak self] action in
            guard let self else { return }
            switch action {
            case .newNote:           self.addNewNote()
            case .noteFromClipboard: self.addNoteFromClipboard()
            case .teleprompter:      self.openTeleprompter()
            case .timers:            self.noteManager.toggleTimerHotkey()
            case .pomodoro:          self.noteManager.startPomodoro()
            case .showNotes:         self.noteManager.showAllNotes()
            case .hideNotes:         self.noteManager.hideAllNotes()
            }
        }
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "StickyPresenter")
            button.image?.size = NSSize(width: 18, height: 18)
        }
        
        let menu = NSMenu()
        
        let newNoteItem = NSMenuItem(title: L("menu.newNote"), action: #selector(addNewNote), keyEquivalent: "n")
        newNoteItem.keyEquivalentModifierMask = [.command, .control]
        menu.addItem(newNoteItem)

        let clipboardItem = NSMenuItem(title: L("menu.newFromClipboard"), action: #selector(addNoteFromClipboard), keyEquivalent: "v")
        clipboardItem.keyEquivalentModifierMask = [.command, .control]
        menu.addItem(clipboardItem)

        menu.addItem(NSMenuItem.separator())

        let teleprompterItem = NSMenuItem(title: L("menu.teleprompter"), action: #selector(openTeleprompter), keyEquivalent: "p")
        teleprompterItem.keyEquivalentModifierMask = [.command, .control]
        menu.addItem(teleprompterItem)

        let timerItem = NSMenuItem(title: L("menu.timers"), action: #selector(openTimer), keyEquivalent: "t")
        timerItem.keyEquivalentModifierMask = [.command, .control]
        menu.addItem(timerItem)

        let pomodoroItem = NSMenuItem(title: L("menu.pomodoro"), action: #selector(startPomodoro), keyEquivalent: "b")
        pomodoroItem.keyEquivalentModifierMask = [.command, .control]
        menu.addItem(pomodoroItem)

        menu.addItem(NSMenuItem.separator())

        let showItem = NSMenuItem(title: L("menu.showAll"), action: #selector(showAllNotes), keyEquivalent: "s")
        showItem.keyEquivalentModifierMask = [.command, .control]
        menu.addItem(showItem)

        let hideItem = NSMenuItem(title: L("menu.hideAll"), action: #selector(hideAllNotes), keyEquivalent: "h")
        hideItem.keyEquivalentModifierMask = [.command, .control]
        menu.addItem(hideItem)

        // 닫은 노트 되살리기 — 되살릴 것이 없으면 흐리게 (validateMenuItem).
        menu.addItem(NSMenuItem(title: L("menu.reopenClosed"), action: #selector(reopenClosedNote), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Color submenu
        let colorMenu = NSMenu()
        let colors: [(String, NoteColor)] = [
            (L("color.yellow"), .yellow),
            (L("color.pink"), .pink),
            (L("color.green"), .green),
            (L("color.blue"), .blue),
            (L("color.purple"), .purple),
            (L("color.orange"), .orange),
        ]
        for (title, color) in colors {
            let item = NSMenuItem(title: title, action: #selector(setNextNoteColor(_:)), keyEquivalent: "")
            item.representedObject = color
            colorMenu.addItem(item)
        }
        let colorItem = NSMenuItem(title: L("menu.defaultColor"), action: nil, keyEquivalent: "")
        colorItem.submenu = colorMenu
        menu.addItem(colorItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L("menu.removeAll"), action: #selector(removeAllNotes), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // MARK: - Remote
        // 연결 코드를 여기 두는 이유: 리모컨이 처음 붙을 때 딱 한 번 필요한 값이라
        // 전용 창을 띄울 만큼은 아니고, 그렇다고 못 찾으면 아예 연결이 안 된다.
        // 메뉴 막대 아이콘은 발표 중에도 늘 보이는 유일한 자리다.
        let remoteMenu = NSMenu()
        remoteMenu.delegate = self
        // 정보 항목(코드·연결 수)을 자동 비활성화에 맡기면 회색으로 흐려져 읽기 어렵다.
        remoteMenu.autoenablesItems = false
        self.remoteMenu = remoteMenu

        let remoteItem = NSMenuItem(title: L("menu.remote"), action: nil, keyEquivalent: "")
        remoteItem.submenu = remoteMenu
        menu.addItem(remoteItem)

        menu.addItem(NSMenuItem.separator())

        // MARK: - Help
        // 기능 설명·지원 페이지·문의를 한곳에. 문의는 원래 최상위에 있던 하위 메뉴를 옮겨 왔다.
        let helpMenu = NSMenu()
        helpMenu.addItem(NSMenuItem(title: L("menu.guide"), action: #selector(showGuide), keyEquivalent: ""))
        helpMenu.addItem(NSMenuItem(title: L("menu.supportSite"), action: #selector(openSupportSite), keyEquivalent: ""))
        helpMenu.addItem(NSMenuItem.separator())
        helpMenu.addItem(NSMenuItem(title: L("menu.contact.email"), action: #selector(contactByEmail), keyEquivalent: ""))
        helpMenu.addItem(NSMenuItem(title: L("menu.contact.instagram"), action: #selector(contactByInstagram), keyEquivalent: ""))
        let helpItem = NSMenuItem(title: L("menu.help"), action: nil, keyEquivalent: "")
        helpItem.submenu = helpMenu
        menu.addItem(helpItem)

        menu.addItem(NSMenuItem(title: L("menu.settings"), action: #selector(showSettings), keyEquivalent: ","))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L("menu.quit"), action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    // MARK: - Remote Menu

    /// 코드와 연결 수는 실행 중에 바뀐다. 메뉴를 만들 때 한 번 적어 두면 곧 거짓말이 되므로
    /// 열릴 때마다 다시 그린다 (`menuNeedsUpdate`).
    // `AppDelegate` 는 통째로 MainActor 가 아니다 — 델리게이트 메서드만 프로토콜을 통해
    // 격리를 물려받는다. `RemoteControlHost` 는 MainActor 라 여기 직접 적어 줘야 한다.
    @MainActor
    private func rebuildRemoteMenu() {
        guard let menu = remoteMenu else { return }
        menu.removeAllItems()

        let host = RemoteControlHost.shared

        // 한 자씩 띄워 적는다 — 옆 사람에게 불러주기도, 눈으로 옮겨 적기도 편하다.
        let spaced = host.pairingCode.map(String.init).joined(separator: " ")
        let codeItem = NSMenuItem(title: L("remote.pairingCode", spaced), action: nil, keyEquivalent: "")
        codeItem.attributedTitle = NSAttributedString(
            string: codeItem.title,
            attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)]
        )
        menu.addItem(codeItem)

        let connected = host.connectedCount
        let statusItem = NSMenuItem(
            title: connected == 0 ? L("remote.none") : L("remote.connected", connected),
            action: nil, keyEquivalent: ""
        )
        menu.addItem(statusItem)

        menu.addItem(NSMenuItem.separator())

        let regenerate = NSMenuItem(title: L("remote.newCode"), action: #selector(regeneratePairingCode), keyEquivalent: "")
        regenerate.target = self
        menu.addItem(regenerate)

        let paired = host.pairedCount
        let forget = NSMenuItem(
            title: paired == 0 ? L("remote.forget") : L("remote.forget.count", paired),
            action: #selector(forgetPairedRemotes), keyEquivalent: ""
        )
        forget.target = self
        forget.isEnabled = paired > 0
        menu.addItem(forget)
    }

    @MainActor
    @objc func regeneratePairingCode() {
        RemoteControlHost.shared.regeneratePairingCode()
    }

    /// 기억해 둔 리모컨을 모두 잊는다 — 붙어 있던 리모컨도 같이 떨어진다.
    /// 되돌릴 수 없으니 한 번 묻는다.
    @MainActor
    @objc func forgetPairedRemotes() {
        let alert = NSAlert()
        alert.messageText = L("remote.forget.title")
        alert.informativeText = L("remote.forget.message")
        alert.alertStyle = .warning
        alert.addButton(withTitle: L("remote.forget.confirm"))
        alert.addButton(withTitle: L("alert.cancel"))
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        RemoteControlHost.shared.unpairAll()
    }

    @objc func addNewNote() {
        noteManager.addNoteAtRandomPosition()
    }

    @objc func addNoteFromClipboard() {
        noteManager.addNoteAtRandomPosition(text: NSPasteboard.general.string(forType: .string) ?? "")
    }

    @objc func reopenClosedNote() {
        noteManager.reopenLastClosedNote()
    }

    // MARK: - Guide & Settings Windows

    /// 사용 가이드 창. 이미 떠 있으면 앞으로 가져온다.
    @objc func showGuide() {
        if let guideWindow {
            present(guideWindow)
            return
        }
        let window = makeUtilityWindow(title: L("window.guide"))
        window.contentView = NSHostingView(rootView: GuideView(onClose: { [weak window] in window?.close() }))
        window.center()
        guideWindow = window
        present(window)
    }

    /// 설정 창 (⌘,).
    @objc func showSettings() {
        if let settingsWindow {
            present(settingsWindow)
            return
        }
        let window = makeUtilityWindow(title: L("settings.title"))
        window.contentView = NSHostingView(rootView:
            SettingsView(onShowGuide: { [weak self] in self?.showGuide() })
                .leeoSatisfactionCheck(StickyPresenterSpec.self)
        )
        window.center()
        settingsWindow = window
        present(window)
    }

    /// 일반 앱 창. 노트·타이머 패널(최상위 레벨)보다 아래지만 다른 앱 창보다는 위에 뜨도록
    /// `.floating` 으로 둔다 — accessory 앱의 창은 다른 앱을 누르면 금세 뒤로 숨어 버린다.
    private func makeUtilityWindow(title: String) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.level = .floating
        window.isReleasedWhenClosed = false  // Swift ARC와 충돌 방지 (이중 해제 크래시)
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        return window
    }

    private func present(_ window: NSWindow) {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @objc func openSupportSite() {
        if let url = URL(string: "https://m1zz.github.io/StickyPresenter/support.html") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func openTimer() {
        noteManager.openTimerList()
    }

    // 클래식 25분 집중 / 5분 휴식 — 멈출 때까지 무한 반복
    @objc func startPomodoro() {
        noteManager.startPomodoro()
    }

    @objc func openTeleprompter() {
        let pasteboard = NSPasteboard.general
        let text = pasteboard.string(forType: .string) ?? L("teleprompter.placeholder")
        noteManager.openTeleprompter(with: text)
    }
    
    @objc func showAllNotes() {
        noteManager.showAllNotes()
    }
    
    @objc func hideAllNotes() {
        noteManager.hideAllNotes()
    }
    
    @objc func setNextNoteColor(_ sender: NSMenuItem) {
        if let color = sender.representedObject as? NoteColor {
            noteManager.defaultColor = color
        }
    }
    
    @objc func removeAllNotes() {
        let alert = NSAlert()
        alert.messageText = L("alert.removeAll.title")
        alert.informativeText = L("alert.removeAll.message")
        alert.alertStyle = .warning
        alert.addButton(withTitle: L("alert.removeAll.confirm"))
        alert.addButton(withTitle: L("alert.cancel"))
        
        if alert.runModal() == .alertFirstButtonReturn {
            noteManager.removeAllNotes()
        }
    }
    
    // MARK: - Contact the Developer
    @objc func contactByEmail() {
        if let url = URL(string: "mailto:leeo@kakao.com") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func contactByInstagram() {
        if let url = URL(string: "https://instagram.com/lee25_ios") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - NSMenuItemValidation

extension AppDelegate: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(reopenClosedNote):
            return noteManager.canReopenClosedNote
        case #selector(setNextNoteColor(_:)):
            // 지금 기본 색에 체크 표시 — 무엇이 골라져 있는지 메뉴만 봐도 알 수 있게.
            let color = menuItem.representedObject as? NoteColor
            menuItem.state = color == noteManager.defaultColor ? .on : .off
            return true
        default:
            return true
        }
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    /// 리모컨 하위 메뉴만 다시 그린다. 이 델리게이트는 그 메뉴에만 걸려 있지만,
    /// 나중에 다른 메뉴가 붙어도 서로 밟지 않도록 대상을 확인하고 들어간다.
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === remoteMenu else { return }
        rebuildRemoteMenu()
    }
}
