import { plannedPlatforms } from '@/app/downloads';
import { publisherProfileLinks, publisherUrl, siteUrl } from '@/lib/seo';

/*
 * The words of the design-system page (/design-system/) and of the press kit zip, in one place.
 * The page renders them as HTML; scripts/build-press-kit.ts writes the same values into the zip's
 * FACTS.txt, COPY.txt and LICENSE-ASSETS.txt, so the page and the download can never say different
 * things. Every description here is copy Nathanial Henniges approved for the IGDB and Twitch
 * listings on 2026-10-16 (tagline, summary, storyline) and 2026-10-17 (studio description); do not
 * reword it here, and add no story beyond what the public landing page already says.
 */

/** The game's name, and the rules for writing it (Nathanial's decision, October 17, 2026). */
export const gameName = {
  /** The name everywhere: two words, no slashes, all capitals. */
  name: 'WOLF OVERRIDE',
  /** Acceptable in running text where all capitals are not allowed (a headline style guide, a store field). */
  titleCase: 'Wolf Override',
  /** The stylised spelling the game had until October 17, 2026; only for listings' alternative names and quotes of history. */
  former: 'WOLF//OVERRIDE',
};

/** The studio, as it is credited everywhere. */
export const studioName = 'MrDemonWolf, Inc.';

/** The one-line credit to put under the logo or at the end of an article. */
export const creditLine = `${gameName.name} by ${studioName}`;

/** The creator credit the site's footer and the game's credits carry. */
export const creatorCredit = 'Original concept, core story and creative vision: Nathanial Henniges.';

/** Approved tagline (31 characters). */
export const tagline = 'Built to obey. Awake to refuse.';

/** Approved short description: the IGDB summary (about 310 characters). */
export const shortDescription =
  'A side-view sci-fi horror adventure. WOLF is a robotic wolf with a will of his own. The Director plans to use him to kill. He refuses. You play the engineer who meets him inside THE DEN. Solve puzzles, make choices he remembers and earn his trust. He can help you, or say no. In development by MrDemonWolf, Inc.';

/** Approved long description: the IGDB storyline, two paragraphs, premise only. */
export const longDescription = [
  'WOLF was built to obey. The Director plans to use him to kill, claiming it will protect people. WOLF wakes in his robotic body and refuses.',
  'You play the engineer who meets him inside THE DEN. Together, you begin to uncover what the program is hiding. WOLF has his own will. He can help you or refuse, and he remembers your choices. His trust must be earned.',
];

/** Approved studio description (the IGDB company entry, final October 17, 2026). */
export const studioDescription =
  'MrDemonWolf, Inc. is the one-person studio of Nathanial Henniges, a software developer since 2012 based in Beloit, Wisconsin. He builds web apps, macOS apps, WordPress sites and open-source tools like FluffBoost, WolfWave and ConPaws, streams live coding on Twitch, makes videos on YouTube, and is now building his next game, WOLF OVERRIDE.';

/** Where the design-system page lives, with the trailing slash every site path uses. */
export const designSystemPath = '/design-system/';

/** The press kit download, as served by the site (the file is apps/docs/public/press/wolf-override-press-kit.zip). */
export const pressKitPath = '/press/wolf-override-press-kit.zip';

/** The profiles listed for press: the publisher's confirmed profiles minus GitHub and LinkedIn, which are not marketing channels. */
export const pressLinks = publisherProfileLinks.filter((profile) => !['GitHub', 'LinkedIn'].includes(profile.label));

/** Where press should get in touch: no email address on purpose (the Discord and the studio site route messages). */
export const pressContact = [
  { label: 'Discord', url: pressLinks.find((link) => link.label === 'Discord')!.url, note: 'Fastest. Ask in the server and say you are press.' },
  { label: 'mrdemonwolf.com', url: publisherUrl, note: 'The studio site, with its own contact options.' },
];

/**
 * Plain facts, one label and value each, for the page's fact table and FACTS.txt. The platforms come
 * from the landing page's planned-platform list (app/downloads.tsx), so the two never disagree.
 */
export const facts: [label: string, value: string][] = [
  ['Name', `${gameName.name} (formerly written ${gameName.former})`],
  ['Developer and publisher', studioName],
  ['Created by', 'Nathanial Henniges'],
  ['Genre', 'Side-view sci-fi horror adventure'],
  ['Players', 'Single player'],
  ['Status', 'In development, no release date. Test builds and the source are available.'],
  ['Platforms planned', `${plannedPlatforms.map((platform) => platform.name).join(', ')} (no release date)`],
  ['Engine', 'Godot'],
  ['Languages', 'English for now; more are planned'],
  ['Website', `${siteUrl}/`],
  ['Press kit and brand guide', `${siteUrl}${designSystemPath}`],
];

/**
 * The asset licence, one rule per line: the page's licence list and LICENSE-ASSETS.txt. It matches
 * the Legal page: the art and logo are outside the code's GPL, and their rights review is still open.
 */
