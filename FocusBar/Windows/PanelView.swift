import SwiftUI
import AppKit

// MARK: - Notification

extension Notification.Name {
    static let focusBarOpenSettings = Notification.Name("focusBarOpenSettings")
    static let focusBarPinChanged   = Notification.Name("focusBarPinChanged")
}

// MARK: - Design tokens

private enum DS {
    // 分区主色
    static let blue   = Color(red: 0.28, green: 0.62, blue: 1.00)   // 本周 #47A0FF
    static let amber  = Color(red: 1.00, green: 0.72, blue: 0.20)   // 今日 #FFB833
    static let coral  = Color(red: 1.00, green: 0.36, blue: 0.36)   // 正在做 #FF5C5C

    // 面板顶部渐变色带（深蓝）
    static let topGrad = Color(red: 0.12, green: 0.35, blue: 0.82)  // #1F59D1
}

// MARK: - NSVisualEffectView glass

private struct GlassMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .sidebar
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Panel shape: square top, rounded bottom

private struct PanelShape: Shape {
    let radius: CGFloat = 14
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                       control: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                       control: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Root Panel

struct PanelView: View {
    @EnvironmentObject var store: MarkdownStore
    @AppStorage("focusbar.isPinned") private var isPinned = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            // 1. 原生玻璃模糊
            GlassMaterial()

            // 2. 蓝色渐变色带：顶部浓→底部淡，给面板视觉重量
            LinearGradient(
                stops: [
                    .init(color: DS.topGrad.opacity(0.28), location: 0.0),
                    .init(color: DS.topGrad.opacity(0.08), location: 0.45),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // 3. 内容
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
            .padding(.top, 12)
            .padding(.bottom, 36)

            // 4. 底部操作按钮（pin + 齿轮）
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
        .clipShape(PanelShape())
        // 顶部亮边（蓝白渐变），底部无边框
        .overlay(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
        }
        .shadow(color: DS.topGrad.opacity(0.30), radius: 20, x: 0, y: 8)
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
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
    @State private var editingIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            SectionBadge(label: "正在做", color: DS.coral)
            Spacer().frame(height: 8)

            ForEach(Array(store.currentFocus.enumerated()), id: \.offset) { index, text in
                FocusItemRow(
                    text: text,
                    isEditing: editingIndex == index,
                    onTap: { editingIndex = index },
                    onUpdate: { newText in
                        store.updateFocus(at: index, text: newText)
                        editingIndex = nil
                    },
                    onDelete: {
                        store.removeFocus(at: index)
                        editingIndex = nil
                    }
                )
            }

            Button {
                store.addFocus()
                DispatchQueue.main.async { editingIndex = store.currentFocus.count - 1 }
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
    let text: String
    let isEditing: Bool
    var onTap: () -> Void
    var onUpdate: (String) -> Void
    var onDelete: () -> Void

    @State private var editText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 7) {
            // 亮色大圆点，更显眼
            Circle()
                .fill(DS.coral)
                .frame(width: 7, height: 7)
                .shadow(color: DS.coral.opacity(0.6), radius: 3)

            if isEditing {
                TextField("", text: $editText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isFocused)
                    .onSubmit { commit() }
                    .onExitCommand { cancel() }
                    .onChange(of: isFocused) { focused in
                        if !focused { commit() }
                    }
                    .onAppear {
                        editText = text
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { isFocused = true }
                    }
            } else {
                Text(text.isEmpty ? "点击输入…" : text)
                    .font(.system(size: 13))
                    .foregroundStyle(text.isEmpty ? Color.secondary : Color.primary)
                    .opacity(text.isEmpty ? 0.3 : 1)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { onTap() }
            }
        }
        .frame(height: 26)
    }

    private func commit() { isFocused = false; onUpdate(editText) }
    private func cancel()  { isFocused = false; onUpdate(text) }
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
