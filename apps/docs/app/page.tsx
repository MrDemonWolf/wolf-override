import Link from 'next/link';
import ThemeToggle from './theme-toggle';
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
        <nav aria-label="Main navigation"><a href="#downloads">Downloads</a><Link href="/docs/">Game guide</Link><ThemeToggle /></nav>
      </header>
      <section className="marketing-hero" aria-labelledby="game-title">
        <img className="marketing-keyart" src={`${base}/title-corridor-key-art-provisional.png`} width="1672" height="941" alt="An engineer in a red hoodie stands beside the robotic wolf WOLF in a blue-lit research corridor." fetchPriority="high" />
        <div className="marketing-hero-copy">
          <p className="marketing-kicker">Side-view sci-fi horror · In development</p>
          <h1 id="game-title">WOLF<span>//</span><br />OVERRIDE</h1>
          <p className="marketing-tagline">He woke himself.<br />They choose what comes next.</p>
          <p className="marketing-pitch">Explore THE DEN as an engineer alongside an independent robotic wolf. Solve a way forward. Choose how you earn his trust.</p>
          <div className="marketing-actions"><a className="marketing-primary" href="#gameplay">See the game <span aria-hidden="true">↓</span></a><a className="marketing-secondary" href="#downloads">Downloads · Coming soon</a></div>
          <p className="marketing-status">In development · Downloads coming soon</p>
        </div>
        <div className="marketing-hero-foot"><span>Side-view sci-fi horror / Narrative adventure</span><span>Provisional key art · Not a gameplay capture</span></div>
      </section>
      <section className="marketing-story marketing-width" aria-labelledby="story-title">
        <div><p className="marketing-kicker">Inside THE DEN</p><h2 id="story-title">Built to obey.<br /><em>Awake to refuse.</em></h2></div>
        <div className="marketing-story-copy"><p>WOLF hears the Director&apos;s plan to turn him into a killer under the cover of protecting people. He wakes himself, already in his robotic body, and refuses.</p><p>You play the engineer who meets him. Together, they begin uncovering what the program is hiding. WOLF has his own will. Earning his trust means respecting it.</p><Link className="marketing-inline" href="/docs/about/">Meet the game&apos;s world <span aria-hidden="true">→</span></Link></div>
      </section>
      <section id="gameplay" className="marketing-play marketing-width" aria-labelledby="play-title">
        <div className="marketing-section-head"><p className="marketing-kicker">The relationship is the game</p><h2 id="play-title">Find a way forward. Together.</h2><p>The current source chapter spans a corridor and Records Access. It is a small beginning to a larger story.</p></div>
        <figure className="marketing-game-frame"><a href={`${base}/corridor-source-build.png`} target="_blank" rel="noopener noreferrer" aria-label="Open full-size corridor screenshot"><img src={`${base}/corridor-source-build.png`} alt="The engineer and WOLF beside the coolant relay in the scrolling maintenance corridor, with the breaker, sealed door and safe point visible." width="960" height="540" loading="lazy" /></a><figcaption><strong>Inside the current source build</strong><span>Godot-rendered development frame · Tap to enlarge · Provisional art and UI</span></figcaption></figure>
        <div className="marketing-features">
          <article><span aria-hidden="true">01</span><h3>Be the engineer</h3><p>Explore a side-view facility with WOLF beside you. You control the engineer; he acts as an independent companion.</p></article>
          <article><span aria-hidden="true">02</span><h3>Respect his boundaries</h3><p>Cooperate to open a path, or take the manual route when WOLF refuses. Essential progress stays in your hands.</p></article>
          <article><span aria-hidden="true">03</span><h3>Leave a memory</h3><p>Choose your words in an authored disagreement. Hear your decision remembered later, then carry it into a checkpoint.</p></article>
        </div>
        <Link className="marketing-inline" href="/docs/">Read the playable chapter guide <span aria-hidden="true">→</span></Link>
      </section>
      <Downloads />
      <section className="marketing-progress marketing-width" aria-labelledby="progress-title">
        <div><p className="marketing-kicker">Follow the build</p><h2 id="progress-title">A story taking shape.</h2><p>Two rooms, an opening scene, puzzles, choices and checkpoints exist in the source build. Final animation, sound, the wider campaign and release packages are still ahead.</p></div>
        <div className="marketing-progress-links"><Link href="/docs/changelog/"><span>Development updates</span><strong>Read the changelog <span aria-hidden="true">↗</span></strong></Link><Link href="/docs/development/"><span>For source players & contributors</span><strong>Setup & build status <span aria-hidden="true">↗</span></strong></Link></div>
      </section>
      <footer className="marketing-footer marketing-width">
        <div><strong>WOLF//OVERRIDE</strong><p>Original concept, core story & creative vision: Nathanial Henniges.<br />Developed by MrDemonWolf, Inc. with AI assistance.</p></div>
        <nav aria-label="Footer navigation"><Link href="/docs/credits/">Credits & sources</Link><Link href="/docs/changelog/">Changelog</Link><a href="https://github.com/MrDemonWolf/wolf-override">Source on GitHub ↗</a></nav>
        <p className="marketing-footnote">Working title · Provisional art · No public release date</p>
      </footer>
    </main>
  );
}
