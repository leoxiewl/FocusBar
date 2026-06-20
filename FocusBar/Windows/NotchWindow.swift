import AppKit

/// 常驻 Notch 区域的透明占位窗口，作为鼠标追踪热区。
final class NotchWindow: NSWindow {

    init() {
        let screen = NotchHelper.notchScreen ?? NSScreen.main!
        let rect = NotchHelper.notchRect(for: screen)

        super.init(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func reposition() {
        guard let screen = NotchHelper.notchScreen else { return }
        setFrame(NotchHelper.notchRect(for: screen), display: true)
    }
}
