import Link from 'next/link';
import SiteHeader from './site-header';
import SiteFooter from './site-footer';
import { landingRoot, landingWidth, textLink } from './landing-classes';
import { pageMetadata, siteDescription } from '@/lib/seo';
import { homeStructuredData, JsonLd } from '@/lib/structured-data';

export const metadata = {
  ...pageMetadata('WOLF OVERRIDE', siteDescription, '/'),
  title: { absolute: 'WOLF OVERRIDE' },
};

/** Public project status and entry points during story development. */
export default function Home() {
  return (
    <div className={landingRoot}>
      <JsonLd data={homeStructuredData()} />
      <SiteHeader />
      <main id="main-content" className={`${landingWidth} grid min-h-[70vh] items-center gap-12 pt-40 pb-20 md:grid-cols-[1fr_auto]`}>
        <div>
          <h1 className="font-heading text-5xl font-bold tracking-tight text-text">WOLF OVERRIDE</h1>
          <p className="my-6 max-w-prose text-lg text-muted">Nathanial Henniges is returning to the story of the engineer and WOLF. The earlier playable chapter has been retired.</p>
          <Link className={textLink} href="/docs/get-game/">View the source and prototype history</Link>
        </div>
        <img className="w-40 md:w-64" width="256" height="256" src="/wolf-override-mark.svg" alt="" />
      </main>
      <SiteFooter />
    </div>
  );
}
