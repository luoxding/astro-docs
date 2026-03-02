// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightScrollToTop from 'starlight-scroll-to-top';

export default defineConfig({
	site: 'https://docs.isrv.cn',
	integrations: [
		starlight({
			title: '时空知识库',
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
				{ label: '介绍', slug: 'readme' },
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
					position: 'right',
					tooltipText: {
						'zh-cn': '回到顶部',
					},
					showTooltip: true,
					smoothScroll: true,
					threshold: 10,
					svgPath: 'M12 4C10 6 9 8 9 12V18H15V12C15 8 14 6 12 4M10 18L12 22L14 18',
					svgStrokeWidth: 1,
					borderRadius: '50',
					showProgressRing: true,
					progressRingColor: '#ff6b6b',
					showOnHomepage: false,
				})
			],
			editLink: {
				baseUrl: 'https://github.com/luoxding/astro-docs/edit/main/',
			},
			// 全局中文化
			translations: {
				'zh-cn': {
					lastUpdated: '最后更新',
					previous: '上一页',
					next: '下一页',
					search: '搜索',
					edit: '编辑此页',
				},
			},
		}),
	],
});
