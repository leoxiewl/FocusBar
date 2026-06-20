import SwiftUI
import AppKit

// MARK: - Notification

extension Notification.Name {
    static let focusBarOpenSettings = Notification.Name("focusBarOpenSettings")
    static let focusBarPinChanged   = Notification.Name("focusBarPinChanged")
}

// MARK: - Design tokens

private enum DS {
    static let blue   = Color(red: 0.28, green: 0.62, blue: 1.00)
    static let amber  = Color(red: 1.00, green: 0.72, blue: 0.20)
    static let coral  = Color(red: 0.85, green: 0.35, blue: 0.19)   // #D85A30

    static let green  = Color(red: 0.11, green: 0.62, blue: 0.46)   // #1D9E75 已完成
    static let orange = Color(red: 0.94, green: 0.62, blue: 0.15)   // #EF9F27 进行中

    static let topGrad = Color(red: 0.12, green: 0.35, blue: 0.82)
}

// MARK: - NSVisualEffectView glass

private struct GlassMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .popover
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// 黄金分割：W/H = φ ≈ 1.618 → W=480, H=297, r = H/φ⁵ ≈ 27
private let φ: CGFloat = 1.6180339887
private let goldenRadius: CGFloat = 297 / (1.6180339887 * 1.6180339887 * 1.6180339887 * 1.6180339887 * 1.6180339887) // ≈ 27

// MARK: - Root Panel

struct PanelView: View {
    @EnvironmentObject var store: MarkdownStore
    @AppStorage("focusbar.isPinned") private var isPinned = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            GlassMaterial()

            // 暖米色叠层，营造示意图中的米白暖调
            Color(red: 0.96, green: 0.93, blue: 0.88).opacity(0.72)

            HStack(alignment: .top, spacing: 0) {
                LeftColumnView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 0.5)
                    .padding(.vertical, 12)

                RightColumnView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.horizontal, 14)
            .padding(.top, 46)
            .padding(.bottom, 36)

            HStack(spacing: 0) {
                Button {
                    isPinned.toggle()
                    NotificationCenter.default.post(name: .focusBarPinChanged, object: nil)
                } label: {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 11, weight: isPinned ? .medium : .light))
                        .foregroundStyle(isPinned ? DS.blue : Color.secondary)
                        .opacity(isPinned ? 1.0 : 0.45)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    NotificationCenter.default.post(name: .focusBarOpenSettings, object: nil)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(.secondary)
                        .opacity(0.45)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 10)
            .padding(.bottom, 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: goldenRadius, style: .continuous))
        .frame(width: NotchHelper.panelWidth)
    }
}

// MARK: - Left Column

struct LeftColumnView: View {
    @EnvironmentObject var store: MarkdownStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            SectionBadge(label: "本周重要三件事", color: DS.blue)
            Spacer().frame(height: 8)

            ForEach(store.weekTasks) { task in
                TaskRowView(
                    task: task,
                    accentColor: DS.blue,
                    onUpdate: { store.updateTaskTitle(task: task, newTitle: $0) },
                    onToggle: { store.toggleCompletion(task: task) }
                )
            }
            if store.canAddWeekTask {
                AddRowButton(color: DS.blue) { store.addWeekTask() }
            }

            Spacer().frame(height: 10)
            Divider().opacity(0.25)
            Spacer().frame(height: 10)

            SectionBadge(label: "今日重要三件事", color: DS.amber)
            Spacer().frame(height: 8)

