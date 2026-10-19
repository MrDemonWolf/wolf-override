import { readFileSync } from 'node:fs';
import path from 'node:path';

/*
 * The brand colours the design-system page shows, read from the site's own stylesheet at build time,
 * so the swatches and their hex codes can never drift from the colours the site really uses.
 * app/global.css is the single source: its @theme block holds the landing palette and its :root
 * block the light guide theme. Contrast ratios are computed here (WCAG 2.2 formula), not typed by hand.
 * Server-only: it reads the file system, so only server components, scripts and tests may import it.
 */

/** app/global.css, from the docs app folder that `next build` and the docs scripts run in. */
export const globalCssFile = path.join(process.cwd(), 'app', 'global.css');

/** One swatch on the page: the CSS custom property it comes from and what it is for. */
export type BrandColor = {
  /** Display name, e.g. "Ink". */
  name: string;
  /** The custom property in app/global.css, without the leading dashes, e.g. "color-ink". */
  token: string;
  /** What the colour is used for, one short line. */
  use: string;
  /**
   * The colour its contrast is measured against: a token for dark-palette pairs, or "white" for the
   * light-ground cyan. Background swatches are measured against Text (text on them); text and accent
   * swatches against Ink (them on the page background).
   */
  against: string;
};

/**
 * The swatches, in page order. The first six are the landing palette (the game's own dark look);
 * the last is the guide's light-theme cyan, used where the bright cyan would be too faint on white.
 */
export const brandColors: BrandColor[] = [
  { name: 'Ink', token: 'color-ink', use: 'Page background, the darkest navy', against: 'color-text' },
  { name: 'Panel navy', token: 'color-panel', use: 'Header bar; MrDemonWolf core navy', against: 'color-text' },
  { name: 'Surface', token: 'color-surface', use: 'Cards and raised panels', against: 'color-text' },
  { name: 'Cyan', token: 'color-accent', use: 'Accents, links and labels on dark', against: 'color-ink' },
  { name: 'Text', token: 'color-text', use: 'Headings and body text on dark', against: 'color-ink' },
  { name: 'Muted', token: 'color-muted', use: 'Secondary text on dark', against: 'color-ink' },
  { name: 'Deep cyan', token: 'color-fd-primary', use: 'Links and accents on white or light grounds', against: 'white' },
];

/**
 * Returns the first value of `--<token>:` in `css` as a lower-case hex code, or throws when it is
 * missing or not a 6-digit hex code, so a renamed token fails the build instead of showing a blank.
 * "First" matters for color-fd-primary: the light :root block comes before the .dark one.
 */
export function readToken(css: string, token: string): string {
  const match = new RegExp(`--${token}:\\s*(#[0-9a-fA-F]{6})\\b`).exec(css);
  if (!match) throw new Error(`app/global.css has no 6-digit hex value for --${token}`);
  return match[1].toLowerCase();
}

/** WCAG 2.2 relative luminance of a #rrggbb colour (0 for black to 1 for white). */
export function luminance(hex: string): number {
  const channel = (offset: number) => {
    const value = parseInt(hex.slice(offset, offset + 2), 16) / 255;
    return value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * channel(1) + 0.7152 * channel(3) + 0.0722 * channel(5);
}

/** WCAG contrast ratio of two #rrggbb colours, from 1 (none) to 21 (black on white). */
export function contrastRatio(a: string, b: string): number {
  const [light, dark] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (light + 0.05) / (dark + 0.05);
}

/**
 * A swatch with its hex code, the hex and display name of the colour it is measured against, and the
 * contrast ratio between them rounded to one decimal.
 */
export type ResolvedBrandColor = BrandColor & { hex: string; againstHex: string; againstName: string; contrast: number };

/** Every swatch in `brandColors` with its value read from `file` (default: app/global.css). */
export function resolveBrandColors(file: string = globalCssFile): ResolvedBrandColor[] {
  const css = readFileSync(file, 'utf8');
  return brandColors.map((color) => {
    const hex = readToken(css, color.token);
    const againstHex = color.against === 'white' ? '#ffffff' : readToken(css, color.against);
    const againstName = color.against === 'white' ? 'White' : (brandColors.find((other) => other.token === color.against)?.name ?? color.against);
    return { ...color, hex, againstHex, againstName, contrast: Math.round(contrastRatio(hex, againstHex) * 10) / 10 };
  });
}
