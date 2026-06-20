import Foundation

struct CalendarHelper {

    // ISO 8601：周一为一周起点
    static var iso: Calendar = {
        var c = Calendar(identifier: .iso8601)
        c.locale = Locale(identifier: "zh_CN")
        c.timeZone = TimeZone.current
        return c
    }()

    // MARK: - Keys

    /// "2026-06-20"
    static func dayKey(for date: Date = Date()) -> String {
        let c = iso.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    /// "2026-W25"
    static func weekKey(for date: Date = Date()) -> String {
        let c = iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", c.yearForWeekOfYear!, c.weekOfYear!)
    }

    // MARK: - Week Range

    struct WeekRange {
        let start: Date      // 周一 00:00:00
        let end: Date        // 周日 23:59:59
        let startLabel: String   // "2026-06-16"
        let endLabel: String     // "2026-06-22"
    }

    static func weekRange(for date: Date = Date()) -> WeekRange {
        // 找到本周一
        let monday = iso.date(from: iso.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: date
        ))!
        // 周日 = 周一 + 6 天的末尾
        let sunday = iso.date(byAdding: .day, value: 6, to: monday)!
        let sundayEnd = iso.date(bySettingHour: 23, minute: 59, second: 59, of: sunday)!

        return WeekRange(
            start: monday,
            end: sundayEnd,
            startLabel: dayKey(for: monday),
            endLabel: dayKey(for: sunday)
        )
    }

    // MARK: - Display

    static func weekRangeDisplay(for date: Date = Date()) -> String {
        let r = weekRange(for: date)
        return "\(r.startLabel) — \(r.endLabel)"
    }

    /// 当天是周几的中文描述
    static func weekdayName(for date: Date = Date()) -> String {
        let names = ["", "周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        let w = iso.component(.weekday, from: date)
        // ISO 周一=2 … 周日=1（macOS Calendar 惯例），转成 1-7
        let idx = w == 1 ? 7 : w - 1
        return names[min(idx, 7)]
    }
}
