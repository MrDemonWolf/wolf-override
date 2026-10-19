import { defineConfig, defineDocs, frontmatterSchema, metaSchema } from 'fumadocs-mdx/config';

/**
 * Front matter every guide page must carry. Fumadocs' own schema leaves `description` optional;
 * here it is required, because it is the page's search snippet, social card text and the line
 * under the title, and a missing one used to fall back to boilerplate. The limits come from the
 * SEO plan (2026-10-16): Google trims snippets at about 150-160 characters, and a line under
 * 80 says too little to be picked over an extract from the page. `seoTitle` is an optional
 * search-only title for pages whose short sidebar title ("Controls") lacks the words people
 * search for; 44 characters plus the " | WOLF OVERRIDE" suffix (16) stays inside the about 60
 * characters Google shows. Both reuse Fumadocs' ZodString so the docs app needs no own zod copy.
 */
const text = frontmatterSchema.shape.title;
const guideFrontmatter = frontmatterSchema.extend({
  description: text
    .min(80, 'description: write at least 80 characters (it is the search snippet)')
    .max(160, 'description: keep it to 160 characters (search results cut it off after that)'),
  seoTitle: text.max(44, 'seoTitle: keep it to 44 characters (60 with " | WOLF OVERRIDE")').optional(),
});

export const docs = defineDocs({
  dir: 'content/docs',
  docs: {
    schema: guideFrontmatter,
    // Each page's last Git commit date (`page.data.lastModified`, a Date) feeds the sitemap's
    // <lastmod>. CI must check out full history (fetch-depth: 0 in .github/workflows/docs.yml):
    // a shallow clone gives every file the same date, and Google ignores lastmod that is not
    // "consistently and verifiably" accurate.
    lastModified: true,
    // Keeps a Markdown copy of each page (`getText('processed')`) for llms.txt, llms-full.txt and
    // the per-page .md files (lib/source.ts). `function` output lets <Screenshot> and <LinkCards>
    // write their own Markdown through asMarkdown() instead of leaking as raw JSX; headingIds off
    // drops the `[#anchor]` suffixes Fumadocs would add to every heading.
    postprocess: { includeProcessedMarkdown: { headingIds: false, output: 'function' } },
  },
  meta: { schema: metaSchema },
});

export default defineConfig({});
