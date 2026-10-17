import type { ComponentProps } from 'react';
import type { StaticImageData } from 'next/image';
import { asMarkdown } from 'fumadocs-core/server';
import { siteUrl } from '@/lib/seo';

/*
 * MDX components for the guide pages. When lib/source.ts renders a page to Markdown for llms.txt,
 * asMarkdown() is true and each component returns its own Markdown (absolute links, so the text
 * still works outside the site) instead of HTML.
 *
 * Styling: Tailwind utilities and Fumadocs' --color-fd-*
 * tokens so they follow the guide's light and dark themes. They render inside Fumadocs' `prose`
 * body; the typography plugin's rules sort after the margin-block utilities and before the
 * margin-top and margin-bottom ones, so margins here use separate top and bottom utilities.
 */

/** Wide screenshot (960px) with its half-size (480px) variant and, optionally, a larger copy the link opens. */
type ScreenshotProps = {
  image: StaticImageData;
  small: StaticImageData;
  large?: StaticImageData;
  alt: string;
  caption: string;
};

/**
 * A build screenshot that links to the full-size image in a new tab. The link names itself from the
 * image's alt text plus a visually hidden note that it opens the full-size image in a new tab.
 * The link clips the image to the frame's top corners; the figure stays unclipped so the shared
 * focus ring shows. The image and caption reset the typography margins (2em and .857em) that
 * otherwise open gaps above and below the image inside the frame.
 */
export function Screenshot({ image, small, large, alt, caption }: ScreenshotProps) {
  const full = large ?? image;
  if (asMarkdown()) return `![${alt}](${siteUrl}${full.src})\n\n*${caption}*\n\n`;
  return (
    <figure className="mt-6 mb-8 rounded-card border border-fd-border bg-fd-card">
      <a className="block overflow-hidden rounded-t-[calc(var(--radius-card)-1px)]" href={full.src} target="_blank" rel="noopener noreferrer">
        <img
          className="mt-0 mb-0 w-full"
          src={image.src}
          srcSet={`${small.src} ${small.width}w, ${image.src} ${image.width}w${large ? `, ${large.src} ${large.width}w` : ''}`}
          sizes="(min-width: 680px) 680px, 100vw"
          alt={alt}
          width={image.width}
          height={image.height}
          loading="lazy"
          decoding="async"
        />
        <span className="sr-only">(full-size image, opens in a new tab)</span>
      </a>
      <figcaption className="mt-0 px-4 py-[.8rem] text-[.85rem]/[1.55] text-fd-muted-foreground">{caption}</figcaption>
    </figure>
  );
}

type GuideLink = { href: string; title: string; description: string };

type LinkCardsProps = {
  /** Accessible name of the navigation landmark. */
  label: string;
  links: GuideLink[];
  /** `cards`: the guide's section index. `actions`: the download and setup buttons. */
  variant?: 'cards' | 'actions';
};

/*
 * Glass link card: a primary-tinted border and gradient over the page background, lifted 2px on
 * hover (not under reduced motion). The prose link styles still apply underneath (font weight and
 * the .8 opacity on hover); the underline and link colour are replaced here. The tints mix in
 * sRGB like the stylesheet they replace (the /opacity modifiers mix in OKLab), and the gradient
 * keeps a second, empty `none` layer over the background colour: with a single layer Chrome
 * anti-aliases the rounded corners one colour step differently.
 */
const linkCard =
  'flex flex-col gap-[.35rem] rounded-card border border-[color-mix(in_srgb,var(--color-fd-border)_68%,var(--color-fd-primary)_32%)] bg-[color-mix(in_srgb,var(--color-fd-background)_84%,transparent)] bg-[image:linear-gradient(145deg,color-mix(in_srgb,var(--color-fd-primary)_11%,transparent),transparent_72%),none] px-5 py-[1.15rem] text-fd-foreground no-underline inset-shadow-[0_1px_rgb(255_255_255/.17)] shadow-[0_10px_24px_rgba(0,8,26,.08)] backdrop-blur-lg backdrop-saturate-130 transition-[border-color,translate,box-shadow] duration-180 ease-[ease] hover-always:-translate-y-0.5 hover-always:border-fd-primary hover-always:inset-shadow-[0_1px_rgb(255_255_255/.2)] hover-always:shadow-[0_14px_30px_rgba(0,8,26,.12)] motion-reduce:transition-none motion-reduce:hover-always:translate-y-0';

/** A labelled navigation of link cards, two columns wide and one column at 680px and below. */
export function LinkCards({ label, links, variant = 'cards' }: LinkCardsProps) {
  if (asMarkdown()) {
    const list = links.map(({ href, title, description }) => `- [${title}](${href.startsWith('/') ? siteUrl + href : href}): ${description}`);
    return `${list.join('\n')}\n\n`;
  }
  const actions = variant === 'actions';
  return (
    <nav className={`grid grid-cols-2 gap-[.85rem] guide-phone:grid-cols-1 ${actions ? 'mt-5 mb-7' : 'mt-6 mb-9'}`} aria-label={label}>
      {links.map(({ href, title, description }) => (
        <a key={href} href={href} className={`${linkCard} ${actions ? 'min-h-22 justify-center' : 'min-h-24 guide-phone:min-h-0'}`}>
          <strong className={actions ? 'text-[1rem]' : 'text-[1rem]/[1.35]'}>{title}</strong>
          <span className="text-[.88rem]/[1.45] text-fd-muted-foreground">{description}</span>
        </a>
      ))}
    </nav>
  );
}

/**
 * A collapsible block for long notes, such as a changelog version's Full notes: the visible text above
 * it must stand on its own, and the block holds the detail. Pages write `<Details>` and `<Summary>`:
 * MDX maps only capitalised JSX names to components (a literal `<details>` would skip the styling).
 * scripts/export_changelog.py leaves everything inside it out of the in-game changelog. Closed by default.
 */
export function Details({ className, ...props }: ComponentProps<'details'>) {
  return <details {...props} className={['mt-4 mb-6 rounded-card border border-fd-border bg-fd-card px-4 py-2', className].filter(Boolean).join(' ')} />;
}

/** The always-visible line of a {@link Details} block: the click and keyboard target that opens it. */
export function Summary({ className, ...props }: ComponentProps<'summary'>) {
  return <summary {...props} className={['cursor-pointer py-1 font-medium text-fd-foreground', className].filter(Boolean).join(' ')} />;
}
