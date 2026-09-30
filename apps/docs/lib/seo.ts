import type { Metadata } from 'next';

export const siteUrl = 'https://wolf-override.mrdemonwolf.dev';
export const siteDescription = 'A side-view sci-fi horror adventure by MrDemonWolf, Inc. Explore THE DEN with an independent robotic wolf, solve puzzles and make choices he remembers. In development.';

export function pageMetadata(title: string, description: string, path: string): Metadata {
  const url = `${siteUrl}${path}`;
  const image = { url: `${siteUrl}/title-corridor-key-art-provisional.png`, width: 1672, height: 941, alt: 'WOLF//OVERRIDE provisional key art: an engineer and robotic wolf in a research corridor.' };
  return {
    title,
    description,
    alternates: { canonical: url },
    openGraph: { type: 'website', siteName: 'WOLF//OVERRIDE', title, description, url, locale: 'en_US', images: [image] },
    twitter: { card: 'summary_large_image', title, description, images: [image] },
  };
}
