import assert from 'node:assert/strict';
import { gameVersion, parseGameVersion } from './version';

// The version is read from [application] only; a config/version under another section is not it.
assert.equal(parseGameVersion('[application]\nconfig/name="WOLF OVERRIDE"\nconfig/version="0.15.0"\n'), '0.15.0');
assert.throws(() => parseGameVersion('[other]\nconfig/version="9.9.9"\n'), /config\/version/);
assert.throws(() => parseGameVersion('[application]\nconfig/name="WOLF OVERRIDE"\n'), /config\/version/);

// The real project file carries a 0.MINOR.0 development version (scripts/export_changelog.py checks it
// against the newest changelog heading, so it is not checked a second time here).
assert.match(gameVersion(), /^0\.\d+\.0$/);
console.log(`Version checks passed (project.godot says ${gameVersion()}).`);
