'use client';

import type { ComponentProps } from 'react';
import { DocsPage } from 'fumadocs-ui/layouts/docs/page';
import { TOC, TOCPopover, TOCProvider } from 'fumadocs-ui/layouts/docs/page/slots/toc';

/*
 * Fumadocs 16.17 renders a guide page's "On this page" contents outside the page's <main>: the
 * desktop list (TOC) as a plain div and the phone and tablet popover (TOCPopover) inside a bare
 * <header>. axe then reports content outside any landmark on desktop and a second banner on phones.
 * Wrapping each in a <nav> fixes both: the list becomes a navigation landmark, and a <header>
 * inside <nav> is no longer a banner (HTML-AAM). `contents` keeps the wrappers out of the layout,
 * so the slots still sit in Fumadocs' grid areas and stay sticky. A role on the slots' own
 * `container` prop is not enough: it is a div, and axe still counts the header in it as a banner.
 * The two never show at the same width (Fumadocs' xl breakpoint), but axe still counts both
 * wrappers (a `contents` box is never hidden), so their labels differ.
 */

/** The desktop "On this page" list in a navigation landmark. Props pass straight to Fumadocs' TOC. */
function GuideTOC(props: ComponentProps<typeof TOC>) {
  return (
    <nav aria-label="On this page" className="contents">
      <TOC {...props} />
    </nav>
  );
}

/** The phone and tablet "On this page" popover in a navigation landmark. Props pass straight to TOCPopover. */
function GuideTOCPopover(props: ComponentProps<typeof TOCPopover>) {
  return (
    <nav aria-label="On this page (drop-down)" className="contents">
      <TOCPopover {...props} />
    </nav>
  );
}

// Defined once at module level: DocsPage reads the slot components on every render.
const slots = { toc: { provider: TOCProvider, main: GuideTOC, popover: GuideTOCPopover } };

/**
 * Fumadocs' DocsPage with the landmark-wrapped table of contents above. A client component because
 * slots are components, which a server component cannot pass to the client DocsPage; the page
 * content still renders on the server and arrives as `children`. Takes every DocsPage prop.
 */
export function GuidePage(props: Omit<ComponentProps<typeof DocsPage>, 'slots'>) {
  return <DocsPage {...props} slots={slots} />;
}
