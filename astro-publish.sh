#!/bin/bash
set -euo pipefail

###################################
# 配置区
###################################
LOCAL_DIR="$HOME/www/astro-docs"
REMOTE_SERVER="us"
REMOTE_PROJECT_DIR="/opt/server/astro-docs"
REMOTE_RELEASE_DIR="/opt/server/releases"
SITE_DIR="/opt/1panel/www/sites/docs.isrv.cn/index"

# 国内服务器：建议写真实 SSH 登录地址，不要依赖别名
#CN_SERVER="ubuntu@YOUR_CN_SERVER_IP_OR_HOSTNAME"
CN_SERVER="root@122.51.240.4"
CN_SITE_DIR="/opt/1panel/www/subpath/docs"

BRANCH="main"
KEEP_RELEASES=5
USE_REMOTE_BUILD=true

###################################
# 功能函数
###################################
git_push() {
    echo "===== Git Push ====="
    git add .
    git commit -m "${1:-update}" || true
    git push origin "$BRANCH"
}

git_pull() {
    echo "===== Git Pull ====="
    git pull origin "$BRANCH"
}

build_remote() {
    echo "===== 服务器构建 ====="
    ssh "$REMOTE_SERVER" bash -e -s <<EOF
set -euo pipefail

export NVM_DIR="/root/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"

echo "===== Step 1: Update source ====="
cd "$REMOTE_PROJECT_DIR"
git fetch origin
git reset --hard origin/$BRANCH

echo "===== Step 2: Build ====="
npm ci
npm run build

if [ ! -d dist ]; then
  echo "Build failed: dist not found"
  exit 1
fi

echo "===== Step 3: Create release ====="
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
NEW_RELEASE="$REMOTE_RELEASE_DIR/\$TIMESTAMP"
mkdir -p "\$NEW_RELEASE"
cp -r dist/* "\$NEW_RELEASE/"

echo "===== Step 4: Cleanup old releases ====="
cd "$REMOTE_RELEASE_DIR"
ls -dt */ | tail -n +$((KEEP_RELEASES+1)) | xargs -r rm -rf

echo "===== Step 5: Deploy on remote site dir ====="
rm -rf "$SITE_DIR"/*
cp -r "\$NEW_RELEASE/"* "$SITE_DIR/"

echo "===== Step 6: Ensure CN target dir exists ====="
ssh "$CN_SERVER" "mkdir -p '$CN_SITE_DIR'"

echo "===== Step 7: Rsync to CN Server ====="
rsync -avz --delete "$SITE_DIR"/ "$CN_SERVER:$CN_SITE_DIR/"

echo "===== Step 8: CN sync finished ====="
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