import { docs } from 'fumadocs-mdx:collections/server';
import { llms, loader } from 'fumadocs-core/source';
import { siteUrl } from '@/lib/seo';
import { getMDXComponents } from '@/mdx-components';

/** The guide's pages and page tree, served under /docs. */
export const source = loader({
  baseUrl: '/docs',
  source: docs.toFumadocsSource(),
});

/**
 * Path of a guide page's Markdown copy, written by app/llms.mdx/docs/[[...slug]]/route.ts.
 * `pageUrl` is `page.url` (`/docs/controls/input`); the result is
 * `/llms.mdx/docs/controls/input/index.md`. The copies live outside /docs because the guide's
 * optional catch-all route cannot have a segment after it, and a static export cannot rewrite
 * `/docs/<slug>.md` to them.
 */
export function markdownUrl(pageUrl: string): string {
  return `${pageUrl.replace(/^\/docs/, '/llms.mdx/docs')}/index.md`;
}

/**
 * llms.txt (`index()`), llms-full.txt (`full()`) and one page's Markdown (`page()`), all rendered
 * at `next build`. Each page starts with its title, absolute URL and description, then the body
 * as Markdown with the guide's own MDX components (they switch to Markdown via asMarkdown()).
 */
export const docsLlms = llms(source, {
  renderPage: async (page) =>
    `# ${page.data.title}\n\nURL: ${siteUrl}${page.url}/\n\n${page.data.description ?? ''}\n\n` +
    (await page.data.getText('processed', { components: getMDXComponents() })),
});