            ForEach(store.todayTasks) { task in
                TaskRowView(
                    task: task,
                    accentColor: DS.amber,
                    onUpdate: { store.updateTaskTitle(task: task, newTitle: $0) },
                    onToggle: { store.toggleCompletion(task: task) }
                )
            }
            if store.canAddTodayTask {
                AddRowButton(color: DS.amber) { store.addTodayTask() }
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Right Column

struct RightColumnView: View {
    @EnvironmentObject var store: MarkdownStore
    @State private var editingID: UUID? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            SectionBadge(label: "正在做", color: DS.coral)
            Spacer().frame(height: 8)

            ForEach(store.currentFocus) { item in
                FocusItemRow(
                    item: item,
                    isEditing: editingID == item.id,
                    onTap: { editingID = item.id },
                    onUpdate: { updated in
                        store.updateFocus(item: updated)
                        editingID = nil
                    },
                    onCancel: { editingID = nil },
                    onDelete: {
                        store.removeFocus(item: item)
                        editingID = nil
                    }
                )
            }

            Button {
                store.addFocus()
                DispatchQueue.main.async { editingID = store.currentFocus.last?.id }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus").font(.system(size: 10))
                    Text("添加").font(.system(size: 11))
                }
                .foregroundStyle(DS.coral)
                .opacity(0.6)
            }
            .buttonStyle(.plain)
            .padding(.top, 3)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Task Row

struct TaskRowView: View {
    let task: FocusTask
    let accentColor: Color
    var onUpdate: (String) -> Void
    var onToggle: () -> Void

    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 7) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 13))
                    .foregroundStyle(task.isCompleted ? accentColor : accentColor.opacity(0.45))
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("", text: $editText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isFocused)
                    .onSubmit { commitEdit() }
                    .onExitCommand { cancelEdit() }
                    .onChange(of: isFocused) { focused in
                        if !focused { commitEdit() }
                    }
            } else {
                Text(task.title.isEmpty ? "点击输入…" : task.title)
                    .font(.system(size: 13))
                    .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)
                    .strikethrough(task.isCompleted)
                    .opacity(task.title.isEmpty ? 0.28 : 1)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { startEditing() }
                    .animation(.easeInOut(duration: 0.1), value: task.isCompleted)
            }
        }
        .frame(height: 26)
    }

    private func startEditing() {
        editText = task.title; isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { isFocused = true }
    }
    private func commitEdit() { isEditing = false; isFocused = false; onUpdate(editText) }
    private func cancelEdit() { isEditing = false; isFocused = false }
}

// MARK: - Focus Item Row

struct FocusItemRow: View {
    let item: FocusItem
    let isEditing: Bool
    var onTap: () -> Void
    var onUpdate: (FocusItem) -> Void
    var onCancel: () -> Void
    var onDelete: () -> Void

    @State private var editTitle:     String = ""
    @State private var editStartDate: Date = Date()
    @State private var editEndDate:   Date = Date()
    @State private var editProgress:  FocusProgress? = nil
    @State private var editNote:      String = ""
    @State private var showStartPicker = false
    @State private var showEndPicker   = false

    @FocusState private var titleFocused: Bool

    var body: some View {
        Group {
            if isEditing {
                editView
            } else {
                displayView
            }
        }
        .onChange(of: isEditing) { editing in
            if editing { loadEditState() }
        }
    }

    // MARK: Display Mode

