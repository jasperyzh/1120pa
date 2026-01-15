import { defineCollection, z } from 'astro:content';

const blogCollection = defineCollection({
    type: 'content',
    schema: z.object({
        title: z.string(),
        pubDate: z.date(),
        description: z.string(),
        category: z.enum(['event', 'announcement', 'info']),
    }),
});

export const collections = {
    'blog': blogCollection,
};
