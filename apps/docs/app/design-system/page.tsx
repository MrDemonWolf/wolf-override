import { statSync } from 'node:fs';
import path from 'node:path';
import type { ReactNode } from 'react';
import Link from 'next/link';
import SiteHeader from '../site-header';
import SiteFooter from '../site-footer';
import { card, inlineLink, landingRoot, landingWidth, sectionCopy } from '../landing-classes';
import recordsCapture from '../images/records-access-doors-capture.png';
import recordsCapture480 from '../images/records-access-doors-capture-480.webp';
import junctionCapture from '../images/service-junction-doors-capture.png';
import junctionCapture480 from '../images/service-junction-doors-capture-480.webp';
import titleCapture from '../images/title-screen-capture.png';
import titleCapture480 from '../images/title-screen-capture-480.webp';
import { contrastRatio, resolveBrandColors } from '@/lib/brand-colors';
import {
  aiDisclosure,
  assetTerms,
  creatorCredit,
  creditLine,
  designSystemPath,
  gameName,
  logoColourways,
  logoLightCyan,
  longDescription,
  pressContact,
  pressFiles,
  pressKitPath,
  pressLinks,
  pressTextFiles,
  shortDescription,
  studioDescription,
  tagline,
  type PressFile,
} from '@/lib/press-kit';
import { pageMetadata, repoUrl } from '@/lib/seo';

/*
 * /design-system/: the public brand guide and press kit. Every word of copy, every file and every
 * licence rule comes from lib/press-kit.ts, the same module scripts/build-press-kit.ts writes the zip
 * from; the colour swatches are read from app/global.css (lib/brand-colors.ts). The page itself only
 * lays them out. Dark only, like the landing page, because the brand's home ground is the game's navy.
 */

export const metadata = pageMetadata(
  'Press kit and brand guide',
  'Logos, colours, fonts, approved copy and one press kit download for WOLF OVERRIDE, the sci-fi horror game by MrDemonWolf, Inc., and how to use them.',
  designSystemPath,
);

/** The page's sections, in order: the on-page navigation and each section's id and heading. */
const sections = [
  ['name', 'Name'],
  ['logo', 'Logo'],
  ['colours', 'Colours'],
  ['type', 'Type'],
  ['imagery', 'Imagery'],
  ['download', 'Asset pack'],
  ['contact', 'Press contact'],
] as const;

type SectionId = (typeof sections)[number][0];

// Files under app/images are served at hashed paths, known only through their imports.
const importedHref: Record<string, string> = {
  'app/images/records-access-doors-capture.png': recordsCapture.src,
  'app/images/service-junction-doors-capture.png': junctionCapture.src,
  'app/images/title-screen-capture.png': titleCapture.src,
};

/** The URL a single file downloads from: its public/ path, an explicit href, or its import's hashed path. */
function hrefFor(file: PressFile): string {
  if (file.href) return file.href;
  if (file.source.startsWith('public/')) return file.source.slice('public'.length);
  const href = importedHref[file.source];
  if (!href) throw new Error(`No download URL for ${file.source}: add its import to importedHref`);
  return href;
}

/**
 * A file's size on disk in KB or MB, read when the site is built (paths are relative to apps/docs).
 * For a single download, pass the file the link serves: for an `href` file that is its public/ copy,
 * not the zipped source.
 */
function sizeOf(source: string): string {
  const bytes = statSync(path.join(process.cwd(), source)).size;
  return bytes >= 1048576 ? `${(bytes / 1048576).toFixed(1)} MB` : `${Math.max(1, Math.round(bytes / 1024))} KB`;
}

/** The screenshots the Imagery section previews (their full PNGs are in the kit). */
const screenshots = [
  { image: recordsCapture480, title: 'Records Access', alt: 'Gameplay frame in Records Access: the engineer at a red console beside a shut steel door, with WOLF nearby.' },
  { image: junctionCapture480, title: 'Service Junction', alt: 'Gameplay frame in the Service Junction: the engineer at a yellow valve wheel under a row of station plates, with WOLF at the left.' },
  { image: titleCapture480, title: 'Title screen', alt: 'The title screen: the key art with the WOLF OVERRIDE name and the menu on the right.' },
];

// The file list's groups, by the zip folder each file sits in.
const fileGroups = [
  ['logo/svg/', 'Logo and wolf mark, SVG (any size)'],
  ['logo/png/', 'Logo and wolf mark, PNG'],
  ['screenshots/', 'Screenshots'],
  ['art/', 'Key art and cover'],
] as const;

