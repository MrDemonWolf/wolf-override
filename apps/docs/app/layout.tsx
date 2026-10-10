import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { RootProvider } from 'fumadocs-ui/provider/next';
import localFont from 'next/font/local';
import './global.css';
import './glass.css';
import { siteUrl } from '@/lib/seo';

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
  applicationName: 'WOLF//OVERRIDE',
  authors: [{ name: 'Nathanial Henniges', url: 'https://mrdemonwolf.com' }],
  creator: 'Nathanial Henniges',
  publisher: 'MrDemonWolf, Inc.',
  robots: { index: true, follow: true, googleBot: { index: true, follow: true, 'max-image-preview': 'large' } },
  title: {
    default: 'WOLF//OVERRIDE',
    template: '%s | WOLF//OVERRIDE',
  },
  description: 'A side-view sci-fi horror game by MrDemonWolf, Inc.',
  icons: {
    icon: '/wolf-override-mark.svg',
  },
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" className={`${roboto.variable} ${montserrat.variable}`} suppressHydrationWarning>
      <body>
        <a className="skip-link" href="#main-content">Skip to content</a>
        <RootProvider search={{ enabled: false }} theme={{ defaultTheme: 'dark', enableSystem: false }}>
          {children}
        </RootProvider>
      </body>
    </html>
  );
}