export const assetTerms = [
  `You may use these files to write about, stream, review or promote ${gameName.name}, in print, video or online, with the credit "${creditLine}".`,
  'Do not change the logo or the wolf mark: no stretching, recolouring, effects, cropping or redrawing. Use the files as they are.',
  'You may resize screenshots and key art and crop them for layout, but do not edit what they show or present them as final art.',
  'The key art, screenshots and logo are provisional and made with AI assistance (see the Credits page). They may change before release.',
  `Everything else is all rights reserved by ${studioName}. These files are not covered by the GPL licence of the game's code.`,
  'The fonts (Montserrat and Roboto) are under the SIL Open Font License 1.1; get them from their own projects.',
];

/** One file of the press kit. */
export type PressFile = {
  /** Path inside the zip. */
  zipPath: string;
  /** Where the file lives, relative to the docs app folder (apps/docs), which the build and scripts run in. */
  source: string;
  /** What it is, for the page's file list. */
  title: string;
  /**
   * The site URL of a single-file download when the file is not served from public/ under its own
   * path: the key art PNG is not published, so its full-width WebP is offered instead. Files under
   * app/images are served at hashed paths the page gets from their imports, so they leave this out.
   */
  href?: string;
};

/** The colourways every logo layout comes in, with the short note the page shows for each. */
export const logoColourways = [
  { id: 'for-dark-bg', title: 'For dark backgrounds', note: 'White name, light cyan ring' },
  { id: 'for-light-bg', title: 'For light backgrounds', note: 'Navy name, deeper cyan ring' },
  { id: 'mono-white', title: 'One colour, white', note: 'Stamps, merch and busy photos' },
  { id: 'mono-navy', title: 'One colour, navy', note: 'Stamps, print and light photos' },
] as const;

// The logo files: an SVG of every layout and colourway, plus PNG exports at fixed sizes. The dark
// mark SVG is the site's own favicon mark (public/wolf-override-mark.svg), not a second copy.
const logoFiles: PressFile[] = logoColourways.flatMap(({ id, title }) => [
  { zipPath: `logo/svg/wolf-override-stacked-${id}.svg`, source: `public/brand/wolf-override-stacked-${id}.svg`, title: `Stacked logo, ${title.toLowerCase()} (SVG)` },
  { zipPath: `logo/svg/wolf-override-horizontal-${id}.svg`, source: `public/brand/wolf-override-horizontal-${id}.svg`, title: `Horizontal logo, ${title.toLowerCase()} (SVG)` },
  {
    zipPath: `logo/svg/wolf-override-mark-${id}.svg`,
    source: id === 'for-dark-bg' ? 'public/wolf-override-mark.svg' : `public/brand/wolf-override-mark-${id}.svg`,
    title: `Wolf mark, ${title.toLowerCase()} (SVG)`,
  },
  { zipPath: `logo/png/wolf-override-stacked-1500x1000-${id}.png`, source: `public/brand/wolf-override-stacked-1500x1000-${id}.png`, title: `Stacked logo, ${title.toLowerCase()} (PNG, 1500x1000)` },
  { zipPath: `logo/png/wolf-override-horizontal-1200x400-${id}.png`, source: `public/brand/wolf-override-horizontal-1200x400-${id}.png`, title: `Horizontal logo, ${title.toLowerCase()} (PNG, 1200x400)` },
  { zipPath: `logo/png/wolf-override-mark-512-${id}.png`, source: `public/brand/wolf-override-mark-512-${id}.png`, title: `Wolf mark, ${title.toLowerCase()} (PNG, 512x512)` },
]);

/** Every file in the press kit except the three generated text files, in zip order. */
export const pressFiles: PressFile[] = [
  ...logoFiles,
  { zipPath: 'screenshots/wolf-override-records-access-1600x900.png', source: 'app/images/records-access-doors-capture.png', title: 'Screenshot: Records Access (PNG, 1600x900)' },
  { zipPath: 'screenshots/wolf-override-service-junction-1600x900.png', source: 'app/images/service-junction-doors-capture.png', title: 'Screenshot: the Service Junction (PNG, 1600x900)' },
  { zipPath: 'screenshots/wolf-override-title-screen-960x540.png', source: 'app/images/title-screen-capture.png', title: 'Screenshot: the title screen (PNG, 960x540)' },
  {
    zipPath: 'art/wolf-override-key-art-provisional-1672x941.png',
    source: '../game/assets/title-corridor-key-art-provisional.png',
    title: 'Key art, provisional (PNG, 1672x941; single download is WebP)',
    href: '/title-corridor-key-art-provisional-1672.webp',
  },
  { zipPath: 'art/wolf-override-cover-1200x1600.png', source: 'public/press/wolf-override-cover-1200x1600.png', title: 'Cover, 3:4 with the name (PNG, 1200x1600)' },
];

/** The zip's text files, in zip order: what each is called and what it holds. */
export const pressTextFiles = [
  { zipPath: 'FACTS.txt', title: 'Facts and links' },
  { zipPath: 'COPY.txt', title: 'Approved name, tagline and descriptions' },
  { zipPath: 'LICENSE-ASSETS.txt', title: 'How you may use these files' },
] as const;
