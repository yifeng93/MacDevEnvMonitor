import SwiftUI
import AppKit

// MARK: - App 入口（Menu Bar 模式）

@main
struct EnvMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

// MARK: - AppDelegate：状态栏 + Popover

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var checker = EnvChecker()
    private var refreshTimer: Timer?
    private var popoverShown = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        startRefreshTimer()
        checker.refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showPopover()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
    }

    // MARK: - 状态栏按钮

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "chart.bar.doc.horizontal",
                accessibilityDescription: "开发环境监测"
            )
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    @objc private func togglePopover() {
        if popoverShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 480, height: 640)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: ContentView(checker: checker)
                .frame(minWidth: 460, minHeight: 560)
        )
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        popoverShown = true
    }

    private func closePopover() {
        popover.performClose(nil)
        popoverShown = false
    }

    // MARK: - 定时刷新

    private func startRefreshTimer() {
        let interval = UserDefaults.standard.double(forKey: "refreshInterval")
        let sec = interval > 0 ? interval : 30
        refreshTimer = Timer.scheduledTimer(withTimeInterval: sec, repeats: true) { [weak self] _ in
            self?.checker.refresh()
            let current = UserDefaults.standard.double(forKey: "refreshInterval")
            if current > 0, let timer = self?.refreshTimer, abs(current - timer.timeInterval) > 1 {
                self?.restartRefreshTimer(interval: current)
            }
        }
        if let timer = refreshTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    private func restartRefreshTimer(interval: Double) {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checker.refresh()
        }
        if let timer = refreshTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
}

// MARK: - NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        popoverShown = false
    }
}
