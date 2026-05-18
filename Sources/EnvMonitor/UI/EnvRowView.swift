import SwiftUI

// MARK: - 单个环境项卡片视图（3 列网格用）

struct EnvCardView: View {
    let item: EnvItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // 工具图标
                Image(systemName: item.icon)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(height: 24)

                // 名称 + 状态图标
                HStack(spacing: 3) {
                    Text(item.name)
                        .font(.caption)
                        .lineLimit(1)
                    Image(systemName: item.status.icon)
                        .font(.caption2)
                        .foregroundColor(item.status.color)
                }

                // 版本号
                if !item.version.isEmpty {
                    Text(item.version)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
