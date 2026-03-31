---
title: 基于 rclone + systemd + 本地索引 JSON 的自建图床完整方案
slug: rclone-systemd-figbed
---

## 一、背景与目标

我在 Claw Cloud（S3 兼容对象存储）上创建了一个 bucket，并绑定自定义域名：

```text
https://images.isrv.cn/
```

目标是构建一个：

- 本地可管理（预览 / 重命名 / 分类）
    
- 自动同步到对象存储
    
- 支持直链访问
    
- 带图床首页（可浏览、搜索、复制 Markdown）
    
- 完全静态（无后端服务）
    

---

## 二、最终架构

```text
📁 /home/ding/Pictures/Images   ← 本地主库
        ↓
🐍 generate-images-json.py      ← 本地生成索引 JSON
        ↓
🔁 rclone sync (systemd timer)
        ↓
☁️ Claw S3 bucket
        ↓
🌍 https://images.isrv.cn/
```

核心思想：

> **本地目录是唯一真源，远端只负责发布和访问**

---

## 三、目录结构

```text
/home/ding/Pictures/Images/
├── index.html          # 图床首页
├── images.json         # 本地生成的索引
├── screenshots/
├── posts/
├── wallpapers/
└── ...
```

---

## 四、rclone 配置

已配置远端（示例）：

```bash
rclone ls claw:ujwn4e6y-img
```

说明：

- `claw`：远端名称
    
- `ujwn4e6y-img`：bucket 名
    

---

## 五、生成图片索引（核心）

### 1. 脚本路径

```bash
/home/ding/.local/bin/generate-images-json.py
```

### 2. 完整代码

```python
#!/usr/bin/env python3
from __future__ import annotations

import json
import mimetypes
from pathlib import Path
from urllib.parse import quote

ROOT = Path("/home/ding/Pictures/Images")
BASE_URL = "https://images.isrv.cn"
OUTPUT = ROOT / "images.json"

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".svg", ".avif"}

def is_image(path: Path) -> bool:
    if path.name in {"index.html", "images.json"}:
        return False
    return path.suffix.lower() in IMAGE_EXTS

def main():
    items = []

    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue

        # 忽略隐藏文件
        if any(part.startswith(".") for part in path.relative_to(ROOT).parts):
            continue

        if not is_image(path):
            continue

        rel = path.relative_to(ROOT).as_posix()
        stat = path.stat()

        items.append({
            "name": path.name,
            "path": rel,
            "url": f"{BASE_URL}/{quote(rel, safe='/')}",
            "mtime": int(stat.st_mtime),
            "size": stat.st_size,
            "type": mimetypes.guess_type(path.name)[0] or "application/octet-stream",
        })

    # 按修改时间倒序（最新优先）
    items.sort(key=lambda x: x["mtime"], reverse=True)

    with OUTPUT.open("w", encoding="utf-8") as f:
        json.dump(items, f, ensure_ascii=False, separators=(",", ":"))

if __name__ == "__main__":
    main()
```

### 3. 赋权

```bash
chmod +x /home/ding/.local/bin/generate-images-json.py
```

---

## 六、同步脚本

### 1. 路径

```bash
/home/ding/.local/bin/rclone-images-sync.sh
```

### 2. 完整代码

```bash
#!/usr/bin/env bash
set -euo pipefail

SRC="/home/ding/Pictures/Images"
DST="claw:ujwn4e6y-img"
LOG="/home/ding/.local/state/rclone-images-sync.log"
GEN="/home/ding/.local/bin/generate-images-json.py"

mkdir -p "$(dirname "$LOG")"

# 先生成 JSON 索引
"$GEN"

# 再同步到对象存储
exec /usr/bin/rclone sync "$SRC" "$DST" \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --delete-during \
  --track-renames \
  --log-file "$LOG" \
  --log-level INFO
```

### 3. 赋权

```bash
chmod +x /home/ding/.local/bin/rclone-images-sync.sh
```

---

## 七、systemd 定时任务

### 1. service

路径：

```bash
~/.config/systemd/user/rclone-images-sync.service
```

内容：

```ini
[Unit]
Description=Sync local image directory to Claw object storage
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/home/ding/.local/bin/rclone-images-sync.sh
```

---

### 2. timer

路径：

```bash
~/.config/systemd/user/rclone-images-sync.timer
```

