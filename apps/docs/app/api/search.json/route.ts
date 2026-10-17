import { createFromSource } from 'fumadocs-core/search/server';
import { source } from '@/lib/source';

// A static export only prerenders route handlers marked force-static (Next static-exports guide).
export const dynamic = 'force-static';

/**
 * The guide's search index at /api/search.json, written once at `next build` as a static JSON file.
 * The .json name makes GitHub Pages serve it as application/json, which it can compress (about
 * 1.9 MB raw, mostly the changelog's full notes); an extensionless file would go out uncompressed.
 * The search dialog (RootProvider `type: 'static'` in app/layout.tsx) downloads it the first time
 * a reader opens search and runs every query in the browser, so search works on GitHub Pages,
 * which has no server. It indexes every guide page's title, description, headings and text; the
 * landing page is not a guide page and is not in it.
 */
export const { staticGET: GET } = createFromSource(source);
