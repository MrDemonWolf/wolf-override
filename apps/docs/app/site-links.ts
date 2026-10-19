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

/** The header's main navigation: three landing sections and the guide. */
export const mainNavLinks = [
  ['#story', 'Story'],
  ['#gameplay', 'Gameplay'],
  ['#downloads', 'Get the build'],
  ['/docs/', 'Game guide'],
] as const;

/** The footer's link groups: a visible title, the nav landmark's accessible name and its links. */
export const footerGroups = [
  {
    title: 'Explore',
    label: 'Explore the game',
    links: [
      ['#story', 'Story'],
      ['#gameplay', 'Gameplay'],
      ['#downloads', 'Get the build'],
    ],
  },
  {
    title: 'Player guide',
    label: 'Player guide',
    links: [
      ['/docs/controls/first-steps/', 'First steps'],
      ['/docs/', 'All game docs'],
      ['/docs/changelog/', 'Changelog'],
    ],
  },
  {
    title: 'Project',
    label: 'Project information',
    links: [
      ['/docs/development/story/', 'Development story'],
      [designSystemPath, 'Press kit & brand'],
      ['/docs/credits/', 'Credits & references'],
      ['/docs/legal/', 'Legal & licensing'],
      ['/docs/privacy/', 'Privacy'],
      ['/docs/support/', 'Support'],
    ],
  },
  {
    title: 'Developers',
    label: 'Developer guide',
    links: [
      ['/docs/development/', 'Developer home'],
      ['/docs/development/setup/', 'Setup'],
      ['/docs/development/testing/', 'Testing & CI'],
      [repoUrl, 'Source on GitHub'],
    ],
  },
] as const;
