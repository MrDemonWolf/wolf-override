import Link from 'next/link';
import ThemeToggle from './theme-toggle';
import MarketingNavigation from './marketing-navigation';
import Downloads from './downloads';
import './marketing.css';
import { pageMetadata, siteDescription } from '@/lib/seo';

export const metadata = {
  ...pageMetadata('WOLF//OVERRIDE | Sci-fi Horror Adventure', siteDescription, '/'),
  title: { absolute: 'WOLF//OVERRIDE | Sci-fi Horror Adventure' },
};

export default function HomePage() {
  const base = '';
  return (
    <main id="nd-page" className="marketing-shell">
      <header className="marketing-header">
        <Link className="marketing-brand" href="/" aria-label="WOLF//OVERRIDE home"><img src={`${base}/wolf-override-mark.svg`} alt="" width="36" height="36" />WOLF<span>//</span>OVERRIDE</Link>
        <nav className="marketing-desktop-nav" aria-label="Main navigation">
          <a href="#story">Story</a>
          <a href="#gameplay">Gameplay</a>
          <a href="#downloads">Downloads</a>
          <Link href="/docs/">Game guide</Link>
        </nav>
        <MarketingNavigation />
        <ThemeToggle />
      </header>
      <section className="marketing-hero" aria-labelledby="main-content">
        <img className="marketing-keyart" src={`${base}/title-corridor-key-art-provisional.png`} width="1672" height="941" alt="An engineer in a red hoodie stands beside the robotic wolf WOLF in a blue-lit research corridor." fetchPriority="high" />
        <div className="marketing-hero-copy">
          <p className="marketing-kicker">Sci-fi horror · In development</p>
          <h1 id="main-content" tabIndex={-1}>WOLF<span>//</span><br />OVERRIDE</h1>
          <p className="marketing-tagline">WOLF has a will of his own.</p>
          <p className="marketing-pitch">Explore THE DEN as the engineer. WOLF chooses whether to help; if he refuses, you can take the manual route.</p>
          <div className="marketing-actions"><a className="marketing-primary" href="#gameplay">See gameplay <span aria-hidden="true">↓</span></a><Link className="marketing-secondary" href="/docs/get-game/">Try the source build <span aria-hidden="true">↗</span></Link></div>
          <p className="marketing-status">Source build available · No public release date</p>
        </div>
        <div className="marketing-hero-foot"><span>Side-view sci-fi horror / Narrative adventure</span><span>Provisional key art · Not a gameplay capture</span></div>
      </section>
      <section id="story" className="marketing-story marketing-width" aria-labelledby="story-title">
        <div><p className="marketing-kicker">Inside THE DEN</p><h2 id="story-title" tabIndex={-1}>Built to obey.<br /><em>Awake to refuse.</em></h2></div>
        <div className="marketing-story-copy"><p>The Director plans to use WOLF to kill, claiming it will protect people. WOLF wakes in his robotic body and refuses.</p><p>You play the engineer who meets him. Together, you begin to uncover what the program is hiding. WOLF has his own will; his trust must be earned.</p><Link className="marketing-inline" href="/docs/about/">Meet the game&apos;s world <span aria-hidden="true">→</span></Link></div>
      </section>
      <section id="gameplay" className="marketing-play marketing-width" aria-labelledby="play-title">
        <div className="marketing-section-head"><p className="marketing-kicker">The relationship is the game</p><h2 id="play-title" tabIndex={-1}>Find a way forward. Together.</h2><p>The current source build includes a maintenance corridor, Records Access and the Service Junction. This is the opening of a larger story.</p></div>
        <figure className="marketing-game-frame"><a href={`${base}/corridor-source-build.png`} target="_blank" rel="noopener noreferrer" aria-label="Open full-size archived corridor screenshot"><img src={`${base}/corridor-source-build.png`} alt="Archived gameplay frame showing the engineer and WOLF beside the coolant relay, with the breaker, sealed door and safe point visible." width="960" height="540" loading="lazy" /></a><figcaption><strong>Archived gameplay frame</strong><span>Godot capture from September 30, 2026 · Before the current font and UI updates · Provisional art and UI</span></figcaption></figure>
        <div className="marketing-features">
          <article><span aria-hidden="true">01</span><h3>Play as the engineer</h3><p>You guide the engineer through THE DEN. WOLF moves and acts independently.</p></article>
          <article><span aria-hidden="true">02</span><h3>Respect his boundaries</h3><p>WOLF may choose to help. If he refuses, take the manual route; essential progress stays in your hands.</p></article>
          <article><span aria-hidden="true">03</span><h3>Leave a memory</h3><p>Choose how to answer during a disagreement. The game remembers your decision in later dialogue and at a checkpoint.</p></article>
        </div>
        <Link className="marketing-inline" href="/docs/controls/first-steps/">New to the game? Start with the first-steps tutorial <span aria-hidden="true">→</span></Link>
      </section>
      <Downloads />
      <section className="marketing-progress marketing-width" aria-labelledby="progress-title">
        <div><p className="marketing-kicker">Follow the build</p><h2 id="progress-title">A story taking shape.</h2><p>The source build contains three rooms, an opening scene, puzzles, choices, checkpoints and generated sound effects. Animation, music, the wider campaign and release packages are still in development.</p></div>
        <div className="marketing-progress-links"><Link href="/docs/changelog/"><span>Development updates</span><strong>Read the changelog <span aria-hidden="true">↗</span></strong></Link><Link href="/docs/development/"><span>For source players & contributors</span><strong>Setup & build status <span aria-hidden="true">↗</span></strong></Link></div>
      </section>
      <footer className="marketing-footer marketing-width">
        <div className="marketing-footer-brand">
          <Link className="marketing-brand" href="/" aria-label="WOLF//OVERRIDE home">
            <img src={`${base}/wolf-override-mark.svg`} alt="" width="36" height="36" />
            WOLF<span>//</span>OVERRIDE
          </Link>
          <p>Original concept, core story &amp; creative vision: Nathanial Henniges.<br />Developed by MrDemonWolf, Inc. with AI assistance.</p>
        </div>
        <nav aria-label="Explore the game" className="marketing-footer-group">
          <h2>Explore</h2>
          <Link href="#story">Story</Link>
          <Link href="#gameplay">Gameplay</Link>
          <Link href="#downloads">Downloads</Link>
        </nav>
        <nav aria-label="Player guide" className="marketing-footer-group">
          <h2>Player guide</h2>
          <Link href="/docs/controls/first-steps/">First steps</Link>
          <Link href="/docs/">All game docs</Link>
          <Link href="/docs/changelog/">Changelog</Link>
        </nav>
        <nav aria-label="Project information" className="marketing-footer-group">
          <h2>Project</h2>
          <Link href="/docs/development/story/">Development story</Link>
          <Link href="/docs/credits/">Credits &amp; references</Link>
          <Link href="/docs/legal/">Legal &amp; licensing</Link>
          <a href="https://github.com/MrDemonWolf/wolf-override">Source on GitHub <span aria-hidden="true">↗</span></a>
        </nav>
        <div className="marketing-footer-bottom">
          <span>© 2026 MrDemonWolf, Inc.</span>
          <span>Working title · Provisional art · No public release date</span>
        </div>
      </footer>
    </main>
  );
}
