import SwiftUI
import AppKit

// MARK: - 标签页枚举

private enum MonitorTab: String, CaseIterable {
    case devEnv = "开发环境"
    case host = "主机状态"
}

// MARK: - 主内容视图

struct ContentView: View {
    @ObservedObject var checker: EnvChecker
    @Binding var alwaysOnTop: Bool
    @State private var showSettings = false
    @State private var windowRef: NSWindow?
    @State private var selectedTab: MonitorTab = .devEnv
    @State private var selectedItem: EnvItem.ID?

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
        .background(WindowAccessor { window in
            guard let w = window else { return }
            if windowRef == nil {
                windowRef = w
                w.title = "开发环境监测"
                w.titlebarAppearsTransparent = true
                w.isMovableByWindowBackground = true
                w.level = alwaysOnTop ? .floating : .normal
                w.collectionBehavior = [.canJoinAllSpaces, .stationary]
                w.setContentSize(NSSize(width: 480, height: 600))
                w.minSize = NSSize(width: 360, height: 420)
            }
        })
        .onChange(of: alwaysOnTop) { newValue in
            windowRef?.level = newValue ? .floating : .normal
        }
        .popover(isPresented: $showSettings, arrowEdge: .trailing) {
            SettingsView(alwaysOnTop: $alwaysOnTop)
        }
    }

    // MARK: - 顶部标题栏

    private var headerBar: some View {
        HStack {
            Image(systemName: "macbook.and.iphone")
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
            .help("手动刷新 (Cmd+R)")
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - 标签页切换

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(MonitorTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
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

    // MARK: - 底部详情面板

    @ViewBuilder
    private var bottomDetailPanel: some View {
        if let itemId = selectedItem,
           let item = checker.items.first(where: { $0.id == itemId }) {
            Divider().opacity(0.3)
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: item.icon)
                    // 可点击的名称 → 打开官网
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

                    // 状态标签
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
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
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

// MARK: - NSWindow 引用捕获器

private struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { self.callback(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
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
