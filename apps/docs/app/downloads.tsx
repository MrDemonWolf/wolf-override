import { Fragment } from 'react';
import Link from 'next/link';
import { inlineLink, landingWidth, sectionAnchor, sectionTitle } from './landing-classes';

/** The guide page with every way to get the game today (test build or source); the hero and this section link it. */
export const getGameHref = '/docs/get-game/';

/** Steps for the unsigned macOS and Windows debug test builds, which run without Godot. */
export const testBuildsHref = '/docs/test-builds/';

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
      className={`border-y border-line bg-surface bg-[radial-gradient(circle_at_85%_8%,rgba(67,162,201,.14),transparent_42%)] py-18 min-[701px]:py-24 ${sectionAnchor}`}
    >
      <div className={`${landingWidth} grid gap-10 min-[701px]:grid-cols-[minmax(0,1.2fr)_minmax(0,1fr)] min-[701px]:items-start min-[701px]:gap-16`}>
        <div>
          <p className="hud-label mb-5">Get the build</p>
          <h2 id="downloads-title" tabIndex={-1} className={sectionTitle}>Try a test build.</h2>
          <ul className="m-0 flex max-w-[50ch] list-disc flex-col gap-2 pl-5 text-body text-muted marker:text-accent">
            <li>There is no release, installer or release date yet.</li>
            <li>Test builds for macOS and Windows run without Godot. They are unsigned debug builds, kept for 14 days, and need a GitHub account to download.</li>
            <li>Or run the source game in Godot 4.7.2 on Windows, macOS or Linux.</li>
          </ul>
          <Link
            href={getGameHref}
            className="mt-8 inline-flex min-h-13 items-center justify-between gap-5 rounded-control border border-accent bg-accent px-5 py-3 font-heading text-body font-bold text-ink transition-[filter,transform] hover:-translate-y-px hover:text-ink hover:brightness-105 motion-reduce:transition-none motion-reduce:hover:translate-y-0 phone:w-full"
          >
            Get the game
            <ArrowIcon />
          </Link>
          <p className="mt-2">
            <Link href={testBuildsHref} className={inlineLink}>
              Install a test build <span aria-hidden="true">→</span>
            </Link>
          </p>
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
