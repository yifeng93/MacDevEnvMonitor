import SwiftUI
import AppKit

// MARK: - 标签页枚举

private enum MonitorTab: String, CaseIterable {
    case devEnv = "开发环境"
    case host = "主机状态"
    case services = "运行服务"
}

// MARK: - 主内容视图

struct ContentView: View {
    @ObservedObject var checker: EnvChecker
    @State private var showSettings = false
    @State private var selectedTab: MonitorTab = .devEnv
    @State private var selectedItem: EnvItem.ID?
    @State private var expandedSections: Set<String> = ["Docker 容器", "Ollama 模型", "系统服务", "监听端口"]

    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
    ]

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                Divider().opacity(0.3)
                tabPicker
                Divider().opacity(0.3)
                mainContent
                bottomDetailPanel
                statusBar
            }
        }
        .frame(minWidth: 380, minHeight: 460)
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings)
        }
    }

    // MARK: - 顶部标题栏

    private var headerBar: some View {
        HStack {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.title3)
            Text("开发环境监测")
                .font(.headline)
            Spacer()
            Button {
                checker.refresh()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(checker.isRefreshing)
            .help("手动刷新")
            .opacity(checker.isRefreshing ? 0.4 : 1.0)
            .rotationEffect(.degrees(checker.isRefreshing ? 360 : 0))
            .animation(checker.isRefreshing
                ? Animation.linear(duration: 1).repeatForever(autoreverses: false)
                : .default, value: checker.isRefreshing)

            Button {
                openEnvGuide()
            } label: {
                Image(systemName: "book.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("环境解释")

            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("设置")

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("退出")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - 标签页切换

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(MonitorTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .onChange(of: selectedTab) { _ in
            selectedItem = nil
        }
    }

    // MARK: - 主内容区

    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case .devEnv:
            devEnvGrid
        case .host:
            hostStatusView
        case .services:
            servicesView
        }
    }

    // MARK: - 开发环境网格

    private var devEnvGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(checker.items) { item in
                    EnvCardView(
                        item: item,
                        isSelected: selectedItem == item.id,
                        onTap: {
                            selectedItem = (selectedItem == item.id) ? nil : item.id
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - 主机状态视图

    private var hostStatusView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // CPU
                hostMeterCard(
                    icon: "cpu.fill",
                    title: "CPU",
                    subtitle: "\(String(format: "%.1f", checker.hostStatus.cpuUsage))%  ·  \(checker.hostStatus.cpuCores) 核心",
                    detail: checker.hostStatus.cpuModel,
                    progress: checker.hostStatus.cpuUsage / 100.0,
                    color: cpuColor
                )

                // RAM
                hostMeterCard(
                    icon: "memorychip.fill",
                    title: "内存",
                    subtitle: "\(formatBytes(checker.hostStatus.ramUsed)) / \(formatBytes(checker.hostStatus.ramTotal))",
                    detail: "已用 \(String(format: "%.1f", checker.hostStatus.ramUsagePercent))%",
                    progress: checker.hostStatus.ramUsagePercent / 100.0,
                    color: ramColor
                )

                // 磁盘
                hostMeterCard(
                    icon: "internaldrive.fill",
                    title: "磁盘",
                    subtitle: "\(formatBytes(checker.hostStatus.diskUsed)) / \(formatBytes(checker.hostStatus.diskTotal))",
                    detail: "已用 \(String(format: "%.1f", checker.hostStatus.diskUsagePercent))%",
                    progress: checker.hostStatus.diskUsagePercent / 100.0,
                    color: diskColor
                )

                // 网速
                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.blue)
                    Text("下载")
                        .font(.caption)
                    Text(formatNetSpeed(checker.hostStatus.netDownloadSpeed))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "arrow.up")
                        .foregroundColor(.green)
                    Text("上传")
                        .font(.caption)
                    Text(formatNetSpeed(checker.hostStatus.netUploadSpeed))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))

                // 运行时间
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.secondary)
                    Text("运行时间")
                        .font(.caption)
                    Spacer()
                    Text(formatUptime(checker.hostStatus.uptime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    private func hostMeterCard(icon: String, title: String, subtitle: String, detail: String,
                                progress: Double, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(6, geo.size.width * progress), height: 6)
                }
            }
            .frame(height: 6)

            Text(detail)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.04)))
    }

    // MARK: - 运行服务视图

    private var servicesView: some View {
        let grouped = groupedServices
        return ScrollView {
            VStack(spacing: 8) {
                if grouped.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "server.rack")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("未检测到运行中的服务")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(Array(grouped.enumerated()), id: \.element.category.id) { _, group in
                        serviceSection(category: group.category, icon: group.icon, items: group.items)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private var groupedServices: [(category: ServiceCategory, icon: String, items: [ServiceItem])] {
        Dictionary(grouping: checker.serviceItems, by: { $0.category })
            .map { ($0.key, $0.key.icon, $0.value) }
            .sorted { a, b in
                let order: [ServiceCategory] = [.docker, .ollama, .systemServices, .ports]
                return (order.firstIndex(of: a.0) ?? 99) < (order.firstIndex(of: b.0) ?? 99)
            }
    }

    private func serviceSection(category: ServiceCategory, icon: String, items: [ServiceItem]) -> some View {
        let isExpanded = expandedSections.contains(category.rawValue)
        let runningCount = items.filter(\.isRunning).count

        return VStack(spacing: 0) {
            // 分类标题栏
            Button {
                if isExpanded {
                    expandedSections.remove(category.rawValue)
                } else {
                    expandedSections.insert(category.rawValue)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    Text(category.rawValue)
                        .font(.subheadline.weight(.medium))
                    Text("\(runningCount)/\(items.count) 运行中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().opacity(0.2)
                VStack(spacing: 2) {
                    ForEach(items) { item in
                        serviceRow(item)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
    }

    private func serviceRow(_ item: ServiceItem) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(item.isRunning ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 6, height: 6)

            Text(item.name)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            if !item.detail.isEmpty {
                Text(item.detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            if !item.extraInfo.isEmpty {
                Text(item.extraInfo)
                    .font(.caption2)
                    .foregroundColor(item.isRunning ? .secondary : .orange)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    // MARK: - 底部详情面板

    @ViewBuilder
    private var bottomDetailPanel: some View {
        if let itemId = selectedItem,
           let item = checker.items.first(where: { $0.id == itemId }) {
            Divider().opacity(0.3)
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: item.icon)
                    if let url = item.website {
                        Button {
                            NSWorkspace.shared.open(url)
                        } label: {
                            Text(item.name)
                                .font(.subheadline.weight(.medium))
                                .underline()
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(item.name)
                            .font(.subheadline.weight(.medium))
                    }

                    Text(item.status.label)
                        .font(.caption2)
                        .foregroundColor(item.status.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(item.status.color.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()

                    Button {
                        selectedItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                if !item.detail.isEmpty {
                    HStack {
                        Text(item.detail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        Spacer()
                    }
                }

                if !item.version.isEmpty {
                    HStack {
                        Text("版本: \(item.version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - 底部状态栏

    private var statusBar: some View {
        HStack {
            if checker.isRefreshing {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 12, height: 12)
                Text("检测中...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let last = checker.lastUpdate {
                Text("上次刷新: \(last, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("共 \(checker.items.count) 项")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    // MARK: - 打开环境解释页面

    private func openEnvGuide() {
        if let url = Bundle.main.url(forResource: "env_guide", withExtension: "html") {
            NSWorkspace.shared.open(url)
            return
        }
        if let exeURL = Bundle.main.executableURL {
            let candidates = [
                exeURL.deletingLastPathComponent().appendingPathComponent("env_guide.html"),
                exeURL.deletingLastPathComponent().appendingPathComponent("../Resources/env_guide.html"),
            ]
            for url in candidates {
                if FileManager.default.fileExists(atPath: url.path) {
                    NSWorkspace.shared.open(url)
                    return
                }
            }
        }
    }

    // MARK: - 工具方法

    private var cpuColor: Color {
        let u = checker.hostStatus.cpuUsage
        if u < 30 { return .green }
        if u < 70 { return .orange }
        return .red
    }

    private var ramColor: Color {
        let u = checker.hostStatus.ramUsagePercent
        if u < 50 { return .green }
        if u < 80 { return .orange }
        return .red
    }

    private var diskColor: Color {
        let u = checker.hostStatus.diskUsagePercent
        if u < 50 { return .green }
        if u < 80 { return .orange }
        return .red
    }

    private func formatNetSpeed(_ bytesPerSec: UInt64) -> String {
        if bytesPerSec == 0 { return "--" }
        if bytesPerSec >= 1_000_000 { return String(format: "%.1f MB/s", Double(bytesPerSec) / 1_000_000) }
        if bytesPerSec >= 1_000 { return String(format: "%.0f KB/s", Double(bytesPerSec) / 1_000) }
        return "\(bytesPerSec) B/s"
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        if bytes == 0 { return "--" }
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }

    private func formatUptime(_ interval: TimeInterval) -> String {
        if interval <= 0 { return "--" }
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let mins = (Int(interval) % 3600) / 60
        if days > 0 { return "\(days) 天 \(hours) 小时" }
        if hours > 0 { return "\(hours) 小时 \(mins) 分钟" }
        return "\(mins) 分钟"
    }
}

// MARK: - 毛玻璃视觉效果

private struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
