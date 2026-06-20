import SwiftUI
import AppKit
import Sparkle

struct SettingsView: View {
    @ObservedObject var store: MarkdownStore
    let updater: SPUUpdater
    @State private var directoryPath: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text("FocusBar 设置")
                .font(.title2.bold())

            Divider()

            // 当前周信息
            VStack(alignment: .leading, spacing: 6) {
                Label("本周", systemImage: "calendar")
                    .font(.headline)

                let range = CalendarHelper.weekRange()
                let weekKey = CalendarHelper.weekKey()
                Text("\(weekKey)   \(range.startLabel) — \(range.endLabel)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("今天：\(CalendarHelper.dayKey())  \(CalendarHelper.weekdayName())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 存储目录
            VStack(alignment: .leading, spacing: 8) {
                Label("数据存储目录", systemImage: "folder")
                    .font(.headline)

                HStack {
                    Text(store.storageDirectory.path)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("在 Finder 中显示") {
                        NSWorkspace.shared.open(store.storageDirectory)
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                .padding(8)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(6)

                Button("更改目录…") {
                    chooseDirectory()
                }
                .buttonStyle(.bordered)

                Text("已存储文件：\(storedFileCount) 个 Markdown 文件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 更新
            VStack(alignment: .leading, spacing: 8) {
                Label("更新", systemImage: "arrow.down.circle")
                    .font(.headline)

                HStack {
                    Button("检查更新…") {
                        updater.checkForUpdates()
                    }
                    .buttonStyle(.bordered)

                    Text("当前版本 v\(appVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack {
                Spacer()
                Text("FocusBar v\(appVersion)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(width: 480, height: 380)
        .onAppear { directoryPath = store.storageDirectory.path }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
    }

    private var storedFileCount: Int {
        let files = try? FileManager.default.contentsOfDirectory(
            at: store.storageDirectory,
            includingPropertiesForKeys: nil
        )
        return files?.filter { store.isFocusBarFile($0.lastPathComponent) }.count ?? 0
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "选择目录"
        panel.message = "选择 FocusBar 数据的存储目录"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let alert = NSAlert()
        alert.messageText = "是否迁移现有数据？"
        alert.informativeText = "是否将当前目录中的 Markdown 文件复制到新目录？\n选择「不迁移」将直接读取新目录中已有的内容。"
        alert.addButton(withTitle: "迁移数据")
        alert.addButton(withTitle: "不迁移")
        alert.addButton(withTitle: "取消")
        alert.alertStyle = .informational

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            store.changeStorageDirectory(to: url, migrate: true)
            directoryPath = url.path
        case .alertSecondButtonReturn:
            store.changeStorageDirectory(to: url, migrate: false)
            directoryPath = url.path
        default:
            break
        }
    }
}
