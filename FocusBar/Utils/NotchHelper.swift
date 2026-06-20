import AppKit

struct NotchHelper {

    static let panelWidth: CGFloat = 480
    static let notchWidth: CGFloat = 260

    /// 常驻 Notch 区域的透明占位窗口 Rect
    static func notchRect(for screen: NSScreen) -> CGRect {
        let menuBarH = menuBarHeight(for: screen)
        let x = screen.frame.midX - notchWidth / 2
        let y = screen.frame.maxY - menuBarH
        return CGRect(x: x, y: y, width: notchWidth, height: menuBarH)
    }

    /// 展开状态：面板顶边贴屏幕顶部，刘海被包裹在面板内，内容从刘海下方开始
    static func panelRect(for screen: NSScreen, panelContentHeight: CGFloat) -> CGRect {
        let x = screen.frame.midX - panelWidth / 2
        return CGRect(x: x,
                      y: screen.frame.maxY - panelContentHeight,
                      width: panelWidth, height: panelContentHeight)
    }

    /// 收起状态：面板向上滑出屏幕顶部，完全隐藏
    static func hiddenPanelRect(for screen: NSScreen, panelContentHeight: CGFloat) -> CGRect {
        let x = screen.frame.midX - panelWidth / 2
        return CGRect(x: x,
                      y: screen.frame.maxY,
                      width: panelWidth, height: panelContentHeight)
    }

    static func menuBarHeight(for screen: NSScreen) -> CGFloat {
        screen.frame.height - screen.visibleFrame.height - screen.visibleFrame.origin.y
    }

    static func hasNotch(screen: NSScreen) -> Bool {
        if #available(macOS 12.0, *) {
            return screen.safeAreaInsets.top > 0
        }
        return false
    }

    static var notchScreen: NSScreen? {
        NSScreen.screens.first(where: { hasNotch(screen: $0) }) ?? NSScreen.main
    }
}
