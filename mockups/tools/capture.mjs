#!/usr/bin/env node
/**
 * capture.mjs: the one capture tool for the WOLF OVERRIDE HTML mockups (design brief 7.1 Captures).
 *
 * What it is for: renders a mockup page in headless Chromium at each reference device's real
 * size and writes one PNG per device and state, so a review reads real frames, not code. It
 * never opens a visible window and serves nothing itself: start the http server first
 * (mockups/README.md, "Serve").
 *
 * Usage:
 *   node mockups/tools/capture.mjs <page> <devices> <outDir> [query] [options]
 *     <page>     a page under /mockups/, for example m01-foundations.html
 *     <devices>  comma list of device names from apps/game/ui/ui.tokens.json (devices.*),
 *                for example desktop,ally,iphone; "all" takes every device
 *     <outDir>   folder for the PNGs (made if missing)
 *     [query]    extra URL query for every capture, for example "input=pad&text=150"
 *   Options:
 *     --states "name:query;name2:query2"  one capture per state, named <page>__<device>__<name>.png
 *     --eval <file.js | expression>       evaluated in the page after it is ready (for example
 *                                         "WO.probe()"); the JSON result is written next to the PNG
 *     --full                              capture the full page height, not just the viewport
 *     --chrome                            keep the control strip (default adds clean=1)
 *     --settle <ms>                       wait this long after ready (default 0)
 *     --base <url>                        default http://127.0.0.1:$WO_PORT/mockups/ (WO_PORT 8000)
 *     --allow-not-loaded                  accept the "Tokens not loaded" state (the no-fallback test)
 *     --chromium <path>                   browser binary; default $WO_CHROMIUM, else the newest
 *                                         chromium_headless_shell in ~/Library/Caches/ms-playwright
 *
 * Contract:
 * - Viewport and device scale come from the token file (devices.<name>.width / scale, height /
 *   scale, deviceScaleFactor scale), the same numbers the mockup frames use; nothing is kept here.
 * - It waits until the page sets html[data-wo-ready="1"] (tokens applied, fonts and images
 *   loaded) or html[data-wo-state="error"].
 * - It fails (exit 1) on any console error, page error, failed request, HTTP status 400 or more,
 *   or the "Tokens not loaded" state (unless --allow-not-loaded).
 * - Output names: <page stem>__<device>[__<state>].png and .json for --eval.
 */
import { readFileSync, existsSync, mkdirSync, readdirSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join, resolve, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '..', '..');

/** Parses argv into positionals and --options (an option takes the next word unless it is a flag). */
function parseArgs(argv) {
  const flags = new Set(['--full', '--chrome', '--allow-not-loaded']);
  const pos = [], opt = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) opt[a.slice(2)] = flags.has(a) ? true : argv[++i];
    else pos.push(a);
  }
  return { pos, opt };
}

/** The reference devices' viewports from the token file: {name: {width, height, scale}}. */
function deviceViewports() {
  const tokens = JSON.parse(readFileSync(join(repo, 'apps/game/ui/ui.tokens.json'), 'utf8'));
  const out = {};
  for (const [name, d] of Object.entries(tokens.devices)) {
    if (!d || typeof d !== 'object' || !d.width) continue;
    const scale = d.scale.$value;
    out[name] = { width: Math.round(d.width.$value / scale), height: Math.round(d.height.$value / scale), scale };
  }
  return out;
}

/** The browser binary: --chromium, $WO_CHROMIUM, or the newest headless shell in Playwright's cache. */
function chromiumPath(arg) {
  if (arg) return arg;
  if (process.env.WO_CHROMIUM) return process.env.WO_CHROMIUM;
  const cache = join(homedir(), 'Library', 'Caches', 'ms-playwright');
  if (!existsSync(cache)) return undefined;
  const shells = readdirSync(cache).filter((d) => d.startsWith('chromium_headless_shell-')).sort((a, b) => Number(b.split('-')[1]) - Number(a.split('-')[1]));
  for (const s of shells) {
    const p = join(cache, s, 'chrome-headless-shell-mac-arm64', 'chrome-headless-shell');
    if (existsSync(p)) return p;
  }
  return undefined;
}

