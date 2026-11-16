#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

export PATH="/home/Gold/opt/flutter/bin:$PATH"

# 检查 gh 是否已认证
if ! gh auth status >/dev/null 2>&1; then
  echo "gh CLI 未认证，请先运行：gh auth login"
  exit 1
fi

# 1. 自动递增版本号 (1.1.0+1 -> 1.1.1+2)
./scripts/bump_version.sh

VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
VER=$(echo "$VERSION" | cut -d'+' -f1)
BUILD=$(echo "$VERSION" | cut -d'+' -f2)

echo "=== 开始打包版本 $VERSION ==="

# 2. 获取依赖并构建 APK
flutter pub get
flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
  echo "APK 构建失败，未找到 $APK_PATH"
  exit 1
fi

echo "=== APK 构建完成: $APK_PATH ==="

# 3. 发布到 GitHub Releases
REPO="1462316579/codecraft"
TAG="v$VER"

# 检查 tag 是否已存在，若存在则删除（允许重复打包同一版本）
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "Release $TAG 已存在，先删除旧版本"
  gh release delete "$TAG" --repo "$REPO" -y
fi

gh release create "$TAG" "$APK_PATH" \
  --repo "$REPO" \
  --title "$TAG" \
  --notes "版本 $VERSION (build $BUILD)

自动构建发布。" \
  --latest

echo "=== 已发布到 GitHub Releases: $TAG ==="
