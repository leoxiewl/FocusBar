---
name: project-ui-redesign-v1-2-0
description: FocusBar v1.2.0 UI 重设计：面板包裹刘海屏，黄金分割比例，圆角超椭圆
metadata: 
  node_type: memory
  type: project
  originSessionId: ebce02d3-c71d-42fd-9693-d7a7739c99f3
---

面板定位从"刘海下方弹出"改为"顶部展开包裹刘海"，版本升至 1.2.0，已发布 GitHub Releases。

**Why:** 用户认为从刘海下方弹出的视觉割裂感强，希望面板与刘海屏融为一体。

**How to apply:** 未来修改面板位置逻辑时，核心是 `NotchHelper.panelRect` 返回 `y = screen.frame.maxY - panelContentHeight`，面板顶边贴屏幕顶部；收起时 `y = screen.frame.maxY`（上滑出屏幕）。不要改回"刘海下方弹出"的方式。

## 关键设计参数（v1.2.0）

- **面板尺寸**：480 × 297pt，宽高比 ≈ φ（黄金分割，480/297 ≈ 1.616）
- **圆角半径**：H/φ⁵ ≈ 27pt，使用 `.continuous` style（超椭圆）
- **顶部 padding**：46pt（跳过刘海/菜单栏区域 ~37pt + 间距）
- **展开动画**：duration 0.28s，CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
- **收起动画**：duration 0.15s，easeIn
- **面板高度常量**：`PanelController.panelContentHeight = 297`

## 圆角迭代记录（用户逐档调小）

- H/φ³ ≈ 70pt → 太大，被否
- H/φ⁴ ≈ 43pt → 仍偏大，被否
- H/φ⁵ ≈ 27pt → 通过（当前值）
- 下一档备选：H/φ⁶ ≈ 16pt

## 被否的设计方案

- **肩部曲线（shoulder shape）**：顶部收窄至刘海宽度 260pt、两侧贝塞尔曲线展开的形状——用户反馈"更丑了"，直接否掉。
- **深色渐变覆盖顶部**：叠黑色渐变与刘海融合——随肩部曲线方案一起废弃。
