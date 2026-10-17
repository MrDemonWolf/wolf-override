import type { Metadata } from 'next';

export const siteUrl = 'https://wolfoverride.mrdemonwolf.dev';
export const siteDescription = 'A side-view sci-fi horror adventure by MrDemonWolf, Inc. Explore THE DEN with an independent robotic wolf, solve puzzles and make choices he remembers. In development.';

/**
 * Title, description, canonical and social-card metadata for one page. `path` is the page's
 * site path with its trailing slash (`/docs/about/`). `markdownPath`, for guide pages, is the
 * path of the page's Markdown copy; it becomes `<link rel="alternate" type="text/markdown">`,
 * the way llmstxt.org asks pages to point AI tools at their Markdown.
 */
export function pageMetadata(title: string, description: string, path: string, markdownPath?: string): Metadata {
  const url = `${siteUrl}${path}`;
  // Social cards get a 1200x630 crop of the provisional key art that keeps both characters (JPEG for the widest crawler support).
  const image = { url: `${siteUrl}/share-card.jpg`, width: 1200, height: 630, alt: 'WOLF//OVERRIDE provisional key art: an engineer and robotic wolf in a research corridor.' };
  return {
    title,
    description,
    alternates: { canonical: url, ...(markdownPath && { types: { 'text/markdown': `${siteUrl}${markdownPath}` } }) },
    openGraph: { type: 'website', siteName: 'WOLF//OVERRIDE', title, description, url, locale: 'en_US', images: [image] },
    twitter: { card: 'summary_large_image', title, description, images: [image] },
  };
}
