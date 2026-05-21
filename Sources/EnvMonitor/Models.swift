import SwiftUI

// MARK: - 环境项状态枚举
enum EnvStatus: String, CaseIterable {
    case installed
    case notInstalled
    case serviceNotRunning
    case unknown

    var icon: String {
        switch self {
        case .installed:         return "checkmark.circle.fill"
        case .notInstalled:      return "xmark.circle.fill"
        case .serviceNotRunning: return "exclamationmark.triangle.fill"
        case .unknown:           return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .installed:         return .green
        case .notInstalled:      return .red
        case .serviceNotRunning: return .orange
        case .unknown:           return .secondary
        }
    }

    var label: String {
        switch self {
        case .installed:         return "已安装"
        case .notInstalled:      return "未安装"
        case .serviceNotRunning: return "服务未运行"
        case .unknown:           return "检测中..."
        }
    }
}

// MARK: - 主机状态数据模型
struct HostStatus {
    var cpuUsage: Double = 0
    var cpuCores: Int = 0
    var cpuModel: String = ""
    var ramUsed: UInt64 = 0
    var ramTotal: UInt64 = 0
    var ramUsagePercent: Double = 0
    var diskTotal: UInt64 = 0
    var diskUsed: UInt64 = 0
    var diskUsagePercent: Double = 0
    var netDownloadSpeed: UInt64 = 0
    var netUploadSpeed: UInt64 = 0
    var uptime: TimeInterval = 0
}

// MARK: - 单个环境项数据模型
struct EnvItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let website: URL?
    var status: EnvStatus = .unknown
    var version: String = ""
    var detail: String = ""
}

// MARK: - 运行服务监测模型

enum ServiceCategory: String, CaseIterable, Identifiable {
    case docker = "Docker 容器"
    case ollama = "Ollama 模型"
    case systemServices = "系统服务"
    case ports = "监听端口"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .docker:         return "shippingbox.fill"
        case .ollama:         return "brain.head.profile"
        case .systemServices: return "gearshape.2.fill"
        case .ports:          return "network"
        }
    }
}

struct ServiceItem: Identifiable {
    let id = UUID()
    let name: String
    let category: ServiceCategory
    var isRunning: Bool = false
    var detail: String = ""
    var extraInfo: String = ""
}

