---
title: 样式测试项目
tableOfContents:
  minHeadingLevel: 1
  maxHeadingLevel: 6
sidebar:
  label: 样式测试文章
slug: test
---

好的，我帮你整理一篇文章草稿，总结你在 **VitePress 服务器部署 + Git 同步 + 构建** 过程中踩过的坑，以及 Git 操作经验。文章内容分条清晰，方便你存档和以后查阅。

---

# VitePress 服务器部署与 Git 同步踩坑记录

## 1. 环境与版本

- **服务器系统**：Ubuntu / Debian
  
- **Node.js**：v24.11.0（注意不要用低版本，VitePress 2.x 需要 >=18）
  
- **Yarn**：1.22.x
  
- **VitePress**：v1.6.x 或 v2.x
  

**注意**：低版本 Node 安装 VitePress 会报错：

```
globby@14.1.0: The engine "node" is incompatible with this module. Expected version ">=18". Got "14.17.6"
```

---

## 2. 服务器部署流程

1. 创建项目目录：
   

```bash
mkdir /www/wwwroot/vitepress
cd /www/wwwroot/vitepress
```

2. 初始化 Node 项目并安装 VitePress：
   

```bash
yarn init -y
yarn add -D vitepress
```

3. 创建必要文件：
   

```text
index.md
markdown-examples.md
api-examples.md
.vitepress/config.mts
```

4. 配置 Nginx 指向 `.vitepress/dist` 目录，使用 `location /` 访问 VitePress 站点。
   
5. 构建 VitePress：
   

```bash
yarn vitepress build
```

**坑**：

- 之前使用 VuePress 命令构建，报错 `The bundler or theme option is missing`，解决方法：确认使用 **VitePress** 而不是 VuePress。
  
- 构建时 `.user.ini` 文件权限问题会报 `EPERM`，解决方法：确保构建目录可写，或清理旧文件：
  

```bash
rm -rf .vitepress/dist/*
```

---

## 3. 本地同步与服务器操作

### 使用 rsync 同步

本地修改后，可以通过 rsync 同步到服务器：

```bash
rsync -avz --exclude 'node_modules' --exclude '.vitepress/dist' ./ user@server:/www/wwwroot/vitepress/
```

**排除目录**：

- `node_modules/`
  
- `.vitepress/dist/`（构建产物，无需同步）
  
- 可按需排除 `.cache` 或日志文件
  

---

### 构建流程

在服务器上：

```bash
cd /www/wwwroot/vitepress
yarn vitepress build
```

生成静态文件在 `.vitepress/dist/`，Nginx 指向此目录即可访问。

# 一级标题

## 二级标题

### 三级标题

#### 四级标题

##### 五级标题

###### 六级标题

看看是不是默认的目录只显示2-3级。显示2-3也刚好，全显示了反而杂乱

### 代码

MDX测试

```js "return true;" ins="插入" del="删除"
function demo() {
  console.log('这是插入以及删除类型的标记');
  // 返回语句使用默认标记类型
  return true;
}
```

代码带标题

```bash title="安装依赖…"
npm install
```

### 插图之图床

![vaultwarden-backup.service.svg](https://img.isrv.cn/code/vaultwarden-backup.service.svg)

## 插入本地图片

![鱼儿](/images/fish.png) ![鱼儿彩](/images/icons8-fish-64.png)

代码图片
![code](/images/screen_20251231_000417.png)

## 双层slug

1. [跳转文章不带后缀](../guides/001)

2. [跳转文章带md后缀](../guides/001.md)

## 以下这两个不带slug

3. [跳转文章不带后缀](../guides/002)

4. [跳转文章带md后缀](../guides/002.md)

## 这个直接指向slug

5. [哈哈](/america88)

---

## 4. Git 同步与常见坑

### 4.1 初始化仓库

```bash
git init
git branch -m main  # 与 GitHub 默认分支保持一致
git remote add origin git@github.com:luoxding/vitepress-docs.git
```

### 4.2 “dubious ownership” 错误

```
fatal: detected dubious ownership in repository
```

原因：Git 检测到当前目录权限和用户与安全策略不符（常见于 root 操作）。

解决方法：

```bash
git config --global --add safe.directory /www/wwwroot/vitepress
```

---

### 4.3 推送时被拒绝

```
Updates were rejected because the remote contains work that you do not have locally.
```

原因：远程仓库已有提交（如 README），与本地仓库不一致。

解决方法：

1. **安全合并**（推荐）：
   

```bash
git pull --rebase origin main
# 解决冲突
git add <file>
git rebase --continue
git push -u origin main
```

2. **强制覆盖**（谨慎）：
   

```bash
git push -u origin main --force
```

> ⚠️ 注意：强制推送会覆盖远程内容，只适合远程仓库为空或者只有 README 的情况。

---

### 4.4 rebase 冲突处理

- 冲突文件会包含 `<<<<<<< HEAD` 等标记
  
- 手动修改内容，然后：
  

```bash
git add <conflict_file>
git rebase --continue
```

直到完成 rebase，再 push。

---

## 5. 显示文章更新时间

VitePress 默认 `lastUpdated` 依赖 **Git 提交时间**，不是 frontmatter `lastUpdated` 字段：

```ts
// .vitepress/config.mts
export default defineConfig({
  lastUpdated: true,
  themeConfig: {
    lastUpdated: {
      text: '上次更新',
      formatOptions: { dateStyle: 'medium', timeStyle: 'short' }
    }
  }
})
```

**注意**：

- 如果没有 Git 仓库或本地未提交，`lastUpdated` 不会生效
  
- 写在 Markdown frontmatter 的 `lastUpdated` 是无效的
  
- 建议本地提交 → 同步到服务器 → 构建，这样更新时间才会显示
  

---

## ✅ 总结

- VitePress 需要 Node >=18
  
- 构建目录权限要正确，`.vitepress/dist` 可写
  
- rsync 排除 `node_modules` 和构建产物目录
  
- Git 在服务器用 root 时注意 `safe.directory`
  
- lastUpdated 依赖 Git 历史，前端 frontmatter 不生效
  
- GitHub 推送遇到冲突优先 `pull --rebase`，避免用 `--force`
  

---

如果你需要，我可以再帮你写一个 **服务器端一键同步 + 构建 + 推送到 GitHub 的脚本**，把 rsync + Git + VitePress 构建全流程自动化，保证安全和 lastUpdated 正常显示。

你希望我帮你写吗？