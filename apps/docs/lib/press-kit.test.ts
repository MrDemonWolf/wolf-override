import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { contrastRatio, readToken, resolveBrandColors } from './brand-colors';
import { assetTerms, gameName, longDescription, pressFiles, shortDescription, studioDescription, tagline } from './press-kit';

/*
 * Checks for the design-system page's data (lib/press-kit.ts, lib/brand-colors.ts). The committed
 * zip itself is checked against a fresh build by `bun scripts/build-press-kit.ts --check`, which
 * `bun run test` runs after this file.
 */

// The contrast maths matches the WCAG reference points: black on white is 21:1, a colour on itself 1:1.
assert.equal(contrastRatio('#000000', '#ffffff'), 21);
assert.equal(contrastRatio('#8be3ff', '#8be3ff'), 1);

// Tokens are read as the first 6-digit hex value, so the light :root cyan wins over the .dark one.
assert.equal(readToken(':root { --color-fd-primary: #006A95; }\n.dark { --color-fd-primary: #8be3ff; }', 'color-fd-primary'), '#006a95');
assert.throws(() => readToken('--color-ink: var(--x);', 'color-ink'), /color-ink/);

// Every swatch resolves from the real stylesheet, and the text and accent colours the page
// recommends for body copy on the dark ground reach WCAG AA (4.5:1).
const colours = resolveBrandColors();
for (const colour of colours.filter((c) => ['color-text', 'color-muted', 'color-accent', 'color-fd-primary'].includes(c.token))) {
  assert.ok(colour.contrast >= 4.5, `${colour.name} is ${colour.contrast}:1 against ${colour.againstName}, below AA`);
}

// Every kit file exists where the site keeps it, and each has its own name inside the zip.
for (const file of pressFiles) assert.ok(existsSync(path.join(process.cwd(), file.source)), `Missing press kit file ${file.source}`);
assert.equal(new Set(pressFiles.map((file) => file.zipPath)).size, pressFiles.length, 'Two press kit files share a zip path');

// The copy uses the current name only; the old slashed spelling appears only where the name rules
// mention it. The tagline and summary keep their approved lengths: a reworded text must be re-approved.
for (const text of [tagline, shortDescription, ...longDescription, studioDescription, ...assetTerms]) {
  assert.ok(!text.includes(gameName.former), `Copy uses the retired name: ${text.slice(0, 40)}`);
}
assert.equal(tagline.length, 31);
assert.equal(shortDescription.length, 311, 'The short description differs from the approved IGDB summary');

console.log(`Press kit data checks passed (${pressFiles.length} files, ${colours.length} colours).`);
