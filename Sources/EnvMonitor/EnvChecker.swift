import Foundation

/// 环境检测器：通过 Process 执行 shell 命令检测各开发工具的安装状态和版本。
/// 所有检测为只读操作，不修改系统文件或配置。
class EnvChecker: ObservableObject {
    @Published var items: [EnvItem] = []
    @Published var hostStatus = HostStatus()
    @Published var serviceItems: [ServiceItem] = []
    @Published var isRefreshing = false
    @Published var lastUpdate: Date?

    private let searchPath = "/opt/homebrew/bin:/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    private let fm = FileManager.default

    // 网速采样：前次读数 + 时间戳，用于计算速率
    private var prevNetRxBytes: UInt64 = 0
    private var prevNetTxBytes: UInt64 = 0
    private var prevNetSampleTime: Date?

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
    ]

    // MARK: - 公开入口

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let results = self.collectAll()
            let status = self.collectHostStatus()
            let services = self.collectAllServices()
            DispatchQueue.main.async {
                self.items = results
                self.hostStatus = status
                self.serviceItems = services
                self.lastUpdate = Date()
                self.isRefreshing = false
            }
        }
    }

    // MARK: - 全量检测（24 项）

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
            checkOllama(),
            // ---- 编辑器 & 终端 ----
            checkVSCode(),
            checkCursor(),
            checkITerm2(),
            checkOhMyZsh(),
            // ---- 系统 ----
            checkXcodeCLT(),
            checkShell(),
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

    private func checkOllama() -> EnvItem {
        var item = EnvItem(name: "Ollama", icon: "brain.head.profile",
                           website: URL(string: "https://ollama.com"))
        guard which("ollama") else { item.status = .notInstalled; return item }
        item.version = exec("ollama", "--version")
        item.detail = whichPath("ollama")
        // 检查 ollama 服务是否在运行
        let (_, code) = run("pgrep", "-f", "ollama serve")
        if code != 0 {
            item.status = .serviceNotRunning
        } else {
            item.status = .installed
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

    // ============================================================
    // MARK: 主机状态
    // ============================================================

    private func collectHostStatus() -> HostStatus {
        var status = HostStatus()

        // CPU 核心数与型号
        let cpuCores = exec("sysctl", "-n", "hw.ncpu")
        status.cpuCores = Int(cpuCores) ?? 0
        status.cpuModel = exec("sysctl", "-n", "machdep.cpu.brand_string")

        // CPU 使用率（通过 top 采样）
        let topOutput = exec("top", "-l", "1", "-n", "0")
        for line in topOutput.split(separator: "\n") where line.contains("CPU usage") {
            let parts = line.split(separator: " ")
            if let idleIdx = parts.firstIndex(where: { $0 == "idle" }), idleIdx > 0 {
                let idleStr = parts[idleIdx - 1].replacingOccurrences(of: "%", with: "")
                if let idle = Double(idleStr) {
                    status.cpuUsage = min(100, max(0, 100.0 - idle))
                }
            }
            break
        }

        // 内存：总量
        let memSizeStr = exec("sysctl", "-n", "hw.memsize")
        status.ramTotal = UInt64(memSizeStr) ?? 0

        // 内存：已用（通过 vm_stat 计算）
        let vmStat = exec("vm_stat")
        var pageSize: UInt64 = 16384
        var usedPages: Int64 = 0
        if let psLine = vmStat.split(separator: "\n").first(where: { $0.contains("page size") }),
           let ps = extractNumber(from: String(psLine)) {
            pageSize = UInt64(ps)
        }
        for line in vmStat.split(separator: "\n") {
            let s = String(line)
            if s.contains("Pages active") || s.contains("Pages wired") || s.contains("Pages occupied") {
                if let n = extractNumber(from: s) { usedPages += n }
            }
        }
        status.ramUsed = UInt64(max(0, usedPages)) * pageSize
        if status.ramTotal > 0 {
            status.ramUsagePercent = Double(status.ramUsed) / Double(status.ramTotal) * 100
        }

        // 磁盘（根分区）
        // APFS 的 "Used" 列只统计当前卷独占数据，不反映容器内其他卷和快照的占用。
        // 用 Total - Available 才能得到真实的磁盘已用空间。
        let dfOut = exec("/bin/df", "-g", "/")
        let dfLines = dfOut.split(separator: "\n")
        if dfLines.count >= 2 {
            let cols = dfLines[1].split(separator: " ", omittingEmptySubsequences: true)
            if cols.count >= 4 {
                let totalBlocks = UInt64(cols[1]) ?? 0
                let availBlocks = UInt64(cols[3]) ?? 0
                status.diskTotal = totalBlocks * 1_073_741_824
                status.diskUsed  = (totalBlocks - availBlocks) * 1_073_741_824
                if status.diskTotal > 0 {
                    status.diskUsagePercent = Double(status.diskUsed) / Double(status.diskTotal) * 100
                }
            }
        }

        // 网速：通过 netstat -ibn 读取主网口的收发字节，两次采样间计算速率
        let now = Date()
        let defaultIface = findDefaultInterface()
        let (rx, tx) = readNetBytes(iface: defaultIface)
        if let prevTime = prevNetSampleTime, rx >= prevNetRxBytes, tx >= prevNetTxBytes {
            let dt = now.timeIntervalSince(prevTime)
            if dt > 0 {
                status.netDownloadSpeed = UInt64(Double(rx - prevNetRxBytes) / dt)
                status.netUploadSpeed   = UInt64(Double(tx - prevNetTxBytes) / dt)
            }
        }
        prevNetRxBytes = rx
        prevNetTxBytes = tx
        prevNetSampleTime = now

        // 运行时间
        let bootTimeStr = exec("sysctl", "-n", "kern.boottime")
        // 格式: { sec = 1234567890, ... }
        if let eqIdx = bootTimeStr.firstIndex(of: "=") {
            let after = bootTimeStr[bootTimeStr.index(after: eqIdx)...]
            let numStr = after.trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(while: { $0.isNumber || $0 == "." })
            if let bootSec = TimeInterval(numStr) {
                status.uptime = Date().timeIntervalSince1970 - bootSec
            }
        }

        return status
    }

    private func extractNumber(from text: String) -> Int64? {
        // 找到字符串中最后一个数字（可能带负号）
        let parts = text.split(separator: ":", omittingEmptySubsequences: true)
        guard let last = parts.last else { return nil }
        let cleaned = last.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ".", with: "")
        return Int64(cleaned)
    }

    // MARK: - 网速采样

    /// 查找默认路由对应的网络接口名（如 en0）
    private func findDefaultInterface() -> String {
        let out = exec("/sbin/route", "-n", "get", "default")
        for line in out.split(separator: "\n") where line.contains("interface:") {
            return line.replacingOccurrences(of: "interface:", with: "")
                       .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "en0" // 回退到 WiFi
    }

    /// 从 netstat -ibn 输出中读取指定网口的收发字节总数
    private func readNetBytes(iface: String) -> (rx: UInt64, tx: UInt64) {
        let out = exec("/usr/sbin/netstat", "-ibn")
        for line in out.split(separator: "\n") {
            let s = line.trimmingCharacters(in: .whitespaces)
            // 精确匹配网口名（避免 en1 误匹配 en10）；只取链路层行（含 <Link#N>）
            guard s.hasPrefix(iface + " ") || s.hasPrefix(iface + "\t"),
                  s.contains("<Link") else { continue }
            let cols = s.split(separator: " ", omittingEmptySubsequences: true)
            // 列数不同：有 MAC 地址时 11 列，无 MAC 时 10 列（如 lo0）
            // 格式: Name Mtu Network [Address] Ipkts Ierrs Ibytes Opkts Oerrs Obytes Coll
            let rxIdx = cols.count >= 11 ? 6 : 5
            let txIdx = cols.count >= 11 ? 9 : 8
            if cols.count > max(rxIdx, txIdx) {
                let rx = UInt64(cols[rxIdx]) ?? 0
                let tx = UInt64(cols[txIdx]) ?? 0
                return (rx, tx)
            }
        }
        return (0, 0)
    }

    // ============================================================
    // MARK: 运行服务监测
    // ============================================================

    private func collectAllServices() -> [ServiceItem] {
        var items: [ServiceItem] = []
        items.append(contentsOf: checkDockerContainers())
        items.append(contentsOf: checkOllamaServices())
        items.append(contentsOf: checkSystemServices())
        items.append(contentsOf: checkListeningPorts())
        return items
    }

    /// Docker 容器列表
    private func checkDockerContainers() -> [ServiceItem] {
        guard which("docker") else { return [] }
        let (output, code) = run("docker", "ps", "--format", "{{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.Ports}}")
        guard code == 0, !output.isEmpty else { return [] }
        var items: [ServiceItem] = []
        for line in output.split(separator: "\n") {
            let cols = line.split(separator: "\t", omittingEmptySubsequences: true)
            guard cols.count >= 1 else { continue }
            let name = String(cols[0])
            let image = cols.count >= 2 ? String(cols[1]) : ""
            let status = cols.count >= 3 ? String(cols[2]) : ""
            let ports = cols.count >= 4 ? String(cols[3]) : ""
            let isRunning = status.hasPrefix("Up")
            var detail = image
            if !ports.isEmpty { detail += "  ·  \(ports)" }
            var item = ServiceItem(name: name, category: .docker, isRunning: isRunning, detail: detail)
            item.extraInfo = status
            items.append(item)
        }
        return items
    }

    /// Ollama 模型状态
    private func checkOllamaServices() -> [ServiceItem] {
        guard which("ollama") else { return [] }
        var items: [ServiceItem] = []

        // 获取所有已下载模型
        let listOut = exec("ollama", "list")
        var allModels: [(name: String, size: String)] = []
        for line in listOut.split(separator: "\n").dropFirst() { // 跳过表头
            let cols = line.split(separator: " ", omittingEmptySubsequences: true)
            if let first = cols.first {
                let modelName = String(first)
                let size = cols.count >= 3 ? String(cols[2]) : ""
                // 如果 size 旁边还有单位
                let fullSize = cols.count >= 4 ? size + " " + String(cols[3]) : size
                allModels.append((modelName, fullSize))
            }
        }

        // 获取当前加载的模型
        let psOut = exec("ollama", "ps")
        var loadedModels: Set<String> = []
        for line in psOut.split(separator: "\n").dropFirst() {
            if let first = line.split(separator: " ", omittingEmptySubsequences: true).first {
                loadedModels.insert(String(first))
            }
        }

        for model in allModels {
            let isLoaded = loadedModels.contains(model.name)
            var item = ServiceItem(
                name: model.name,
                category: .ollama,
                isRunning: isLoaded,
                detail: model.size
            )
            item.extraInfo = isLoaded ? "已加载到内存" : "已下载，未加载"
            items.append(item)
        }

        // 如果没有通过 ollama list 获取到模型，检查 ps
        if items.isEmpty {
            for line in psOut.split(separator: "\n").dropFirst() {
                let cols = line.split(separator: " ", omittingEmptySubsequences: true)
                if let first = cols.first {
                    let size = cols.count >= 3 ? String(cols[2]) + (cols.count >= 4 ? " " + String(cols[3]) : "") : ""
                    var item = ServiceItem(
                        name: String(first),
                        category: .ollama,
                        isRunning: true,
                        detail: size
                    )
                    item.extraInfo = "已加载到内存"
                    items.append(item)
                }
            }
        }

        return items
    }

    /// 常见系统后台服务
    private func checkSystemServices() -> [ServiceItem] {
        let services: [(name: String, processName: String, versionArgs: [String])] = [
            ("Nginx", "nginx", ["-v"]),
            ("Apache HTTPD", "httpd", ["-v"]),
            ("MySQL", "mysqld", ["--version"]),
            ("MariaDB", "mariadbd", ["--version"]),
            ("PostgreSQL", "postgres", ["--version"]),
            ("Redis", "redis-server", ["--version"]),
            ("MongoDB", "mongod", ["--version"]),
            ("RabbitMQ", "rabbitmq-server", []),
            ("Jenkins", "jenkins", ["--version"]),
            ("Grafana", "grafana-server", ["-v"]),
            ("Prometheus", "prometheus", ["--version"]),
        ]

        var items: [ServiceItem] = []
        for svc in services {
            var item = ServiceItem(name: svc.name, category: .systemServices)
            let processes = exec("pgrep", "-fl", svc.processName)
            if !processes.isEmpty {
                item.isRunning = true
                // 尝试获取版本
                if !svc.versionArgs.isEmpty {
                    let result = runArgs([svc.processName] + svc.versionArgs)
                    let ver = result.0.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !ver.isEmpty {
                        // 许多服务的版本输出到 stderr，截取第一行
                        item.detail = ver.split(separator: "\n").first.map(String.init) ?? ""
                    }
                }
                // 提取 PID
                let firstLine = processes.split(separator: "\n").first ?? ""
                let firstCol = firstLine.split(separator: " ", omittingEmptySubsequences: true).first ?? ""
                item.extraInfo = "PID: \(firstCol)"
            } else {
                item.isRunning = false
                item.extraInfo = "未运行"
            }
            items.append(item)
        }
        return items
    }

    /// 监听 TCP 端口
    private func checkListeningPorts() -> [ServiceItem] {
        let out = exec("/usr/sbin/lsof", "-iTCP", "-sTCP:LISTEN", "-nP")
        var items: [ServiceItem] = []
        var seen = Set<String>() // 去重: 进程名+端口

        for line in out.split(separator: "\n").dropFirst() {
            let cols = line.split(separator: " ", omittingEmptySubsequences: true)
            // 格式: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
            // 索引:  0       1   2    3  4    5      6        7    8
            guard cols.count >= 9 else { continue }
            let process = String(cols[0])
            let pid = String(cols[1])
            let nameField = String(cols[8])

            // 过滤掉 macOS 系统服务端口
            let systemProcesses: Set<String> = [
                "rapportd", "ControlCe", "sharingd", "remoted", "ARDAgent",
                "corecdn", "sysmond", "WiFiAgent", "nfsd", "rpc.statd",
                "SystemUIS", "UserEvent", "univers", "netbiosd", "ocspd", "trustd"
            ]
            guard !systemProcesses.contains(process) else { continue }

            // 提取端口号
            guard let portRange = nameField.split(separator: ":").last,
                  let _ = Int(portRange) else { continue }

            let port = String(portRange)
            let key = "\(process):\(port)"
            if seen.contains(key) { continue }
            seen.insert(key)

            let isDevPort = isCommonDevPort(port)
            var item = ServiceItem(
                name: ":\(port)",
                category: .ports,
                isRunning: true,
                detail: process
            )
            item.extraInfo = "PID: \(pid)" + (isDevPort ? "  ·  开发端口" : "")
            items.append(item)
        }

        // 按端口号排序
        items.sort { a, b in
            let pa = Int(a.name.dropFirst()) ?? 0
            let pb = Int(b.name.dropFirst()) ?? 0
            return pa < pb
        }
        return items
    }

    private func isCommonDevPort(_ port: String) -> Bool {
        let devPorts: Set<String> = [
            "3000", "3001", "4200", "5000", "5173", "8000", "8080", "8888", "9000",
            "3306", "5432", "6379", "27017", "11434",
            "9090", "9092", "15672", "5672", "9200", "5601",
        ]
        return devPorts.contains(port)
    }

    // ============================================================
    // MARK: Shell 命令执行 (已有)
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
