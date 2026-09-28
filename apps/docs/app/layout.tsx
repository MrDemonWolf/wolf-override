import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { RootProvider } from 'fumadocs-ui/provider/next';
import './global.css';

export const metadata: Metadata = {
  title: {
    default: 'WOLF//OVERRIDE',
    template: '%s | WOLF//OVERRIDE',
  },
  description: 'A side-view sci-fi horror game by MrDemonWolf, Inc.',
  icons: {
    icon: `${process.env.GITHUB_PAGES === 'true' ? '/wolf-override' : ''}/wolf-override-mark.svg`,
  },
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <a className="skip-link" href="#nd-page">Skip to content</a>
        <RootProvider search={{ enabled: false }} theme={{ defaultTheme: 'dark', enableSystem: false }}>
          {children}
        </RootProvider>
      </body>
    </html>
  );
}