// The three logo layouts, shown in every colourway on the ground each is made for.
const layouts = [
  { id: 'stacked', title: 'Stacked', use: 'Recommended. Square-ish and 3:2 spaces: store tiles, IGDB, posters.', minimum: 'At least 150 px wide.', box: 'h-24' },
  { id: 'horizontal', title: 'Horizontal', use: 'Wide spaces: website headers, stream and social banners.', minimum: 'At least 160 px wide (32 px tall).', box: 'h-12' },
  { id: 'mark', title: 'Wolf mark', use: 'Small and square spaces: avatars, profile pictures, icons.', minimum: 'At least 40 px tall; finer details blur below that.', box: 'h-20' },
] as const;

/** The SVG of one layout in one colourway. The dark mark is the site's favicon mark, not a second copy. */
function logoSrc(layout: string, colourway: string): string {
  return layout === 'mark' && colourway === 'for-dark-bg' ? '/wolf-override-mark.svg' : `/brand/wolf-override-${layout}-${colourway}.svg`;
}

// Tile ground per colourway: navy for the dark and white versions, near-white for the light and navy ones.
const groundFor = (colourway: string) => (colourway === 'for-dark-bg' || colourway === 'mono-white' ? 'bg-panel' : 'bg-[#f4f9fd]');

// Small-caps label above a section's heading, and the heading itself; smaller than the landing's
// section titles because this page is a reference sheet, read section by section.
const kicker = 'hud-label mb-3';
const sectionHeading = 'mb-4 text-title font-bold';
const sectionBox = `${landingWidth} border-t border-t-line py-16 phone:py-12`;
const subHeading = 'mt-10 mb-3 font-heading text-[1.15rem] font-bold';
const bulletList = 'flex list-disc flex-col gap-2 pl-5 leading-[1.6] text-muted marker:text-accent';

/** One section of the page: an anchor target with its number, heading and a one-line TL;DR. */
function Section({ id, index, title, tldr, children }: { id: SectionId; index: number; title: string; tldr: string; children: ReactNode }) {
  return (
    <section id={id} className={sectionBox} aria-labelledby={`${id}-title`}>
      <p className={kicker}>{String(index).padStart(2, '0')}</p>
      <h2 id={`${id}-title`} tabIndex={-1} className={sectionHeading}>{title}</h2>
      <p className={`${sectionCopy} text-lead`}><strong className="text-text">TL;DR:</strong> {tldr}</p>
      {children}
    </section>
  );
}

/** A block of approved copy with a label and a character count, so it can be pasted into a length-limited field. */
function CopyBlock({ label, paragraphs }: { label: string; paragraphs: readonly string[] }) {
  const length = paragraphs.join('\n\n').length;
  return (
    <figure className={`${card} p-5`}>
      <figcaption className="mb-3 flex flex-wrap justify-between gap-2 text-caption text-muted">
        <strong className="text-text">{label}</strong>
        <span>{length} characters</span>
      </figcaption>
      {paragraphs.map((paragraph) => (
        <p key={paragraph} className="mb-3 leading-[1.7] last:mb-0">{paragraph}</p>
      ))}
    </figure>
  );
}

/** One "don't" example: the real logo file with a misuse applied, and what it shows. */
function DontTile({ label, children, ground = 'bg-panel' }: { label: string; children: ReactNode; ground?: string }) {
  return (
    <figure className={`${card} overflow-hidden`}>
      <div className={`flex h-32 items-center justify-center overflow-hidden p-4 ${ground}`} aria-hidden="true">{children}</div>
      <figcaption className="flex items-start gap-2 px-4 py-3 text-caption">
        <span className="font-heading font-bold text-[#ff8c8c]">Don&apos;t</span>
        <span className="text-muted">{label}</span>
      </figcaption>
    </figure>
  );
}

/** The download button for the whole kit: one per page, in the TL;DR and repeated at the file list. */
function DownloadButton() {
  return (
    <a
      href={pressKitPath}
      download
      className="inline-flex min-h-12 items-center gap-3 rounded-control bg-accent px-5 py-3 font-heading font-bold text-ink transition-[background-color] duration-180 ease-[ease] hover-always:bg-text motion-reduce:transition-none"
    >
      Download the press kit
      <span className="font-sans text-caption font-normal">ZIP · {sizeOf(`public${pressKitPath}`)}</span>
    </a>
  );
}

