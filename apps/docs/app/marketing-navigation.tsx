'use client';

import Link from 'next/link';
import { useEffect, useRef, useState } from 'react';

export default function MarketingNavigation() {
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
      className="marketing-mobile-navigation"
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
        className="marketing-menu-trigger"
        type="button"
        aria-label={isOpen ? 'Close navigation menu' : 'Open navigation menu'}
        aria-expanded={isOpen}
        aria-controls="marketing-mobile-menu"
        onClick={() => setIsOpen((open) => !open)}
      >
        <span className="marketing-menu-icon" aria-hidden="true"><span /><span /><span /></span>
        <span>{isOpen ? 'Close' : 'Menu'}</span>
      </button>
      <nav id="marketing-mobile-menu" aria-label="Main navigation" hidden={!isOpen}>
        <a href="#story" onClick={handleNavigation}>Story</a>
        <a href="#gameplay" onClick={handleNavigation}>Gameplay</a>
        <a href="#downloads" onClick={handleNavigation}>Downloads</a>
        <Link href="/docs/" onClick={handleNavigation}>Game guide</Link>
      </nav>
    </div>
  );
}
