import Link from 'next/link';

/*
 * The approved horizontal WOLF OVERRIDE logo (wolf mark plus the name in Montserrat 800 outlines,
 * approved by Nathanial Henniges on 2026-10-19). The SVG is 1620x320 including 25 units of clear
 * space on every side, so it is drawn by height with its width following that 81:16 ratio.
 */
const logoClass = 'h-10 w-auto phone:h-9 phone-xs:h-8';
const logoSize = { width: 203, height: 40 } as const;

/**
 * The WOLF OVERRIDE logo linking home, used by the landing header and footer and the guide's
 * navigation bar. The link carries the accessible name, so the logo image itself is decorative.
 * - `className` adds to the link.
 * - `themed` follows the guide's light/dark switch: the navy-type logo on the light theme and the
 *   white-type one on dark. The landing page is dark only, so it leaves this off and always shows
 *   the logo for dark backgrounds.
 * - `prefetch` is passed to the Next link; the guide turns it off so a docs page does not pull the
 *   landing's key-art preload until the link is used.
 */
export default function BrandLockup({
  className = '',
  themed = false,
  prefetch,
}: {
  className?: string;
  themed?: boolean;
  prefetch?: boolean;
}) {
  return (
    <Link href="/" aria-label="WOLF OVERRIDE home" prefetch={prefetch} className={`inline-flex flex-none items-center ${className}`}>
      {themed && <img src="/brand/wolf-override-horizontal-for-light-bg.svg" alt="" {...logoSize} className={`${logoClass} dark:hidden`} />}
      <img
        src="/brand/wolf-override-horizontal-for-dark-bg.svg"
        alt=""
        {...logoSize}
        className={`${logoClass} ${themed ? 'hidden dark:block' : ''}`}
      />
    </Link>
  );
}