    private var displayView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 7, height: 7)

                Text(item.title.isEmpty ? "点击输入…" : item.title)
                    .font(.system(size: 13))
                    .foregroundStyle(item.title.isEmpty ? Color.secondary.opacity(0.4) : Color.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if hasMetadata {
                HStack(spacing: 5) {
                    if !item.timeRangeToken.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                            Text(item.timeRangeToken)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let prog = item.progress {
                        progressBadge(prog)
                    }
                    if !item.note.isEmpty {
                        Text(item.note)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .padding(.leading, 13)
            }
        }
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var hasMetadata: Bool {
        !item.timeRangeToken.isEmpty || item.progress != nil || !item.note.isEmpty
    }

    private var dotColor: Color {
        switch item.progress {
        case .completed:             return DS.green
        case .percent(let v) where v > 0: return DS.orange
        default:                     return DS.coral
        }
    }

    @ViewBuilder
    private func progressBadge(_ prog: FocusProgress) -> some View {
        let (label, fg, bg): (String, Color, Color) = {
            switch prog {
            case .completed:
                return ("已完成", DS.green, DS.green.opacity(0.15))
            case .percent(let v):
                return ("\(v)%", DS.orange, DS.orange.opacity(0.15))
            }
        }()
        Text(label)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(fg)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(bg)
            .clipShape(Capsule())
    }

    // MARK: Edit Mode

    private var editView: some View {
        VStack(alignment: .leading, spacing: 5) {
            // 标题
            HStack(spacing: 6) {
                Circle()
                    .fill(DS.coral)
                    .frame(width: 7, height: 7)
                TextField("任务标题", text: $editTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($titleFocused)
                    .onSubmit { commitEdit() }
                    .onExitCommand { onCancel() }
            }

            // 时间段
            HStack(spacing: 5) {
                Image(systemName: "clock")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .frame(width: 11)
                Button(formatTime(editStartDate)) {
                    showStartPicker = true
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.primary)
                .buttonStyle(.plain)
                .popover(isPresented: $showStartPicker, arrowEdge: .bottom) {
                    TimeScrollPicker(selection: $editStartDate) { showStartPicker = false }
                }

                Text("~").font(.system(size: 11)).foregroundStyle(.secondary)

                Button(formatTime(editEndDate)) {
                    showEndPicker = true
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.primary)
                .buttonStyle(.plain)
                .popover(isPresented: $showEndPicker, arrowEdge: .bottom) {
                    TimeScrollPicker(selection: $editEndDate) { showEndPicker = false }
                }
            }
            .padding(.leading, 13)

            // 进度按钮
            HStack(spacing: 4) {
                ForEach([0, 25, 50, 75], id: \.self) { pct in
                    progressToggleBtn(label: "\(pct)%", value: .percent(pct))
                }
                progressToggleBtn(label: "已完成", value: .completed)
            }
            .padding(.leading, 13)

            // 备注
            HStack(spacing: 4) {
                Image(systemName: "note.text")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .frame(width: 11)
                TextField("备注", text: $editNote)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .onSubmit { commitEdit() }
            }
            .padding(.leading, 13)

            // 操作按钮
            HStack {
                Button("删除") { onDelete() }
                    .font(.system(size: 10))
                    .foregroundStyle(Color.red.opacity(0.75))
                    .buttonStyle(.plain)
                Spacer()
                Button("取消") { onCancel() }
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                Button("确认") { commitEdit() }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DS.coral)
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
            }
            .padding(.leading, 13)
            .padding(.top, 1)
        }
        .padding(.vertical, 5)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { titleFocused = true }
        }
    }

    @ViewBuilder
    private func progressToggleBtn(label: String, value: FocusProgress) -> some View {
        let isSelected = editProgress == value
        Button {
            editProgress = isSelected ? nil : value
        } label: {
            Text(label)
                .font(.system(size: 9, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? DS.coral : Color.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isSelected ? DS.coral.opacity(0.14) : Color.secondary.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? DS.coral.opacity(0.4) : Color.clear, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    private func loadEditState() {
        editTitle     = item.title
        editProgress  = item.progress
        editNote      = item.note
        editStartDate = parseTime(item.timeStart) ?? nextHalfHour()
        editEndDate   = parseTime(item.timeEnd)   ?? nextHalfHour().addingTimeInterval(3600)
    }

    private func commitEdit() {
        titleFocused = false
        var updated = item
        updated.title     = editTitle
        updated.timeStart = formatTime(editStartDate)
        updated.timeEnd   = formatTime(editEndDate)
        updated.progress  = editProgress
        updated.note      = editNote.trimmingCharacters(in: .whitespaces)
        onUpdate(updated)
    }

    private func parseTime(_ s: String) -> Date? {
        guard !s.isEmpty else { return nil }
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.date(from: s)
    }

    private func formatTime(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: d)
    }

    // 下一个半小时整点：17:10 → 17:30，17:31 → 18:00
    private func nextHalfHour() -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        let min = comps.minute ?? 0
        let next = (min / 15 + 1) * 15
        if next < 60 {
            comps.minute = next
        } else {
            comps.hour = (comps.hour ?? 0) + 1
            comps.minute = 0
        }
        comps.second = 0
        return cal.date(from: comps) ?? Date()
    }
}

// MARK: - Section Badge

private struct SectionBadge: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }
}

// MARK: - Time Scroll Picker

private struct TimeScrollPicker: View {
    @Binding var selection: Date
    let onSelect: () -> Void

    private let slots: [Date] = {
        let base = Calendar.current.startOfDay(for: Date())
        return (0..<96).map { base.addingTimeInterval(Double($0) * 900) }
    }()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(Array(slots.enumerated()), id: \.offset) { i, slot in
                        Button {
                            selection = slot
                            onSelect()
                        } label: {
                            Text(label(slot))
                                .font(.system(size: 13, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(isSame(slot, selection) ? DS.coral.opacity(0.85) : Color.clear)
                                .foregroundStyle(isSame(slot, selection) ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                        .id(i)
                    }
                }
            }
            .frame(width: 90, height: 200)
            .onAppear {
                let idx = slots.firstIndex(where: { isSame($0, selection) }) ?? 0
                proxy.scrollTo(max(0, idx - 2), anchor: .top)
            }
        }
        .padding(.vertical, 4)
    }

    private func label(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: d)
    }

    private func isSame(_ a: Date, _ b: Date) -> Bool {
        let c = Calendar.current
        return c.component(.hour, from: a) == c.component(.hour, from: b)
            && c.component(.minute, from: a) == c.component(.minute, from: b)
    }
}

// MARK: - Add Row Button

private struct AddRowButton: View {
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "plus").font(.system(size: 10))
                Text("添加").font(.system(size: 11))
            }
            .foregroundStyle(color)
            .opacity(0.5)
        }
        .buttonStyle(.plain)
        .frame(height: 24)
    }
}
