import Link from 'next/link';
import type { ComponentProps } from 'react';

// The guide's brand link back to the landing page. Prefetching "/" from a docs page would also pull
// the landing's key-art preload, so this link only loads the landing when it is actually used.
// Fumadocs calls a function `nav.title` directly during server rendering, so this stays a server component.
export default function BrandLink({ href = '/', className }: ComponentProps<'a'>) {
  return (
    <Link href={href} className={className} prefetch={false}>
      WOLF//OVERRIDE
    </Link>
  );
}
