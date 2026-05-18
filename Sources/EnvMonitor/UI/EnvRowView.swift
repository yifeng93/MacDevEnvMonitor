import SwiftUI

// MARK: - 单个环境项行视图

struct EnvRowView: View {
    let item: EnvItem

    var body: some View {
        HStack(spacing: 10) {
            // 工具图标
            Image(systemName: item.icon)
                .frame(width: 24, height: 24)
                .foregroundColor(.primary)

            // 工具名称
            Text(item.name)
                .font(.body)
                .lineLimit(1)

            Spacer()

            // 版本信息（右侧对齐）
            VStack(alignment: .trailing, spacing: 2) {
                if !item.version.isEmpty {
                    Text(item.version)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if !item.detail.isEmpty {
                    Text(item.detail)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            // 状态图标
            Image(systemName: item.status.icon)
                .foregroundColor(item.status.color)
                .font(.callout)
                .help(item.status.label)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        // 点击打开官网
        .onTapGesture {
            if let url = item.website {
                NSWorkspace.shared.open(url)
            }
        }
        // 有官网链接时显示手型光标
        .cursor(item.website != nil ? .pointingHand : .arrow)
    }
}

// MARK: - 自定义光标修饰符

private struct CursorModifier: ViewModifier {
    let cursor: NSCursor

    func body(content: Content) -> some View {
        content.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

private extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        modifier(CursorModifier(cursor: cursor))
    }
}