async function main() {
  const { pos, opt } = parseArgs(process.argv.slice(2));
  if (pos.length < 3) {
    console.error('usage: capture.mjs <page> <devices> <outDir> [query] [--states ...] [--eval ...] [--full] [--chrome]');
    process.exit(2);
  }
  const [page, deviceList, outDir, query = ''] = pos;
  const viewports = deviceViewports();
  const devices = deviceList === 'all' ? Object.keys(viewports) : deviceList.split(',');
  for (const d of devices) if (!viewports[d]) { console.error('unknown device: ' + d + ' (token file has ' + Object.keys(viewports).join(', ') + ')'); process.exit(2); }
  const states = opt.states ? opt.states.split(';').filter(Boolean).map((s) => { const i = s.indexOf(':'); return [s.slice(0, i), s.slice(i + 1)]; }) : [[null, '']];
  const base = opt.base || `http://127.0.0.1:${process.env.WO_PORT || 8000}/mockups/`;
  let evalExpr = null;
  if (opt.eval) evalExpr = existsSync(opt.eval) ? readFileSync(opt.eval, 'utf8') : opt.eval;
  mkdirSync(outDir, { recursive: true });

  let playwright;
  try { playwright = await import(process.env.WO_PLAYWRIGHT || 'playwright-core'); } catch (e) {
    console.error('playwright-core not found: install it in the repo (node_modules) or set WO_PLAYWRIGHT to its path. ' + e.message);
    process.exit(2);
  }
  const chromium = playwright.chromium || (playwright.default && playwright.default.chromium);
  const browser = await chromium.launch({ headless: true, executablePath: chromiumPath(opt.chromium) });
  const stem = basename(page).replace(/\.html?$/, '');
  let failures = 0;
  try {
    for (const name of devices) {
      const vp = viewports[name];
      const context = await browser.newContext({ viewport: { width: vp.width, height: vp.height }, deviceScaleFactor: vp.scale });
      for (const [state, stateQuery] of states) {
        const q = new URLSearchParams(query);
        for (const [k, v] of new URLSearchParams(stateQuery)) q.set(k, v);
        q.set('device', name);
        if (!opt.chrome && !q.has('clean')) q.set('clean', '1');
        const [path, pageQuery] = page.split('?');
        if (pageQuery) for (const [k, v] of new URLSearchParams(pageQuery)) if (!q.has(k)) q.set(k, v);
        const url = base + path + '?' + q.toString();
        const tab = await context.newPage();
        const errors = [];
        const allowed = (u) => /\/favicon\.ico$/.test(u) || (opt['allow-not-loaded'] && q.has('tokens') && u.includes(q.get('tokens').replace(/^\.\.\//, '')));
        tab.on('console', (m) => { if (m.type() === 'error' && !(opt['allow-not-loaded'] && /Failed to load resource/.test(m.text()))) errors.push('console: ' + m.text()); });
        tab.on('pageerror', (e) => errors.push('page error: ' + e.message));
        tab.on('requestfailed', (r) => { if (!allowed(r.url())) errors.push('request failed: ' + r.url() + ' ' + (r.failure() || {}).errorText); });
        tab.on('response', (r) => { if (r.status() >= 400 && !allowed(r.url())) errors.push('HTTP ' + r.status() + ': ' + r.url()); });
        await tab.goto(url, { waitUntil: 'load' });
        try {
          await tab.waitForFunction(() => document.documentElement.dataset.woReady === '1' || document.documentElement.dataset.woState === 'error', null, { timeout: 30000 });
        } catch (e) { errors.push('never became ready: ' + url); }
        const st = await tab.evaluate(() => document.documentElement.dataset.woState);
        if (st === 'error' && !opt['allow-not-loaded']) errors.push('Tokens not loaded: ' + url);
        if (opt.settle) await tab.waitForTimeout(Number(opt.settle));
        const file = join(outDir, `${stem}__${name}${state ? '__' + state : ''}.png`);
        await tab.screenshot({ path: file, fullPage: !!opt.full });
        if (evalExpr) {
          const result = await tab.evaluate((src) => (0, eval)(src), evalExpr);
          writeFileSync(file.replace(/\.png$/, '.json'), JSON.stringify(result, null, 2) + '\n');
        }
        console.log((errors.length ? 'FAIL ' : 'ok   ') + file);
        for (const e of errors) console.log('     ' + e);
        failures += errors.length ? 1 : 0;
        await tab.close();
      }
      await context.close();
    }
  } finally {
    await browser.close();
  }
  process.exit(failures ? 1 : 0);
}

main().catch((e) => { console.error(e); process.exit(1); });
