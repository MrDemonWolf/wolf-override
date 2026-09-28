import Link from 'next/link';
import ThemeToggle from './theme-toggle';

export default function HomePage() {
  const assetBase = process.env.GITHUB_PAGES === 'true' ? '/wolf-override' : '';
  return (
    <main id="nd-page" className="site-shell">
      <header className="site-header">
        <Link className="wordmark" href="/" aria-label="WOLF//OVERRIDE home">
          <img src={`${assetBase}/wolf-override-mark.svg`} alt="" width="40" height="40" aria-hidden="true" />
          WOLF<span>//</span>OVERRIDE
        </Link>
        <div className="header-actions">
          <ThemeToggle />
          <Link className="header-link" href="/docs/">Game guide <span aria-hidden="true">↗</span></Link>
        </div>
      </header>

      <section className="hero" aria-labelledby="hero-title">
        <div className="hero-copy">
          <span className="eyebrow"><span className="signal-dot" /> Side-view sci-fi horror · In development</span>
          <h1 id="hero-title">He woke himself.<br /><em>They choose what comes next.</em></h1>
          <p>
            WOLF wakes himself after hearing the Program Director&apos;s plan to
            turn him into a killer under the cover of protecting people. With
            an engineer at his side, he must uncover the truth and find a way
            out of THE DEN.
          </p>
          <div className="hero-actions">
            <Link className="button-primary" href="/docs/about/">Explore the game <span aria-hidden="true">→</span></Link>
            <Link className="text-link" href="/docs/development/">Development status</Link>
          </div>
          <p className="release-note">Early source prototype · No public download yet</p>
        </div>
        <figure className="hero-scene">
          <img
            src={`${assetBase}/title-corridor-key-art-provisional.png`}
            width="1672"
            height="941"
            alt="An engineer and WOLF stand beside a sealed, blue-lit door in a dark research corridor."
          />
          <figcaption className="scene-caption">Provisional title artwork, not gameplay capture</figcaption>
        </figure>
      </section>

      <section className="game-section" aria-labelledby="game-title">
        <span className="eyebrow">01 / What you do</span>
        <h2 id="game-title">Two minds. One way forward.</h2>
        <p className="section-lead">The first playable chapter slice begins in a side-view corridor and continues into Records Access.</p>
        <div className="feature-strip">
          <div><span className="feature-index">01 /</span><strong>Play the engineer</strong><p>Move through two rooms with WOLF beside you as an independent companion.</p></div>
          <div><span className="feature-index">02 /</span><strong>Solve it together</strong><p>Open the route through cooperation, or use the engineer&apos;s fallback when WOLF refuses.</p></div>
          <div><span className="feature-index">03 /</span><strong>Live with a choice</strong><p>Choose a response in one disagreement and hear WOLF remember it later.</p></div>
        </div>
      </section>

      <section className="stakes-section" aria-labelledby="stakes-title">
        <div>
          <span className="eyebrow">02 / The world</span>
          <h2 id="stakes-title">THE DEN was built to keep secrets.</h2>
        </div>
        <div className="stakes-copy">
          <p>The Program Director calls WOLF property and conceals what the program has done. WOLF has his own will, boundaries, and responsibility.</p>
          <p>The planned story follows WOLF and the engineer as they preserve evidence, expose wrongdoing, protect people, and work to prevent catastrophe.</p>
        </div>
      </section>

      <section className="closing-cta" aria-labelledby="closing-title">
        <span className="eyebrow">The story starts here</span>
        <h2 id="closing-title">Meet WOLF. See what exists.</h2>
        <p>Explore the game&apos;s premise and the current two-room source build. Art, audio, and a downloadable release are still in development.</p>
        <div className="hero-actions">
          <Link className="button-primary" href="/docs/">Read the game guide <span aria-hidden="true">→</span></Link>
          <Link className="text-link" href="/docs/development/">See what&apos;s built</Link>
        </div>
      </section>

      <footer className="site-footer">
        <span>WOLF//OVERRIDE <span className="footer-divider">/</span> By MrDemonWolf, Inc.</span>
        <span>In development · No public release yet</span>
      </footer>
    </main>
  );
}
