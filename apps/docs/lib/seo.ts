import type { Metadata } from 'next';

export const siteUrl = 'https://wolfoverride.mrdemonwolf.dev';
/** The public source repository on GitHub: the game, this website and their history. */
export const repoUrl = 'https://github.com/MrDemonWolf/wolf-override';
/** The publisher MrDemonWolf, Inc.'s official website: the JSON-LD Organization's `url` and the footer link. */
export const publisherUrl = 'https://www.mrdemonwolf.com';
/**
 * The publisher's official profiles, each with the name it is listed under on the design-system
 * page and in the press kit's FACTS.txt. Confirmed by Nathanial Henniges for MrDemonWolf, Inc.'s
 * IGDB company entry (2026-10-18); add a profile here only once he has confirmed it.
 */
export const publisherProfileLinks = [
  { label: 'Twitch', url: 'https://twitch.tv/mrdemonwolf' },
  { label: 'YouTube', url: 'https://youtube.com/@mrdemonwolf' },
  { label: 'GitHub', url: 'https://github.com/MrDemonWolf' },
  { label: 'Discord', url: 'https://discord.com/invite/A9x3qEN' },
  { label: 'X', url: 'https://x.com/mrdemonwolf' },
  { label: 'Bluesky', url: 'https://bsky.app/profile/mrdemonwolf.com' },
  { label: 'LinkedIn', url: 'https://www.linkedin.com/company/mrdemonwolf' },
] as const;
/** The profile URLs alone: the JSON-LD Organization's `sameAs`, so search engines tie them to the same company. */
export const publisherProfiles = publisherProfileLinks.map((profile) => profile.url);
/**
 * The landing page's search snippet and the game's JSON-LD description. Kept under the about 155
 * characters Google shows before it trims a snippet (SEO plan, 2026-10-16).
 */
export const siteDescription = 'WOLF OVERRIDE is returning to story development. Find the Godot project, prototype history and credits for the game by Nathanial Henniges and MrDemonWolf, Inc.';

/**
 * How a page title reads in the browser tab and search results: the root layout's title template,
 * and the guide pages' social-card titles, which Next does not run through that template.
 */
export const titleTemplate = '%s | WOLF OVERRIDE';

/**
 * Title, description, canonical and social-card metadata for one page. `path` is the page's
 * site path with its trailing slash (`/docs/about/`). Guide pages also pass `guide`:
 * - `markdownPath`, the path of the page's Markdown copy, becomes
 *   `<link rel="alternate" type="text/markdown">`, the way llmstxt.org asks pages to point AI
 *   tools at their Markdown;
 * - the card becomes `og:type` article (a page of a site, not the site itself) with the game name
 *   in its title (`Controls | WOLF OVERRIDE`), since a shared link otherwise shows only "Controls";
 * - `modifiedTime`, the page's last Git commit date (source.config.ts `lastModified`), becomes
 *   `article:modified_time`; it is left out when unknown rather than guessed.
 */
export function pageMetadata(
  title: string,
  description: string,
  path: string,
  guide?: { markdownPath: string; modifiedTime?: Date },
): Metadata {
  const url = `${siteUrl}${path}`;
  // Use the site-owned brand asset so link previews remain independent of the game runtime.
  const image = { url: `${siteUrl}/brand/wolf-override-stacked-1500x1000-for-dark-bg.png`, width: 1500, height: 1000, alt: 'The WOLF OVERRIDE logo.' };
  const cardTitle = guide ? titleTemplate.replace('%s', title) : title;
  const card = { siteName: 'WOLF OVERRIDE', title: cardTitle, description, url, locale: 'en_US', images: [image] };
  return {
    title,
    description,
    alternates: { canonical: url, ...(guide && { types: { 'text/markdown': `${siteUrl}${guide.markdownPath}` } }) },
    openGraph: guide
      ? { ...card, type: 'article', ...(guide.modifiedTime && { modifiedTime: guide.modifiedTime.toISOString() }) }
      : { ...card, type: 'website' },
    twitter: { card: 'summary_large_image', title: cardTitle, description, images: [image] },
  };
}