内容：

```ini
[Unit]
Description=Run rclone image sync periodically

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
```

---

### 3. 启用

```bash
systemctl --user daemon-reload
systemctl --user enable --now rclone-images-sync.timer
```

查看：

```bash
systemctl --user list-timers
```

---

### 4. 关键（保持后台运行）

```bash
loginctl enable-linger ding
```

---

## 八、图床首页（index.html）

路径：

```bash
/home/ding/Pictures/Images/index.html
```

（此处省略代码，已在上一条提供完整版本）
```html
<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>images.isrv.cn</title>
<style>
:root{
  --bg:#0b1020;
  --bg2:#11182d;
  --card:#121a2b;
  --line:#23304a;
  --text:#e8eefc;
  --muted:#9fb0d1;
  --accent:#63b3ff;
  --accent2:#7cf7d4;
  --shadow:0 12px 40px rgba(0,0,0,.35);
}
*{box-sizing:border-box}
html,body{margin:0;padding:0}
body{
  font-family:system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"PingFang SC","Noto Sans CJK SC",sans-serif;
  color:var(--text);
  background:
    radial-gradient(circle at top left, rgba(99,179,255,.18), transparent 30%),
    radial-gradient(circle at top right, rgba(124,247,212,.12), transparent 25%),
    linear-gradient(180deg, #0a0f1d, #0b1020 30%, #0a1020);
  min-height:100vh;
}
.wrap{
  max-width:1200px;
  margin:0 auto;
  padding:32px 18px 48px;
}
.hero{
  display:flex;
  justify-content:space-between;
  gap:20px;
  align-items:flex-start;
  margin-bottom:24px;
  flex-wrap:wrap;
}
.hero-card,.toolbar,.panel{
  background:rgba(18,26,43,.85);
  border:1px solid var(--line);
  box-shadow:var(--shadow);
  backdrop-filter:blur(10px);
}
.hero-card{
  border-radius:22px;
  padding:24px;
  flex:1 1 560px;
}
.hero h1{
  margin:0 0 10px;
  font-size:34px;
  line-height:1.1;
}
.hero p{
  margin:0;
  color:var(--muted);
  line-height:1.7;
}
.hero code{
  background:#0d1425;
  border:1px solid var(--line);
  border-radius:8px;
  padding:2px 8px;
  font-size:.92em;
}
.badges{
  display:flex;
  gap:10px;
  flex-wrap:wrap;
  margin-top:16px;
}
.badge{
  font-size:12px;
  padding:7px 12px;
  border-radius:999px;
  border:1px solid var(--line);
  color:#dbe8ff;
  background:rgba(255,255,255,.03);
}
.toolbar{
  border-radius:18px;
  padding:16px;
  margin-bottom:18px;
  display:grid;
  grid-template-columns:1.2fr 180px 140px;
  gap:12px;
}
.input,.select,.btn{
  width:100%;
  border-radius:12px;
  border:1px solid var(--line);
  background:#0d1425;
  color:var(--text);
  padding:12px 14px;
  font-size:14px;
}
.input:focus,.select:focus{
  outline:none;
  border-color:var(--accent);
}
.btn{
  cursor:pointer;
  transition:.18s ease;
}
.btn:hover{
  transform:translateY(-1px);
}
.btn:disabled{
  opacity:.45;
  cursor:not-allowed;
  transform:none;
}
.btn-primary{
  background:linear-gradient(135deg, var(--accent), #7dc1ff);
  color:#07111f;
  font-weight:700;
  border:none;
}
.btn-ghost{
  background:#10192d;
}
.stats{
  display:flex;
  gap:12px;
  flex-wrap:wrap;
  margin:16px 0 0;
}
.stat{
  min-width:140px;
  border:1px solid var(--line);
  border-radius:14px;
  padding:12px 14px;
  background:rgba(255,255,255,.02);
}
.stat .label{
  font-size:12px;
  color:var(--muted);
}
.stat .value{
  margin-top:6px;
  font-size:20px;
  font-weight:700;
}
.panel{
  border-radius:20px;
  padding:18px;
}
.grid{
  display:grid;
  grid-template-columns:repeat(auto-fill, minmax(240px, 1fr));
  gap:16px;
}
.card{
  border:1px solid var(--line);
  border-radius:18px;
  overflow:hidden;
  background:#0d1425;
}
.thumb-link{
  display:block;
  background:#09101d;
}
.thumb{
  aspect-ratio:4 / 3;
  display:block;
  width:100%;
  object-fit:cover;
  background:#09101d;
}
.meta{
  padding:12px;
}
.name{
  font-size:14px;
  font-weight:600;
  line-height:1.5;
  word-break:break-all;
  min-height:42px;
}
.sub{
  margin-top:8px;
  color:var(--muted);
  font-size:12px;
  display:flex;
  justify-content:space-between;
  gap:8px;
}
.actions{
  display:grid;
  grid-template-columns:1fr 1fr 1fr;
  gap:8px;
  margin-top:12px;
}
.actions .btn{
  padding:10px 8px;
  font-size:13px;
}
.actions a.btn{
  text-decoration:none;
  display:inline-flex;
  align-items:center;
  justify-content:center;
}
.pagination{
  margin-top:22px;
  display:flex;
  justify-content:center;
  align-items:center;
  gap:10px;
  flex-wrap:wrap;
}
.page-info{
  color:var(--muted);
  font-size:14px;
}
.empty{
  text-align:center;
  color:var(--muted);
  padding:48px 20px;
}
.footer{
  text-align:center;
  color:var(--muted);
  font-size:13px;
  margin-top:22px;
}
.toast{
  position:fixed;
  right:20px;
  bottom:20px;
  background:#0f1a2d;
  color:#eaf3ff;
  border:1px solid var(--line);
  border-radius:12px;
  padding:12px 16px;
  box-shadow:var(--shadow);
  opacity:0;
  transform:translateY(10px);
  pointer-events:none;
  transition:.2s ease;
  z-index:9999;
}
.toast.show{
  opacity:1;
  transform:translateY(0);
}
@media (max-width:780px){
  .toolbar{
    grid-template-columns:1fr;
  }
  .hero h1{
    font-size:28px;
  }
}
</style>
</head>
<body>
<div class="wrap">
  <section class="hero">
    <div class="hero-card">
      <h1>images.isrv.cn</h1>
      <p>本地图床索引页。图片列表由本地扫描生成 <code>images.json</code>，再通过 rclone 同步到对象存储。支持最近上传排序、当前页打开原图、预览按钮新标签打开、复制直链、复制 Markdown 链接与分页浏览。</p>
      <div class="badges">
        <span class="badge">Static Site</span>
        <span class="badge">rclone sync</span>
        <span class="badge">Local JSON Index</span>
      </div>
      <div class="stats">
        <div class="stat">
          <div class="label">图片总数</div>
          <div class="value" id="totalCount">-</div>
        </div>
        <div class="stat">
          <div class="label">当前页</div>
          <div class="value" id="currentPageStat">-</div>
        </div>
        <div class="stat">
          <div class="label">最后更新时间</div>
          <div class="value" id="latestUpdate" style="font-size:15px">-</div>
        </div>
      </div>
    </div>
  </section>

  <section class="toolbar">
    <input id="searchInput" class="input" type="text" placeholder="搜索文件名或路径，例如 screen / posts / wallpaper">
    <select id="pageSizeSelect" class="select">
      <option value="12">每页 12 张</option>
      <option value="24" selected>每页 24 张</option>
      <option value="48">每页 48 张</option>
      <option value="96">每页 96 张</option>
    </select>
    <button id="resetBtn" class="btn btn-primary">重置筛选</button>
  </section>

  <section class="panel">
    <div id="grid" class="grid"></div>
    <div id="empty" class="empty" style="display:none;">没有匹配的图片。</div>

    <div class="pagination">
      <button id="prevBtn" class="btn btn-ghost">上一页</button>
      <span id="pageInfo" class="page-info">-</span>
      <button id="nextBtn" class="btn btn-ghost">下一页</button>
    </div>
  </section>

  <div class="footer">
    Built with local JSON index · Arch Linux · systemd · rclone
  </div>
</div>

<div id="toast" class="toast"></div>

<script>
const state = {
  allItems: [],
  filteredItems: [],
  currentPage: 1,
  pageSize: 24,
  query: ""
};

function formatSize(size) {
  const units = ["B","KB","MB","GB","TB"];
  let i = 0;
  let n = size;
  while (n >= 1024 && i < units.length - 1) {
    n /= 1024;
    i++;
  }
  return `${n.toFixed(n >= 10 || i === 0 ? 0 : 1)} ${units[i]}`;
}

function formatTime(ts) {
  const d = new Date(ts * 1000);
  return d.toLocaleString("zh-CN", { hour12: false });
}

function escapeHtml(str) {
  return str.replace(/[&<>"']/g, s => ({
    "&":"&amp;",
    "<":"&lt;",
    ">":"&gt;",
    '"':"&quot;",
    "'":"&#39;"
  }[s]));
}

function escapeJsSingleQuoted(str) {
  return str.replace(/\\/g, "\\\\").replace(/'/g, "\\'");
}

function toast(msg) {
  const el = document.getElementById("toast");
  el.textContent = msg;
  el.classList.add("show");
  clearTimeout(toast._timer);
  toast._timer = setTimeout(() => el.classList.remove("show"), 1400);
}

async function copyText(text, msg) {
  try {
    await navigator.clipboard.writeText(text);
    toast(msg);
  } catch (err) {
    toast("复制失败");
  }
}

function buildMarkdown(item) {
  return `![${item.name}](${item.url})`;
}

function applyFilter() {
  const q = state.query.trim().toLowerCase();
  state.filteredItems = !q
    ? [...state.allItems]
    : state.allItems.filter(item =>
        item.name.toLowerCase().includes(q) ||
        item.path.toLowerCase().includes(q)
      );

  state.currentPage = 1;
  render();
}

function render() {
  const total = state.filteredItems.length;
  const totalPages = Math.max(1, Math.ceil(total / state.pageSize));
  if (state.currentPage > totalPages) state.currentPage = totalPages;

  const start = (state.currentPage - 1) * state.pageSize;
  const pageItems = state.filteredItems.slice(start, start + state.pageSize);

  const grid = document.getElementById("grid");
  const empty = document.getElementById("empty");

  if (!pageItems.length) {
    grid.innerHTML = "";
    empty.style.display = "block";
  } else {
    empty.style.display = "none";
    grid.innerHTML = pageItems.map(item => {
      const safeUrlForJs = escapeJsSingleQuoted(item.url);
      const safeMdForJs = escapeJsSingleQuoted(buildMarkdown(item));
      return `
      <article class="card">
        <a class="thumb-link" href="${item.url}">
          <img class="thumb" src="${item.url}" alt="${escapeHtml(item.name)}" loading="lazy">
        </a>
        <div class="meta">
          <div class="name">${escapeHtml(item.name)}</div>
          <div class="sub">
            <span>${formatSize(item.size)}</span>
            <span>${formatTime(item.mtime)}</span>
          </div>
          <div class="actions">
            <a class="btn btn-ghost" href="${item.url}" target="_blank" rel="noopener noreferrer">预览</a>
            <button class="btn btn-ghost" onclick="copyText('${safeUrlForJs}', '已复制直链')">直链</button>
            <button class="btn btn-ghost" onclick="copyText('${safeMdForJs}', '已复制 Markdown')">Markdown</button>
          </div>
        </div>
      </article>
      `;
    }).join("");
  }

  document.getElementById("pageInfo").textContent = `第 ${state.currentPage} / ${totalPages} 页，共 ${total} 张`;
  document.getElementById("currentPageStat").textContent = `${state.currentPage}/${totalPages}`;
  document.getElementById("totalCount").textContent = String(state.allItems.length);

  document.getElementById("prevBtn").disabled = state.currentPage <= 1;
  document.getElementById("nextBtn").disabled = state.currentPage >= totalPages;
}

async function init() {
  try {
    const res = await fetch("images.json?_=" + Date.now(), { cache: "no-store" });
    if (!res.ok) throw new Error("无法加载 images.json");
    const data = await res.json();

    state.allItems = Array.isArray(data) ? data : [];
    state.filteredItems = [...state.allItems];

    if (state.allItems.length) {
      document.getElementById("latestUpdate").textContent = formatTime(state.allItems[0].mtime);
    } else {
      document.getElementById("latestUpdate").textContent = "暂无";
    }

    render();
  } catch (err) {
    document.getElementById("grid").innerHTML = `
      <div class="empty">
        读取 images.json 失败，请确认本地已生成并同步到远端。<br>
        <small>${escapeHtml(String(err.message || err))}</small>
      </div>
    `;
  }
}

document.getElementById("searchInput").addEventListener("input", (e) => {
  state.query = e.target.value;
  applyFilter();
});

document.getElementById("pageSizeSelect").addEventListener("change", (e) => {
  state.pageSize = parseInt(e.target.value, 10);
  state.currentPage = 1;
  render();
});

document.getElementById("resetBtn").addEventListener("click", () => {
  state.query = "";
  state.currentPage = 1;
  state.pageSize = 24;
  document.getElementById("searchInput").value = "";
  document.getElementById("pageSizeSelect").value = "24";
  applyFilter();
});

document.getElementById("prevBtn").addEventListener("click", () => {
  if (state.currentPage > 1) {
    state.currentPage--;
    render();
    window.scrollTo({ top: 0, behavior: "smooth" });
  }
});

document.getElementById("nextBtn").addEventListener("click", () => {
  const totalPages = Math.max(1, Math.ceil(state.filteredItems.length / state.pageSize));
  if (state.currentPage < totalPages) {
    state.currentPage++;
    render();
    window.scrollTo({ top: 0, behavior: "smooth" });
  }
});

init();
</script>
</body>
</html>
```

