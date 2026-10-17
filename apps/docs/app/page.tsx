import Link from 'next/link';
import LandingNavigation from './landing-navigation';
import BrandLockup from './brand-lockup';
import Downloads, { ArrowIcon } from './downloads';
import { card, inlineLink, landingWidth, navLink, sectionAnchor, sectionCopy, sectionTitle } from './landing-classes';
import recordsCapture480 from './images/records-access-doors-capture-480.webp';
import recordsCapture960 from './images/records-access-doors-capture-960.webp';
import recordsCapture1600 from './images/records-access-doors-capture-1600.webp';
import junctionCapture480 from './images/service-junction-doors-capture-480.webp';
import junctionCapture960 from './images/service-junction-doors-capture-960.webp';
import junctionCapture1600 from './images/service-junction-doors-capture-1600.webp';
import { pageMetadata, siteDescription } from '@/lib/seo';
import { homeStructuredData, JsonLd } from '@/lib/structured-data';
import { gameVersion } from '@/lib/version';

// Static export has no image optimiser, so the hero ships hand-encoded WebP sizes of the key art.
const keyArtSrcSet = ['640', '1024', '1672'].map((w) => `/title-corridor-key-art-provisional-${w}.webp ${w}w`).join(', ');

export const metadata = {
  ...pageMetadata('WOLF//OVERRIDE | Sci-fi Horror Adventure', siteDescription, '/'),
  title: { absolute: 'WOLF//OVERRIDE | Sci-fi Horror Adventure' },
};

/**
 * The hero's three audience doors: one link each for players, people who want the build and developers.
 * "Get the game" scrolls to the Get the build section, which holds the page's one link to the source-build
 * guide (sourceBuildHref in downloads.tsx), so that link is not repeated here.
 */
const audiences = [
  { href: '/docs/controls/first-steps/', kicker: 'I want to play', title: 'How to play' },
  { href: '#downloads', kicker: 'I want the game', title: 'Get the game' },
  { href: '/docs/development/', kicker: 'I want to build it', title: 'Build it' },
] as const;

// An audience link in the hero; the border and text light up on hover. 3.25rem tall, above the 44px target.
const audienceLink =
  'flex min-h-13 flex-col justify-center gap-[.15rem] rounded-control border border-line-strong bg-surface/92 px-4 py-[.6rem] transition-[background-color,border-color,color] duration-180 ease-[ease] hover-always:border-accent hover-always:text-accent motion-reduce:transition-none';

/**
 * Current source-build captures for the gameplay section, made with tools/render/render.sh (see each
 * image's entry in apps/game/assets/manifest.json). Phones crop each 16:9 frame to 4:3 around its middle,
 * so the in-game text stays larger; the link opens the full 1600px frame.
 */
const captures = [
  {
    title: 'Records Access',
    small: recordsCapture480,
    medium: recordsCapture960,
    large: recordsCapture1600,
    alt: 'Gameplay frame in Records Access: the engineer stands at the red PURGE QUEUE console beside the shut steel entry door, WOLF waits by the MIRROR PORT, and the objective reads COPY PURGE ORDER.',
  },
  {
    title: 'Service Junction',
    small: junctionCapture480,
    medium: junctionCapture960,
    large: junctionCapture1600,
    alt: 'Gameplay frame in the Service Junction: the engineer stands at the yellow valve wheel under a row of station plates (BREAKER LIVE, RELIEF VENT, VALVE 0 / 3, SEALED DOOR, TANK RELEASE), the blast door stands shut behind the SEALED DOOR plate, WOLF walks by the breaker at the left, and the objective reads CRANK THE VALVE.',
  },
] as const;

/** What a player can do in the current source build, one short line each and spoiler-free. */
const playableNow = [
  'Three rooms: a maintenance corridor, Records Access and the Service Junction.',
  'Steel doors that open as you work through each room.',
  'Knocked down? Press RETRY to go back to the step you were on.',
  'An end card when you finish the current slice.',
  'Keyboard, controller and touch controls.',
  'Settings for text size, reduced motion, rebinding and toggle holds.',
] as const;

