import type { ReactNode } from 'react';
import { DocsLayout } from 'fumadocs-ui/layouts/docs';
import { source } from '@/lib/source';
import BrandLink from './brand-link';
import SidebarDrawerShim from './sidebar-drawer-shim';
import './docs-guide.css';

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <DocsLayout tree={source.getPageTree()} nav={{ title: BrandLink, url: '/' }} sidebar={{ 'aria-label': 'Guide navigation' }}>
      <SidebarDrawerShim />
      {/* display: contents keeps the page article and table of contents in Fumadocs' grid while giving the docs a main landmark. */}
      <main id="guide-main" className="contents">
        {children}
      </main>
    </DocsLayout>
  );
}
