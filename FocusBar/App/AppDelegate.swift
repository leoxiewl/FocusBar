import AppKit
import SwiftUI
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {

    var store: MarkdownStore!
    var notchWindow: NotchWindow!
    var panelController: PanelController!
    var statusItem: NSStatusItem!
    var settingsWindow: NSWindow?

    // Sparkle 更新控制器（必须持有引用，否则会被释放）
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        store = MarkdownStore()
        panelController = PanelController(store: store)

        notchWindow = NotchWindow()
        notchWindow.orderFront(nil)

        setupStatusItem()
        startMouseTracking()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettings),
            name: .focusBarOpenSettings,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: "target", accessibilityDescription: "FocusBar")
            btn.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "设置…", action: #selector(openSettings), keyEquivalent: ","))

        let checkItem = NSMenuItem(title: "检查更新…", action: #selector(checkForUpdates), keyEquivalent: "")
        menu.addItem(checkItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出 FocusBar", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    @objc private func openSettings() {
        if let w = settingsWindow, w.isVisible {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = SettingsView(store: store, updater: updaterController.updater)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 340),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "FocusBar 设置"
        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Mouse Tracking

    private func startMouseTracking() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.panelController.handleMouseMoved(to: NSEvent.mouseLocation)
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.panelController.handleMouseMoved(to: NSEvent.mouseLocation)
            return event
        }
    }

    // MARK: - Screen Change

    @objc private func screenParametersChanged() {
        notchWindow.reposition()
        panelController.repositionForScreenChange()
    }

    deinit {
        if let m = globalMouseMonitor { NSEvent.removeMonitor(m) }
        if let m = localMouseMonitor  { NSEvent.removeMonitor(m) }
    }
}
