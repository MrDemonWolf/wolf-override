import type { BreadcrumbItem } from 'fumadocs-core/breadcrumb';
import { getBreadcrumbItems } from 'fumadocs-core/breadcrumb';
import { plannedPlatforms } from '@/app/downloads';
import { siteDescription, siteUrl } from '@/lib/seo';
import { source } from '@/lib/source';

/*
 * schema.org JSON-LD for search engines (Google structured-data guides, checked 2026-10-16).
 * Only facts the site already states go in: no offers, prices, ratings or reviews until they are
 * real (inventing them breaks Google's spam policy), and `sameAs` lists only profile links
 * Nathanial Henniges has confirmed. Google shows no rich result for a VideoGame without ratings,
 * so the game entry is for entity understanding, not a search feature.
 */

type JsonLdObject = Record<string, unknown>;

/** Stable node ids, so the home page's entries can point at each other inside one @graph. */
const ids = {
  website: `${siteUrl}/#website`,
  organization: `${siteUrl}/#organization`,
  game: `${siteUrl}/#game`,
  author: `${siteUrl}/#nathanial-henniges`,
};

/**
 * The landing page's graph: WebSite (the site name Google shows in results; home page only),
 * Organization (the publisher) and VideoGame (the game itself), with the author as a Person.
 */
export function homeStructuredData(): JsonLdObject {
  return {
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'WebSite',
        '@id': ids.website,
        name: 'WOLF OVERRIDE',
        // The stylised name the game had until October 17, 2026, kept so older links and listings match.
        alternateName: ['WOLF//OVERRIDE'],
        url: `${siteUrl}/`,
        inLanguage: 'en',
        publisher: { '@id': ids.organization },
      },
      {
        '@type': 'Organization',
        '@id': ids.organization,
        name: 'MrDemonWolf, Inc.',
        url: 'https://www.mrdemonwolf.com',
      },
      {
        '@type': 'Person',
        '@id': ids.author,
        name: 'Nathanial Henniges',
        url: 'https://mrdemonwolf.com',
      },
      {
        '@type': 'VideoGame',
        '@id': ids.game,
        name: 'WOLF OVERRIDE',
        // Same former name as the WebSite entry, as IGDB also lists it.
        alternateName: ['WOLF//OVERRIDE'],
        description: siteDescription,
        url: `${siteUrl}/`,
        image: `${siteUrl}/share-card.jpg`,
        genre: ['Horror', 'Science fiction', 'Adventure'],
        // The landing page's planned platforms, so the two never disagree.
        gamePlatform: plannedPlatforms.map((platform) => platform.name),
        inLanguage: 'en',
        author: { '@id': ids.author },
        creator: { '@id': ids.author },
        publisher: { '@id': ids.organization },
        // The public source repository, already linked from every guide page.
        sameAs: ['https://github.com/MrDemonWolf/wolf-override'],
      },
    ],
  };
}

/**
 * BreadcrumbList for a guide page: Home > guide root > section > page, from the Fumadocs page
 * tree so renamed sections follow automatically. `pageUrl` is the page's `page.url` (no trailing
 * slash). Section folders without their own page have no URL and are skipped (Google needs an
 * `item` URL on crumbs), and a section index page is listed once. Always at least two items
 * (Google's minimum): the guide index itself is Home > guide root.
 */
export function breadcrumbStructuredData(pageUrl: string): JsonLdObject {
  const tree = source.getPageTree();
  const trail: BreadcrumbItem[] = [
    { name: 'Home', url: '/' },
    { name: tree.name, url: '/docs' },
    // The guide index is the root crumb itself; deeper pages add their sections and themselves.
    ...(pageUrl === '/docs' ? [] : getBreadcrumbItems(pageUrl, tree, { includePage: true })),
  ];
  // A section's index page appears twice (as the folder and as the page): keep the first.
  const crumbs = trail.filter(
    (item, index): item is { name: string; url: string } =>
      typeof item.name === 'string' && typeof item.url === 'string' && trail.findIndex((other) => other.url === item.url) === index,
  );
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: crumbs.map((item, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: item.name,
      item: `${siteUrl}${item.url === '/' ? '/' : `${item.url}/`}`,
    })),
  };
}

/**
 * Renders one JSON-LD block. `<` is escaped so page text can never close the script tag
 * (the pattern in Next's JSON-LD guide); JSON parsers read `<` back as `<`.
 */
export function JsonLd({ data }: { data: JsonLdObject }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data).replace(/</g, '\\u003c') }}
    />
  );
}
