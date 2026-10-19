import Link from 'next/link';
import BrandLockup from './brand-lockup';
import { landingWidth } from './landing-classes';
import SiteCopyright from './site-copyright';
import { footerGroups, withBase } from './site-links';

const footerLink = 'inline-flex min-h-11 items-center text-muted';

/**
 * The footer of the landing page and the design-system page: the logo and credit, four link groups
 * (site-links.ts) and the copyright line. `linkBase` is prefixed to landing-section anchors:
 * "" on the landing page, "/" on other pages.
 */
export default function SiteFooter({ linkBase = '' }: { linkBase?: string }) {
  return (
    <footer className={`${landingWidth} grid grid-cols-[minmax(15rem,1.7fr)_repeat(4,minmax(8rem,1fr))] gap-x-8 gap-y-10 border-t border-t-line pt-14 pb-6 phone:grid-cols-2 phone:gap-x-5 phone:gap-y-8 tablet:grid-cols-4 tablet:gap-x-[1.4rem] tablet:gap-y-8`}>
      <div className="menu:col-span-full">
        <BrandLockup />
        <p className="mt-4 max-w-[34ch] text-[.85rem] leading-[1.75] text-muted">Original concept, core story &amp; creative vision: Nathanial Henniges.<br />Developed by MrDemonWolf, Inc. with AI assistance.</p>
      </div>
      {footerGroups.map((group) => (
        <nav key={group.title} aria-label={group.label} className="flex flex-col items-start gap-1">
          {/* A label, not a heading: the nav's aria-label already names the group, and three H2s here
              would add empty topics to the page outline search engines and screen readers read. */}
          <p className="mt-1 mb-[.65rem] font-heading text-[.76rem] leading-[1.4] font-bold tracking-[.1em] text-text uppercase">{group.title}</p>
          {group.links.map(([href, label]) =>
            // Off-site links use a plain anchor and an arrow that says they leave the site.
            href.startsWith('https://') ? (
              <a key={href} href={href} className={footerLink}>{label}&nbsp;<span aria-hidden="true">↗</span></a>
            ) : (
              <Link key={href} href={withBase(href, linkBase)} className={footerLink}>{label}</Link>
            ),
          )}
        </nav>
      ))}
      <div className="col-span-full flex justify-between gap-4 border-t border-t-line pt-5 text-[.78rem] text-muted phone:flex-col">
        <SiteCopyright />
        <span>Working title · Provisional art · No public release date</span>
      </div>
    </footer>
  );
}
