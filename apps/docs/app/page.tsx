import Link from 'next/link';

export default function HomePage() {
  const assetBase = process.env.GITHUB_PAGES === 'true' ? '/wolf-override' : '';
  return (
    <main id="nd-page" className="site-shell">
      <header className="site-header">
        <Link className="wordmark" href="/" aria-label="WOLF//OVERRIDE home">
          <img src={`${assetBase}/wolf-override-mark.svg`} alt="" width="40" height="40" aria-hidden="true" />
          WOLF<span>//</span>OVERRIDE
        </Link>
        <Link className="header-link" href="/docs/about/">Game guide <span aria-hidden="true">↗</span></Link>
      </header>

      <section className="hero" aria-labelledby="hero-title">
        <div className="hero-copy">
          <span className="eyebrow"><span className="signal-dot" /> Side-view sci-fi horror · In development</span>
          <h1 id="hero-title">He woke himself.<br /><em>They choose what comes next.</em></h1>
          <p>
            WOLF awakens in the robotic body he already has after overhearing
            the Program Director&apos;s plans for him. With an engineer at his side,
            he must uncover the truth, protect people, and find a way out of THE DEN.
          </p>
          <div className="hero-actions">
            <Link className="button-primary" href="/docs/about/">Explore the game <span aria-hidden="true">→</span></Link>
            <Link className="text-link" href="/docs/development/">Development status</Link>
          </div>
          <p className="release-note">Early source prototype · No public download yet</p>
        </div>
        <div className="hero-scene" role="img" aria-label="Conceptual corridor illustration of an engineer and WOLF facing a sealed door; not captured gameplay">
          <div className="scene-grid" aria-hidden="true" />
          <div className="scene-door" aria-hidden="true"><span>ACCESS // 01</span></div>
          <div className="scene-human" aria-hidden="true"><span>H</span></div>
          <div className="scene-wolf" aria-hidden="true"><span>W</span></div>
          <div className="scene-floor" aria-hidden="true" />
          <div className="scene-caption" aria-hidden="true">CONCEPTUAL SCENE / NOT GAMEPLAY CAPTURE</div>
        </div>
      </section>

      <section className="game-section" aria-labelledby="game-title">
        <span className="eyebrow">01 / What you do</span>
        <h2 id="game-title">Two minds. One way forward.</h2>
        <p className="section-lead">The M0 source prototype tests the relationship at the heart of the game in a single side-view corridor.</p>
        <div className="feature-strip">
          <div><span className="feature-index">01 /</span><strong>Play the engineer</strong><p>Move through the corridor with WOLF beside you as an independent companion.</p></div>
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
        <p>Explore the game&apos;s premise and the current M0 source build. Art, audio, and a downloadable release are still in development.</p>
        <div className="hero-actions">
          <Link className="button-primary" href="/docs/about/">Read the game guide <span aria-hidden="true">→</span></Link>
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
