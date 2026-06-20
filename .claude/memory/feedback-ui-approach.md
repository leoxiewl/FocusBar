---
name: feedback-ui-approach
description: FocusBar UI 修改的用户偏好：不喜欢复杂形状变换，偏好直接的定位改变
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ebce02d3-c71d-42fd-9693-d7a7739c99f3
---

做视觉融合效果时，优先用**定位/布局**解决，不要用复杂的自定义形状。

**Why:** 第一次尝试肩部曲线（shoulder shape）+ 深色渐变让刘海融合，用户直接回复"更丑了，完全不行"。第二次改用面板直接定位到屏幕顶部包裹刘海，用户反应"新设计还不错"。

**How to apply:** 遇到刘海/边缘融合需求时，先考虑窗口定位，不要先想自定义 Path/Shape。自定义 Shape 会引入复杂的几何问题和渲染边缘情况。
