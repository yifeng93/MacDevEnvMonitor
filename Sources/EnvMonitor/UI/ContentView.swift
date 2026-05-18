import SwiftUI
import AppKit

// MARK: - 主内容视图

struct ContentView: View {
    @ObservedObject var checker: EnvChecker
    @Binding var alwaysOnTop: Bool
    @State private var showSettings = false
    @State private var windowRef: NSWindow?

    var body: some View {
        ZStack {
            // 毛玻璃半透明背景
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                Divider().opacity(0.3)
                envItemList
                statusBar
            }
        }
        .frame(minWidth: 350, minHeight: 420)
        // 捕获 NSWindow 引用以支持置顶切换
        .background(WindowAccessor { window in
            guard let w = window else { return }
            if windowRef == nil {
                windowRef = w
                w.title = "开发环境监测"
                w.titlebarAppearsTransparent = true
                w.isMovableByWindowBackground = true
                w.level = alwaysOnTop ? .floating : .normal
                w.collectionBehavior = [.canJoinAllSpaces, .stationary]
                w.setContentSize(NSSize(width: 420, height: 560))
                w.minSize = NSSize(width: 320, height: 380)
            }
        })
        .onChange(of: alwaysOnTop) { newValue in
            windowRef?.level = newValue ? .floating : .normal
        }
        // 设置弹出窗口
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
            // 刷新按钮
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

            // 环境解释按钮
            Button {
                openEnvGuide()
            } label: {
                Image(systemName: "book.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("环境解释")

            // 设置按钮
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
        .padding(.vertical, 12)
    }

    // MARK: - 环境项列表

    private var envItemList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(checker.items) { item in
                    EnvRowView(item: item)
                    Divider().opacity(0.15).padding(.leading, 40)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - 打开环境解释页面

    private func openEnvGuide() {
        // 优先从 Bundle Resources 读取
        if let url = Bundle.main.url(forResource: "env_guide", withExtension: "html") {
            NSWorkspace.shared.open(url)
            return
        }
        // 开发模式回退：在可执行文件同级或上级目录查找
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

// MARK: - 毛玻璃视觉效果（NSVisualEffectView 包装）

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