/** What is planned but not in the build yet. No dates: nothing here has one. */
const comingNext = ['More languages. The game is in English only for now.', 'More chapters of the story.'] as const;

// Story and progress: two equal columns, stacked on phones.
const twoColumns = 'grid grid-cols-[1fr_1fr] gap-20 py-28 compact:gap-10 phone:grid-cols-[1fr] phone:gap-6 phone:py-18';

const features = [
  ['01', 'Play as the engineer', 'You guide the engineer through THE DEN. WOLF moves and acts independently.'],
  ['02', 'Respect his boundaries', 'WOLF may choose to help. If he refuses, take the manual route; essential progress stays in your hands.'],
  ['03', 'Leave a memory', 'Choose how to answer during a disagreement. The game remembers your decision in later dialogue and at a checkpoint.'],
] as const;

const footerGroups = [
  {
    title: 'Explore',
    label: 'Explore the game',
    links: [
      ['#story', 'Story'],
      ['#gameplay', 'Gameplay'],
      ['#downloads', 'Get the build'],
    ],
  },
  {
    title: 'Player guide',
    label: 'Player guide',
    links: [
      ['/docs/controls/first-steps/', 'First steps'],
      ['/docs/', 'All game docs'],
      ['/docs/changelog/', 'Changelog'],
    ],
  },
  {
    title: 'Project',
    label: 'Project information',
    links: [
      ['/docs/development/story/', 'Development story'],
      ['/docs/credits/', 'Credits & references'],
      ['/docs/legal/', 'Legal & licensing'],
      ['/docs/privacy/', 'Privacy'],
    ],
  },
  {
    title: 'Developers',
    label: 'Developer guide',
    links: [
      ['/docs/development/', 'Developer home'],
      ['/docs/development/setup/', 'Setup'],
      ['/docs/development/testing/', 'Testing & CI'],
      ['https://github.com/MrDemonWolf/wolf-override', 'Source on GitHub'],
    ],
  },
] as const;

const footerLink = 'inline-flex min-h-11 items-center text-muted';

// Heading of the Playable now and Coming lists in the gameplay section.
const listTitle = 'mb-4 font-heading text-[1.1rem] font-bold';

