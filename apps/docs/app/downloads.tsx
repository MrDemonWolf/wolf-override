import { Fragment } from 'react';
import Link from 'next/link';

/** The one place the landing page sends players for the current source build. */
export const sourceBuildHref = '/docs/get-game/';

/** Planned distribution targets. None has a package or a release date yet. */
export const plannedPlatforms = [
  { name: 'Windows', status: 'no release date' },
  { name: 'macOS', status: 'no release date' },
  { name: 'iPhone / iPad', status: 'no release date' },
  { name: 'Android', status: 'no release date' },
] as const;

export function ArrowIcon() {
  return (
    <svg aria-hidden="true" className="size-5 shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 12h14M13 6l6 6-6 6" />
    </svg>
  );
}

export default function Downloads() {
  return (
    <section
      id="downloads"
      aria-labelledby="downloads-title"
      className="border-y border-line bg-surface bg-[radial-gradient(circle_at_85%_8%,rgba(67,162,201,.14),transparent_42%)] py-18 min-[701px]:py-24"
    >
      <div className="marketing-width grid gap-10 min-[701px]:grid-cols-[minmax(0,1.2fr)_minmax(0,1fr)] min-[701px]:items-start min-[701px]:gap-16">
        <div>
          <p className="hud-label mb-5">Get the build</p>
          <h2 id="downloads-title" tabIndex={-1}>Try the source build.</h2>
          <p className="m-0 max-w-[50ch] text-body text-muted">
            There is no packaged game download yet. The current development build runs from source in Godot; it is not an installer and has no release date.
          </p>
          <Link
            href={sourceBuildHref}
            className="mt-8 inline-flex min-h-13 items-center justify-between gap-5 rounded-control border border-accent bg-accent px-5 py-3 font-heading text-body font-bold text-ink transition-[filter,transform] hover:-translate-y-px hover:text-ink hover:brightness-105 motion-reduce:transition-none motion-reduce:hover:translate-y-0 max-[700px]:w-full"
          >
            Get the source build
            <ArrowIcon />
          </Link>
        </div>
        <div className="rounded-card border border-line-strong bg-ink p-6">
          <h3 className="m-0 font-heading text-body font-bold">Planned platforms:</h3>
          <dl className="mt-4 grid grid-cols-[auto_minmax(0,1fr)] gap-x-6 gap-y-3 text-body">
            {plannedPlatforms.map((platform) => (
              <Fragment key={platform.name}>
                <dt className="font-heading font-semibold">{platform.name}</dt>
                <dd className="m-0 text-muted">{platform.status}</dd>
              </Fragment>
            ))}
          </dl>
        </div>
      </div>
    </section>
  );
}
