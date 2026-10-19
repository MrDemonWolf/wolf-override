/*
 * Builds the press kit zip the design-system page offers: apps/docs/public/press/wolf-override-press-kit.zip.
 *
 * Usage (from apps/docs): `bun scripts/build-press-kit.ts`. The docs app's `dev` and `build` scripts
 * run it first, so the zip is always fresh and `next build` exports it (and the page reads its size).
 * The zip is git-ignored: every file in it already lives in the repository, and committing the zip
 * would store an extra multi-megabyte copy in Git history on every logo, screenshot or copy change.
 *
 * Contents: every file in lib/press-kit.ts `pressFiles` (logo set, wolf mark, screenshots, key art,
 * cover), read from where the site already keeps it, plus three text files written here from the same
 * module the page renders (FACTS.txt, COPY.txt, LICENSE-ASSETS.txt). The zip is byte-stable
 * (lib/zip.ts), so rebuilding unchanged inputs gives the same file, and its size is capped at 25 MB so
 * the download stays quick on a phone connection.
 */
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import * as kit from '@/lib/press-kit';
import { buildZip, type ZipEntry } from '@/lib/zip';

/** The zip on disk, relative to the docs app folder this script runs in. */
export const pressKitFile = path.join(process.cwd(), 'public', kit.pressKitPath);

/** 25 MB: the size budget for the whole download. */
const maxBytes = 25 * 1024 * 1024;

// Plain-text helpers. The files use LF line endings (every current text editor reads them) and end
// with one newline; a heading is underlined with "=" so it stands out without Markdown.
const heading = (text: string) => `${text}\n${'='.repeat(text.length)}\n`;
const bullets = (lines: readonly string[]) => lines.map((line) => `- ${line}`).join('\n');

/** The text of each generated file, keyed by its zip path. Every value comes from lib/press-kit.ts. */
export function pressTexts(): Record<(typeof kit.pressTextFiles)[number]['zipPath'], string> {
  const linkLines = kit.pressLinks.map((link) => `${link.label}: ${link.url}`);
  const contactLines = kit.pressContact.map((contact) => `${contact.label}: ${contact.url} (${contact.note})`);
  return {
    'FACTS.txt': [
      heading(`${kit.gameName.name}: facts`),
      kit.facts.map(([label, value]) => `${label}: ${value}`).join('\n'),
      '',
      heading('Links'),
      linkLines.join('\n'),
      '',
      heading('Press contact'),
      contactLines.join('\n'),
      '',
      heading('Credit'),
      `${kit.creditLine}`,
      kit.creatorCredit,
      '',
    ].join('\n'),
    'COPY.txt': [
      heading('Name'),
      bullets([
        `Write it ${kit.gameName.name}: two words, no slashes, all capitals.`,
        `Where all capitals are not allowed, ${kit.gameName.titleCase} is fine.`,
        `Do not write ${kit.gameName.former}; that spelling is retired.`,
      ]),
      '',
      heading('Tagline'),
      kit.tagline,
      '',
      heading('Short description'),
      kit.shortDescription,
      '',
      heading('Long description'),
      kit.longDescription.join('\n\n'),
      '',
      heading(`About ${kit.studioName}`),
      kit.studioDescription,
      '',
      heading('Credit line'),
      kit.creditLine,
      '',
    ].join('\n'),
    'LICENSE-ASSETS.txt': [heading(`${kit.gameName.name} press kit: how you may use these files`), bullets(kit.assetTerms), '', `© ${kit.studioName} All rights reserved except as stated above.`, ''].join('\n'),
  };
}

/** Every zip entry, in order: the three text files first (they explain the rest), then `pressFiles`. */
export function pressKitEntries(): ZipEntry[] {
  const texts = pressTexts();
  return [
    ...kit.pressTextFiles.map(({ zipPath }) => ({ name: zipPath, data: Buffer.from(texts[zipPath], 'utf8') })),
    ...kit.pressFiles.map(({ zipPath, source }) => ({ name: zipPath, data: readFileSync(path.join(process.cwd(), source)) })),
  ];
}

if (import.meta.main) {
  const zip = buildZip(pressKitEntries());
  if (zip.length > maxBytes) throw new Error(`Press kit is ${(zip.length / 1048576).toFixed(1)} MB, over the 25 MB budget`);
  // public/press/ also holds the committed cover, but create it anyway so a fresh checkout never fails here.
  mkdirSync(path.dirname(pressKitFile), { recursive: true });
  writeFileSync(pressKitFile, zip);
  console.log(`Wrote ${kit.pressKitPath} (${kit.pressFiles.length + kit.pressTextFiles.length} files, ${(zip.length / 1048576).toFixed(1)} MB).`);
}
