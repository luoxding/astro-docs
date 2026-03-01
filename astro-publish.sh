#!/bin/bash
set -e

############################
# 配置区
############################
REMOTE_SERVER="us"
REMOTE_PROJECT_DIR="/opt/server/astro-docs"
BRANCH="main"

############################
# 函数区
############################

function usage() {
    echo "用法:"
    echo "  ./astro-publish.sh push [msg]    # 本地提交并 push"
    echo "  ./astro-publish.sh pull          # 本地 pull"
    echo "  ./astro-publish.sh deploy        # 服务器部署"
    echo "  ./astro-publish.sh all [msg]     # push + 部署"
    exit 1
}

function local_push() {
    MSG=${2:-"update"}
    echo "=== 本地提交并 push ==="
    git add .
    git commit -m "$MSG" || echo "无变更可提交"
    git push origin $BRANCH
}

function local_pull() {
    echo "=== 本地 pull ==="
    git pull origin $BRANCH
}

function remote_deploy() {
    echo "=== 服务器部署 ==="
    ssh $REMOTE_SERVER "
        cd $REMOTE_PROJECT_DIR && \
        ./deploy.sh
    "
}

############################
# 主逻辑
############################

case "$1" in
    push)
        local_push "$@"
        ;;
    pull)
        local_pull
        ;;
    deploy)
        remote_deploy
        ;;
    all)
        local_push "$@"
        remote_deploy
        ;;
    *)
        usage
        ;;
esac