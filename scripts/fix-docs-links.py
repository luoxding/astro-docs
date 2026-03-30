#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path("/home/ding/www/astro-docs/src/content/docs")

# 匹配 Markdown 链接和图片：
# [text](/path) 或 ![alt](/path)
LINK_PATTERN = re.compile(r'(!?\[[^\]]*\]\()(/[^)\s]+)(\))')

def should_skip(url: str) -> bool:
    # 已经是 /docs 开头
    if url.startswith("/docs/") or url == "/docs":
        return True
    # 锚点、协议相对、奇怪双斜杠
    if url.startswith("//"):
        return True
    # 静态资源你想单独控制的话，可先跳过这些
    if url.startswith("/images/") or url.startswith("/assets/"):
        return True
    return False

def replace_links(text: str) -> tuple[str, int]:
    count = 0

    def repl(match: re.Match[str]) -> str:
        nonlocal count
        prefix, url, suffix = match.groups()
        if should_skip(url):
            return match.group(0)
        count += 1
        return f"{prefix}/docs{url}{suffix}"

    return LINK_PATTERN.sub(repl, text), count

def main() -> None:
    total_files = 0
    total_replacements = 0

    for path in list(ROOT.rglob("*.md")) + list(ROOT.rglob("*.mdx")):
        original = path.read_text(encoding="utf-8")
        updated, changed = replace_links(original)

        if changed > 0:
            path.write_text(updated, encoding="utf-8")
            total_files += 1
            total_replacements += changed
            print(f"[UPDATED] {path} ({changed} replacements)")

    print(f"\nDone. Updated {total_files} files, {total_replacements} links.")

if __name__ == "__main__":
    main()
