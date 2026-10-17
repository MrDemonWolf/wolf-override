import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { DocsBody, DocsDescription, DocsTitle } from 'fumadocs-ui/layouts/docs/page';
import { GuidePage } from '@/app/docs/guide-page';
import { createRelativeLink } from 'fumadocs-ui/mdx';
import { getMDXComponents } from '@/mdx-components';
import { markdownUrl, source } from '@/lib/source';
import { pageMetadata } from '@/lib/seo';
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

export default async function Page({ params }: PageProps) {
  const { slug } = await params;
  const page = source.getPage(slug);
  if (!page) notFound();
  const MDX = page.data.body;

  return (
    <GuidePage toc={page.data.toc} full={page.data.full}>
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
  return pageMetadata(page.data.title, page.data.description ?? `Read ${page.data.title} in the WOLF OVERRIDE game guide.`, `${page.url}/`, markdownUrl(page.url));
}
