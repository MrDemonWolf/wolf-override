'use client';

import Link from 'next/link';
import { useEffect, useRef, useState } from 'react';
import { navLink } from './landing-classes';
import { mainNavLinks, withBase } from './site-links';

// Hamburger bars; with the menu open the outer two turn into a cross and the middle one fades out.
const bar =
  'block h-0.5 rounded-[2px] bg-current transition-[translate,rotate,opacity] duration-180 ease-[ease] motion-reduce:transition-none';

/**
 * The phone menu (980px and below): a Menu button that opens the header's links in a panel.
 * `linkBase` is prefixed to landing-section anchors: "" on the landing page, "/" on other pages,
 * where they become ordinary page links.
 */
export default function LandingNavigation({ linkBase = '' }: { linkBase?: string }) {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (!isOpen) return;

    const closeOnOutsidePress = (event: PointerEvent) => {
      if (event.target instanceof Node && !containerRef.current?.contains(event.target)) {
        setIsOpen(false);
      }
    };

    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') return;
      setIsOpen(false);
      triggerRef.current?.focus({ preventScroll: true });
    };

    document.addEventListener('pointerdown', closeOnOutsidePress);
    document.addEventListener('keydown', closeOnEscape);
    return () => {
      document.removeEventListener('pointerdown', closeOnOutsidePress);
      document.removeEventListener('keydown', closeOnEscape);
    };
  }, [isOpen]);

  const handleNavigation = (event: React.MouseEvent<HTMLAnchorElement>) => {
    const href = event.currentTarget.getAttribute('href') ?? '';
    setIsOpen(false);
    if (href.startsWith('#')) {
      // Move focus to the destination heading so keyboard and screen-reader users land in the section.
      const heading = document.getElementById(href.slice(1))?.querySelector<HTMLElement>('h2');
      requestAnimationFrame(() => (heading ?? triggerRef.current)?.focus({ preventScroll: true }));
    }
  };

  return (
    <div
      ref={containerRef}
      // Shown at 980px and below in place of the desktop navigation. Static there, so the menu panel
      // below is positioned against the header and spans its width.
      className="group relative ml-auto hidden flex-none font-heading menu:static menu:block"
      data-open={isOpen}
      onBlurCapture={(event) => {
        const nextTarget = event.relatedTarget;
        if (!(nextTarget instanceof Node) || !event.currentTarget.contains(nextTarget)) {
          setIsOpen(false);
        }
      }}
    >
      <button
        ref={triggerRef}
        className="flex min-h-11 min-w-11 cursor-pointer items-center gap-2 rounded-control border border-line-strong bg-accent/6 px-3 py-2 font-bold text-text hover-always:bg-accent/12 phone-xs:w-11 phone-xs:justify-center phone-xs:px-0"
        type="button"
        aria-label={isOpen ? 'Close navigation menu' : 'Open navigation menu'}
        aria-expanded={isOpen}
        aria-controls="landing-mobile-menu"
        onClick={() => setIsOpen((open) => !open)}
      >
        <span className="grid w-4 gap-1" aria-hidden="true">
          <span className={`${bar} group-data-[open=true]:translate-y-1.5 group-data-[open=true]:rotate-45`} />
          <span className={`${bar} group-data-[open=true]:opacity-0`} />
          <span className={`${bar} group-data-[open=true]:-translate-y-1.5 group-data-[open=true]:-rotate-45`} />
        </span>
        <span className="phone-xs:hidden">{isOpen ? 'Close' : 'Menu'}</span>
      </button>
      {/* A dropdown under the trigger; a four-column bar across the header on tablets; one column across it on phones. */}
      <nav
        id="landing-mobile-menu"
        aria-label="Main navigation"
        hidden={!isOpen}
        className="absolute top-[calc(100%+.5rem)] right-0 z-40 grid min-w-52 gap-1 rounded-control border border-line-strong bg-panel/99 p-2 shadow-[0_14px_32px_rgba(0,5,18,.3)] phone:left-2 phone:right-2 phone:min-w-0 phone:grid-cols-[1fr] tablet:left-4 tablet:right-4 tablet:min-w-0 tablet:grid-cols-4"
      >
        {mainNavLinks.map(([anchor, label]) => {
          const className = `${navLink} justify-start tablet:justify-center`;
          const href = withBase(anchor, linkBase);
          return href.startsWith('#') ? (
            <a key={href} href={href} className={className} onClick={handleNavigation}>{label}</a>
          ) : (
            <Link key={href} href={href} className={className} onClick={handleNavigation}>{label}</Link>
          );
        })}
      </nav>
    </div>
  );
}
