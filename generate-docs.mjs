import fs from 'fs';
import path from 'path';

// 你的侧边栏配置
const sidebar = [
  {
    label: "🧭 开始",
    items: [
      { label: "知识地图", link: "/knowledge-map" },
      { label: "阅读指南", link: "/reading-guide" }
    ]
  },
  {
    label: "🖥 服务器",
    items: [
      { label: "Linux 基础", link: "/linux-base" },
      { label: "系统管理", link: "/system-admin" },
      { label: "网络与安全", link: "/network-security" },
      { label: "性能优化", link: "/performance" }
    ]
  },
  {
    label: "🚀 部署与运维",
    items: [
      { label: "Docker", link: "/docker-index" },
      { label: "Nginx", link: "/nginx-index" },
      { label: "数据库", link: "/database-index" },
      { label: "CI/CD", link: "/cicd-index" }
    ]
  },
  {
    label: "🛠 工具与应用",
    items: [
      { label: "开发工具", link: "/dev-tools" },
      { label: "服务器面板", link: "/panel-tools" },
      { label: "常用软件记录", link: "/software-notes" }
    ]
  },
  {
    label: "📖 个人记录",
    items: [
      { label: "学习笔记", link: "/study-notes" },
      { label: "工作记录", link: "/work-notes" },
      { label: "生活见闻", link: "/life-notes" }
    ]
  }
];

const docsDir = path.join(process.cwd(), 'src/content/docs');

// 递归创建目录和文件
sidebar.forEach(section => {
  section.items.forEach(item => {
    // 移除 link 开头的斜杠，并添加 .md 后缀
    const fileName = `${item.link.replace(/^\//, '')}.md`;
    const filePath = path.join(docsDir, fileName);
    
    // 提取 slug (去掉开头的斜杠)
    const slug = item.link.replace(/^\//, '');

    const content = `---
title: ${item.label}
slug: ${slug}
---

这是 ${item.label} 的初始内容。
`;

    // 确保父目录存在
    fs.mkdirSync(path.dirname(filePath), { recursive: true });

    // 写入文件（如果文件不存在则创建，避免覆盖已有内容）
    if (!fs.existsSync(filePath)) {
      fs.writeFileSync(filePath, content);
      console.log(`✅ 已创建: ${fileName}`);
    } else {
      console.log(`⚠️ 跳过已存在的文件: ${fileName}`);
    }
  });
});

// node generate-docs.mjs // 执行脚本，生成对应文件。
