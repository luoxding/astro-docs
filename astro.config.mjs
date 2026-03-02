// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightScrollToTop from 'starlight-scroll-to-top';

export default defineConfig({
	site: 'https://docs.isrv.cn',
	integrations: [
		starlight({
			title: '时空知识库',
			// locale: 'zh-cn',   // 👈 简体中文
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
				// {
				// label: '简介',
				// items: [
				// Each item here is one entry in the navigation menu.
				{ label: '介绍', slug: 'readme' },
				// ],
				// },
				{
					label: '指南',
					autogenerate: { directory: 'guides', collapsed: true },
				},
				{
					label: '参考',
					autogenerate: { directory: 'reference', collapsed: true },
				},
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
