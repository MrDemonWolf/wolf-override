import { docsLlms } from '@/lib/source';

// A static export only prerenders route handlers marked force-static (Next static-exports guide).
export const dynamic = 'force-static';

/** /llms-full.txt: every guide page as Markdown, in page-tree order (llmstxt.org companion file). */
export async function GET() {
  return new Response(await docsLlms.full(), { headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
}