功能：

- 图片网格展示
    
- 按时间排序（最新优先）
    
- 搜索（文件名 / 路径）
    
- 分页
    
- 点击缩略图 → 当前页打开（支持 Alt+← 返回）
    
- 预览按钮 → 新标签打开
    
- 复制直链
    
- 复制 Markdown
    

---

## 九、访问方式

### 单图访问

```text
https://images.isrv.cn/screen_20260329_195241.png
```

### 图床首页

```text
https://images.isrv.cn/
```

---

## 十、验证流程

### 手动执行同步

```bash
/home/ding/.local/bin/rclone-images-sync.sh
```

### 查看远端

```bash
rclone ls claw:ujwn4e6y-img
```

### 浏览器访问

```text
https://images.isrv.cn/
```

---

## 十一、关键设计决策

### 1. 为什么不用 S3 挂载

- 非 POSIX 文件系统
    
- 预览体验差
    
- 性能差
    
- 行为不稳定
    

👉 放弃 mount，采用直传

---

### 2. 为什么不用 rsync

- rsync 适用于文件系统
    
- 不理解对象存储语义
    

👉 使用 rclone 原生支持

---

### 3. 为什么本地生成 JSON

对象存储：

- 不支持目录列表
    
- 不支持动态查询
    

👉 本地生成索引 → 静态加载

