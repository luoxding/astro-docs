#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RELEASE_BASE="/opt/server/releases"
SITE_DIR="/opt/1panel/www/sites/docs.isrv.cn/index"
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

echo "[5] 拷贝 dist 内容到 release"
cp -r dist/* "$NEW_RELEASE/"

echo "[6] 清理旧版本（保留 $KEEP_RELEASES 个）"
cd "$RELEASE_BASE"
ls -dt */ | tail -n +$((KEEP_RELEASES+1)) | xargs -r rm -rf

echo "[7] 同步到 1Panel site 目录"
# 先清空旧内容，再拷贝
rm -rf "$SITE_DIR"/*
cp -r "$NEW_RELEASE/"* "$SITE_DIR/"

echo "====== Deploy Success ======"
