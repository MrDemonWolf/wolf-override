import { Callout } from 'fumadocs-ui/components/callout';
import { gameVersion } from '@/lib/version';

/**
 * "Current version: 0.N.0" for the changelog page, read from the game's project.godot when the site is
 * built (lib/version.ts), so the page and the game's title screen always show the same number. A
 * server component: the version is baked into the static export, with no client JavaScript.
 */
export function CurrentVersion() {
  return <Callout title={`Current version: ${gameVersion()}`}>The game shows the same number on its title screen, under CHANGELOG.</Callout>;
}
