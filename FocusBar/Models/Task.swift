import Foundation

enum TaskType: String, Codable {
    case todayTop
    case weekTop
}

struct FocusTask: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var type: TaskType
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

// MARK: - File Records

/// 每天一个文件：今日 Top3 + 正在做
struct DayRecord: Codable {
    var date: String                  // "2026-06-20"
    var todayTasks: [FocusTask] = []
    var currentFocus: [String] = []
}

/// 每周一个文件：本周 Top3
struct WeekRecord: Codable {
    var weekKey: String               // "2026-W25"
    var weekStart: String             // "2026-06-16"
    var weekEnd: String               // "2026-06-22"
    var weekTasks: [FocusTask] = []
}
