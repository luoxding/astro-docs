---
title: Vaultwarden 自建密码管理服务完整部署指南
description: Bitwarden 的轻量化自托管实现
slug: vaultwarden
---

> 适用环境：Ubuntu / Fedora / Arch / CentOS  
> 部署方式：Docker Compose  
> 目标域名：`vw.isrv.cn`  
> HTTPS：acme.sh 证书  
> 作者：Luo Xingding

---

## 📘 简介

本文介绍如何使用 **Docker Compose** 在服务器上部署 **Vaultwarden**（Bitwarden 的轻量化自托管实现），并通过 **Nginx + HTTPS** 实现安全访问，附带完整配置、环境变量和安全加固建议。

Vaultwarden 提供了与官方 Bitwarden 客户端兼容的 API，可搭配浏览器扩展、桌面端、移动端使用，数据完全保存在本地或自有服务器。

---

## 🧱 一、目录结构

```bash
/opt/docker/vaultwarden/
├── docker-compose.yml
├── .env
└── data/
````

---

## ⚙️ 二、准备环境

```bash
sudo mkdir -p /opt/docker/vaultwarden
cd /opt/docker/vaultwarden
```

### 安装依赖

```bash
sudo apt install docker.io docker-compose -y   # Ubuntu/Debian
# 或
sudo dnf install docker docker-compose -y      # Fedora
```

---

## 🔐 三、配置文件

### 1️⃣ `.env`

用于保存敏感变量（推荐使用 Argon2 哈希形式的管理员密码）。

```bash
VAULTWARDEN_ADMIN_TOKEN='$argon2id$v=19$m=65540,t=3,p=4$cmFuZG9tX3NhbHRfbWluaW11bV84X2NoYXJhY3RlcnM$oesx9INQVL9HGd/wBTLj3zZSXYqEZifnTcx01oZOgmA'
```

#### 🔧 生成安全哈希

```bash
echo -n your_admin_password | argon2 "random_salt_minimum_8_characters" -e -id -k 65540 -t 3 -p 4
```

> 💡 只需记住 `your_admin_password` 作为登录后台密码。  
> `.env` 文件中保存的只是哈希值，不会泄露明文密码。

---

### 2️⃣ `docker-compose.yml`

```yaml
version: '3'

services:
  vaultwarden:
    container_name: vaultwarden
    image: vaultwarden/server:latest
    restart: unless-stopped
    ports:
      - "16210:80"
    volumes:
      - ./data:/data
    environment:
      - DOMAIN=https://vw.isrv.cn
      - LOGIN_RATELIMIT_MAX_BURST=10
      - LOGIN_RATELIMIT_SECONDS=60
      - ADMIN_RATELIMIT_MAX_BURST=10
      - ADMIN_RATELIMIT_SECONDS=60
      - ADMIN_SESSION_LIFETIME=20
      - ADMIN_TOKEN=${VAULTWARDEN_ADMIN_TOKEN}
      - SENDS_ALLOWED=true
      - EMERGENCY_ACCESS_ALLOWED=true
      - WEB_VAULT_ENABLED=true
      - SIGNUPS_ALLOWED=true
```

---

## 🚀 四、启动服务

```bash
docker compose up -d
```

查看运行状态：

```bash
docker ps
```

确认端口监听：

```bash
sudo ss -tlnp | grep 16210
```

---

## 🌐 五、Nginx 反向代理配置

文件路径：`/etc/nginx/conf.d/vaultwarden.conf`

```nginx
server {
    listen 80;
    server_name vw.isrv.cn;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name vw.isrv.cn;

    ssl_certificate     /etc/nginx/ssl/vw.isrv.cn/fullchain.cer;
    ssl_certificate_key /etc/nginx/ssl/vw.isrv.cn/vw.isrv.cn.key;

    location / {
        proxy_pass http://127.0.0.1:16210;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }

    # 管理后台访问控制
    location /admin {
        allow 192.168.0.0/16;   # 本地内网
        allow 1.94.254.213;     # 管理IP
        deny all;

        proxy_pass http://127.0.0.1:16210/admin;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

重新加载 Nginx：

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🧭 六、访问测试

|功能|地址|
|---|---|
|前端登录|[https://vw.isrv.cn](https://vw.isrv.cn/)|
|管理后台|[https://vw.isrv.cn/admin](https://vw.isrv.cn/admin)|

> 首次访问时，使用你在生成 token 时设置的 **明文密码** 登录 `/admin`。

---

## 💾 七、数据备份与恢复

Vaultwarden 数据目录：`/opt/docker/vaultwarden/data/`

|文件|功能说明|
|---|---|
|`db.sqlite3`|用户数据库|
|`rsa_key.pem` / `rsa_key.pub.pem`|加密密钥|
|`attachments/`|附件存储目录|

### 备份命令

```bash
tar czvf /backup/vaultwarden_$(date +%F).tar.gz /opt/docker/vaultwarden/data
```

恢复时仅需解压覆盖即可。

---

## 🧰 八、常用维护命令

|操作|命令|
|---|---|
|查看日志|`docker logs -f vaultwarden`|
|停止容器|`docker compose down`|
|更新版本|`docker compose pull && docker compose up -d`|
|查看状态|`docker ps`|

---

## 🛡️ 九、安全加固建议

1. **使用 Argon2 哈希 token**，禁止明文存储密码。
    
2. **限制 `/admin` 路径访问**，仅允许内网或特定 IP。
    
3. **强制 HTTPS 访问**，关闭 HTTP 明文访问。
    
4. **单用户使用建议**：
    
    ```yaml
    - SIGNUPS_ALLOWED=false
    ```
    
5. **定期备份数据目录**。
    

---

## ✅ 十、总结

至此，Vaultwarden 服务部署完成。  
你现在拥有一个 **完全私有、安全、可控** 的密码管理系统，  
兼容 Bitwarden 全平台客户端（浏览器扩展、桌面、手机），  
同时所有数据均由你掌控。

---

> 📌 标签： #Vaultwarden #Bitwarden #Docker #自建服务 #密码管理  
> 📦 目录：`02_Nginx与网站/03_Vaultwarden部署指南.md`

