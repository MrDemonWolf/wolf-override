import Link from 'next/link';

/**
 * The WOLF OVERRIDE wordmark (mark plus name) linking home. `className` adds to the link and
 * `markClassName` to the mark, e.g. the header's smaller phone sizes.
 */
export default function BrandLockup({ className = '', markClassName = '' }: { className?: string; markClassName?: string }) {
  return (
    <Link
      href="/"
      aria-label="WOLF OVERRIDE home"
      className={`inline-flex flex-none items-center gap-[.6rem] font-heading font-bold tracking-[.04em] text-text ${className}`}
    >
      <img src="/wolf-override-mark.svg" alt="" width="36" height="36" className={`size-9 ${markClassName}`} />
      WOLF OVERRIDE
    </Link>
  );
}
