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

    /// 展开状态：紧贴 Notch 下方向下延伸，顶部无空隙
    static func panelRect(for screen: NSScreen, panelContentHeight: CGFloat) -> CGRect {
        let notchBottomY = notchRect(for: screen).minY   // Notch 底边（屏幕坐标 y 向上）
        let x = screen.frame.midX - panelWidth / 2
        return CGRect(x: x, y: notchBottomY - panelContentHeight,
                      width: panelWidth, height: panelContentHeight)
    }

    /// 收起状态：面板隐藏于 Notch 内部（y 向上移，完全遮在 menu bar 后面）
    static func hiddenPanelRect(for screen: NSScreen, panelContentHeight: CGFloat) -> CGRect {
        let notchBottomY = notchRect(for: screen).minY
        let x = screen.frame.midX - panelWidth / 2
        return CGRect(x: x, y: notchBottomY,
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
