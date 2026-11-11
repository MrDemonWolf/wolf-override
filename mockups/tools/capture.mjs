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
 *     --states "name:query;name2:query2"  one capture per state, named <page>__<device>__<name>.png.
 *                                         In a state's query, keys starting with "@" are actions,
 *                                         not page parameters; they run in order after the page is
 *                                         ready (and --settle) and before the screenshot, with real
 *                                         (trusted) input: @hover=<selector>, @click=<selector>,
 *                                         @key=<key name, e.g. ArrowDown>, @wait=<ms>,
 *                                         @tick=<selector> (adds the idle "is-tick" class),
 *                                         @eval=<expression> (for example WO.motion.stagger()),
 *                                         @freeze=<ms> (pauses every animation at that time),
 *                                         @tap=<selector> (a touch press and click on its centre),
 *                                         @pad=<Xbox button, e.g. A, X, LB, DPadDown> (the
 *                                         page's own pad path, WO.pad.press; no Gamepad needed)
 *     --hover <selector>                  hover this before every screenshot (@hover in each state)
 *     --press <keys>                      press these keys, comma list, before every screenshot
 *     --input "key:Space@300;tap@300;padA@300"
 *                                         scripted presses for every state: each waits its @ms after
 *                                         the one before, then presses (key:<name>, tap[:<selector>]
 *                                         on the first frame by default, pad<Button>)
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

/**
 * One state action (see --states): real mouse and keyboard input through Playwright, a wait, an
 * expression, an idle tick on matching elements, or every running animation paused at [v] ms of
 * its own time (delays included, so @freeze=150 shows an entrance 150 ms in).
 */
async function runAction(tab, k, v) {
  if (k === '@hover') return tab.hover(v);
  if (k === '@click') return tab.click(v);
  if (k === '@key') return tab.keyboard.press(v);
  if (k === '@wait') return tab.waitForTimeout(Number(v));
  if (k === '@eval') return tab.evaluate((src) => (0, eval)(src), v);
  if (k === '@tick') return tab.evaluate((sel) => document.querySelectorAll(sel).forEach((el) => el.classList.add('is-tick')), v);
  if (k === '@freeze') return tab.evaluate((ms) => document.getAnimations().forEach((a) => { a.pause(); a.currentTime = ms; }), Number(v));
  if (k === '@tap') {
    return tab.evaluate((sel) => {
      const el = document.querySelector(sel);
      if (!el) throw new Error('no element ' + sel);
      const r = el.getBoundingClientRect(), o = { bubbles: true, composed: true, pointerType: 'touch', isPrimary: true, clientX: r.left + r.width / 2, clientY: r.top + r.height / 2 };
      el.dispatchEvent(new PointerEvent('pointerdown', o));
      el.dispatchEvent(new PointerEvent('pointerup', o));
      el.dispatchEvent(new MouseEvent('click', o));
    }, v);
  }
  if (k === '@pad') return tab.evaluate((b) => window.WO.pad.press(b), v);
  throw new Error('unknown action');
}
/** The actions every state runs, from --hover, --press and --input (see the usage above). */
function globalActions(opt) {
  const out = [];
  if (opt.hover) out.push(['@hover', opt.hover]);
  if (opt.press) for (const key of opt.press.split(',').filter(Boolean)) out.push(['@key', key]);
  for (const step of (opt.input || '').split(';').filter(Boolean)) {
    const [what, ms] = step.split('@');
    if (ms) out.push(['@wait', ms]);
    if (what.startsWith('key:')) out.push(['@key', what.slice(4)]);
    else if (what.startsWith('tap')) out.push(['@tap', what.slice(4) || '.wo-frame']);
    else if (what.startsWith('pad')) out.push(['@pad', what.slice(3)]);
    else throw new Error('--input: unknown step ' + step);
  }
  return out;
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
        const actions = globalActions(opt);
        for (const [k, v] of new URLSearchParams(stateQuery)) { if (k.startsWith('@')) actions.push([k, v]); else q.set(k, v); }
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
        for (const [k, v] of actions) {
          try { await runAction(tab, k, v); } catch (e) { errors.push('action ' + k + '=' + v + ': ' + e.message); }
        }
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
