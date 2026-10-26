import type { Metadata, Viewport } from 'next';
import type { ReactNode } from 'react';
import { RootProvider } from 'fumadocs-ui/provider/next';
import localFont from 'next/font/local';
import './global.css';
import { siteDescription, siteUrl, titleTemplate } from '@/lib/seo';

// Latin-subset WOFF2 builds of the OFL fonts; licence texts sit beside them in ./fonts.
const roboto = localFont({
  src: './fonts/roboto-latin-wght400-700.woff2',
  weight: '400 700',
  style: 'normal',
  display: 'swap',
  variable: '--font-roboto',
});

const montserrat = localFont({
  src: './fonts/montserrat-latin-wght500-800.woff2',
  weight: '500 800',
  style: 'normal',
  display: 'swap',
  variable: '--font-montserrat',
});

export const metadata: Metadata = {
  metadataBase: new URL(`${siteUrl}/`),
  applicationName: 'WOLF OVERRIDE',
  authors: [{ name: 'Nathanial Henniges', url: 'https://mrdemonwolf.com' }],
  creator: 'Nathanial Henniges',
  publisher: 'MrDemonWolf, Inc.',
  // GitHub Pages cannot set a custom response header; apply the policy to every exported page.
  referrer: 'strict-origin-when-cross-origin',
  // One robots meta for every crawler; a separate googlebot copy said the same thing twice.
  robots: { index: true, follow: true, 'max-image-preview': 'large' },
  title: {
    default: 'WOLF OVERRIDE',
    template: titleTemplate,
  },
  // Pages without their own description (the 404) use the same one as the landing page.
  description: siteDescription,
  // SVG for browsers that take it; a 96 px PNG (a multiple of 48, as Google asks for search-result
  // favicons) for those that do not; a 180 px opaque PNG for iOS home screens. Both PNGs are
  // rendered from the SVG mark (apps/game/assets/manifest.json, wolf-override-logo-mark).
  icons: {
    icon: [
      { url: '/wolf-override-mark.svg', type: 'image/svg+xml' },
      { url: '/wolf-override-mark-96.png', type: 'image/png', sizes: '96x96' },
    ],
    apple: { url: '/apple-touch-icon.png', sizes: '180x180' },
  },
};

/** Browser UI colour (mobile address bar): the landing page's --color-ink background. */
export const viewport: Viewport = {
  themeColor: '#080f1b',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" className={`${roboto.variable} ${montserrat.variable}`} suppressHydrationWarning>
      <body>
        <a className="skip-link" href="#main-content">Skip to content</a>
        {/* Fumadocs 16.13+ toggles the theme on a bare "D" key press; single-character shortcuts are switched off (WCAG 2.1.4). */}
        {/* Search is static: the browser downloads the index from app/api/search.json/route.ts and searches it locally, since the GitHub Pages export has no server. Its default hotkey is Ctrl/Cmd+K, never a bare key. */}
        <RootProvider search={{ options: { type: 'static', api: '/api/search.json' } }} theme={{ defaultTheme: 'dark', enableSystem: false, hotKey: false }}>
          {children}
        </RootProvider>
      </body>
    </html>
  );
}
