#!/bin/bash
# ============================================================
#  开发环境监测看板 — 编译 + 打包脚本 (ARM64 / Apple Silicon)
# ============================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="EnvMonitor"
BUNDLE_DIR="$PROJECT_DIR/$APP_NAME.app"
SOURCES_DIR="$PROJECT_DIR/Sources/$APP_NAME"
ICON_SRC="$PROJECT_DIR/AppIcon.icns"
DMG_FILE="$PROJECT_DIR/$APP_NAME.dmg"

echo "🔨 正在编译 (arm64-apple-macos11)..."
swiftc \
    -target arm64-apple-macos11 \
    -sdk "$(xcrun --show-sdk-path --sdk macosx)" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Combine \
    -o "$APP_NAME" \
    "$SOURCES_DIR/"*.swift \
    "$SOURCES_DIR/UI/"*.swift

# ---- 创建 .app Bundle ----
echo "📦 正在创建 .app Bundle..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

cp "$APP_NAME" "$BUNDLE_DIR/Contents/MacOS/"
cp "$PROJECT_DIR/Info.plist" "$BUNDLE_DIR/Contents/"
cp "$SOURCES_DIR/Resources/"* "$BUNDLE_DIR/Contents/Resources/" 2>/dev/null || true

# 嵌入图标
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$BUNDLE_DIR/Contents/Resources/AppIcon.icns"
    echo "🎨 图标已嵌入"
else
    echo "⚠️  未找到 AppIcon.icns，跳过图标嵌入"
fi

# 清理中间产物
rm -f "$APP_NAME"

echo "✅ App 编译完成: $BUNDLE_DIR"

# ---- 创建 DMG 安装包 ----
echo ""
echo "💿 正在生成 DMG 安装包..."

DMG_STAGING="$PROJECT_DIR/.dmg_staging"
rm -rf "$DMG_STAGING" "$DMG_FILE"
mkdir -p "$DMG_STAGING"

cp -R "$BUNDLE_DIR" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_FILE"

rm -rf "$DMG_STAGING"

echo "✅ DMG 已生成: $DMG_FILE"
echo ""
echo "=============================================="
echo "  产物:"
echo "    $BUNDLE_DIR"
echo "    $DMG_FILE"
echo ""
echo "  运行:  open $BUNDLE_DIR"
echo "  安装:  双击 $DMG_FILE 拖入 Applications 即可"
echo "=============================================="
