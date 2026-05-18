import Foundation

/// 环境检测器：通过 Process 执行 shell 命令检测各开发工具的安装状态和版本。
/// 所有检测为只读操作，不修改系统文件或配置。
class EnvChecker: ObservableObject {
    @Published var items: [EnvItem] = []
    @Published var isRefreshing = false
    @Published var lastUpdate: Date?

    private let searchPath = "/opt/homebrew/bin:/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    private let fm = FileManager.default

    // MARK: - .app 路径定义

    private let appPaths: [String: [String]] = [
        "vscode": [
            "/Applications/Visual Studio Code.app",
            NSString("~/Applications/Visual Studio Code.app").expandingTildeInPath,
        ],
        "cursor": [
            "/Applications/Cursor.app",
            NSString("~/Applications/Cursor.app").expandingTildeInPath,
        ],
        "iterm2": [
            "/Applications/iTerm.app",
            NSString("~/Applications/iTerm.app").expandingTildeInPath,
        ],
        "chrome": [
            "/Applications/Google Chrome.app",
            NSString("~/Applications/Google Chrome.app").expandingTildeInPath,
        ],
    ]

    // MARK: - 公开入口

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let results = self.collectAll()
            DispatchQueue.main.async {
                self.items = results
                self.lastUpdate = Date()
                self.isRefreshing = false
            }
        }
    }

    // MARK: - 全量检测（25 项）

    private func collectAll() -> [EnvItem] {
        [
            // ---- 包管理器 ----
            checkHomebrew(),
            checkNvm(),
            checkPnpm(),
            checkYarn(),
            // ---- 语言运行时 ----
            checkNode(),
            checkBun(),
            checkPython(),
            checkRuby(),
            checkGo(),
            checkRust(),
            checkJava(),
            // ---- 开发工具 ----
            checkGit(),
            checkTypeScript(),
            checkVite(),
            checkESLint(),
            checkPrettier(),
            // ---- 容器 ----
            checkDocker(),
            // ---- 编辑器 & 终端 ----
            checkVSCode(),
            checkCursor(),
            checkITerm2(),
            checkOhMyZsh(),
            checkChrome(),
            // ---- 系统 ----
            checkXcodeCLT(),
            checkShell(),
            checkMacOS(),
        ]
    }

    // ============================================================
    // MARK: 包管理器
    // ============================================================

    private func checkHomebrew() -> EnvItem {
        var item = EnvItem(name: "Homebrew", icon: "mug.fill",
                           website: URL(string: "https://brew.sh"))
        guard which("brew") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("brew", "--version")
        item.detail = whichPath("brew")
        return item
    }

    private func checkNvm() -> EnvItem {
        var item = EnvItem(name: "nvm", icon: "arrow.triangle.swap",
                           website: URL(string: "https://github.com/nvm-sh/nvm"))
        let nvmDir = NSString("~/.nvm").expandingTildeInPath
        guard fm.fileExists(atPath: nvmDir) else { item.status = .notInstalled; return item }
        item.status = .installed
        item.detail = nvmDir
        let ver = exec("/bin/zsh", "-c", "source \(nvmDir)/nvm.sh 2>/dev/null && nvm --version 2>/dev/null")
        if !ver.isEmpty { item.version = "v\(ver)" } else { item.version = "已安装" }
        return item
    }

    private func checkPnpm() -> EnvItem {
        var item = EnvItem(name: "pnpm", icon: "square.stack.3d.up.fill",
                           website: URL(string: "https://pnpm.io"))
        guard which("pnpm") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("pnpm", "--version")
        item.detail = whichPath("pnpm")
        return item
    }

    private func checkYarn() -> EnvItem {
        var item = EnvItem(name: "Yarn", icon: "square.stack.fill",
                           website: URL(string: "https://yarnpkg.com"))
        guard which("yarn") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("yarn", "--version")
        item.detail = whichPath("yarn")
        return item
    }

    // ============================================================
    // MARK: 语言运行时
    // ============================================================

    private func checkNode() -> EnvItem {
        var item = EnvItem(name: "Node.js", icon: "circle.hexagongrid.fill",
                           website: URL(string: "https://nodejs.org"))
        guard which("node") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("node", "--version")
        let npmVer = exec("npm", "--version")
        var detail = whichPath("node")
        if !npmVer.isEmpty { detail += "  ·  npm \(npmVer)" }
        item.detail = detail
        return item
    }

    private func checkBun() -> EnvItem {
        var item = EnvItem(name: "Bun", icon: "flame.fill",
                           website: URL(string: "https://bun.sh"))
        guard which("bun") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("bun", "--version")
        item.detail = whichPath("bun")
        return item
    }

    private func checkPython() -> EnvItem {
        var item = EnvItem(name: "Python3", icon: "swift",
                           website: URL(string: "https://www.python.org"))
        guard which("python3") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("python3", "--version")
        let pipVer = exec("pip3", "--version")
        var detail = whichPath("python3")
        if !pipVer.isEmpty {
            let parts = pipVer.split(separator: " ")
            if parts.count >= 2 { detail += "  ·  pip3 \(parts[1])" }
        }
        item.detail = detail
        return item
    }

    private func checkRuby() -> EnvItem {
        var item = EnvItem(name: "Ruby", icon: "diamond.fill",
                           website: URL(string: "https://www.ruby-lang.org"))
        guard which("ruby") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("ruby", "--version")
        let gemVer = exec("gem", "--version")
        var detail = whichPath("ruby")
        if !gemVer.isEmpty { detail += "  ·  gem \(gemVer)" }
        item.detail = detail
        return item
    }

    private func checkGo() -> EnvItem {
        var item = EnvItem(name: "Go", icon: "circle.grid.cross.fill",
                           website: URL(string: "https://go.dev"))
        guard which("go") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("go", "version")
        item.detail = whichPath("go")
        return item
    }

    private func checkRust() -> EnvItem {
        var item = EnvItem(name: "Rust", icon: "gearshape.2.fill",
                           website: URL(string: "https://www.rust-lang.org"))
        guard which("rustc") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("rustc", "--version")
        let cargoVer = exec("cargo", "--version")
        var detail = whichPath("rustc")
        if !cargoVer.isEmpty {
            let parts = cargoVer.split(separator: " ")
            if parts.count >= 2 { detail += "  ·  cargo \(parts[1])" }
        }
        item.detail = detail
        return item
    }

    private func checkJava() -> EnvItem {
        var item = EnvItem(name: "Java", icon: "cup.and.saucer.fill",
                           website: URL(string: "https://www.java.com"))
        guard which("java") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("java", "-version")
        if let firstLine = item.version.split(separator: "\n").first {
            item.version = String(firstLine)
        }
        let javaHome = exec("/usr/libexec/java_home")
        var detail = whichPath("java")
        if !javaHome.isEmpty { detail += "\nJAVA_HOME: \(javaHome)" }
        item.detail = detail
        return item
    }

    // ============================================================
    // MARK: 开发工具
    // ============================================================

    private func checkGit() -> EnvItem {
        var item = EnvItem(name: "Git", icon: "arrow.triangle.branch",
                           website: URL(string: "https://git-scm.com"))
        guard which("git") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("git", "--version")
        item.detail = whichPath("git")
        return item
    }

    private func checkTypeScript() -> EnvItem {
        var item = EnvItem(name: "TypeScript", icon: "chevron.left.forwardslash.chevron.right",
                           website: URL(string: "https://www.typescriptlang.org"))
        guard which("tsc") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("tsc", "--version")
        item.detail = whichPath("tsc")
        return item
    }

    private func checkVite() -> EnvItem {
        var item = EnvItem(name: "Vite", icon: "bolt.fill",
                           website: URL(string: "https://vitejs.dev"))
        guard which("vite") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("vite", "--version")
        item.detail = whichPath("vite")
        return item
    }

    private func checkESLint() -> EnvItem {
        var item = EnvItem(name: "ESLint", icon: "shield.fill",
                           website: URL(string: "https://eslint.org"))
        guard which("eslint") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("eslint", "--version")
        item.detail = whichPath("eslint")
        return item
    }

    private func checkPrettier() -> EnvItem {
        var item = EnvItem(name: "Prettier", icon: "text.alignleft",
                           website: URL(string: "https://prettier.io"))
        guard which("prettier") else { item.status = .notInstalled; return item }
        item.status = .installed
        item.version = exec("prettier", "--version")
        item.detail = whichPath("prettier")
        return item
    }

    // ============================================================
    // MARK: 容器
    // ============================================================

    private func checkDocker() -> EnvItem {
        var item = EnvItem(name: "Docker", icon: "shippingbox.fill",
                           website: URL(string: "https://www.docker.com"))
        guard which("docker") else { item.status = .notInstalled; return item }
        item.version = exec("docker", "--version")
        var detail = whichPath("docker")
        let (dockerInfo, code) = run("docker", "info")
        if code != 0 {
            item.status = .serviceNotRunning
        } else {
            item.status = .installed
            for line in dockerInfo.split(separator: "\n") {
                if line.hasPrefix("Server Version:") {
                    detail += "\n\(line.trimmingCharacters(in: .whitespaces))"
                    break
                }
            }
        }
        item.detail = detail
        return item
    }

    // ============================================================
    // MARK: 编辑器 & 终端
    // ============================================================

    private func checkVSCode() -> EnvItem {
        var item = EnvItem(name: "VS Code", icon: "chevron.left.slash.chevron.right",
                           website: URL(string: "https://code.visualstudio.com"))
        // CLI 优先
        if which("code") {
            item.status = .installed
            let output = exec("code", "--version")
            if let firstLine = output.split(separator: "\n").first {
                item.version = String(firstLine)
            }
            item.detail = whichPath("code")
            return item
        }
        // 回退到 .app
        if let path = findAppBundle(in: "vscode") {
            item.status = .installed
            item.detail = path
            item.version = appVersion(at: path)
            return item
        }
        item.status = .notInstalled
        return item
    }

    private func checkCursor() -> EnvItem {
        var item = EnvItem(name: "Cursor", icon: "cursorarrow.rays",
                           website: URL(string: "https://cursor.sh"))
        if let path = findAppBundle(in: "cursor") {
            item.status = .installed
            item.detail = path
            item.version = appVersion(at: path)
        } else {
            item.status = .notInstalled
        }
        return item
    }

    private func checkITerm2() -> EnvItem {
        var item = EnvItem(name: "iTerm2", icon: "apple.terminal",
                           website: URL(string: "https://iterm2.com"))
        if let path = findAppBundle(in: "iterm2") {
            item.status = .installed
            item.detail = path
            item.version = appVersion(at: path)
        } else {
            item.status = .notInstalled
        }
        return item
    }

    private func checkOhMyZsh() -> EnvItem {
        var item = EnvItem(name: "Oh My Zsh", icon: "sparkles",
                           website: URL(string: "https://ohmyz.sh"))
        let omzDir = NSString("~/.oh-my-zsh").expandingTildeInPath
        guard fm.fileExists(atPath: omzDir) else { item.status = .notInstalled; return item }
        item.status = .installed
        item.detail = omzDir
        // 读取版本号（OMZ 模板文件中有记录）
        let versionFile = "\(omzDir)/templates/version.zsh-template"
        if fm.fileExists(atPath: versionFile),
           let content = try? String(contentsOfFile: versionFile, encoding: .utf8) {
            // 文件中通常包含 "OMZ_VERSION=..." 这类信息
            for line in content.split(separator: "\n") {
                if line.contains("OMZ") && line.contains("VERSION") {
                    item.version = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            }
        }
        if item.version.isEmpty {
            // 回退：git describe
            let ver = exec("git", "-C", omzDir, "describe", "--tags", "--abbrev=0")
            if !ver.isEmpty { item.version = ver } else { item.version = "已安装" }
        }
        return item
    }

    private func checkChrome() -> EnvItem {
        var item = EnvItem(name: "Google Chrome", icon: "globe",
                           website: URL(string: "https://www.google.com/chrome"))
        if let path = findAppBundle(in: "chrome") {
            item.status = .installed
            item.detail = path
            item.version = appVersion(at: path)
        } else {
            item.status = .notInstalled
        }
        return item
    }

    // ============================================================
    // MARK: 系统
    // ============================================================

    private func checkXcodeCLT() -> EnvItem {
        var item = EnvItem(name: "Xcode CLT", icon: "hammer.fill", website: nil)
        let (path, code) = run("xcode-select", "-p")
        guard code == 0, !path.isEmpty else { item.status = .notInstalled; return item }
        item.status = .installed
        let pkgInfo = exec("pkgutil", "--pkg-info=com.apple.pkg.CLTools_Executables")
        for line in pkgInfo.split(separator: "\n") {
            if line.hasPrefix("version:") {
                item.version = String(line).replacingOccurrences(of: "version: ", with: "")
                break
            }
        }
        if item.version.isEmpty { item.version = "已安装" }
        item.detail = path.trimmingCharacters(in: .whitespacesAndNewlines)
        return item
    }

    private func checkShell() -> EnvItem {
        var item = EnvItem(name: "Shell", icon: "terminal.fill", website: nil)
        item.status = .installed
        let shellPath = exec("printenv", "SHELL")
        item.version = shellPath
        if !shellPath.isEmpty {
            let shellVer = exec(shellPath, "--version")
            if let firstLine = shellVer.split(separator: "\n").first {
                item.detail = String(firstLine)
            }
        }
        if item.version.isEmpty { item.version = ProcessInfo.processInfo.environment["SHELL"] ?? "未知" }
        return item
    }

    private func checkMacOS() -> EnvItem {
        var item = EnvItem(name: "macOS", icon: "desktopcomputer", website: nil)
        item.status = .installed
        item.version = exec("sw_vers", "-productVersion")
        let build = exec("sw_vers", "-buildVersion")
        if !build.isEmpty { item.detail = "Build \(build)" }
        return item
    }

    // ============================================================
    // MARK: Shell 命令执行
    // ============================================================

    private func which(_ name: String) -> Bool {
        let (_, code) = run("/usr/bin/which", name)
        return code == 0
    }

    private func whichPath(_ name: String) -> String {
        let (output, code) = run("/usr/bin/which", name)
        guard code == 0 else { return "" }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func exec(_ args: String...) -> String {
        let (output, _) = runArgs(args)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func run(_ args: String...) -> (String, Int32) {
        runArgs(args)
    }

    private func runArgs(_ args: [String]) -> (String, Int32) {
        guard let first = args.first, !first.isEmpty else { return ("", -1) }
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        if first.hasPrefix("/") {
            process.executableURL = URL(fileURLWithPath: first)
            if args.count > 1 { process.arguments = Array(args.dropFirst()) }
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = args
        }

        process.standardOutput = stdout
        process.standardError = stderr

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = searchPath
        process.environment = env

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ("", -1)
        }

        let outStr = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let errStr = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (outStr + errStr, process.terminationStatus)
    }

    // ============================================================
    // MARK: .app Bundle 辅助
    // ============================================================

    /// 在预定义的路径列表中查找第一个存在的 .app Bundle
    private func findAppBundle(in key: String) -> String? {
        guard let paths = appPaths[key] else { return nil }
        for p in paths where fm.fileExists(atPath: p) {
            return p
        }
        return nil
    }

    /// 从 .app Bundle 的 Info.plist 中读取 CFBundleShortVersionString
    private func appVersion(at path: String) -> String {
        let plistPath = "\(path)/Contents/Info.plist"
        guard fm.fileExists(atPath: plistPath) else { return "已安装" }
        let ver = exec("/usr/libexec/PlistBuddy", "-c", "Print :CFBundleShortVersionString", plistPath)
        return ver.isEmpty ? "已安装" : ver
    }
}
