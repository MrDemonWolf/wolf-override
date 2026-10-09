'use client';

import { useEffect } from 'react';

const DRAWER_ID = 'nd-sidebar-mobile';
const TRIGGER_SELECTOR = 'button[aria-label="Open Sidebar"], button[aria-label="Close Sidebar"]';

/**
 * Fumadocs 16.4 renders the mobile sidebar as a plain aside toggled by an "Open Sidebar" button with no
 * aria-expanded, no focus management and no Escape handling. This renders nothing and patches the DOM:
 * it mirrors the drawer state onto the triggers, labels the drawer, moves focus into it when it opens,
 * returns focus to the trigger when it closes, and closes it on Escape. Every step is a no-op when the
 * expected elements are absent, so a Fumadocs upgrade that fixes this cannot break the page.
 */
export default function SidebarDrawerShim() {
  useEffect(() => {
    let lastTrigger: HTMLElement | null = null;
    let wasOpen = false;

    const triggers = () => Array.from(document.querySelectorAll<HTMLButtonElement>(TRIGGER_SELECTOR));
    const drawer = () => document.getElementById(DRAWER_ID);
    const headerTrigger = (panel: HTMLElement | null) => triggers().find((trigger) => !panel?.contains(trigger)) ?? null;

    const sync = () => {
      const panel = drawer();
      const open = panel?.dataset.state === 'open';
      for (const trigger of triggers()) {
        const inDrawer = !!panel && panel.contains(trigger);
        trigger.setAttribute('aria-expanded', String(open));
        trigger.setAttribute('aria-controls', DRAWER_ID);
        trigger.setAttribute('aria-label', inDrawer && open ? 'Close Sidebar' : 'Open Sidebar');
      }
      if (panel) {
        panel.setAttribute('role', 'dialog');
        panel.setAttribute('aria-modal', 'true');
        panel.setAttribute('aria-label', 'Guide navigation');
      }
      if (open && !wasOpen) {
        const closeButton = panel?.querySelector<HTMLElement>(TRIGGER_SELECTOR);
        const firstControl = panel?.querySelector<HTMLElement>('a[href], button:not([disabled])');
        (closeButton ?? firstControl)?.focus({ preventScroll: true });
      } else if (!open && wasOpen) {
        (lastTrigger ?? headerTrigger(panel))?.focus({ preventScroll: true });
      }
      wasOpen = open;
    };

    const rememberTrigger = (event: Event) => {
      const trigger = event.target instanceof Element ? event.target.closest<HTMLElement>(TRIGGER_SELECTOR) : null;
      if (trigger && !drawer()?.contains(trigger)) lastTrigger = trigger;
    };

    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key !== 'Escape' || event.defaultPrevented) return;
      const panel = drawer();
      if (panel?.dataset.state !== 'open') return;
      event.preventDefault();
      (lastTrigger ?? headerTrigger(panel))?.click();
    };

    const observer = new MutationObserver(sync);
    observer.observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ['data-state'] });
    document.addEventListener('click', rememberTrigger, true);
    document.addEventListener('keydown', closeOnEscape);
    sync();

    return () => {
      observer.disconnect();
      document.removeEventListener('click', rememberTrigger, true);
      document.removeEventListener('keydown', closeOnEscape);
    };
  }, []);

  return null;
}
