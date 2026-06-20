import Foundation
import Combine

/// 以 Markdown 文件为持久化格式的数据层。
/// 每天一个 .md 文件，每周一个 .md 文件，存于用户指定目录。
final class MarkdownStore: ObservableObject {

    // MARK: - Published State

    @Published var todayTasks: [FocusTask] = []
    @Published var weekTasks: [FocusTask] = []
    @Published var currentFocus: [FocusItem] = []

    private(set) var currentDayKey: String = ""
    private(set) var currentWeekKey: String = ""

    // MARK: - Storage Config

    private let dirKey = "focusbar.storageDirectory"

    var storageDirectory: URL {
        get {
            if let path = UserDefaults.standard.string(forKey: dirKey) {
                return URL(fileURLWithPath: path)
            }
            return defaultDirectory
        }
        set {
            UserDefaults.standard.set(newValue.path, forKey: dirKey)
        }
    }

    private var defaultDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("FocusBarData")
    }

    // MARK: - Init

    init() {
        ensureDirectoryExists()
        loadToday()
        loadWeek()
        observeDayChange()
    }

    // MARK: - Directory

    func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(
            at: storageDirectory, withIntermediateDirectories: true
        )
    }

    func changeStorageDirectory(to url: URL, migrate: Bool) {
        let old = storageDirectory
        storageDirectory = url
        ensureDirectoryExists()
        if migrate { migrateFiles(from: old, to: url) }
        loadToday()
        loadWeek()
    }

    private func migrateFiles(from source: URL, to dest: URL) {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: source, includingPropertiesForKeys: nil
        ) else { return }
        for file in files where isFocusBarFile(file.lastPathComponent) {
            let target = dest.appendingPathComponent(file.lastPathComponent)
            if !FileManager.default.fileExists(atPath: target.path) {
                try? FileManager.default.copyItem(at: file, to: target)
            }
        }
    }

    /// 判断文件名是否为 FocusBar 生成的格式：2026-06-20.md 或 2026-W25.md
    func isFocusBarFile(_ name: String) -> Bool {
        guard name.hasSuffix(".md") else { return false }
        let stem = String(name.dropLast(3))
        let dayPattern = #"^\d{4}-\d{2}-\d{2}$"#
        let weekPattern = #"^\d{4}-W\d{1,2}$"#
        return stem.range(of: dayPattern, options: .regularExpression) != nil
            || stem.range(of: weekPattern, options: .regularExpression) != nil
    }

    // MARK: - Load

    func loadToday() {
        let key = CalendarHelper.dayKey()
        currentDayKey = key
        let parsed = parseDayFile(key: key)
        todayTasks   = parsed.tasks
        currentFocus = parsed.focus
    }

    func loadWeek() {
        let key = CalendarHelper.weekKey()
        currentWeekKey = key
        weekTasks = parseWeekFile(key: key)
    }

    // MARK: - File Paths

    private func dayFile(key: String) -> URL {
        storageDirectory.appendingPathComponent("\(key).md")
    }

    private func weekFile(key: String) -> URL {
        storageDirectory.appendingPathComponent("\(key).md")
    }

    // MARK: - Markdown Parser

    private enum Section { case none, focus, todayTasks, weekTasks }

    private func parseDayFile(key: String) -> (tasks: [FocusTask], focus: [FocusItem]) {
        let url = dayFile(key: key)
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else {
            return ([], [])
        }

        var tasks: [FocusTask] = []
        var focus: [FocusItem] = []
        var section = Section.none

        for line in raw.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            if      t.hasPrefix("## 🔴") { section = .focus }
            else if t.hasPrefix("## 📅") { section = .todayTasks }
            else if t.hasPrefix("- ") {
                let body = String(t.dropFirst(2))
                switch section {
                case .focus:
                    if !body.isEmpty { focus.append(FocusItem.parse(from: body)) }
                case .todayTasks:
                    if let task = parseCheckboxLine(body, type: .todayTop) { tasks.append(task) }
                default: break
                }
            }
        }
        return (tasks, focus)
    }

    private func parseWeekFile(key: String) -> [FocusTask] {
        let url = weekFile(key: key)
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return [] }

        var tasks: [FocusTask] = []
        var inSection = false

        for line in raw.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("## 📆") {
                inSection = true
            } else if inSection, t.hasPrefix("- ") {
                let body = String(t.dropFirst(2))
                if let task = parseCheckboxLine(body, type: .weekTop) { tasks.append(task) }
            }
        }
        return tasks
    }

    /// 解析 `[x] 标题` 或 `[ ] 标题`
    private func parseCheckboxLine(_ body: String, type: TaskType) -> FocusTask? {
        if body.hasPrefix("[x] ") {
            let title = String(body.dropFirst(4))
            return FocusTask(title: title, type: type, isCompleted: true)
        } else if body.hasPrefix("[ ] ") {
            let title = String(body.dropFirst(4))
            return FocusTask(title: title, type: type, isCompleted: false)
        }
        return nil
    }

    // MARK: - Markdown Writer

    private func saveDayFile() {
        var lines: [String] = []

        lines.append("# \(currentDayKey) \(CalendarHelper.weekdayName())")
        lines.append("")

        lines.append("## 🔴 现在正在做")
        for item in currentFocus where !item.title.isEmpty {
            var parts: [String] = [item.title]
            if !item.timeRangeToken.isEmpty { parts.append(item.timeRangeToken) }
            if let p = item.progress         { parts.append(p.markdownToken) }
            if !item.note.isEmpty            { parts.append(item.note) }
            lines.append("- " + parts.joined(separator: " | "))
        }
        lines.append("")

        lines.append("## 📅 今日重要三件事")
        todayTasks.filter { !$0.title.isEmpty }.forEach { task in
            lines.append("- \(task.isCompleted ? "[x]" : "[ ]") \(task.title)")
        }
        lines.append("")

        try? lines.joined(separator: "\n")
            .write(to: dayFile(key: currentDayKey), atomically: true, encoding: .utf8)
    }

    private func saveWeekFile() {
        var lines: [String] = []

        let r = CalendarHelper.weekRange()
        lines.append("# \(currentWeekKey)（\(r.startLabel) — \(r.endLabel)）")
        lines.append("")

        lines.append("## 📆 本周重要三件事")
        weekTasks.filter { !$0.title.isEmpty }.forEach { task in
            lines.append("- \(task.isCompleted ? "[x]" : "[ ]") \(task.title)")
        }
        lines.append("")

        try? lines.joined(separator: "\n")
            .write(to: weekFile(key: currentWeekKey), atomically: true, encoding: .utf8)
    }

    // MARK: - Constraints

    var canAddTodayTask: Bool { todayTasks.count < 3 }
    var canAddWeekTask: Bool  { weekTasks.count < 3 }

    // MARK: - Today Tasks

    func addTodayTask(title: String = "") {
        guard canAddTodayTask else { return }
        todayTasks.append(FocusTask(title: title, type: .todayTop))
        saveDayFile()
    }

    // MARK: - Week Tasks

    func addWeekTask(title: String = "") {
        guard canAddWeekTask else { return }
        weekTasks.append(FocusTask(title: title, type: .weekTop))
        saveWeekFile()
    }

    // MARK: - Shared Task Operations

    func toggleCompletion(task: FocusTask) {
        updateTask(task) { $0.isCompleted.toggle() }
    }

    func updateTaskTitle(task: FocusTask, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            deleteTask(task)
        } else {
            updateTask(task) { $0.title = trimmed }
        }
    }

    func deleteTask(_ task: FocusTask) {
        let inToday = todayTasks.contains { $0.id == task.id }
        todayTasks.removeAll { $0.id == task.id }
        weekTasks.removeAll  { $0.id == task.id }
        if inToday { saveDayFile() } else { saveWeekFile() }
    }

    private func updateTask(_ task: FocusTask, mutation: (inout FocusTask) -> Void) {
        if let idx = todayTasks.firstIndex(where: { $0.id == task.id }) {
            mutation(&todayTasks[idx])
            todayTasks[idx].updatedAt = Date()
            saveDayFile()
        } else if let idx = weekTasks.firstIndex(where: { $0.id == task.id }) {
            mutation(&weekTasks[idx])
            weekTasks[idx].updatedAt = Date()
            saveWeekFile()
        }
    }

    // MARK: - Current Focus

    func addFocus() {
        currentFocus.append(FocusItem(title: ""))
        saveDayFile()
    }

    func updateFocus(item: FocusItem) {
        guard let idx = currentFocus.firstIndex(where: { $0.id == item.id }) else { return }
        let trimmed = item.title.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            currentFocus.remove(at: idx)
        } else {
            var updated = item
            updated.title = trimmed
            currentFocus[idx] = updated
        }
        saveDayFile()
    }

    func removeFocus(item: FocusItem) {
        currentFocus.removeAll { $0.id == item.id }
        saveDayFile()
    }

    // MARK: - Day Change

    private func observeDayChange() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDayChange),
            name: .NSCalendarDayChanged,
            object: nil
        )
    }

    @objc private func handleDayChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.loadToday()
            let newWeekKey = CalendarHelper.weekKey()
            if newWeekKey != self.currentWeekKey { self.loadWeek() }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
