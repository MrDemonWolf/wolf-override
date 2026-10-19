import assert from 'node:assert/strict';
import { getGameHref, plannedPlatforms, testBuildsHref } from './downloads';

// The landing page sends players to the guide pages (Get the game, Install a test build), never to a package
// file or a release that does not exist.
assert.equal(getGameHref, '/docs/get-game/');
assert.equal(testBuildsHref, '/docs/test-builds/');

// Every planned platform stays honest: a plain "no release date" status, no dates, versions or store names.
assert.deepEqual(
  plannedPlatforms.map((platform) => platform.name),
  ['Windows', 'macOS', 'iPhone / iPad', 'Android'],
);
for (const platform of plannedPlatforms) {
  assert.equal(platform.status, 'no release date', `${platform.name} must not announce a release`);
  assert.doesNotMatch(platform.status, /\b(19|20)\d{2}\b|\bv?\d+\.\d+/, `${platform.name} must not carry a date or version`);
}
console.log('Planned-platform checks passed (no release dates; actions target /docs/get-game/ and /docs/test-builds/).');
