import { readFileSync } from 'node:fs';
import path from 'node:path';

/*
 * The game's development version for the website, read from apps/game/project.godot at build time.
 * project.godot's `application/config/version` is the single source of the version (0.MINOR.0, one
 * minor version per milestone): the game shows it on its title screen, scripts/export_changelog.py
 * checks the newest changelog heading against it, and this site reads it here instead of typing it
 * by hand. Server-only: it reads the file system, so only server components and tests may import it.
 */

/** project.godot, from the docs app folder that `next build` and the docs scripts run in. */
export const projectFile = path.join(process.cwd(), '..', 'game', 'project.godot');

/**
 * Returns `config/version` from the `[application]` section of a project.godot text, or throws when it
 * is missing, so a build never shows an empty or made-up version.
 */
export function parseGameVersion(projectText: string): string {
  let section = '';
  for (const raw of projectText.split(/\r?\n/)) {
    const line = raw.trim();
    const header = /^\[(.+)\]$/.exec(line);
    if (header) {
      section = header[1];
      continue;
    }
    const value = /^config\/version="([^"]+)"$/.exec(line);
    if (section === 'application' && value) return value[1];
  }
  throw new Error('project.godot has no [application] config/version');
}

/** The game's current version (for example "0.15.0"), read from `file` (default: the game's project.godot). */
export function gameVersion(file: string = projectFile): string {
  return parseGameVersion(readFileSync(file, 'utf8'));
}
