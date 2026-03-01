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
