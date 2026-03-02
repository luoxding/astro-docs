#!/bin/bash

OBSIDIAN="$HOME/obsidian-vault/90-public/"
ASTRO="$HOME/astro-docs/src/content/docs/"

echo "== 从 WebDAV 同步内容 =="
rsync -av --delete "$OBSIDIAN" "$ASTRO"

cd "$HOME/astro-docs" || exit

echo "== 检查缺少 frontmatter 的文件 =="
grep -L "^---" src/content/docs/**/*.md

echo "== Git 提交 =="
git add .
git commit -m "server publish $(date '+%Y-%m-%d %H:%M:%S')"
git push

echo "== 发布完成 =="
