/*
 * Tailwind class lists the landing page repeats. They live in a plain module, not in a component file,
 * so both the server-rendered page and the client phone menu can import them as strings.
 */

/** Content column of the landing sections and footer: up to 1200px with a 2rem gutter, 1rem on phones. */
export const landingWidth = 'mx-auto w-[min(100%-4rem,1200px)] phone:w-[calc(100%-2rem)]';

/** Section heading (h2) of the landing page. */
export const sectionTitle = 'mb-6 text-section';

/** Body copy under a section heading. */
export const sectionCopy = 'mb-5 max-w-[58ch] leading-[1.8] text-muted';

/** Raised card: the feature cards, the gameplay frame and the progress links. */
export const card = 'rounded-card border border-line-strong bg-surface';

/** Underlined accent link that closes a section. */
export const inlineLink =
  'inline-flex min-h-11 items-center gap-3 py-[.65rem] leading-[1.5] text-accent underline underline-offset-[5px]';

/** Links of the header navigation and the phone menu. */
export const navLink =
  'inline-flex min-h-11 items-center rounded-control border border-transparent px-3 py-2 transition-[background-color,border-color,color] duration-180 ease-[ease] hover-always:border-accent/20 hover-always:bg-accent/10 hover-always:text-white focus-visible:border-accent/20 focus-visible:bg-accent/10 focus-visible:text-white motion-reduce:transition-none';
