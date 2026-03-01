// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightScrollToTop from 'starlight-scroll-to-top';

export default defineConfig({
	site: 'https://docs.isrv.cn',
	integrations: [
		starlight({
			title: '时空知识库',
			sidebar: [
				{
					label: '简介',
					items: [
						// Each item here is one entry in the navigation menu.
						{ label: '服务器笔记', slug: 'readme' },
					],
				},
				{
					label: '指南',
					autogenerate: { directory: 'guides' },
				},
				{
					label: '参考',
					autogenerate: { directory: 'reference' },
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
					threshold: 20,
					// Customize the SVG icon
					svgPath: 'M25 42 12 29 42 29Z',
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
	// i18n: {
	// 	locales: ["zh-cn"],
	// 	defaultLocale: "zh-cn",
	// },
});
