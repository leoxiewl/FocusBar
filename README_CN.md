# FocusBar &nbsp;·&nbsp; [English](README.md)

一个住在 MacBook 刘海屏里的 macOS 应用——鼠标悬浮，随时看清最重要的事。

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 这是什么？

FocusBar 是一个轻量级专注锚点，常驻在 MacBook Pro 的刘海屏区域。它不是另一个任务管理工具——它让你最重要的事情始终可见，无需切换任何 App。

鼠标移入刘海屏 → 玻璃面板向下展开，你需要的一切都在里面。

## 功能

- **现在正在做** — 记录当前正在并行处理的事情，支持多条
- **今日重要三件事** — 今天必须完成的 3 件事，可勾选标记完成
- **本周重要三件事** — 本周必须推进的 3 件事，可勾选标记完成
- **固定面板** — 点击 pin 图标将面板常驻桌面，不再自动收起
- **Markdown 存储** — 所有数据保存为纯文本 Markdown 文件（`2026-06-20.md`、`2026-W25.md`），完全兼容 Obsidian 和任何文本编辑器
- **可配置目录** — 自由选择数据存放位置；切换目录时提示是否迁移
- **ISO 8601 日历** — 周从周一开始，周键格式为 `YYYY-Wnn`

## 截图

> 鼠标悬浮刘海屏，面板自动展开

*(在此处放置截图)*

## 系统要求

- macOS 13 Ventura 及以上
- MacBook Pro 2021 及以上（需要刘海屏）

## 安装

### 方式一 — 下载安装（推荐）

1. 从 [Releases](../../releases) 下载 `FocusBar.zip`
2. 解压后将 **FocusBar.app** 移入应用程序文件夹
3. 启动 FocusBar，它会自动出现在刘海屏区域

> 首次启动时，macOS 可能提示你在**系统设置 → 隐私与安全性**中允许该应用运行。

### 方式二 — 从源码构建

需要 [Xcode 15+](https://developer.apple.com/xcode/) 和 [xcodegen](https://github.com/yonaskolb/XcodeGen)。

```bash
git clone https://github.com/YOUR_USERNAME/focusbar.git
cd focusbar
brew install xcodegen
xcodegen generate
open FocusBar.xcodeproj
```

在 Xcode 中按 **⌘R** 运行。

## 使用方式

| 操作 | 效果 |
|---|---|
| 鼠标移入刘海屏 | 面板向下展开 |
| 点击任意文字 | 进入编辑模式，回车或点击其他区域保存 |
| 点击复选框 | 切换任务完成状态 |
| 点击 pin 图标 | 固定面板，不再自动收起 |
| 点击齿轮图标 | 打开设置（更改存储目录） |
| 鼠标移出面板 | 300ms 后自动收起（未固定时） |

## 数据存储

FocusBar 将所有数据保存为可读的 Markdown 文件：

```
~/Documents/FocusBarData/
├── 2026-06-20.md   ← 当天任务 + 正在做的事
├── 2026-06-21.md
└── 2026-W25.md     ← 本周重要三件事
```

可在设置中更改存储目录。切换目录时，FocusBar 会询问是否将现有文件迁移到新位置。

## 技术栈

- **Swift + SwiftUI + AppKit** — 纯原生 macOS，非 Electron
- **NSVisualEffectView** — 原生 macOS 玻璃模糊效果
- **Markdown 文件** — 纯文本存储，兼容 Obsidian
- **xcodegen** — 项目文件由 `project.yml` 生成
- 无任何第三方依赖

## 项目结构

```
FocusBar/
├── App/
│   ├── FocusBarApp.swift       # 入口
│   └── AppDelegate.swift       # 窗口初始化、鼠标追踪、菜单栏图标
├── Models/
│   ├── Task.swift              # 数据模型
│   └── MarkdownStore.swift     # Markdown 读写、日历感知
├── Utils/
│   ├── NotchHelper.swift       # 刘海位置计算
│   └── CalendarHelper.swift    # ISO 8601 周键
└── Windows/
    ├── NotchWindow.swift       # 刘海占位透明窗口
    ├── PanelController.swift   # 展开/收起动画、pin 逻辑
    ├── PanelView.swift         # SwiftUI 面板 UI
    └── SettingsView.swift      # 设置窗口
```

## License

MIT — 查看 [LICENSE](LICENSE)
