import { designSystemPath } from '@/lib/press-kit';
import { repoUrl } from '@/lib/seo';

/*
 * The links of the site header (desktop bar and phone menu) and footer, shared by the landing page
 * and the design-system page. A plain module, not a component file, so both the server-rendered
 * header and footer and the client phone menu can import it.
 *
 * Links to landing sections are written "#story"; `withBase` prefixes them with the page's
 * `linkBase` ("" on the landing page itself, "/" elsewhere) so they reach the landing from any page.
 */

/** Returns `href` with `linkBase` in front when it is a landing-section anchor; other links are unchanged. */
export const withBase = (href: string, linkBase: string) => (href.startsWith('#') ? `${linkBase}${href}` : href);

/** Routes shared by the header and compact phone navigation. */
export const mainNavLinks = [
  ['/docs/', 'Project guide'],
  ['/docs/changelog/', 'History'],
  [designSystemPath, 'Press kit'],
] as const;

/** Credit, licensing and source links shared by the landing and press pages. */
export const footerGroups = [
  { title: 'Project', label: 'Project information', links: mainNavLinks },
  { title: 'Source', label: 'Project source', links: [[repoUrl, 'Source on GitHub'], ['/docs/development/testing/', 'Development checks']] },
  { title: 'Attribution', label: 'Attribution and rights', links: [['/docs/credits/', 'Credits'], ['/docs/legal/', 'Licensing'], ['/docs/privacy/', 'Privacy']] },
] as const;
