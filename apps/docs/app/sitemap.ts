import type { MetadataRoute } from 'next';
import { source } from '@/lib/source';
import { siteUrl } from '@/lib/seo';
import { designSystemPath } from '@/lib/press-kit';

export const dynamic = 'force-static';

/**
 * sitemap.xml: the landing page, the design-system page and every guide page, with trailing slashes
 * matching the canonicals. Guide pages carry their last Git commit date as <lastmod> (see
 * source.config.ts); the landing and design-system pages are built from several components and data
 * files with no single date, so they have none rather than a guessed one. Google ignores priority and changefreq, so neither is set.
 */
export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: `${siteUrl}/` },
    { url: `${siteUrl}${designSystemPath}` },
    ...source.getPages().map((page) => ({ url: `${siteUrl}${page.url}/`, lastModified: page.data.lastModified })),
  ];
}
