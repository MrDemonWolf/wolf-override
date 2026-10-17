import { notFound } from 'next/navigation';
import { docsLlms, source } from '@/lib/source';

// A static export only prerenders route handlers marked force-static (Next static-exports guide).
export const dynamic = 'force-static';
export const dynamicParams = false;

type RouteContext = { params: Promise<{ slug?: string[] }> };

/**
 * One Markdown file per guide page at /llms.mdx/docs/<slug>/index.md (see markdownUrl in
 * lib/source.ts). The last slug segment is always `index.md`, the file name the export writes;
 * the segments before it pick the page. GitHub Pages serves .md as text/markdown by extension, so
 * the header here only matters in `next dev`.
 */
export async function GET(_request: Request, { params }: RouteContext) {
  const { slug } = await params;
  const page = source.getPage(slug?.slice(0, -1));
  if (!page) notFound();
  return new Response(await docsLlms.page(page), { headers: { 'Content-Type': 'text/markdown; charset=utf-8' } });
}

export function generateStaticParams() {
  return source.generateParams().map((params) => ({ slug: [...(params.slug ?? []), 'index.md'] }));
}
