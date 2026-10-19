import Link from 'next/link';
import BrandLockup from './brand-lockup';
import LandingNavigation from './landing-navigation';
import { navLink } from './landing-classes';
import { mainNavLinks, withBase } from './site-links';

/**
 * The floating header bar of the landing page and the design-system page: the logo, the desktop
 * navigation and, at 980px and below, the phone menu. It is sticky on every width: it rests 1rem down
 * (.5rem on phones), or below the notch when the browser reports a safe-area inset. Its negative bottom
 * margin pulls the page's first section up under it (the landing hero's art runs behind it), so
 * sticking causes no layout jump and that section needs about 6rem (8rem on phones) of top padding.
 * z-30 keeps it over the page content; the phone menu panel (z-40) lives inside it. bg-panel/94 plus
 * the blur keeps the links readable over the key art and the cards.
 * The page's root must not be a scroll container (use overflow-clip, not overflow-hidden) and should
 * carry [html:has(&)]:scroll-pt-24, so anchors and focused elements land below the bar (WCAG 2.4.11).
 * `linkBase` is prefixed to landing-section anchors: "" on the landing page, "/" on other pages.
 */
export default function SiteHeader({ linkBase = '' }: { linkBase?: string }) {
  return (
    <header className="sticky top-[max(1rem,env(safe-area-inset-top))] z-30 mx-auto mt-4 -mb-23 flex min-h-19 w-[min(calc(100%-2rem),1232px)] items-center justify-between gap-4 rounded-control border border-accent/24 bg-panel/94 px-[clamp(1rem,2.5vw,1.75rem)] py-[.65rem] shadow-panel backdrop-blur-md phone:top-[max(.5rem,env(safe-area-inset-top))] phone:mt-2 phone:-mb-30 phone:min-h-0 phone:w-[calc(100%-1rem)] phone:px-3 phone-xs:gap-2 phone-xs:px-2">
      <BrandLockup />
      <nav className="ml-auto flex flex-wrap items-center justify-end gap-[.2rem] font-heading font-semibold menu:hidden" aria-label="Main navigation">
        {mainNavLinks.map(([href, label]) =>
          // Same-page anchors stay plain links; everything else uses the Next link.
          href.startsWith('#') && !linkBase ? (
            <a key={href} className={navLink} href={href}>{label}</a>
          ) : (
            <Link key={href} className={navLink} href={withBase(href, linkBase)}>{label}</Link>
          ),
        )}
      </nav>
      <LandingNavigation linkBase={linkBase} />
    </header>
  );
}
