---
name: project-build-release
description: FocusBar 打包 DMG 并发布 GitHub Releases 的流程
metadata: 
  node_type: memory
  type: project
  originSessionId: ebce02d3-c71d-42fd-9693-d7a7739c99f3
---

FocusBar 使用 xcodegen + xcodebuild 构建，hdiutil 打包 DMG，gh CLI 发布。

**Why:** 无 Makefile 或脚本，需要手动执行以下步骤。

**How to apply:** 每次发布新版本时按此流程执行。

## 发布流程

```bash
# 1. 更新版本号（project.yml）
# MARKETING_VERSION: "x.y.z"
# CURRENT_PROJECT_VERSION: "n"

# 2. 重新生成 xcodeproj
xcodegen generate

# 3. 提交代码
git add <修改的文件>  # 不要 add FocusBar.xcodeproj/ dist/ design.md implementation-plan.md
git commit -m "feat: ..."

# 4. 构建 Release
xcodebuild -project FocusBar.xcodeproj -scheme FocusBar \
  -configuration Release \
  -derivedDataPath /tmp/FocusBar-build clean build

# 5. 打包 DMG
APP="/tmp/FocusBar-build/Build/Products/Release/FocusBar.app"
DMG="dist/FocusBar-v{版本}.dmg"
STAGING=$(mktemp -d)
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "FocusBar" -srcfolder "$STAGING" -ov -format UDZO "$DMG"
rm -rf "$STAGING"

# 6. 发布 GitHub Release
gh release create v{版本} "$DMG" \
  --repo leoxiewl/FocusBar \
  --title "FocusBar v{版本}" \
  --notes "..."
```

## 注意事项

- `dist/` 目录不提交到 git（存放 DMG 二进制）
- `FocusBar.xcodeproj/` 不提交（由 xcodegen 从 project.yml 生成）
- Code signing 使用 "Sign to Run Locally"（ad-hoc），无开发者证书
- 首次打开提示无法验证：右键 → 打开

## 历史版本

| 版本 | build | 说明 |
|------|-------|------|
| 1.0.0 | 1 | 初始发布 |
| 1.1.0 | 2 | 集成 Sparkle 自动更新 |
| 1.2.0 | 3 | UI 重设计（面板包裹刘海，黄金分割），移除 Sparkle |
