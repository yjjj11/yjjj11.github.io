import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const blog = defineCollection({
	// Load Markdown and MDX files in the `src/content/blog/` directory.
	loader: glob({ base: './src/content/blog', pattern: '**/*.{md,mdx}' }),
	// Type-check frontmatter using a schema
	schema: ({ image }) =>
		z.object({
			title: z.string(),
			description: z.string(),
			// Transform string to Date object
			pubDate: z.coerce.date(),
			updatedDate: z.coerce.date().optional(),
			heroImage: z.optional(image()),
			category: z.string().optional(),
			tags: z.array(z.string()).optional(),
		}),
});

// 项目页：手动维护的项目列表（每项目一个 md，正文写综述）
const projects = defineCollection({
	loader: glob({ base: './src/content/projects', pattern: '**/*.{md,mdx}' }),
	schema: z.object({
		title: z.string(),
		description: z.string(),
		github: z.string().url(),
		category: z.string(),
		tech: z.array(z.string()).default([]),
		order: z.number().default(0),
	}),
});

// 问题解决页：踩坑记录（每问题一个 md，正文写问题描述 + 解决办法）
const solutions = defineCollection({
	loader: glob({ base: './src/content/solutions', pattern: '**/*.{md,mdx}' }),
	schema: z.object({
		title: z.string(),
		description: z.string(),
		category: z.string(),
		tags: z.array(z.string()).default([]),
		pubDate: z.coerce.date(),
	}),
});

export const collections = { blog, projects, solutions };
