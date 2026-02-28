---
title: Docker 容器内自动构建 Astro 并把 dist/ 同步到站点目录
description: A guide in my new Starlight docs site.
sidebar:
  label: Astro 构建流程
slug: astro-build
---

现在的目录结构和目标：

- Astro 源码目录：`/opt/server/astro-docs`
    
- 构建输出目录：`/opt/server/astro-docs/dist`
    
- 站点目录（Nginx/1Panel）：`/opt/1panel/www/sites/docs.isrv.cn/`
    

目标：**Docker 容器内自动构建 Astro 并把 dist/ 同步到站点目录**，无需手动拷贝。

下面给你写一个 **完整 Docker Compose 配置示例**，并配套启动脚本：

---

## 1️⃣ docker-compose.yml

```yaml
version: "3.9"

services:
  astro-docs:
    image: node:20-bullseye
    container_name: astro-docs
    working_dir: /app
    volumes:
      - /opt/server/astro-docs:/app            # 源码挂载
      - /opt/1panel/www/sites/docs.isrv.cn:/app/dist-out  # 构建输出挂载到站点
    environment:
      NODE_ENV: production
    command: >
      /bin/bash -c "
      npm install &&
      npm run build &&
      cp -r dist/* dist-out/
      "
    restart: unless-stopped
```

---

## 2️⃣ package.json 构建脚本

在 `/opt/server/astro-docs/package.json` 里加一个自动部署脚本：

```json
"scripts": {
  "build": "astro build",
  "deploy": "npm run build && cp -r dist/* /app/dist-out/"
}
```

> `/app/dist-out/` 对应容器挂载到宿主机的站点目录 `/opt/1panel/www/sites/docs.isrv.cn`

---

## 3️⃣ 使用方法

1. 启动容器：
    

```bash
docker compose up -d
```

- 会自动安装依赖、构建 Astro、把 dist/ 内容同步到宿主机站点目录
    

2. 更新笔记时，只需重启容器或执行部署：
    

```bash
docker compose exec astro-docs npm run deploy
```

- 自动把最新的 Markdown → Astro 构建 → 输出同步到 Nginx
    

3. Nginx/1Panel 配置：
    

- 直接指向 `/opt/1panel/www/sites/docs.isrv.cn`
    
- 不需要运行 Node，完全静态
    

---

## 4️⃣ 优点

- 自动化：无需手动拷贝 `dist/`
    
- 安全：生产站点只暴露静态文件
    
- 可重复执行：修改笔记 → 容器内 `npm run deploy` → 静态站点自动更新
    
- 支持中文 + 主题 + 代码高亮（Starlight 模板）
    

---

💡 补充优化：

- 可以把 `dist-out` 挂载成只读模式，保证 Astro 构建不会覆盖源站点其他文件
    
- 如果你想加定时构建，每天 `cron` 调用 `docker exec astro-docs npm run deploy` 就行
    

---


