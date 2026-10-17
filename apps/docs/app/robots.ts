import type { MetadataRoute } from 'next';
import { siteUrl } from '@/lib/seo';

// A static export only writes metadata routes marked force-static (Next static-exports guide).
export const dynamic = 'force-static';

/**
 * robots.txt: every crawler may read the whole site, and the Sitemap line points crawlers at
 * sitemap.xml (Google's sitemap guide asks for it here). Exported as out/robots.txt.
 */
export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: '*', allow: '/' },
    sitemap: `${siteUrl}/sitemap.xml`,
  };
}
