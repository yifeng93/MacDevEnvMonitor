# 开发环境监测看板 (EnvMonitor)

轻量级 macOS 桌面看板，实时显示常用开发工具的安装状态和版本信息。

## 功能

- 检测 10 项开发环境：Homebrew、Node.js、Python3、Git、Java、Docker、Xcode CLT、VS Code、Shell、macOS
- 状态图标：✅ 已安装 / ⚠️ 未安装 / ❌ 服务未运行
- 半透明毛玻璃背景，窗口可置顶悬浮
- 手动刷新 + 定时自动刷新（可配置间隔）
- 点击工具行打开对应官网
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
4. 首次打开时，由于 app 未签名，请右键点击 → **打开**（或到 **系统设置 → 隐私与安全性** 中允许运行）

> 本项目已自带编译好的 DMG 安装包，无需手动编译即可使用。

## 编译

### 方式一：命令行编译

```bash
# 给编译脚本执行权限
chmod +x build.sh

# 编译（生成 .app Bundle）
./build.sh
```

编译完成后，`EnvMonitor.app` 会出现在项目目录下。

### 方式二：Xcode 编译

1. 打开 Xcode，选择 **File → New → Project → macOS → App**
2. 将 `Sources/EnvMonitor/` 下的所有 `.swift` 文件拖入项目
3. 设置 **Architectures** 为 `arm64`
4. 设置 **Deployment Target** 为 `macOS 11.0`
5. 将 `Info.plist` 合并到项目的 Info 设置中
6. **Product → Run** (Cmd+R)

### 方式三：swiftc 单文件编译（若合并为单文件）

```bash
swiftc -target arm64-apple-macos11 \
  -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -framework SwiftUI -framework AppKit -framework Combine \
  -o EnvMonitor main.swift
```

## 运行

```bash
# 打开编译好的 App Bundle
open EnvMonitor.app

# 或直接运行二进制
./EnvMonitor
```

## 项目结构

```
EnvMonitor/
├── Sources/EnvMonitor/
│   ├── EnvMonitorApp.swift    # @main 入口，窗口配置
│   ├── Models.swift           # 数据模型（EnvItem, EnvStatus）
│   ├── EnvChecker.swift       # 检测逻辑（Process 执行命令）
│   └── UI/
│       ├── ContentView.swift  # 主界面（列表 + 工具栏 + 状态栏）
│       ├── EnvRowView.swift   # 单个环境项行视图
│       └── SettingsView.swift # 设置面板（刷新间隔、置顶）
├── Info.plist                 # App Bundle 配置
├── build.sh                   # 命令行编译脚本
└── README.md
```

## 扩展新检测项

在 `EnvChecker.swift` 的 `collectAll()` 方法中添加新条目，参考现有模式：

```swift
private func checkMyTool() -> EnvItem {
    var item = EnvItem(name: "MyTool", icon: "star.fill",
                       website: URL(string: "https://example.com"))
    guard which("mytool") else { item.status = .notInstalled; return item }
    item.status = .installed
    item.version = exec("mytool", "--version")
    return item
}
```

然后将 `checkMyTool()` 加入 `collectAll()` 返回数组中即可。

## 技术实现

- **SwiftUI + AppKit**：纯原生 macOS 实现，无第三方依赖
- **Process API**：通过 `Process` 执行 shell 命令，只读检测
- **NSVisualEffectView**：实现半透明毛玻璃窗口背景
- **Timer + Combine**：定时自动刷新
- **@AppStorage**：用户配置持久化（UserDefaults）
- **NSWindow.level**：窗口置顶控制
