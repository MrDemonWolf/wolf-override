import assert from 'node:assert/strict';
import { plannedPlatforms, sourceBuildHref } from './downloads';

// The landing page must keep sending players to the source-build guide, not to a package that does not exist.
assert.equal(sourceBuildHref, '/docs/get-game/');

// Every planned platform stays honest: a plain "no release date" status, no dates, versions or store names.
assert.deepEqual(
  plannedPlatforms.map((platform) => platform.name),
  ['Windows', 'macOS', 'iPhone / iPad', 'Android'],
);
for (const platform of plannedPlatforms) {
  assert.equal(platform.status, 'no release date', `${platform.name} must not announce a release`);
  assert.doesNotMatch(platform.status, /\b(19|20)\d{2}\b|\bv?\d+\.\d+/, `${platform.name} must not carry a date or version`);
}
console.log('Planned-platform checks passed (no release dates; primary action targets /docs/get-game/).');
