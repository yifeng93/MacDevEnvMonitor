import SwiftUI

/// 开发环境监测看板 — 主入口
///
/// 轻量级 macOS 桌面应用，实时显示常用开发工具的安装状态和版本信息。
/// 窗口支持置顶、半透明毛玻璃背景，手动刷新或定时自动刷新。
@main
struct EnvMonitorApp: App {
    @StateObject private var checker = EnvChecker()
    @AppStorage("refreshInterval") private var refreshInterval: Double = 30
    @AppStorage("alwaysOnTop") private var alwaysOnTop: Bool = true

    var body: some Scene {
        WindowGroup {
            ContentView(checker: checker, alwaysOnTop: $alwaysOnTop)
                .onAppear { checker.refresh() }
                .onReceive(
                    Timer.publish(every: refreshInterval, on: .main, in: .common).autoconnect()
                ) { _ in checker.refresh() }
        }
        .windowStyle(.hiddenTitleBar)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}
