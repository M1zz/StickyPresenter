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
        Settings {
            StickyPresenterSupportView()
                .leeoSatisfactionCheck(StickyPresenterSpec.self)
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var noteManager = NoteManager.shared
    var settingsWindow: NSWindow?
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

        // 최초 실행 시에만 사용법 스티키 노트 표시
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            let screenFrame = NSScreen.main?.visibleFrame ?? .zero
            noteManager.addNote(
                text: L("guide.note"),
                color: .yellow,
                position: CGPoint(x: screenFrame.minX + 60, y: screenFrame.midY - 100)
            )
        } else {
            noteManager.showAllNotes()
        }

        // 앱 시작 시 타이머 항상 열기
        noteManager.openTimerList()

        // 지난 실행에서 남은 스냅샷을 현재 상태로 덮어쓴다.
        // 타이머가 돌아가는 중에 앱이 종료되면 위젯이 끝나지 않는 카운트다운을 계속 그리기 때문.
        WidgetSync.refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 앱이 없으면 타이머도 멈춘 것 — 위젯에 남은 카운트다운을 정리한다.
        SharedTimerStore.save(nil)
    }

    // MARK: - Global Hotkeys (⌘⌃ prefix for all)
    private func setupGlobalHotkey() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleHotkeyEvent(event)
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleHotkeyEvent(event)
            return event
        }
    }

    private func handleHotkeyEvent(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags == [.command, .control] else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch event.keyCode {
            case 45: self.addNewNote()           // ⌘⌃N
            case 9:  self.addNoteFromClipboard() // ⌘⌃V
            case 35: self.openTeleprompter()     // ⌘⌃P
            case 17: self.noteManager.toggleTimerHotkey() // ⌘⌃T
            case 11: self.noteManager.startPomodoro()     // ⌘⌃B
            case 1:  self.noteManager.showAllNotes()      // ⌘⌃S
            case 4:  self.noteManager.hideAllNotes()      // ⌘⌃H
            default: break
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

        // MARK: - Contact the Developer
        let contactMenu = NSMenu()
        contactMenu.addItem(NSMenuItem(title: L("menu.contact.email"), action: #selector(contactByEmail), keyEquivalent: ""))
        contactMenu.addItem(NSMenuItem(title: L("menu.contact.instagram"), action: #selector(contactByInstagram), keyEquivalent: ""))
        let contactItem = NSMenuItem(title: L("menu.contact"), action: nil, keyEquivalent: "")
        contactItem.submenu = contactMenu
        menu.addItem(contactItem)

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
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let randomX = CGFloat.random(in: screenFrame.minX + 50...screenFrame.maxX - 300)
        let randomY = CGFloat.random(in: screenFrame.minY + 50...screenFrame.maxY - 250)
        
        noteManager.addNote(
            text: "",
            color: noteManager.defaultColor,
            position: CGPoint(x: randomX, y: randomY)
        )
    }
    
    @objc func addNoteFromClipboard() {
        let pasteboard = NSPasteboard.general
        let text = pasteboard.string(forType: .string) ?? ""
        
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let randomX = CGFloat.random(in: screenFrame.minX + 50...screenFrame.maxX - 300)
        let randomY = CGFloat.random(in: screenFrame.minY + 50...screenFrame.maxY - 250)
        
        noteManager.addNote(
            text: text,
            color: noteManager.defaultColor,
            position: CGPoint(x: randomX, y: randomY)
        )
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

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    /// 리모컨 하위 메뉴만 다시 그린다. 이 델리게이트는 그 메뉴에만 걸려 있지만,
    /// 나중에 다른 메뉴가 붙어도 서로 밟지 않도록 대상을 확인하고 들어간다.
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === remoteMenu else { return }
        rebuildRemoteMenu()
    }
}
