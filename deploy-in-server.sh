#!/bin/bash
set -e

###################################
# 配置区
###################################
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RELEASE_DIR="/opt/server/releases"
SITE_DIR="/opt/1panel/www/sites/docs.isrv.cn/index"
BRANCH="main"
KEEP_RELEASES=5

echo "====== Astro Server Deploy ======"

# 1. 拉取最新代码
echo "[1] 拉取最新代码..."
cd "$PROJECT_DIR"
git fetch origin
git reset --hard origin/$BRANCH

# 2. 安装依赖
echo "[2] 安装依赖..."
npm ci

# 3. 构建项目
echo "[3] 构建项目..."
npm run build

# 4. 创建 timestamp release
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
NEW_RELEASE="$RELEASE_DIR/$TIMESTAMP"
echo "[4] 创建发布目录: $NEW_RELEASE"
mkdir -p "$NEW_RELEASE"

# 5. 拷贝 dist 内容到 release
echo "[5] 拷贝 dist 内容"
cp -r dist/* "$NEW_RELEASE/"

# 6. 同步到 1Panel site 根目录
echo "[6] 更新 1Panel site 根目录: $SITE_DIR"
rm -rf "$SITE_DIR"/*
cp -r "$NEW_RELEASE/"* "$SITE_DIR/"

# 7. 清理旧 release
echo "[7] 清理旧版本（保留 $KEEP_RELEASES 个）"
cd "$RELEASE_DIR"
ls -dt */ | tail -n +$((KEEP_RELEASES+1)) | xargs -r rm -rf

echo "====== Deploy Success ======"
