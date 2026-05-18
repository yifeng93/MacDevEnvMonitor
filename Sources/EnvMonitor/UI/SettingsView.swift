import SwiftUI

// MARK: - 设置视图

struct SettingsView: View {
    @Binding var alwaysOnTop: Bool
    @AppStorage("refreshInterval") private var refreshInterval: Double = 30

    private let intervals: [(Double, String)] = [
        (15, "15 秒"),
        (30, "30 秒"),
        (60, "1 分钟"),
        (120, "2 分钟"),
        (300, "5 分钟"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置")
                .font(.headline)

            Divider()

            // 自动刷新间隔
            VStack(alignment: .leading, spacing: 6) {
                Text("自动刷新间隔")
                    .font(.subheadline)
                Picker("", selection: $refreshInterval) {
                    ForEach(intervals, id: \.0) { interval, label in
                        Text(label).tag(interval)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Divider()

            // 窗口置顶
            Toggle(isOn: $alwaysOnTop) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("窗口置顶")
                        .font(.subheadline)
                    Text("窗口始终悬浮在其他窗口之上")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)

            Divider()

            // 说明
            VStack(alignment: .leading, spacing: 4) {
                Text("关于")
                    .font(.subheadline)
                    .padding(.bottom, 2)
                Text("开发环境监测看板 v1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("轻量级 macOS 原生应用，只读检测，不做任何系统修改。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("点击环境项可打开其官网。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(width: 300)
    }
}
