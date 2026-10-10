import type { Metadata } from 'next';
import Link from 'next/link';

// Next adds its own noindex robots meta to the 404 page, so this page must not emit a second one from the root layout.
export const metadata: Metadata = {
  title: 'Page not found',
  robots: null,
};

export default function NotFound() {
  return (
    <main className="mx-auto flex min-h-[70vh] max-w-xl flex-col justify-center gap-4 px-6">
      <p className="m-0 font-heading text-label font-semibold uppercase tracking-[.12em] text-fd-muted-foreground">WOLF//OVERRIDE</p>
      <h1 id="main-content" tabIndex={-1} className="m-0 text-3xl font-semibold">Page not found</h1>
      <p className="m-0">This page may have moved. Head back to the game site or open the game guide.</p>
      <nav aria-label="Page not found" className="flex flex-wrap gap-x-6 gap-y-2">
        {/* Prefetching "/" would also pull the landing's key-art preload onto a page that never shows it. */}
        <Link href="/" className="text-fd-primary underline underline-offset-4" prefetch={false}>Return home</Link>
        <Link href="/docs/" className="text-fd-primary underline underline-offset-4">Open the game guide</Link>
      </nav>
    </main>
  );
}
