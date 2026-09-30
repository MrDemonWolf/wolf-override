import assert from 'node:assert/strict';
import { detectPlatform } from './downloads';

for (const [ua, platform, touch, expected] of [
  ['Windows NT 10.0', 'Win32', 0, 'windows'],
  ['Macintosh; Intel Mac OS X', 'MacIntel', 0, 'macos'],
  ['iPhone; CPU iPhone OS', 'iPhone', 5, 'ios'],
  ['iPad; CPU OS', 'iPad', 5, 'ios'],
  ['Macintosh; Intel Mac OS X', 'MacIntel', 5, 'ios'],
  ['Linux; Android 15', 'Linux', 5, 'android'],
  ['Linux x86_64', 'Linux', 0, ''],
] as const) assert.equal(detectPlatform(ua, platform, touch), expected);
console.log('Platform suggestion checks passed (including desktop-mode iPad and unknown OS).');
