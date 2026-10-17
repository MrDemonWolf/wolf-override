import Link from 'next/link';
import LandingNavigation from './landing-navigation';
import BrandLockup from './brand-lockup';
import Downloads, { ArrowIcon, sourceBuildHref } from './downloads';
import { card, inlineLink, landingWidth, navLink, sectionAnchor, sectionCopy, sectionTitle } from './landing-classes';
import corridorCapture480 from './images/corridor-start-capture-480.webp';
import corridorCapture960 from './images/corridor-start-capture-960.webp';
import corridorCapture1600 from './images/corridor-start-capture-1600.webp';
import { pageMetadata, siteDescription } from '@/lib/seo';
import { homeStructuredData, JsonLd } from '@/lib/structured-data';

// Static export has no image optimiser, so the hero ships hand-encoded WebP sizes of the key art.
const keyArtSrcSet = ['640', '1024', '1672'].map((w) => `/title-corridor-key-art-provisional-${w}.webp ${w}w`).join(', ');

export const metadata = {
  ...pageMetadata('WOLF//OVERRIDE | Sci-fi Horror Adventure', siteDescription, '/'),
  title: { absolute: 'WOLF//OVERRIDE | Sci-fi Horror Adventure' },
};

// Hero call-to-action buttons; the primary lifts on hover unless reduced motion is requested.
const heroAction =
  'inline-flex min-h-13 items-center justify-between gap-[1.2rem] rounded-control border px-[1.2rem] py-[.85rem] font-heading font-bold leading-[1.3] transition-[background-color,border-color,color,translate] duration-180 ease-[ease] motion-reduce:transition-none phone:w-full';

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
] as const;

const footerLink = 'inline-flex min-h-11 items-center text-muted';

export default function HomePage() {
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
            <div className="mt-8 flex flex-wrap gap-[.85rem] phone:mt-6 phone:gap-[.65rem]">
              <a className={`${heroAction} border-accent bg-accent text-[#081521] hover-always:-translate-y-px hover-always:brightness-106 motion-reduce:hover-always:translate-y-0`} href="#gameplay">See gameplay <span aria-hidden="true">↓</span></a>
              <Link className={`${heroAction} border-line-strong bg-surface text-text hover-always:border-accent hover-always:bg-[color-mix(in_srgb,var(--color-surface)_82%,var(--color-accent))]`} href={sourceBuildHref}>Get the source build <ArrowIcon /></Link>
            </div>
            <p className="mt-4 text-caption text-[#bdd0d9]">Source build available · No public release date</p>
          </div>
          <div className="absolute right-8 bottom-6 left-8 flex justify-between gap-4 phone:static phone:flex-col phone:gap-[.2rem] phone:px-5 phone:pb-5">
            <span className="hud-label text-muted">Side-view sci-fi horror / Narrative adventure</span>
            <span className="hud-label text-muted">Provisional key art · Not a gameplay capture</span>
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
          <figure className={`${card} mt-14 phone:mt-10`}>
            {/* The link clips the image to the frame's top corners; the figure stays unclipped so the link's focus ring shows. */}
            <a className="block overflow-hidden rounded-t-[calc(var(--radius-card)-1px)] hover-always:text-accent" href={corridorCapture1600.src} target="_blank" rel="noopener noreferrer">
              <img className="w-full" src={corridorCapture960.src} srcSet={`${corridorCapture480.src} 480w, ${corridorCapture960.src} 960w, ${corridorCapture1600.src} 1600w`} sizes="(max-width: 700px) calc(100vw - 2rem), min(100vw - 4rem, 1200px)" alt="Gameplay frame at the start of the maintenance corridor: the engineer and WOLF stand by the purge display while the objective card reads CHECK THE BREAKER and a tutorial box lists the move and read controls." width={corridorCapture960.width} height={corridorCapture960.height} loading="lazy" decoding="async" />
              <span className="sr-only">(full-size image, opens in a new tab)</span>
            </a>
            <figcaption className="flex flex-wrap justify-between gap-x-4 gap-y-2 px-5 py-4 text-caption text-muted phone:flex-col">
              <strong className="text-text">Source build capture, October 12, 2026</strong>
              <span>Provisional art and UI</span>
            </figcaption>
          </figure>
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
              ['/docs/changelog/', 'Development updates', 'Read the changelog'],
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
      <footer className={`${landingWidth} grid grid-cols-[minmax(15rem,1.7fr)_repeat(3,minmax(8rem,1fr))] gap-x-8 gap-y-10 border-t border-t-line pt-14 pb-6 phone:grid-cols-2 phone:gap-x-5 phone:gap-y-8 tablet:grid-cols-3 tablet:gap-x-[1.4rem] tablet:gap-y-8`}>
        <div className="menu:col-span-full">
          <BrandLockup />
          <p className="mt-4 max-w-[34ch] text-[.85rem] leading-[1.75] text-muted">Original concept, core story &amp; creative vision: Nathanial Henniges.<br />Developed by MrDemonWolf, Inc. with AI assistance.</p>
        </div>
        {footerGroups.map((group) => (
          <nav key={group.title} aria-label={group.label} className="flex flex-col items-start gap-1">
            {/* A label, not a heading: the nav's aria-label already names the group, and three H2s here
                would add empty topics to the page outline search engines and screen readers read. */}
            <p className="mt-1 mb-[.65rem] font-heading text-[.76rem] leading-[1.4] font-bold tracking-[.1em] text-text uppercase">{group.title}</p>
            {group.links.map(([href, label]) => (
              <Link key={href} href={href} className={footerLink}>{label}</Link>
            ))}
            {group.title === 'Project' && (
              <a href="https://github.com/MrDemonWolf/wolf-override" className={footerLink}>Source on GitHub <span aria-hidden="true">↗</span></a>
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
