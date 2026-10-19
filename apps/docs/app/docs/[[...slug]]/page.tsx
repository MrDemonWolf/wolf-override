import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { DocsBody, DocsDescription, DocsTitle } from 'fumadocs-ui/layouts/docs/page';
import { GuidePage } from '@/app/docs/guide-page';
import { createRelativeLink } from 'fumadocs-ui/mdx';
import { getMDXComponents } from '@/mdx-components';
import { markdownUrl, source } from '@/lib/source';
import { pageMetadata } from '@/lib/seo';
import SiteCopyright from '@/app/site-copyright';
import { breadcrumbStructuredData, JsonLd } from '@/lib/structured-data';

type PageProps = { params: Promise<{ slug?: string[] }> };

/**
 * Reading width for the guide's running text: about 70 characters per line, the upper end of the
 * 45 to 75 character range usually advised for comfortable reading. Only text blocks (the
 * description, paragraphs, lists, quotes and headings) are capped; tables, cards, screenshots and
 * code blocks keep the full column, so wide tables do not start scrolling sooner.
 */
const readingWidth = 'max-w-[70ch]';
const bodyReadingWidth = '[&>:is(p,ul,ol,blockquote,h2,h3,h4)]:max-w-[70ch]';

/**
 * The copyright line under every guide page, below Fumadocs' previous and next page links (its
 * footer slot renders `children` after them, inside the page's article). The same line as the
 * landing page footer (site-copyright.tsx); a <footer> in an article is the article's footer, not
 * a second contentinfo landmark.
 */
const guideFooter = (
  <footer className="mt-6 border-t border-fd-border pt-5 text-sm text-fd-muted-foreground">
    <SiteCopyright />
  </footer>
);

export default async function Page({ params }: PageProps) {
  const { slug } = await params;
  const page = source.getPage(slug);
  if (!page) notFound();
  const MDX = page.data.body;

  return (
    <GuidePage toc={page.data.toc} full={page.data.full} footer={{ children: guideFooter }}>
      <JsonLd data={breadcrumbStructuredData(page.url)} />
      <DocsTitle id="main-content" tabIndex={-1}>{page.data.title}</DocsTitle>
      <DocsDescription className={readingWidth}>{page.data.description}</DocsDescription>
      <DocsBody className={bodyReadingWidth}>
        <MDX components={getMDXComponents({ a: createRelativeLink(source, page) })} />
      </DocsBody>
    </GuidePage>
  );
}

export function generateStaticParams() {
  return source.generateParams();
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const page = source.getPage(slug);
  if (!page) notFound();
  // seoTitle (source.config.ts) replaces the sidebar title only in <title> and the social cards;
  // the page's heading and menu entry keep the short title.
  return pageMetadata(page.data.seoTitle ?? page.data.title, page.data.description, `${page.url}/`, {
    markdownPath: markdownUrl(page.url),
    modifiedTime: page.data.lastModified,
  });
}
