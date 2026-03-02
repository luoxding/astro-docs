#!/bin/bash

OBSIDIAN="$HOME/obsidian-vault/90-public/"
ASTRO="$HOME/astro-docs/src/content/docs/"

echo "== 同步笔记到 Astro =="
rsync -av --delete "$OBSIDIAN" "$ASTRO"

cd "$HOME/astro-docs" || exit

echo "== 检查未写 slug 的文件 =="
grep -L "slug:" src/content/docs/**/*.md

echo "== 提交 Git =="
git add .
git commit -m "publish update $(date '+%Y-%m-%d %H:%M:%S')"
git push

echo "== 完成 =="
