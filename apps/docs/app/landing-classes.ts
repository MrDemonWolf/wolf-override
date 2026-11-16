/*
 * Tailwind class lists the landing page and /design-system/ repeat. They live in a plain module, not in a component file,
 * so both the server-rendered page and the client phone menu can import them as strings.
 */

/**
 * Root of a page under the sticky SiteHeader (the landing page and /design-system/). data-landing on
 * the same element keeps it dark (see the end of global.css). overflow-clip, unlike overflow-hidden,
 * makes no scroll container, so the sticky header still sticks to the viewport.
 * [html:has(&)]:scroll-pt-24 sets scroll-padding-top on the page's scroller (html) while such a page
 * is shown: 6rem clears the sticky header (1rem offset + 4.75rem bar on wide screens, .5rem + about
 * 4.2rem on phones), so anchor targets land with their headings below the bar, and keyboard focus
 * scrolled into view is not hidden under it (WCAG 2.4.11).
 */
export const landingRoot = 'flow-root overflow-clip bg-ink text-text scheme-dark [html:has(&)]:scroll-pt-24';

/** Content column of the landing sections and footer: up to 1200px with a 2rem gutter, 1rem on phones. */
export const landingWidth = 'mx-auto w-[min(100%-4rem,1200px)] phone:w-[calc(100%-2rem)]';

/** Section heading (h2) of the landing page. */
export const sectionTitle = 'mb-6 text-section';

/** Body copy under a section heading. */
export const sectionCopy = 'mb-5 max-w-[58ch] leading-[1.8] text-muted';

/** Raised card: the feature cards, the gameplay frame and the progress links. */
export const card = 'rounded-card border border-line-strong bg-surface';

/**
 * Bulleted list on a dark page: muted copy with accent markers, one idea per item. Add a max-w-*
 * or text-* utility where a list needs its own measure or size.
 */
export const bulletList = 'flex list-disc flex-col gap-2 pl-5 leading-[1.6] text-muted marker:text-accent';

/** Link inside running copy: accent colour, underlined. For a link that closes a section use inlineLink. */
export const textLink = 'text-accent underline underline-offset-4';

/** Small outlined pill link (on-page section links, off-site "follow" links); 44px tall touch target. */
export const chipLink =
  'inline-flex min-h-11 items-center rounded-control border border-line-strong px-4 hover-always:border-accent hover-always:text-accent';

/** Underlined accent link that closes a section. */
export const inlineLink =
  'inline-flex min-h-11 items-center gap-3 py-[.65rem] leading-[1.5] text-accent underline underline-offset-[5px]';

/** Links of the header navigation and the phone menu. */
export const navLink =
  'inline-flex min-h-11 items-center rounded-control border border-transparent px-3 py-2 transition-[background-color,border-color,color] duration-180 ease-[ease] hover-always:border-accent/20 hover-always:bg-accent/10 hover-always:text-white focus-visible:border-accent/20 focus-visible:bg-accent/10 focus-visible:text-white motion-reduce:transition-none';