---

### 4. 为什么用 systemd timer

相比 cron：

- 支持开机补执行（Persistent）
    
- 更好日志管理
    
- 可观测性强
    

---

### 5. 为什么用 sync 而不是 copy

```bash
rclone sync
```

保证：

- 本地删除 → 远端删除
    
- 本地修改 → 远端更新
    

👉 保持完全一致

---

## 十二、注意事项

### ⚠️ 删除风险

`sync` 会删除远端文件：

> 本地误删 = 远端也会删除

建议：

- 初期使用 `--dry-run`
    
- 或增加备份策略
    

---

### ⚠️ 文件命名建议

推荐：

```text
screen_20260329_195241.png
autumn-leaves.png
post-cover.jpg
```

避免：

- 空格
    
- 中文（可用但不推荐）
    
- 特殊符号
    

---

### ⚠️ URL 编码

已在 Python 中处理：

```python
quote(rel, safe='/')
```

---

## 十三、最终效果

你现在拥有：

- ✔ 本地文件管理体验（完全自由）
    
- ✔ 自动同步到对象存储
    
- ✔ 自定义域名访问
    
- ✔ 可浏览的图床首页
    
- ✔ 一键复制 Markdown
    
- ✔ 完全静态，无后端依赖
    

---

## 十四、一句话总结

> **用本地目录作为主库 + rclone 定时同步 + 本地生成 JSON 索引 + 静态页面渲染，就是一个稳定、可控、零后端的图床方案。**

---

如果以后你要继续升级，这一套可以自然扩展到：

- 自动压缩 / WebP
    
- Markdown 自动上传工具（类似 PicGo）
    
- 私有签名 URL
    
- CDN 加速策略
    

但就目前而言，这套已经是**工程上非常干净且稳定的方案**了。