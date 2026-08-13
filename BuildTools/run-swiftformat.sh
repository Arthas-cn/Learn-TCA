#!/bin/sh
set -e

# Xcode 会把 SDKROOT 设成 iOS Simulator，SwiftFormat 是 macOS CLI，必须改回 macOS SDK。
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"

DERIVED_DATA_ROOT="${BUILD_DIR%/Build/Products*}"
SWIFTFORMAT=""

# 1) 使用 workspace 已经 resolve 好的 SourcePackages 里自带的预编译二进制
#    （不要再 swift run：那会重新 fetch + 从源码编译，容易一直卡住）
for candidate in \
  "$DERIVED_DATA_ROOT/SourcePackages/checkouts/SwiftFormat/CommandLineTool/swiftformat" \
  "$SRCROOT/BuildTools/.build/release/swiftformat"
do
  if [ -x "$candidate" ]; then
    SWIFTFORMAT="$candidate"
    break
  fi
done

if [ -z "$SWIFTFORMAT" ]; then
  echo "error: 未找到本地 SwiftFormat 二进制，已跳过联网编译以免卡住构建。"
  echo "error: 请打开 TCA.xcworkspace，执行 File > Packages > Resolve Package Versions 后再编译。"
  echo "error: 预期路径: $DERIVED_DATA_ROOT/SourcePackages/checkouts/SwiftFormat/CommandLineTool/swiftformat"
  exit 1
fi

echo "note: Running SwiftFormat: $SWIFTFORMAT"
"$SWIFTFORMAT" "$SRCROOT" --exclude BuildTools
