import { defineConfig, defineDocs, frontmatterSchema, metaSchema } from 'fumadocs-mdx/config';

export const docs = defineDocs({
  dir: 'content/docs',
  docs: {
    schema: frontmatterSchema,
    // Each page's last Git commit date (`page.data.lastModified`, a Date) feeds the sitemap's
    // <lastmod>. CI must check out full history (fetch-depth: 0 in .github/workflows/docs.yml):
    // a shallow clone gives every file the same date, and Google ignores lastmod that is not
    // "consistently and verifiably" accurate.
    lastModified: true,
  },
  meta: { schema: metaSchema },
});

export default defineConfig({});
