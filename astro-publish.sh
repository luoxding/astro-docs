#!/bin/bash
set -e

###################################
# 配置区
###################################
# LOCAL_DIR="$HOME/Documents/www/docs"          # 本地 Obsidian 笔记/配置目录
LOCAL_DIR="$HOME/www/astro-docs"          # 本地 Obsidian 笔记/配置目录
REMOTE_SERVER="us"                             # 远程服务器别名或IP
REMOTE_PROJECT_DIR="/opt/server/astro-docs"   # 服务器项目目录
REMOTE_RELEASE_DIR="/opt/server/releases"     # 服务器 release 目录
SITE_DIR="/opt/1panel/www/sites/docs.isrv.cn/index" # 1Panel site 根目录
BRANCH="main"                                  # Git 分支
KEEP_RELEASES=5                                # 保留历史 release 数量
USE_REMOTE_BUILD=true                           # true 在服务器构建，false 桌面构建

###################################
# 功能函数
###################################
git_push() {
    echo "===== Git Push ====="
    git add .
    git commit -m "${1:-update}"
    git push origin $BRANCH
}

git_pull() {
    echo "===== Git Pull ====="
    git pull origin $BRANCH
}

build_remote() {
    echo "===== 服务器构建 ====="
    ssh "$REMOTE_SERVER" bash -l -e -s <<EOF
set -e

cd "$REMOTE_PROJECT_DIR"
git fetch origin
git reset --hard origin/$BRANCH

npm ci
npm run build

if [ ! -d dist ]; then
  echo "Build failed: dist not found"
  exit 1
fi

TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
NEW_RELEASE="$REMOTE_RELEASE_DIR/\$TIMESTAMP"
mkdir -p "\$NEW_RELEASE"
cp -r dist/* "\$NEW_RELEASE/"

cd "$REMOTE_RELEASE_DIR"
ls -dt */ | tail -n +$((KEEP_RELEASES+1)) | xargs -r rm -rf

rm -rf "$SITE_DIR"/*
cp -r "\$NEW_RELEASE/"* "$SITE_DIR/"

echo "===== Deploy Success on Server ====="
EOF
}


build_local() {
    echo "===== 本地构建 ====="
    cd "$LOCAL_DIR"
    npm ci
    npm run build
    echo "本地构建完成: dist/"
}

sync_to_server() {
    echo "===== 同步笔记到服务器 ====="
    rsync -avz --delete "$LOCAL_DIR/src/content/docs/" "$REMOTE_SERVER:$REMOTE_PROJECT_DIR/src/content/docs/"
}

###################################
# 主流程
###################################
# 1. 可选 git pull
read -p "是否执行 git pull? [y/N]: " yn
[[ "$yn" =~ ^[Yy]$ ]] && git_pull

# 2. 可选 git push
read -p "是否执行 git push? [y/N]: " yn
[[ "$yn" =~ ^[Yy]$ ]] && git_push "update from local"

# 3. 同步笔记
sync_to_server

# 4. 构建
if [ "$USE_REMOTE_BUILD" = true ]; then
    build_remote
else
    build_local
fi

echo "===== All Done ====="
