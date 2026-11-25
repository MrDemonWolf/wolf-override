import { publisherProfileLinks, publisherUrl, siteUrl } from '@/lib/seo';

/** Shared public brand facts and press-kit licensing, used by the page and its ZIP. */

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

/** Approved studio description (the IGDB company entry, final October 17, 2026). */
export const studioDescription =
  'MrDemonWolf, Inc. is the one-person studio of Nathanial Henniges, a software developer since 2012 based in Beloit, Wisconsin. He builds web apps, macOS apps, WordPress sites and open-source tools like FluffBoost, WolfWave and ConPaws, streams live coding on Twitch, makes videos on YouTube, and is now building his next game, WOLF OVERRIDE.';

/**
 * The AI disclosure, word for word as Nathanial Henniges approved it on 2026-10-19 (docs/decisions.md,
 * AI-01). The one home of the text on the site: the Credits page (app/docs/ai-disclosure.tsx), the
 * design-system page and the press kit's FACTS.txt and COPY.txt all read it from here, and store pages
 * should paste it as it is. Changes require a new approval.
 */
export const aiDisclosure =
  'WOLF OVERRIDE is a solo project by Nathanial Henniges (MrDemonWolf, Inc.). AI tools were used with careful human oversight to support the creative process for art and code. The story, characters and game design are his, and every AI-assisted asset is reviewed, edited and credited.';

/** Where the design-system page lives, with the trailing slash every site path uses. */
export const designSystemPath = '/design-system/';

/**
 * The press kit download, as served by the site. scripts/build-press-kit.ts writes it to
 * apps/docs/public/press/wolf-override-press-kit.zip before every `dev` and `build`; it is
 * git-ignored, so the repository never stores a second copy of the files it packs.
 */
export const pressKitPath = '/press/wolf-override-press-kit.zip';

/** The profiles listed for press: the publisher's confirmed profiles minus GitHub and LinkedIn, which are not marketing channels. */
export const pressLinks = publisherProfileLinks.filter((profile) => !['GitHub', 'LinkedIn'].includes(profile.label));

/** Where press should get in touch: no email address on purpose (the Discord and the studio site route messages). */
export const pressContact = [
  { label: 'Discord', url: pressLinks.find((link) => link.label === 'Discord')!.url, note: 'Fastest. Ask in the server and say you are press.' },
  { label: 'mrdemonwolf.com', url: publisherUrl, note: 'The studio site, with its own contact options.' },
];

/** Current project facts for the press kit and FACTS.txt. */
export const facts: [label: string, value: string][] = [
  ['Name', `${gameName.name} (formerly written ${gameName.former})`],
  ['Developer and publisher', studioName],
  ['Created by', 'Nathanial Henniges'],
  ['Status', 'In story development. The current Godot project opens an empty scene.'],
  ['Engine', 'Godot'],
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
  `The logo is provisional and was made with AI assistance (details: ${siteUrl}/docs/credits/). It may change before release.`,
  `All other rights are reserved by ${studioName}; these files are not covered by the GPL licence of the game's code.`,
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
};

/**
 * The cyan of the rule and the ring in the logo files made for light backgrounds (the *-for-light-bg
 * SVGs in public/brand/ draw with it). It is not a site token: it lives only in those files, and it is
 * too faint on white for text, so the page shows it beside the palette as a logo-only colour.
 */
export const logoLightCyan = '#00aced';

/**
 * The colourways every logo layout comes in, with the short note the page shows for each. `note`
 * describes the stacked and horizontal logos (which have lettering); `markNote`, where given,
 * describes the wolf mark alone, which has none. The hex codes are the ones the SVG files draw with.
 */
export const logoColourways = [
  { id: 'for-dark-bg', title: 'For dark backgrounds', note: 'White lettering, light cyan #8BE3FF rule', markNote: 'Light cyan #8BE3FF ring' },
  { id: 'for-light-bg', title: 'For light backgrounds', note: `Navy lettering, cyan ${logoLightCyan.toUpperCase()} rule`, markNote: `Cyan ${logoLightCyan.toUpperCase()} ring` },
  { id: 'mono-white', title: 'One colour, white', note: 'Stamps, merch and busy photos' },
  { id: 'mono-navy', title: 'One colour, navy', note: 'Stamps, print and light photos' },
] as const satisfies readonly { id: string; title: string; note: string; markNote?: string }[];

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
export const pressFiles: PressFile[] = logoFiles;

/** The zip's text files, in zip order: what each is called and what it holds. */
export const pressTextFiles = [
  { zipPath: 'FACTS.txt', title: 'Facts and links' },
  { zipPath: 'COPY.txt', title: 'Name, studio description, credits and AI disclosure' },
  { zipPath: 'LICENSE-ASSETS.txt', title: 'How you may use these files' },
] as const;
