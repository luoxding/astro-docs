#!/bin/bash
set -e

############################
# 基础配置
############################
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RELEASE_BASE="/opt/server/releases"
CURRENT_LINK="/opt/server/current"
# CURRENT_LINK="/opt/1panel/www/sites/docs.isrv.cn/index"
BRANCH="main"
KEEP_RELEASES=5

echo "====== Astro Deploy ======"

cd "$PROJECT_DIR"

echo "[1] 拉取最新代码..."
git fetch origin
git reset --hard origin/$BRANCH

echo "[2] 安装依赖..."
npm ci

echo "[3] 构建项目..."
npm run build

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
NEW_RELEASE="$RELEASE_BASE/$TIMESTAMP"

echo "[4] 创建发布目录: $NEW_RELEASE"
mkdir -p "$NEW_RELEASE"

echo "[5] 拷贝 dist 内容"
cp -r dist/* "$NEW_RELEASE/"

echo "[6] 切换 current 软链接"
ln -sfn "$NEW_RELEASE" "$CURRENT_LINK"

echo "[7] 清理旧版本（保留 $KEEP_RELEASES 个）"
cd "$RELEASE_BASE"
ls -dt */ | tail -n +$((KEEP_RELEASES+1)) | xargs -r rm -rf

echo "====== Deploy Success ======"