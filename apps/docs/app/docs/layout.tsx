import type { ReactNode } from 'react';
import { DocsLayout } from 'fumadocs-ui/layouts/docs';
import { source } from '@/lib/source';
import BrandLink from './brand-link';
import './docs-guide.css';

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <DocsLayout tree={source.getPageTree()} nav={{ title: BrandLink, url: '/' }}>
      {children}
    </DocsLayout>
  );
}
