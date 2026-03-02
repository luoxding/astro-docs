// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightScrollToTop from 'starlight-scroll-to-top';

export default defineConfig({
	site: 'https://docs.isrv.cn',
	integrations: [
		starlight({
			title: '知鱼档案',
			// 1. 设置默认语言
			defaultLocale: 'zh-cn',
			// 2. 配置语言字典（root 表示根目录直接使用该语言）
			locales: {
				root: {
					label: '简体中文',
					lang: 'zh-CN', // 注意：这里通常建议用标准格式 zh-CN
				},
			},
			favicon: '/images/icons8-leaf-64.png',
			lastUpdated: true,
			social: [
				{
					icon: 'github',
					label: 'GitHub',
					href: 'https://github.com/luoxding/astro-docs',
				},
			],
			sidebar: [
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
				},

				{
					label: '参考资料及杂项',
					autogenerate: { directory: 'reference', collapsed: true },
				}

			],
			plugins: [
				starlightScrollToTop({
					// Button position
					position: 'right',
					// Tooltip text (supports I18N)
					tooltipText: {
						'en': 'Scroll to top',
						'zh-cn': '回到顶部',
						'es': 'Ir arriba',
						'fr': 'Retour en haut',
						'pt': 'Voltar ao topo',
						'de': 'Nach oben scrollen'
					},
					showTooltip: true,
					// Use smooth scrolling
					smoothScroll: true,
					// Visibility threshold (show after scrolling 20% down)
					threshold: 10,
					// Customize the SVG icon
					svgPath: 'M12 4C10 6 9 8 9 12V18H15V12C15 8 14 6 12 4M10 18L12 22L14 18',
					svgStrokeWidth: 1,
					borderRadius: '50',
					// Show scroll progress ring
					showProgressRing: true,
					// Customize progress ring color
					progressRingColor: '#ff6b6b',
					// Control homepage visibility
					showOnHomepage: false,
				})
			],
			editLink: {
				baseUrl: 'https://github.com/luoxding/astro-docs/edit/main/',
			},
			//   footer: {
			//     copyright:
			//       '© 2026 Ding · 服务器知识库 · Powered by Astro & Starlight',
			//   },
		}),
	],
});