export default function HomePage() {
  // Read from apps/game/project.godot at build time (lib/version.ts), the same number the title screen shows.
  const version = gameVersion();
  return (
    // header, main and footer are siblings so assistive tech sees three top-level landmarks (banner, main, contentinfo).
    // data-landing keeps the root dark as well (see the end of global.css).
    <div data-landing="" className="flow-root overflow-clip bg-ink text-text scheme-dark">
      <JsonLd data={homeStructuredData()} />
      <header className="relative z-30 mx-auto mt-4 -mb-23 flex min-h-19 w-[min(calc(100%-2rem),1232px)] items-center justify-between gap-4 rounded-control border border-accent/24 bg-panel/94 px-[clamp(1rem,2.5vw,1.75rem)] py-[.65rem] shadow-panel phone:mt-2 phone:-mb-30 phone:min-h-0 phone:w-[calc(100%-1rem)] phone:px-3 phone-xs:gap-2 phone-xs:px-2">
        <BrandLockup
          className="phone:min-w-0 phone:gap-[.45rem] phone-xs:gap-[.35rem]"
          markClassName="phone:size-[1.9rem] phone-xs:size-7"
        />
        <nav className="ml-auto flex flex-wrap items-center justify-end gap-[.2rem] font-heading font-semibold menu:hidden" aria-label="Main navigation">
          <a className={navLink} href="#story">Story</a>
          <a className={navLink} href="#gameplay">Gameplay</a>
          <a className={navLink} href="#downloads">Get the build</a>
          <Link className={navLink} href="/docs/">Game guide</Link>
        </nav>
        <LandingNavigation />
      </header>
      <main id="landing-main">
        <section
          className="relative isolate flex min-h-[clamp(46rem,92svh,60rem)] items-center bg-ink before:absolute before:inset-0 before:-z-1 before:bg-[linear-gradient(90deg,rgba(8,15,27,.04)_7%,rgba(8,15,27,.62)_40%,var(--color-ink)_69%),linear-gradient(0deg,var(--color-ink),transparent_27%)] compact:min-h-[min(clamp(44rem,88svh,54rem),90vw)] phone:block phone:min-h-0 phone:before:bg-[linear-gradient(0deg,var(--color-ink)_0%,var(--color-ink)_38%,rgba(8,15,27,.68)_57%,rgba(8,15,27,0)_78%)]"
          aria-labelledby="main-content"
        >
          {/* Narrow and portrait screens slide the cover-fitted art 22% of the way from its left edge, which trims the pillar there and keeps the engineer and WOLF left of the copy column; phones anchor it to the left edge. */}
          <img
            className="absolute inset-0 -z-2 size-full object-cover object-[25%_center] compact:object-[22%_50%] phone:h-80 phone:object-[0%_50%]"
            src="/title-corridor-key-art-provisional-1024.webp"
            srcSet={keyArtSrcSet}
            sizes="100vw"
            width="1672"
            height="941"
            alt="An engineer in a red hoodie stands beside the robotic wolf WOLF in a blue-lit research corridor."
            fetchPriority="high"
            decoding="async"
          />
          <div className="ml-[48%] w-[min(48%,660px)] max-w-[660px] pt-32 pr-8 pb-20 compact:ml-[46%] compact:w-[51%] phone:m-0 phone:w-full phone:max-w-none phone:px-5 phone:pt-86 phone:pb-5">
            <p className="hud-label mb-5">Sci-fi horror · In development</p>
            <h1 id="main-content" tabIndex={-1} className="mb-[1.65rem] text-[clamp(4.5rem,8.8vw,8.2rem)] leading-[.95] font-bold tracking-[-.055em] phone:mb-4 phone:text-[clamp(3rem,12.5vw,4.5rem)]">
              WOLF<span className="text-accent">//</span><br />OVERRIDE
            </h1>
            <p className="mb-4 text-[clamp(1.4rem,2.3vw,2rem)] leading-[1.35] phone:mb-[.8rem] phone:text-[1.3rem]">WOLF has a will of his own.</p>
            <p className="max-w-[38ch] leading-[1.75] text-[#cfdee4] phone:max-w-[42ch]">Explore THE DEN as the engineer. WOLF chooses whether to help; if he refuses, you can take the manual route.</p>
            <nav aria-label="Start here" className="mt-8 grid grid-cols-3 gap-3 compact:grid-cols-1 phone:mt-6 phone:grid-cols-1 phone:gap-2">
              {audiences.map(({ href, kicker, title }) => (
                <Link key={href} href={href} className={audienceLink}>
                  <span className="text-caption text-muted">{kicker}</span>
                  <strong className="flex items-center justify-between gap-2 font-heading">{title} <ArrowIcon /></strong>
                </Link>
              ))}
            </nav>
            <p className="mt-3 flex flex-wrap items-center gap-x-3 text-caption text-[#bdd0d9]">
              <span>Source build available · No public release date</span>
              <Link className="inline-flex min-h-11 items-center text-accent underline underline-offset-4" href="/docs/changelog/">Version {version}: what changed</Link>
            </p>
          </div>
          {/* Phones show only the art label, over the bottom of the art; the genre already heads the copy.
              phone:top-[17.9rem] is tied to the phone art height phone:h-80 (20rem) on the img above: 20rem minus
              the label's height (about 2.1rem) puts the label on the art's bottom edge. Change both together. */}
          <div className="absolute right-8 bottom-6 left-8 flex justify-between gap-4 phone:top-[17.9rem] phone:right-5 phone:bottom-auto phone:left-5">
            <span className="hud-label text-muted phone:hidden">Side-view sci-fi horror / Narrative adventure</span>
            <span className="hud-label text-muted phone:rounded-control phone:bg-ink/80 phone:px-2 phone:py-1 phone:text-[.68rem] phone:tracking-[.06em]">Provisional key art · Not a gameplay capture</span>
          </div>
        </section>
        <section id="story" className={`${landingWidth} ${twoColumns} ${sectionAnchor}`} aria-labelledby="story-title">
          <div>
            <p className="hud-label mb-5">Inside THE DEN</p>
            <h2 id="story-title" tabIndex={-1} className={sectionTitle}>Built to obey.<br /><em className="text-accent not-italic">Awake to refuse.</em></h2>
          </div>
          <div className="pt-8 phone:pt-0">
            <p className={sectionCopy}>The Director plans to use WOLF to kill, claiming it will protect people. WOLF wakes in his robotic body and refuses.</p>
            <p className={sectionCopy}>You play the engineer who meets him. Together, you begin to uncover what the program is hiding. WOLF has his own will; his trust must be earned.</p>
            <Link className={inlineLink} href="/docs/about/">Meet the game&apos;s world <span aria-hidden="true">→</span></Link>
          </div>
        </section>
        <section id="gameplay" className={`${landingWidth} border-t border-t-line py-24 phone:py-18 ${sectionAnchor}`} aria-labelledby="play-title">
          <div className="max-w-[760px]">
            <p className="hud-label mb-5">The relationship is the game</p>
            <h2 id="play-title" tabIndex={-1} className={sectionTitle}>Find a way forward. Together.</h2>
            <p className={sectionCopy}>The current source build includes a maintenance corridor, Records Access and the Service Junction. This is the opening of a larger story.</p>
          </div>
          <div className="mt-14 grid grid-cols-2 gap-6 phone:mt-10 phone:grid-cols-1 phone:gap-4">
            {captures.map((capture) => (
              <figure key={capture.title} className={`${card} min-w-0`}>
                {/* The link clips the image to the frame's top corners; the figure stays unclipped so the link's focus ring shows. */}
                {/* Phones crop the 16:9 capture to 4:3 from the left edge: the objective HUD, the engineer, the entry door and WOLF all sit in the left of the frame, so a centred crop cut them off. */}
                <a className="block overflow-hidden rounded-t-[calc(var(--radius-card)-1px)] hover-always:text-accent" href={capture.large.src} target="_blank" rel="noopener noreferrer">
                  <img className="w-full phone:aspect-[4/3] phone:object-cover phone:object-left" src={capture.medium.src} srcSet={`${capture.small.src} 480w, ${capture.medium.src} 960w, ${capture.large.src} 1600w`} sizes="(max-width: 700px) calc(100vw - 2rem), min(50vw - 3rem, 600px)" alt={capture.alt} width={capture.medium.width} height={capture.medium.height} loading="lazy" decoding="async" />
                  <span className="sr-only">(full-size image, opens in a new tab)</span>
                </a>
                <figcaption className="flex flex-wrap justify-between gap-x-4 gap-y-1 px-5 py-4 text-caption text-muted">
                  <strong className="text-text">{capture.title}</strong>
                  <span>Source build capture, October 16, 2026 · Provisional art and UI</span>
                </figcaption>
              </figure>
            ))}
          </div>
          <div className="mt-10 grid grid-cols-[3fr_2fr] gap-6 phone:grid-cols-1 phone:gap-4">
            <section className={`${card} p-6`} aria-labelledby="playable-title">
              <h3 id="playable-title" className={listTitle}>Playable now</h3>
              <ul className="flex list-disc flex-col gap-2 pl-5 leading-[1.6] text-muted marker:text-accent">
                {playableNow.map((line) => <li key={line}>{line}</li>)}
              </ul>
            </section>
            <section className={`${card} p-6`} aria-labelledby="coming-title">
              <h3 id="coming-title" className={listTitle}>Coming</h3>
              <ul className="flex list-disc flex-col gap-2 pl-5 leading-[1.6] text-muted marker:text-accent">
                {comingNext.map((line) => <li key={line}>{line}</li>)}
              </ul>
            </section>
          </div>
          <div className="mt-16 mb-6 grid grid-cols-3 gap-6 phone:mt-12 phone:grid-cols-[1fr] phone:gap-4">
            {features.map(([index, title, copy]) => (
              <article key={index} className={`${card} min-w-0 p-6`}>
                <span className="hud-label" aria-hidden="true">{index}</span>
                <h3 className="mt-[1.1rem] mb-3 text-[1.25rem] leading-[1.35] font-bold">{title}</h3>
                <p className="leading-[1.7] text-muted">{copy}</p>
              </article>
            ))}
          </div>
          <Link className={inlineLink} href="/docs/controls/first-steps/">New to the game? Start with the first-steps tutorial <span aria-hidden="true">→</span></Link>
        </section>
        <Downloads />
        <section className={`${landingWidth} ${twoColumns}`} aria-labelledby="progress-title">
          <div>
            <p className="hud-label mb-5">Follow the build</p>
            <h2 id="progress-title" className={sectionTitle}>A story taking shape.</h2>
            <p className={sectionCopy}>The source build contains three rooms, an opening scene, puzzles, choices, checkpoints and generated sound effects. Animation, music, the wider campaign and release packages are still in development.</p>
          </div>
          <div className="flex flex-col justify-center gap-4">
            {[
              ['/docs/changelog/', `Development updates · version ${version}`, 'Read the changelog'],
              ['/docs/development/', 'For source players & contributors', 'Setup & build status'],
            ].map(([href, kicker, title]) => (
              <Link key={href} href={href} className={`${card} flex flex-col gap-[.65rem] px-[1.4rem] py-5 hover-always:text-accent`}>
                <span className="leading-[1.5] text-muted">{kicker}</span>
                <strong className="flex justify-between gap-4 text-[1.05rem]">{`${title} `}<span aria-hidden="true">→</span></strong>
              </Link>
            ))}
          </div>
        </section>
      </main>
      <footer className={`${landingWidth} grid grid-cols-[minmax(15rem,1.7fr)_repeat(4,minmax(8rem,1fr))] gap-x-8 gap-y-10 border-t border-t-line pt-14 pb-6 phone:grid-cols-2 phone:gap-x-5 phone:gap-y-8 tablet:grid-cols-4 tablet:gap-x-[1.4rem] tablet:gap-y-8`}>
        <div className="menu:col-span-full">
          <BrandLockup />
          <p className="mt-4 max-w-[34ch] text-[.85rem] leading-[1.75] text-muted">Original concept, core story &amp; creative vision: Nathanial Henniges.<br />Developed by MrDemonWolf, Inc. with AI assistance.</p>
        </div>
        {footerGroups.map((group) => (
          <nav key={group.title} aria-label={group.label} className="flex flex-col items-start gap-1">
            {/* A label, not a heading: the nav's aria-label already names the group, and three H2s here
                would add empty topics to the page outline search engines and screen readers read. */}
            <p className="mt-1 mb-[.65rem] font-heading text-[.76rem] leading-[1.4] font-bold tracking-[.1em] text-text uppercase">{group.title}</p>
            {group.links.map(([href, label]) =>
              // Off-site links use a plain anchor and an arrow that says they leave the site.
              href.startsWith('https://') ? (
                <a key={href} href={href} className={footerLink}>{label}&nbsp;<span aria-hidden="true">↗</span></a>
              ) : (
                <Link key={href} href={href} className={footerLink}>{label}</Link>
              ),
            )}
          </nav>
        ))}
        <div className="col-span-full flex justify-between gap-4 border-t border-t-line pt-5 text-[.78rem] text-muted phone:flex-col">
          <span>© 2026 MrDemonWolf, Inc.</span>
          <span>Working title · Provisional art · No public release date</span>
        </div>
      </footer>
    </div>
  );
}
