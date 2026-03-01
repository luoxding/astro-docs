---
title: 站点概览
description: A guide in my new Starlight docs site.
sidebar:
  label: 简介
slug: readme
lastUpdated: 2026-02-22
---

## 概要2

本站主要记录我多年来的各种学习笔记，其中大多数为电脑笔记，而这又是绝大部分是服务器的应用笔记记录。

### Path
- Local: `/home/ding/Documents/www`
- Remote: `us:/opt/server/astro-docs`
- Site: https://docs.isrv.cn/
- GitHub: https://github.com/luoxding/astro-docs

### Build

`astro-publish.sh `

```bash
#!/bin/bash
set -e
# sync-to-server.sh

LOCAL_DIR="$HOME/Documents/www/docs"
# REMOTE_USER="root"
# REMOTE_HOST="your.server.ip"
REMOTE_SERVER="us"
REMOTE_DIR="/opt/server/astro-docs/src/content/docs"

echo "同步笔记到服务器..."
# rsync -avz --delete "$LOCAL_DIR/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/"
rsync -avz --delete "$LOCAL_DIR/" "$REMOTE_SERVER:$REMOTE_DIR/"

echo "远程构建发布..."
ssh "$REMOTE_SERVER" "
cd /opt/docker/astro-docs && \
docker compose up --build --remove-orphans
"

echo "发布完成，访问站点即可。"

```

### Compose
`/opt/docker/astro-docs/docker-compose.yml `
```yml
services:
  astro-docs:
    image: node:20-bullseye
    container_name: astro-docs
    working_dir: /app
    volumes:
      - /opt/server/astro-docs:/app
      - /opt/1panel/www/sites/docs.isrv.cn/index:/app/dist-out
    environment:
      NODE_ENV: production
    command: >
      /bin/bash -c "
      npm ci &&
      npm run build &&
      cp -r dist/* dist-out/
      "
    restart: "no"  # 改成 no，构建完成后容器自动退出

```

### Config
`/opt/server/astro-docs/astro.config.mjs`
```js
root@isrv:
// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
        site: 'https://docs.isrv.cn',
        integrations: [
                starlight({
                        title: '时空知识库',
                        sidebar: [
                                {
                                        label: '指南',
                                        autogenerate: { directory: 'guides' },
                                },
                                {
                                        label: '参考',
                                        autogenerate: { directory: 'reference' },
                                },
                        ],
                        // editLink: {
                        //      baseUrl: 'https://github.com/withastro/starlight/edit/main/',
                        // },
                        //   footer: {
                        //     copyright:
                        //       '© 2026 Ding · 服务器知识库 · Powered by Astro & Starlight',
                        //   },
                }),
        ],
});

```