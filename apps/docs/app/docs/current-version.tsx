import { asMarkdown } from 'fumadocs-core/server';
import { gameVersion } from '@/lib/version';
import { Callout } from '@/app/docs/guide-components';

/**
 * "Current version: 0.N.0" for the changelog and Releases pages, read from the game's project.godot when the site is
 * built (lib/version.ts), so the page and the game's title screen always show the same number. A
 * server component: the version is baked into the static export, with no client JavaScript.
 *
 * The Markdown copies (llms-full.txt and each page's .md; see lib/source.ts) render it too, as a
 * block quote. The asMarkdown() call only opts this component in there (it returns false on the
 * site): without it the renderer writes a bare JSX tag in place of the version. The Callout from
 * guide-components.tsx then writes the quote, so the site and the Markdown share one wording.
 */
export function CurrentVersion() {
  asMarkdown();
  return <Callout title={`Current version: ${gameVersion()}`}>The game shows the same number on its title screen, under CHANGELOG.</Callout>;
}
