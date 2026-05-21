# 开发环境监测看板 (EnvMonitor)

轻量级 macOS 状态栏看板，实时显示开发工具安装状态 + 主机资源用量 + 运行服务状态。点击右上角图标弹出面板，不占桌面空间。

## 功能

### 开发环境监测（24 项）

卡片式网格布局，点击卡片在底部展开详情（路径、版本），点击名称打开官网。

| 类别 | 检测项 |
|---|---|
| 包管理器 | Homebrew、nvm、pnpm、Yarn |
| 语言运行时 | Node.js、Bun、Python3、Ruby、Go、Rust、Java |
| 开发工具 | Git、TypeScript、Vite、ESLint、Prettier |
| 容器 | Docker、Ollama |
| 编辑器 & 终端 | VS Code、Cursor、iTerm2、Oh My Zsh |
| 系统 | Xcode CLT、Shell |

状态图标：✅ 已安装 / ❌ 未安装 / ⚠️ 服务未运行

### 主机状态监测

| 指标 | 说明 |
|---|---|
| CPU | 使用率 + 核心数 + 型号，进度条颜色自动变化 |
| 内存 | 已用/总量 + 使用率进度条 |
| 磁盘 | 已用/总量 + 使用率进度条（APFS 真实占用） |
| 网速 | 实时上传/下载速率 |
| 运行时间 | 距离上次开机已过多久 |

### 运行服务监测（新增）

| 类别 | 说明 | 检测方式 |
|---|---|---|
| Docker 容器 | 运行中容器名、镜像、状态、端口映射 | `docker ps` |
| Ollama 模型 | 已下载模型 + 当前加载到内存的模型 | `ollama list` + `ollama ps` |
| 系统服务 | nginx、mysql、postgres、redis、mongod 等 11 项 | `pgrep` 逐项检查 |
| 监听端口 | 所有 TCP LISTEN 端口，标记常见开发端口 | `lsof -iTCP` |

每组可折叠展开，显示运行中/总数统计，绿色圆点=运行中，灰色=未运行。

---

- **Menu Bar 状态栏模式**：驻留在 macOS 右上角，点击图标弹出面板，点击外部自动关闭
- 半透明毛玻璃背景
- 手动刷新 + 定时自动刷新（可配置 15s ~ 5min）
- 只读检测，不修改任何系统文件

## 系统要求

- macOS 11.0 (Big Sur) 及以上
- Apple Silicon (M 系列芯片) — ARM64 原生
- Xcode Command Line Tools（编译时需要）

## 安装

### 直接下载 DMG 安装包

1. 从本仓库下载 [EnvMonitor.dmg](./EnvMonitor.dmg)
2. 双击打开 `.dmg` 文件
3. 将 `EnvMonitor.app` 拖入 `应用程序` 文件夹
4. 首次打开时，右键点击 → **打开**（或到 **系统设置 → 隐私与安全性** 中允许运行）

> 本项目已自带编译好的 DMG 安装包，无需手动编译即可使用。
>
> 启动后 App 会出现在右上角状态栏（无 Dock 图标），点击图标即可弹出面板。如需退出，点击面板右上角的 X 按钮。

## 编译

```bash
chmod +x build.sh
./build.sh
```

编译完成后，`EnvMonitor.app` 和 `EnvMonitor.dmg` 会出现在项目目录下。

## 项目结构

```
EnvMonitor/
├── Sources/EnvMonitor/
│   ├── EnvMonitorApp.swift    # @main 入口，NSStatusItem + NSPopover + 定时刷新
│   ├── Models.swift           # 数据模型（EnvItem, HostStatus, ServiceItem）
│   ├── EnvChecker.swift       # 检测逻辑（开发环境 + 主机状态 + 运行服务）
│   ├── Resources/
│   │   └── env_guide.html     # 环境说明页面
│   └── UI/
│       ├── ContentView.swift  # 主界面（标签页 + 网格 + 详情面板 + 服务列表）
│       ├── EnvRowView.swift   # 环境项卡片组件（EnvCardView）
│       └── SettingsView.swift # 设置面板（刷新间隔）
├── Info.plist                 # App Bundle 配置
├── build.sh                   # 命令行编译脚本
└── README.md
```

## 技术实现

- **SwiftUI + AppKit**：纯原生 macOS 实现，无第三方依赖
- **NSStatusItem + NSPopover**：状态栏驻留 + 弹出面板
- **Process API**：通过 `Process` 执行 shell 命令，只读检测
- **NSVisualEffectView**：实现半透明毛玻璃背景
- **Timer + RunLoop**：定时自动刷新
- **@AppStorage**：用户配置持久化（UserDefaults）
- **sysctl / vm_stat / netstat / lsof**：主机资源和服务状态采集
