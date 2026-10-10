'use client';

import Link from 'next/link';
import type { ComponentProps } from 'react';

// The guide's brand link back to the landing page. Prefetching "/" from a docs page would also pull
// the landing's key-art preload, so this link only loads the landing when it is actually used.
// Fumadocs 16.16 renders the header from a client component and calls a function `nav.title` there,
// so this must be a client component for the docs layout to pass it across the server boundary.
export default function BrandLink({ href = '/', className }: ComponentProps<'a'>) {
  return (
    <Link href={href} className={className} prefetch={false}>
      WOLF//OVERRIDE
    </Link>
  );
}
