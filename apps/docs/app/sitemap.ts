import type { MetadataRoute } from 'next';
import { source } from '@/lib/source';
import { siteUrl } from '@/lib/seo';

export const dynamic = 'force-static';

/**
 * sitemap.xml: the landing page plus every guide page, with trailing slashes matching the
 * canonicals. Guide pages carry their last Git commit date as <lastmod> (see source.config.ts);
 * the landing page is built from several components with no single date, so it has none rather
 * than a guessed one. Google ignores priority and changefreq, so neither is set.
 */
export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: `${siteUrl}/` },
    ...source.getPages().map((page) => ({ url: `${siteUrl}${page.url}/`, lastModified: page.data.lastModified })),
  ];
}
