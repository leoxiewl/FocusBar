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

// MARK: - Focus Progress

enum FocusProgress: Equatable {
    case percent(Int)   // 0–100
    case completed      // 已完成

    var markdownToken: String {
        switch self {
        case .percent(let v): return "\(v)%"
        case .completed:      return "已完成"
        }
    }

    static func parse(_ s: String) -> FocusProgress? {
        let t = s.trimmingCharacters(in: .whitespaces)
        if t == "已完成" { return .completed }
        if t.hasSuffix("%"), let v = Int(t.dropLast()), (0...100).contains(v) {
            return .percent(v)
        }
        return nil
    }
}

extension FocusProgress: Codable {
    enum CodingKeys: String, CodingKey { case kind, value }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(String.self, forKey: .kind)
        if kind == "completed" {
            self = .completed
        } else {
            let v = try c.decode(Int.self, forKey: .value)
            self = .percent(v)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .completed:
            try c.encode("completed", forKey: .kind)
        case .percent(let v):
            try c.encode("percent", forKey: .kind)
            try c.encode(v, forKey: .value)
        }
    }
}

// MARK: - Focus Item

struct FocusItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var timeStart: String = ""
    var timeEnd:   String = ""
    var progress:  FocusProgress? = nil
    var note:      String = ""

    var timeRangeToken: String {
        switch (timeStart.isEmpty, timeEnd.isEmpty) {
        case (true, true):   return ""
        case (false, true):  return "\(timeStart)~"
        case (true, false):  return "~\(timeEnd)"
        case (false, false): return "\(timeStart)~\(timeEnd)"
        }
    }

    static func parseTimeRange(_ token: String) -> (start: String, end: String) {
        let parts = token.components(separatedBy: "~")
        guard parts.count == 2 else { return ("", "") }
        return (parts[0].trimmingCharacters(in: .whitespaces),
                parts[1].trimmingCharacters(in: .whitespaces))
    }

    // Parses a raw Markdown list-item body (everything after "- ")
    // Format: "Title | 14:00~15:00 | 50% | Note text"
    static func parse(from raw: String) -> FocusItem {
        let parts = raw.components(separatedBy: " | ")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var item = FocusItem(title: parts[0])
        var fieldIdx = 1

        if fieldIdx < parts.count, parts[fieldIdx].contains("~") {
            let (s, e) = FocusItem.parseTimeRange(parts[fieldIdx])
            item.timeStart = s
            item.timeEnd   = e
            fieldIdx += 1
        }

        if fieldIdx < parts.count, let prog = FocusProgress.parse(parts[fieldIdx]) {
            item.progress = prog
            fieldIdx += 1
        }

        if fieldIdx < parts.count {
            item.note = parts[fieldIdx...].joined(separator: " | ")
        }

        return item
    }
}

// MARK: - File Records

/// 每天一个文件：今日 Top3 + 正在做
struct DayRecord: Codable {
    var date: String                  // "2026-06-20"
    var todayTasks: [FocusTask] = []
    var currentFocus: [FocusItem] = []
}

/// 每周一个文件：本周 Top3
struct WeekRecord: Codable {
    var weekKey: String               // "2026-W25"
    var weekStart: String             // "2026-06-16"
    var weekEnd: String               // "2026-06-22"
    var weekTasks: [FocusTask] = []
}
