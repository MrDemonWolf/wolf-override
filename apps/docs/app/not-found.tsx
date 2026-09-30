import Link from 'next/link';

export default function NotFound() {
  return (
    <main id="nd-page" tabIndex={-1} className="mx-auto flex min-h-[70vh] max-w-xl flex-col justify-center gap-4 px-6">
      <p className="text-sm text-fd-muted-foreground">WOLF//OVERRIDE</p>
      <h1 className="text-3xl font-semibold">Page not found</h1>
      <p>This page may have moved. Head back to the game site.</p>
      <Link href="/" className="text-fd-primary underline">Return home</Link>
    </main>
  );
}
