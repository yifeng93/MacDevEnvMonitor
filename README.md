# 开发环境监测看板 (EnvMonitor)

轻量级 macOS 桌面看板，实时显示开发工具安装状态 + 主机资源用量。

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

- 半透明毛玻璃背景，窗口可置顶悬浮
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

## 编译

```bash
chmod +x build.sh
./build.sh
```

编译完成后，`EnvMonitor.app` 和 `EnvMonitor.dmg` 会出现在项目目录下。

### Xcode 编译

1. 打开 Xcode，选择 **File → New → Project → macOS → App**
2. 将 `Sources/EnvMonitor/` 下的所有 `.swift` 文件拖入项目
3. 设置 **Architectures** 为 `arm64`
4. 设置 **Deployment Target** 为 `macOS 11.0`
5. 将 `Info.plist` 合并到项目的 Info 设置中
6. **Product → Run** (Cmd+R)

## 运行

```bash
open EnvMonitor.app
```

## 项目结构

```
EnvMonitor/
├── Sources/EnvMonitor/
│   ├── EnvMonitorApp.swift    # @main 入口，窗口 + 定时刷新
│   ├── Models.swift           # 数据模型（EnvItem, EnvStatus, HostStatus）
│   ├── EnvChecker.swift       # 检测逻辑（开发环境 + 主机状态）
│   ├── Resources/
│   │   └── env_guide.html     # 环境说明页面
│   └── UI/
│       ├── ContentView.swift  # 主界面（标签页 + 网格 + 详情面板 + 状态栏）
│       ├── EnvRowView.swift   # 环境项卡片组件（EnvCardView）
│       └── SettingsView.swift # 设置面板（刷新间隔、置顶）
├── Info.plist                 # App Bundle 配置
├── build.sh                   # 命令行编译脚本
└── README.md
```

## 技术实现

- **SwiftUI + AppKit**：纯原生 macOS 实现，无第三方依赖
- **Process API**：通过 `Process` 执行 shell 命令，只读检测
- **NSVisualEffectView**：实现半透明毛玻璃窗口背景
- **Timer + Combine**：定时自动刷新
- **@AppStorage**：用户配置持久化（UserDefaults）
- **NSWindow.level**：窗口置顶控制
- **host_statistics / sysctl / vm_stat**：主机 CPU、内存、磁盘用量采集
