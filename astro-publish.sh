#!/bin/bash
set -e

###################################
# 配置区
###################################
LOCAL_DIR="$HOME/www/astro-docs"                # 本地项目目录
REMOTE_SERVER="us"                              # 海外构建服务器别名或IP
REMOTE_PROJECT_DIR="/opt/server/astro-docs"     # 海外服务器项目目录
REMOTE_RELEASE_DIR="/opt/server/releases"       # 海外服务器 release 目录
SITE_DIR="/opt/1panel/www/sites/docs.isrv.cn/index"   # 海外服务器站点目录

# 新增：国内服务器与目标目录
CN_SERVER="root@122.51.240.4"
CN_SITE_DIR="/opt/1panel/www/subpath/docs"

BRANCH="main"                                   # Git 分支
KEEP_RELEASES=5                                 # 保留历史 release 数量
USE_REMOTE_BUILD=true                           # true 在服务器构建，false 本地构建

###################################
# 功能函数
###################################
git_push() {
    echo "===== Git Push ====="
    git add .
    git commit -m "${1:-update}"
    git push origin "$BRANCH"
}

git_pull() {
    echo "===== Git Pull ====="
    git pull origin "$BRANCH"
}

build_remote() {
    echo "===== 服务器构建 ====="
    ssh "$REMOTE_SERVER" bash -e -s <<EOF
set -e

export NVM_DIR="/root/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"

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

echo "===== Sync to CN Server ====="
ssh "$CN_SERVER" "mkdir -p '$CN_SITE_DIR'"
rsync -avz --delete "$SITE_DIR"/ "$CN_SERVER:$CN_SITE_DIR/"

echo "===== Deploy Success on Remote + CN Server ====="
EOF
}

build_local() {
    echo "===== 本地构建 ====="
    cd "$LOCAL_DIR"
    npm ci
    npm run build
    echo "本地构建完成: dist/"
}

###################################
# 主流程
###################################
cd "$LOCAL_DIR"

read -p "是否执行 git pull? [y/N]: " yn
[[ "$yn" =~ ^[Yy]$ ]] && git_pull

read -p "是否执行 git push? [y/N]: " yn
[[ "$yn" =~ ^[Yy]$ ]] && git_push "update from local"

if [ "$USE_REMOTE_BUILD" = true ]; then
    build_remote
else
    build_local
fi

echo "===== All Done ====="