export default function DesignSystemPage() {
  const colours = resolveBrandColors();
  // The bright cyan's contrast on white, for the note on why light grounds use the deep cyan, and the
  // logo-only cyan's, for the note on why it is never used for text.
  const cyanOnWhite = contrastRatio(colours.find((colour) => colour.token === 'color-accent')!.hex, '#ffffff').toFixed(1);
  const logoCyanOnWhite = contrastRatio(logoLightCyan, '#ffffff').toFixed(1);
  return (
    // data-landing keeps the root dark, as on the landing page; landingRoot clears the sticky header for the section links.
    <div data-landing="" className={landingRoot}>
      <SiteHeader linkBase="/" />
      <main id="design-system-main">
        <section className={`${landingWidth} pt-40 pb-16 phone:pt-36 phone:pb-12`} aria-labelledby="main-content">
          <p className={kicker}>Press kit &amp; brand guide</p>
          <h1 id="main-content" tabIndex={-1} className="mb-6 text-headline font-bold tracking-[-.04em]">
            {gameName.name} design system
          </h1>
          <ul className={`${bulletList} mb-8 max-w-[62ch] text-lead`}>
            <li><strong className="text-text">What this is:</strong> how to show the game: its name, logo, colours, fonts and pictures.</li>
            <li><strong className="text-text">Who it is for:</strong> press, streamers, creators and anyone making something about the game.</li>
            <li><strong className="text-text">The short rule:</strong> use the files as they are, and credit &ldquo;{creditLine}&rdquo;.</li>
          </ul>
          <DownloadButton />
          <p className="mt-3 text-caption text-muted">Logos, wolf mark, screenshots, key art, cover, facts and approved copy in one file.</p>
          <nav aria-label="On this page" className="mt-10 flex flex-wrap gap-2">
            {sections.map(([id, title]) => (
              <a key={id} href={`#${id}`} className="inline-flex min-h-11 items-center rounded-control border border-line-strong px-4 hover-always:border-accent hover-always:text-accent">
                {title}
              </a>
            ))}
          </nav>
        </section>

        <Section id="name" index={1} title="Name" tldr={`Write ${gameName.name}: two words, no slashes.`}>
          <div className="grid grid-cols-2 gap-6 phone:grid-cols-1">
            <div className={`${card} p-6`}>
              <h3 className="mb-3 font-heading font-bold text-accent">Do</h3>
              <ul className={bulletList}>
                <li><strong className="text-text">{gameName.name}</strong> in the logo, headlines and anywhere capitals work.</li>
                <li><strong className="text-text">{gameName.titleCase}</strong> in running text where all capitals are not allowed.</li>
                <li>Credit the studio: <strong className="text-text">{creditLine}</strong></li>
              </ul>
            </div>
            <div className={`${card} p-6`}>
              <h3 className="mb-3 font-heading font-bold text-[#ff8c8c]">Don&apos;t</h3>
              <ul className={bulletList}>
                <li><strong className="text-text">{gameName.former}</strong>: the old spelling, retired on October 17, 2026.</li>
                <li>WolfOverride, Wolf-Override or W.O.: one word, a hyphen or initials.</li>
                <li>Calling it released: it is in development, with no release date.</li>
              </ul>
            </div>
          </div>
          <h3 className={subHeading}>Approved copy</h3>
          <p className={sectionCopy}>Paste these as they are. They are approved, spoiler-free and fit common listing limits.</p>
          <div className="grid gap-4">
            <CopyBlock label="Tagline" paragraphs={[tagline]} />
            <CopyBlock label="Short description" paragraphs={[shortDescription]} />
            <CopyBlock label="Long description" paragraphs={longDescription} />
            <CopyBlock label="About the studio" paragraphs={[studioDescription]} />
            <CopyBlock label="Credit line" paragraphs={[creditLine, creatorCredit]} />
          </div>
        </Section>

        <Section id="logo" index={2} title="Logo" tldr="Pick the layout that fits the space and the version made for its background. Never change the files.">
          {layouts.map((layout) => (
            <div key={layout.id} className="mt-8 first-of-type:mt-2">
              <h3 className="mb-1 font-heading text-[1.15rem] font-bold">{layout.title}</h3>
              <p className="mb-4 leading-[1.6] text-muted">{layout.use} {layout.minimum}</p>
              <div className="grid grid-cols-4 gap-4 compact:grid-cols-2 phone:grid-cols-2 phone-xs:grid-cols-1">
                {logoColourways.map((colourway) => (
                  <figure key={colourway.id} className={`${card} overflow-hidden`}>
                    <a href={logoSrc(layout.id, colourway.id)} download className={`flex h-36 items-center justify-center p-5 ${groundFor(colourway.id)}`}>
                      <img src={logoSrc(layout.id, colourway.id)} alt={`${layout.title} logo, ${colourway.title.toLowerCase()}`} className={`${layout.box} w-auto max-w-full object-contain`} loading="lazy" decoding="async" />
                    </a>
                    <figcaption className="px-4 py-3 text-caption">
                      <strong className="block text-text">{colourway.title}</strong>
                      <span className="text-muted">{layout.id === 'mark' && 'markNote' in colourway ? colourway.markNote : colourway.note}</span>
                    </figcaption>
                  </figure>
                ))}
              </div>
            </div>
          ))}
          <h3 className={subHeading}>Clear space and size</h3>
          <ul className={`${bulletList} max-w-[62ch]`}>
            <li><strong className="text-text">Clear space:</strong> every file already has a margin built in. Keep at least that much empty space around the logo; about a quarter of the letter height on each side.</li>
            <li><strong className="text-text">Don&apos;t crop</strong> into that margin or put text or other logos inside it.</li>
            <li><strong className="text-text">Minimum sizes</strong> are listed under each layout above. Smaller than that, use the wolf mark.</li>
            <li><strong className="text-text">Busy pictures:</strong> use a one-colour version, or put the logo on a calm, dark part of the picture.</li>
          </ul>
          <h3 className={subHeading}>Don&apos;t change the logo</h3>
          <p className={sectionCopy}>Each example below is the real logo file with one mistake applied.</p>
          <div className="grid grid-cols-3 gap-4 compact:grid-cols-2 phone:grid-cols-1">
            <DontTile label="Stretch or squash it.">
              <img src={logoSrc('stacked', 'for-dark-bg')} alt="" className="h-16 w-56 max-w-full object-fill" />
            </DontTile>
            <DontTile label="Recolour it or swap its colours.">
              <img src={logoSrc('stacked', 'for-dark-bg')} alt="" className="h-20 w-auto hue-rotate-[150deg] saturate-200" />
            </DontTile>
            <DontTile label="Add glows, shadows, outlines or other effects.">
              <img src={logoSrc('stacked', 'for-dark-bg')} alt="" className="h-20 w-auto drop-shadow-[0_0_10px_#ff4fd8]" />
            </DontTile>
            <DontTile label="Rotate or tilt it.">
              <img src={logoSrc('stacked', 'for-dark-bg')} alt="" className="h-20 w-auto -rotate-12" />
            </DontTile>
            <DontTile label="Put the colour version on busy art." ground="bg-[url(/title-corridor-key-art-provisional-640.webp)] bg-cover bg-[position:30%_45%]">
              <img src={logoSrc('stacked', 'for-light-bg')} alt="" className="h-20 w-auto" />
            </DontTile>
            <DontTile label="Redraw the mark or retype the name in another font.">
              <span className="flex items-center gap-3">
                <img src={logoSrc('mark', 'for-dark-bg')} alt="" className="h-14 w-auto" />
                <span className="font-serif text-[1.6rem] italic">Wolf Override</span>
              </span>
            </DontTile>
          </div>
        </Section>

        <Section id="colours" index={3} title="Colours" tldr="Deep navy grounds, white text, bright cyan accents. On white, use the deep cyan.">
          <ul className="grid grid-cols-4 gap-4 compact:grid-cols-2 phone:grid-cols-2 phone-xs:grid-cols-1">
            {colours.map((colour) => (
              <li key={colour.token} className={`${card} overflow-hidden`}>
                {/* The swatch shows the pair its contrast is measured on: the colour as a ground with Text on it, or as text on its ground. */}
                <div
                  className="flex h-24 items-end p-3 font-heading text-[1.4rem] font-bold"
                  style={colour.against === 'color-text' ? { background: colour.hex, color: colour.againstHex } : { background: colour.againstHex, color: colour.hex }}
                  aria-hidden="true"
                >
                  Aa
                </div>
                <div className="px-4 py-3 text-caption">
                  <strong className="block text-[.95rem] text-text">{colour.name}</strong>
                  <code className="font-mono text-accent">{colour.hex.toUpperCase()}</code>
                  <span className="mt-1 block text-muted">{colour.use}</span>
                  <span className="mt-1 block text-muted">
                    {colour.contrast}:1 {colour.against === 'color-text' ? 'with Text on it' : `on ${colour.againstName}`}
                    {colour.contrast >= 7 ? ' · AAA' : colour.contrast >= 4.5 ? ' · AA' : ' · large text only'}
                  </span>
                </div>
              </li>
            ))}
          </ul>
          <ul className={`${bulletList} mt-6 max-w-[62ch]`}>
            <li><strong className="text-text">Contrast</strong> is the WCAG ratio, worked out from the site&apos;s own colours when this page is built. AA needs 4.5:1 for body text; AAA needs 7:1.</li>
            <li><strong className="text-text">Cyan is an accent,</strong> not a background for long text.</li>
            <li><strong className="text-text">On white,</strong> the bright cyan is too faint ({cyanOnWhite}:1). Use the deep cyan, or the logo made for light backgrounds.</li>
            <li>
              <strong className="text-text">Logo cyan <code className="font-mono text-accent">{logoLightCyan.toUpperCase()}</code></strong> is the rule and ring in the logo for light backgrounds. It belongs to the logo files only: don&apos;t use it for text ({logoCyanOnWhite}:1 on white).
            </li>
          </ul>
        </Section>

        <Section id="type" index={4} title="Type" tldr="Montserrat for headings, Roboto for text. Both are free under the SIL Open Font License.">
          <div className="grid grid-cols-2 gap-6 phone:grid-cols-1">
            <div className={`${card} p-6`}>
              <p className="hud-label mb-3 text-muted">Headings · Montserrat Bold</p>
              <p className="mb-3 font-heading text-[2.2rem] leading-[1.1] font-bold tracking-[-.03em]">{tagline}</p>
              <p className="leading-[1.6] text-muted">Bold (700) for headings, Semibold (600) for small labels in capitals. The logo uses its own outlines; don&apos;t retype it.</p>
              <a className={inlineLink} href="https://fonts.google.com/specimen/Montserrat">Get Montserrat <span aria-hidden="true">↗</span></a>
            </div>
            <div className={`${card} p-6`}>
              <p className="hud-label mb-3 text-muted">Text · Roboto Regular</p>
              <p className="mb-3 text-[1.05rem] leading-[1.7]">{shortDescription}</p>
              <p className="leading-[1.6] text-muted">Regular (400) for body text, Bold (700) for emphasis. Line height about 1.6 to 1.8.</p>
              <a className={inlineLink} href="https://fonts.google.com/specimen/Roboto">Get Roboto <span aria-hidden="true">↗</span></a>
            </div>
          </div>
          <p className={`${sectionCopy} mt-6`}>
            Licence: <a className="text-accent underline underline-offset-4" href="https://openfontlicense.org/">SIL Open Font License 1.1</a>. The licence texts ship beside the fonts in the{' '}
            <a className="text-accent underline underline-offset-4" href={`${repoUrl}/tree/main/apps/docs/app/fonts`}>source repository</a>.
          </p>
        </Section>

        <Section id="imagery" index={5} title="Imagery" tldr="Use the key art and screenshots as they are, credit them, and say the art is provisional.">
          <div className="grid grid-cols-2 gap-6 phone:grid-cols-1">
            <figure className={`${card} min-w-0 overflow-hidden`}>
              <img src="/title-corridor-key-art-provisional-1024.webp" alt="Provisional key art: an engineer in a red hoodie stands beside the robotic wolf WOLF in a blue-lit research corridor." width="1672" height="941" className="w-full" loading="lazy" decoding="async" />
              <figcaption className="px-5 py-4 text-caption text-muted"><strong className="text-text">Key art</strong> · Provisional · Not a gameplay capture</figcaption>
            </figure>
            {screenshots.map(({ image, title, alt }) => (
              <figure key={title} className={`${card} min-w-0 overflow-hidden`}>
                <img src={image.src} alt={alt} width={image.width} height={image.height} className="w-full" loading="lazy" decoding="async" />
                <figcaption className="px-5 py-4 text-caption text-muted"><strong className="text-text">{title}</strong> · Source build capture, October 2026 · Provisional art and UI</figcaption>
              </figure>
            ))}
          </div>
          <h3 className={subHeading}>How to credit</h3>
          <ul className={`${bulletList} max-w-[62ch]`}>
            <li>Under a picture: <strong className="text-text">&ldquo;{creditLine}&rdquo;</strong>.</li>
            <li>For the key art, add <strong className="text-text">&ldquo;provisional art&rdquo;</strong>. It is not a gameplay screenshot.</li>
            <li>Don&apos;t edit what a picture shows or present it as final. Resizing and cropping for layout are fine.</li>
          </ul>
          <h3 className={subHeading}>About the art</h3>
          <ul className={`${bulletList} max-w-[62ch]`}>
            <li><strong className="text-text">All current art is provisional</strong> and may change before release.</li>
            <li><strong className="text-text">Made with AI assistance:</strong> the key art and the game&apos;s art were made with AI image tools, then reviewed and approved by Nathanial Henniges. The wolf mark started as an AI concept (ChatGPT Create) and was redrawn by the project as SVG; the logo sets the name in Montserrat letter shapes beside it.</li>
            <li>Details for every file: <Link className="text-accent underline underline-offset-4" href="/docs/credits/#provisional-art">Credits</Link> and the <a className="text-accent underline underline-offset-4" href={`${repoUrl}/blob/main/apps/game/assets/manifest.json`}>asset register</a>.</li>
          </ul>
          <h3 className={subHeading}>AI disclosure</h3>
          {/* The approved text (lib/press-kit.ts aiDisclosure); press may quote it as it is, as stores will. */}
          <p className={sectionCopy}>{aiDisclosure}</p>
        </Section>

        <Section id="download" index={6} title="Asset pack" tldr="One zip with everything on this page. Or pick single files below.">
          <DownloadButton />
          <h3 className={subHeading}>What is in the zip</h3>
          <div className="grid grid-cols-2 gap-6 phone:grid-cols-1">
            <section className={`${card} p-6`} aria-labelledby="text-files-title">
              <h4 id="text-files-title" className="mb-3 font-heading font-bold">Text files</h4>
              <ul className={bulletList}>
                {pressTextFiles.map((file) => (
                  <li key={file.zipPath}><code className="font-mono text-text">{file.zipPath}</code>: {file.title.toLowerCase()}</li>
                ))}
              </ul>
            </section>
            {fileGroups.map(([folder, title]) => (
              <section key={folder} className={`${card} p-6`} aria-labelledby={`files-${folder.replaceAll('/', '-')}title`}>
                <h4 id={`files-${folder.replaceAll('/', '-')}title`} className="mb-3 font-heading font-bold">{title}</h4>
                <ul className="flex flex-col gap-1">
                  {pressFiles.filter((file) => file.zipPath.startsWith(folder)).map((file) => (
                    <li key={file.zipPath}>
                      <a href={hrefFor(file)} download className="flex min-h-11 items-center justify-between gap-3 leading-[1.4] text-muted hover-always:text-accent">
                        <span>{file.title}</span>
                        <span className="flex-none text-caption">{sizeOf(file.href ? `public${file.href}` : file.source)}</span>
                      </a>
                    </li>
                  ))}
                </ul>
              </section>
            ))}
          </div>
          <h3 className={subHeading}>How you may use these files</h3>
          <ul className={`${bulletList} max-w-[70ch]`}>
            {assetTerms.map((term) => <li key={term}>{term}</li>)}
          </ul>
          <p className={`${sectionCopy} mt-4`}>
            These are the press terms. The <Link className="text-accent underline underline-offset-4" href="/docs/legal/">Legal page</Link> covers the licences for everything else in the project.
          </p>
        </Section>

        <Section id="contact" index={7} title="Press contact" tldr="Ask on Discord, or reach the studio through its website.">
          <div className="grid grid-cols-2 gap-6 phone:grid-cols-1">
            {pressContact.map((contact) => (
              <a key={contact.url} href={contact.url} className={`${card} flex flex-col gap-2 px-6 py-5 hover-always:text-accent`}>
                <strong className="flex justify-between gap-4 text-[1.05rem]">{contact.label} <span aria-hidden="true">↗</span></strong>
                <span className="leading-[1.5] text-muted">{contact.note}</span>
              </a>
            ))}
          </div>
          <h3 className={subHeading}>Follow the game</h3>
          <ul className="flex flex-wrap gap-2">
            {pressLinks.map((link) => (
              <li key={link.url}>
                <a href={link.url} className="inline-flex min-h-11 items-center rounded-control border border-line-strong px-4 hover-always:border-accent hover-always:text-accent">
                  {link.label}&nbsp;<span aria-hidden="true">↗</span>
                </a>
              </li>
            ))}
          </ul>
        </Section>
      </main>
      <SiteFooter linkBase="/" />
    </div>
  );
}
