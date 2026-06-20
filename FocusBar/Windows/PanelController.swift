import AppKit
import SwiftUI

/// 悬浮展开时不抢焦点，用户主动点击时成为 key window 以支持文字输入。
private final class FocusPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown, !isKeyWindow {
            makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: false)
        }
        super.sendEvent(event)
    }
}

final class PanelController {

    private var panelWindow: FocusPanel?
    private(set) var isExpanded = false
    private var collapseWorkItem: DispatchWorkItem?
    private let store: MarkdownStore
    private var pinObserver: Any?

    // 黄金分割：480 / φ ≈ 297（面板宽高比 = φ）
    static let panelContentHeight: CGFloat = 297

    private var isPinned: Bool {
        UserDefaults.standard.bool(forKey: "focusbar.isPinned")
    }

    init(store: MarkdownStore) {
        self.store = store
        pinObserver = NotificationCenter.default.addObserver(
            forName: .focusBarPinChanged, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if self.isPinned {
                self.cancelCollapseTimer()
                self.expandPanel()
            }
        }
    }

    // MARK: - Mouse Handling

    func handleMouseMoved(to location: NSPoint) {
        guard let screen = NotchHelper.notchScreen else { return }
        let hotArea = NotchHelper.notchRect(for: screen).insetBy(dx: -12, dy: 0).offsetBy(dx: 0, dy: 8)
        let hasPopover = panelWindow?.childWindows?.isEmpty == false

        if hotArea.contains(location) {
            cancelCollapseTimer()
            if !isExpanded { expandPanel() }
        } else if let panelFrame = panelWindow?.frame, panelFrame.contains(location) {
            cancelCollapseTimer()
        } else if hasPopover {
            // popover 弹出时保持面板不收起
            cancelCollapseTimer()
        } else {
            scheduleCollapse()
        }
    }

    // MARK: - Expand / Collapse

    func expandPanel() {
        guard !isExpanded else { return }
        isExpanded = true

        if panelWindow == nil { buildPanelWindow() }
        panelWindow?.orderFront(nil)

        guard let screen = NotchHelper.notchScreen else { return }
        let targetRect = NotchHelper.panelRect(for: screen, panelContentHeight: Self.panelContentHeight)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            panelWindow?.animator().setFrame(targetRect, display: true)
            panelWindow?.animator().alphaValue = 1
        }
    }

    private func scheduleCollapse() {
        guard !isPinned else { return }
        collapseWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.collapsePanel() }
        collapseWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: item)
    }

    private func collapsePanel() {
        guard isExpanded else { return }
        isExpanded = false

        if panelWindow?.isKeyWindow == true { panelWindow?.resignKey() }

        guard let screen = NotchHelper.notchScreen else { return }
        let hiddenRect = NotchHelper.hiddenPanelRect(for: screen, panelContentHeight: Self.panelContentHeight)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panelWindow?.animator().setFrame(hiddenRect, display: true)
            panelWindow?.animator().alphaValue = 0
        }
    }

    private func cancelCollapseTimer() {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
    }

    // MARK: - Build Window

    private func buildPanelWindow() {
        guard let screen = NotchHelper.notchScreen else { return }
        let initialRect = NotchHelper.hiddenPanelRect(for: screen, panelContentHeight: Self.panelContentHeight)

        let panel = FocusPanel(
            contentRect: initialRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false   // shadow handled by SwiftUI
        panel.alphaValue = 0
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isReleasedWhenClosed = false

        let rootView = PanelView()
            .environmentObject(store)

        panel.contentView = NSHostingView(rootView: rootView)
        panelWindow = panel
    }

    // MARK: - Screen Change

    func repositionForScreenChange() {
        collapsePanel()
        panelWindow = nil
    }

    deinit {
        if let obs = pinObserver { NotificationCenter.default.removeObserver(obs) }
    }
}
