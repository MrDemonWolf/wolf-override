/*
 * wo.js: the one shared script for the WOLF OVERRIDE HTML mockups (design brief 7.1 and 7.2).
 *
 * What it is for: every mockup page loads this file and mockups/shared/wo.css, and nothing else.
 * Pages hold markup and per-screen data only; every behaviour lives here, written once.
 *
 * Contract:
 * - It holds formulas and readers, and no UI values. Every number and colour comes from its one
 *   home in the game folder: the token file (apps/game/ui/ui.tokens.json), languages.json, the
 *   theme (game_theme.tres), project.godot, or the script or scene constant that owns it today.
 *   If a home cannot be read, the page shows "Tokens not loaded" and draws nothing styled: there
 *   are no fallback values anywhere (brief 7.1, gap-3 section 4).
 * - Units: "canvas px" are px of the game's canvas (960 x 540 at 16:9). Inside a .wo-frame one
 *   CSS px is one canvas px; the frame is scaled to the device with a CSS transform. Durations in
 *   the token file are ms; Godot constants in seconds are converted to ms when they become CSS.
 * - Side effects: sets CSS custom properties (--wo-*) on :root and on each frame, registers the
 *   game fonts with the FontFace API, rewrites the URL with history.replaceState (debounced
 *   250 ms), polls the token and language files once a second, and talks on the BroadcastChannel
 *   "wo-tune". It sets html[data-wo-state] to "loading", "ready" or "error", and
 *   html[data-wo-ready="1"] once fonts and images have loaded (capture.mjs waits for that).
 *
 * Public API (window.WO): tokens, today, devices, profile, input, pad, glyph, padmap, frames,
 * screen, motion, scene, world, boot, seq, tune, probe(), report(). Each section below starts
 * with its own doc comment. Sections: 0 homes, 1 helpers, 2 URL, 3 Godot readers, 4 fetching,
 * 5 tokens, 6 theme and fonts, 7 today readers, 8 devices and profiles, 9 input (press events,
 * current item, pad), 10 bindings and glyphs, 10b controller map, 11 frames and templates,
 * 11b screen behaviour (overlays, answers, tabs, lists, rows, holds), 12 motion, 12b scenes,
 * 12c dialogue reveal, 13 worlds, 13b texts and inline SVG, 14 strip, 15 Tune, 16 sheets,
 * 17 clocks (boot and screen changes), 18 rendering, 19 probes, 20 start.
 */
(function () {
  'use strict';

  /** @namespace WO The mockup runtime. Pages never need to call it; it boots itself. */
  const WO = (window.WO = {});

  // ---------------------------------------------------------------------------------------------
  // 0. Homes: where each value lives (paths only, relative to mockups/)
  // ---------------------------------------------------------------------------------------------

  /** The game folder, relative to a page in mockups/. */
  const GAME = '../apps/game/';
  /** The four core homes the brief names (7.1 "Tokens"). The URL may point "tokens" elsewhere
   *  (?tokens=<path>) only to test the no-fallback notice (M00 accept, "no fallback"). */
  const CORE = {
    tokens: 'ui/ui.tokens.json',
    languages: 'i18n/languages.json',
    theme: 'assets/fonts/game_theme.tres',
    project: 'project.godot',
  };
  /** Repo-relative names used in Copy JSON diff (the patch says which file it is for). */
  const REPO_FILE = { tokens: 'apps/game/ui/ui.tokens.json', languages: 'apps/game/i18n/languages.json' };
  /** Today-value homes: the scripts and scenes that own a value no token holds yet. */
  const SOURCES = {
    'main.gd': 'scripts/main.gd',
    'main.tscn': 'scenes/main.tscn',
    'studio_logo.gd': 'scripts/studio_logo.gd',
    'studio_logo.tscn': 'scenes/studio_logo.tscn',
    'text_size.gd': 'scripts/text_size.gd',
    'dialogue_boxes.gd': 'scripts/dialogue_boxes.gd',
    'room_depth.gd': 'scripts/room_depth.gd',
    'impact.gd': 'scripts/impact.gd',
    'm0_actor.gd': 'scripts/m0_actor.gd',
    'door_kit.gd': 'scripts/door_kit.gd',
    'palette.gd': 'scripts/fx/palette.gd',
    'game_settings.gd': 'scripts/game_settings.gd',
    'post_grade.gdshader': 'assets/shaders/post_grade.gdshader',
  };
  /** The $extensions key of every token (brief 2.7). */
  const EXT = 'com.mrdemonwolf.wolfoverride';

  // ---------------------------------------------------------------------------------------------
  // 1. Small helpers
  // ---------------------------------------------------------------------------------------------

  /** Makes an element: h('div', {class: 'x', onclick: fn}, child, 'text'). Strings become text. */
  function h(tag, attrs, ...children) {
    const el = tag.includes(':') ? document.createElementNS('http://www.w3.org/2000/svg', tag.split(':')[1]) : document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) {
      if (v === undefined || v === null || v === false) continue;
      if (k.startsWith('on')) el.addEventListener(k.slice(2), v);
      else if (k === 'text') el.textContent = v;
      else el.setAttribute(k, v === true ? '' : String(v));
    }
    for (const c of children.flat()) if (c !== null && c !== undefined && c !== false) el.append(c.nodeType ? c : String(c));
    return el;
  }
  /** Rounds for display only (never for a formula): up to [digits] decimals, no trailing zeros. */
  function fmt(n, digits = 2) {
    if (typeof n !== 'number' || !isFinite(n)) return String(n);
    return String(Number(n.toFixed(digits)));
  }
  /** A CSS custom property name for a token path: type.body.size -> --wo-type-body-size. */
  const cssVar = (path) => '--wo-' + path.replace(/\./g, '-');
  /** Every reader error lands here and in the console (capture.mjs fails on console errors). */
  const problems = [];
  function problem(msg, err) {
    problems.push(msg);
    console.error('[wo] ' + msg + (err && err.stack ? '\n' + err.stack : ''));
    renderProblems();
  }

  // ---------------------------------------------------------------------------------------------
  // 2. URL state (brief 7.1 control strip, 7.2 step 5)
  // ---------------------------------------------------------------------------------------------

  /**
   * URL state. get() reads a parameter; set() writes one (null removes it) and schedules one
   * history.replaceState 250 ms after the last change, so Back is never flooded with steps.
   */
  const url = {
    params: new URLSearchParams(location.search),
    get(k) { return this.params.get(k); },
    set(k, v) {
      if (v === null || v === undefined || v === '') this.params.delete(k);
      else this.params.set(k, String(v));
      clearTimeout(this.timer);
      this.timer = setTimeout(() => {
        const q = this.params.toString();
        history.replaceState(null, '', location.pathname + (q ? '?' + q : '') + location.hash);
        carryLinks();
      }, 250);
    },
    /** All [key, value] pairs whose key starts with [prefix]. */
    entries(prefix) { return [...this.params.entries()].filter(([k]) => k.startsWith(prefix)); },
  };
  WO.url = url;

  // ---------------------------------------------------------------------------------------------
  // 3. Godot text readers (.tres, .tscn, project.godot, .gd, .gdshader)
  // ---------------------------------------------------------------------------------------------

  /** Splits [s] at top-level commas (outside brackets and strings). */
  function splitTop(s) {
    const out = [];
    let depth = 0, cur = '', str = false;
    for (let i = 0; i < s.length; i++) {
      const c = s[i];
      if (str) { cur += c; if (c === '\\') { cur += s[++i]; } else if (c === '"') str = false; continue; }
      if (c === '"') { str = true; cur += c; continue; }
      if ('([{'.includes(c)) depth++;
      if (')]}'.includes(c)) depth--;
      if (c === ',' && depth === 0) { out.push(cur.trim()); cur = ''; } else cur += c;
    }
    if (cur.trim()) out.push(cur.trim());
    return out;
  }
  /** Parses a "#rrggbb" or "#rrggbbaa" string to [r, g, b, a] in 0..1. */
  function hexColor(hex) {
    const m = hex.replace('#', '');
    const n = (i) => parseInt(m.slice(i, i + 2), 16) / 255;
    return [n(0), n(2), n(4), m.length >= 8 ? n(6) : 1];
  }
  /**
   * Parses one Godot text value. Returns a number, boolean, string, array, plain object
   * ({color: [r,g,b,a]}, {sub: id}, {ext: id}, {res: path}) or {expr: raw} for anything that is
   * an expression (for example "960.0 / GAMEPLAY_ZOOM"), which no reader evaluates.
   */
  function gv(raw) {
    const s = raw.trim();
    if (s === 'true' || s === 'false') return s === 'true';
    if (s === 'null') return null;
    if (/^-?\d+(\.\d+)?(e[+-]?\d+)?$/i.test(s)) return Number(s);
    if (/^&?"/.test(s)) return JSON.parse(s.replace(/^&/, ''));
    let m = s.match(/^Color\(\s*"(#[0-9a-fA-F]+)"\s*\)$/);
    if (m) return { color: hexColor(m[1]) };
    m = s.match(/^Color\(([^()]*)\)$/);
    if (m) { const p = splitTop(m[1]).map(Number); return { color: [p[0], p[1], p[2], p.length > 3 ? p[3] : 1] }; }
    m = s.match(/^(Vector2i?|Vector3|Rect2i?|vec[234])\(([^()]*)\)$/);
    if (m) return splitTop(m[2]).map(Number);
    m = s.match(/^Packed\w+Array\(([^()]*)\)$/);
    if (m) return m[1].trim() ? splitTop(m[1]).map(Number) : [];
    m = s.match(/^SubResource\("([^"]+)"\)$/);
    if (m) return { sub: m[1] };
    m = s.match(/^ExtResource\("([^"]+)"\)$/);
    if (m) return { ext: m[1] };
    m = s.match(/^Resource\("[^"]*",\s*"([^"]+)"\)$/);
    if (m) return { res: m[1] };
    m = s.match(/^(?:Array\[\w+\])?\(?\[(.*)\]\)?$/s);
    if (m) return splitTop(m[1]).map(gv);
    if (s.startsWith('{')) { try { return JSON.parse(s); } catch (e) { return { expr: s }; } }
    return { expr: s };
  }
  /** True when [s] has more opening than closing brackets outside strings (a value goes on). */
  function openBrackets(s) {
    let d = 0, str = false;
    for (let i = 0; i < s.length; i++) {
      const c = s[i];
      if (str) { if (c === '\\') i++; else if (c === '"') str = false; continue; }
      if (c === '"') str = true;
      else if ('([{'.includes(c)) d++;
      else if (')]}'.includes(c)) d--;
    }
    return d > 0;
  }
  /**
   * Reads Godot's text resource format (.tres, .tscn, project.godot): a list of sections
   * {tag, attrs, props} where props maps each key to its raw value text (multi-line values joined).
   * Keys before the first header land in a section with tag "".
   */
  function parseSections(text) {
    const sections = [{ tag: '', attrs: {}, props: {} }];
    const lines = text.split('\n');
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (!line.trim() || line.startsWith(';')) continue;
      const head = line.match(/^\[(\w+)(.*)\]\s*$/);
      if (head) {
        const attrs = {};
        for (const a of head[2].matchAll(/(\w+)=("(?:[^"\\]|\\.)*"|[^\s\]]+)/g)) attrs[a[1]] = gv(a[2]);
        sections.push({ tag: head[1], attrs, props: {} });
        continue;
      }
      const kv = line.match(/^([^=\s]+)\s*=\s*(.*)$/);
      if (!kv) continue;
      let value = kv[2];
      while (openBrackets(value) && i + 1 < lines.length) value += '\n' + lines[++i];
      sections[sections.length - 1].props[kv[1]] = value;
    }
    return sections;
  }
  /** Scene nodes by path ("CanvasLayer/TopBar/Accent"; the root is "."), each {type, props}. */
  function sceneNodes(sections) {
    const nodes = {};
    for (const s of sections.filter((x) => x.tag === 'node')) {
      const parent = s.attrs.parent;
      const path = parent === undefined ? '.' : parent === '.' ? s.attrs.name : parent + '/' + s.attrs.name;
      nodes[path] = { type: s.attrs.type, props: s.props, name: s.attrs.name };
    }
    return nodes;
  }
  /**
   * The top-level constants and variables of a GDScript file: {NAME: rawValueText}. Reads
   * "const", "static var" and "var" lines at column 0, strips trailing comments.
   */
  function gdConsts(text) {
    const out = {};
    for (const line of text.split('\n')) {
      const m = line.match(/^(?:const|static var|var|@export var)\s+([A-Za-z_]\w*)\s*(?::\s*[\w\[\]]+)?\s*:?=\s*(.+)$/);
      if (!m) continue;
      let v = m[2], str = false;
      for (let i = 0; i < v.length; i++) {
        if (v[i] === '"') str = !str;
        if (v[i] === '#' && !str && !/^#[0-9a-fA-F]{6}/.test(v.slice(i))) { v = v.slice(0, i); break; }
      }
      out[m[1]] = v.trim();
    }
    return out;
  }
  /** A shader's uniform defaults: {name: rawValueText}. */
  function shaderUniforms(text) {
    const out = {};
    for (const m of text.matchAll(/^uniform\s+\w+\s+(\w+)\s*(?::[^=;]*)?=\s*([^;]+);/gm)) out[m[1]] = m[2];
    return out;
  }
  WO.godot = { parseSections, sceneNodes, gdConsts, shaderUniforms, value: gv };

  // ---------------------------------------------------------------------------------------------
  // 4. Fetching the homes
  // ---------------------------------------------------------------------------------------------

  /** Raw text of every file read so far, by its path under the game folder. */
  const files = {};
  /** Fetches one game file as text with cache "no-store" (see brief 7.1 Live reload for why). */
  async function fetchText(path) {
    const res = await fetch(GAME + path, { cache: 'no-store' });
    if (!res.ok) throw new Error('HTTP ' + res.status);
    return res.text();
  }
  /** Fetches each path in [paths]; returns the list of failures (empty when all loaded). */
  async function fetchAll(paths) {
    const failed = [];
    await Promise.all(paths.map(async (p) => {
      try { files[p] = await fetchText(p); } catch (e) { failed.push(p + ' (' + (e.message || e) + ')'); }
    }));
    return failed;
  }

  // ---------------------------------------------------------------------------------------------
  // 5. Tokens (brief 2.7): flatten, aliases, overrides, typed getters, CSS variables
  // ---------------------------------------------------------------------------------------------

  const ALIAS = /^\{([^{}]+)\}$/;
  /**
   * The token store. file is the parsed token file; flat maps a dot path to {path, node, type,
   * ext, desc}; overrides maps a dot path to a $value from the Tune panel or the URL (t.*).
   * Overrides always win over the file, also after a live reload.
   */
  const tokens = { file: null, text: '', flat: new Map(), overrides: new Map(), lang: null, langText: '', langOverrides: new Map() };
  WO.tokens = tokens;

  /** Rebuilds tokens.flat from tokens.file. */
  function flatten() {
    tokens.flat.clear();
    (function walk(node, path, groupDesc) {
      for (const [k, v] of Object.entries(node)) {
        if (k.startsWith('$') || !v || typeof v !== 'object') continue;
        const p = path ? path + '.' + k : k;
        if ('$value' in v) tokens.flat.set(p, { path: p, node: v, type: v.$type, ext: (v.$extensions || {})[EXT] || {}, desc: v.$description || groupDesc || '' });
        else walk(v, p, v.$description || groupDesc);
      }
    })(tokens.file, '', '');
  }
  /** A token's own $value (the override if any), alias text included. Throws if the token is missing. */
  function rawOf(path) {
    if (tokens.overrides.has(path)) return tokens.overrides.get(path);
    const t = tokens.flat.get(path);
    if (!t) throw new Error('token missing: ' + path);
    return t.node.$value;
  }
  /** A token's $value with aliases followed (loops throw). */
  function resolved(path, seen = []) {
    if (seen.includes(path)) throw new Error('alias loop: ' + seen.concat(path).join(' -> '));
    const v = rawOf(path);
    const m = typeof v === 'string' && v.match(ALIAS);
    return m ? resolved(m[1], seen.concat(path)) : v;
  }
  /** The token record (type, ext, desc); throws if missing. */
  function rec(path) {
    const t = tokens.flat.get(path);
    if (!t) throw new Error('token missing: ' + path);
    return t;
  }
  /** Number from a dimension, duration or number token. */
  function num(path) {
    const v = resolved(path);
    return typeof v === 'object' && v !== null ? v.value : v;
  }
  /** A choice token's option string (a number token with ext.options). */
  function choice(path) {
    const t = rec(path);
    return t.ext.options[num(path)];
  }
  /** [r, g, b, a] in 0..1 from a colour token's components (never from its hex, brief 2.7). */
  function color(path) {
    const v = resolved(path);
    return [...v.components, v.alpha === undefined ? 1 : v.alpha];
  }
  /** CSS text for a colour [r, g, b, a] in 0..1. */
  const rgba = (c) => `rgb(${fmt(c[0] * 255, 3)} ${fmt(c[1] * 255, 3)} ${fmt(c[2] * 255, 3)} / ${fmt(c[3], 4)})`;
  /** "#rrggbb" for display of a colour [r, g, b, a]. */
  const hexOf = (c) => '#' + c.slice(0, 3).map((x) => Math.round(x * 255).toString(16).padStart(2, '0')).join('').toUpperCase();
  /** The CSS text of one token's resolved value. */
  function tokenCss(path) {
    const t = rec(path);
    const v = resolved(path);
    switch (t.type) {
      case 'color': return rgba(color(path));
      case 'dimension': return v.value + 'px';
      case 'duration': return v.value + 'ms';
      case 'cubicBezier': return `cubic-bezier(${v.join(', ')})`;
      case 'fontFamily': return fontStack(v);
      case 'fontWeight': return String(v);
      default: return String(typeof v === 'object' ? v.value : v);
    }
  }
  /** Display text of a $value with its unit ("16 px", "250 ms", "{color.base.x}"). */
  function showValue(t, v) {
    if (v && typeof v === 'object' && 'value' in v) return fmt(v.value, 4) + ' ' + v.unit;
    if (v && typeof v === 'object' && 'components' in v) return v.hex || hexOf([...v.components, v.alpha]);
    if (Array.isArray(v)) return '[' + v.join(', ') + ']';
    if (t && t.ext.options && t.type === 'number') return t.ext.options[v] + ' (' + v + ')';
    return String(v);
  }
  Object.assign(tokens, { raw: rawOf, resolved, rec, num, choice, color, css: tokenCss, show: showValue });

  /** The language table row [code]'s [field], with the Tune override if any. */
  function langField(code, field) {
    const k = code + '.' + field;
    if (tokens.langOverrides.has(k)) return tokens.langOverrides.get(k);
    const row = tokens.lang.languages[code];
    if (!row || !(field in row)) throw new Error('languages.json has no ' + k);
    return row[field];
  }
  WO.lang = langField;

  // ---------------------------------------------------------------------------------------------
  // 6. Theme reader (box metrics, gradients, font files) from game_theme.tres
  // ---------------------------------------------------------------------------------------------

  /** Parsed theme: {subs: {id: section}, exts: {id: path}, styles: {"Type/state": subId},
   *  colors: {"Type/colors/name": raw}, fonts: {Type: extId}, base: {Type: BaseType}, props: [resource]}. */
  const theme = {};
  WO.theme = theme;

  /** Reads game_theme.tres into [theme]. */
  function readTheme() {
    const secs = parseSections(files[CORE.theme]);
    theme.subs = {}; theme.exts = {}; theme.styles = {}; theme.colors = {}; theme.fonts = {}; theme.base = {};
    for (const s of secs) {
      if (s.tag === 'sub_resource') theme.subs[s.attrs.id] = s;
      if (s.tag === 'ext_resource') theme.exts[s.attrs.id] = s.attrs.path;
      if (s.tag === 'resource') theme.props = s.props;
    }
    for (const [k, raw] of Object.entries(theme.props)) {
      let m = k.match(/^(\w+)\/styles\/(\w+)$/);
      if (m) theme.styles[m[1] + '/' + m[2]] = gv(raw).sub;
      m = k.match(/^(\w+)\/colors\/(\w+)$/);
      if (m) theme.colors[k] = raw;
      m = k.match(/^(\w+)\/fonts\/font$/);
      if (m) theme.fonts[m[1]] = gv(raw).ext;
      m = k.match(/^(\w+)\/base_type$/);
      if (m) theme.base[m[1]] = gv(raw);
    }
  }
  /** The theme slot a token binding names ("Button_normal.bg_color" or "Button/colors/font_color")
   *  mapped to its token path, from every token's theme binding (brief 2.7 "theme"). */
  function themeBindings() {
    const map = {};
    for (const t of tokens.flat.values()) for (const slot of t.ext.theme || []) map[slot] = t.path;
    return map;
  }
  /** A theme colour slot's CSS: the bound token's colour (so a tuned role shows), else the theme
   *  file's own value (the generator keeps them equal; an unbound slot's home is the theme). */
  function slotColor(bind, slot, raw) {
    if (bind[slot]) return rgba(color(bind[slot]));
    return rgba(gv(raw).color);
  }
  /** CSS for a Gradient sub-resource drawn by a GradientTexture2D (linear or radial). */
  function gradientCss(sections, texId) {
    const tex = sections[texId];
    const grad = sections[gv(tex.props.gradient).sub];
    const offs = gv(grad.props.offsets);
    const cols = gv(grad.props.colors);
    const stops = offs.map((o, i) => rgba(cols.slice(i * 4, i * 4 + 4)) + ' ' + fmt(o * 100, 3) + '%').join(', ');
    const from = tex.props.fill_from ? gv(tex.props.fill_from) : [0, 0];
    const to = tex.props.fill_to ? gv(tex.props.fill_to) : [1, 0];
    // A radial fill is an ellipse whose radii are |fill_to - fill_from| of the box on each axis: the
    // texture stretches to its rect (a circle in UV space), not a circle in px.
    if (tex.props.fill && gv(tex.props.fill) === 1) {
      const r = Math.hypot(to[0] - from[0], to[1] - from[1]) * 100;
      return `radial-gradient(${fmt(r, 3)}% ${fmt(r, 3)}% at ${fmt(from[0] * 100)}% ${fmt(from[1] * 100)}%, ${stops})`;
    }
    const deg = 90 + (Math.atan2(to[1] - from[1], to[0] - from[0]) * 180) / Math.PI;
    return `linear-gradient(${fmt(deg)}deg, ${stops})`;
  }
  /**
   * Sets one set of variables per theme type and state, following base_type when a state is
   * missing: --wo-<Type>-<state>-{bg, border, bw, bw-top, radius, pad, shadow, inset} for a StyleBoxFlat,
   * --wo-<Type>-<state>-image for a gradient StyleBoxTexture, and --wo-<Type>-<color> for the
   * font colours. Godot's content margin counts from the outer edge, so CSS padding is the margin
   * less the border; an unset margin is the border alone (StyleBoxFlat::get_style_margin).
   */
  function themeVars(target) {
    const bind = themeBindings();
    const types = new Set(Object.keys(theme.styles).map((k) => k.split('/')[0]).concat(Object.keys(theme.base), Object.keys(theme.colors).map((k) => k.split('/')[0])));
    const lookup = (map, type, key) => {
      for (let t = type; t; t = theme.base[t]) if (map[t + '/' + key] !== undefined) return map[t + '/' + key];
      return undefined;
    };
    const states = new Set(Object.keys(theme.styles).map((k) => k.split('/')[1]));
    for (const type of types) {
      for (const state of states) {
        const id = lookup(theme.styles, type, state);
        if (!id) continue;
        const sb = theme.subs[id];
        const pre = `--wo-${type}-${state}-`;
        if (sb.attrs.type === 'StyleBoxTexture') {
          target.setProperty(pre + 'image', gradientCss(theme.subs, gv(sb.props.texture).sub));
          continue;
        }
        const p = (k, d = 0) => (sb.props[k] === undefined ? d : gv(sb.props[k]));
        const sides = ['top', 'right', 'bottom', 'left'];
        const bw = sides.map((s) => p('border_width_' + s));
        const cm = sides.map((s) => p('content_margin_' + s, -1));
        const pad = cm.map((m, i) => (m < 0 ? 0 : Math.max(0, m - bw[i])));
        const rad = ['top_left', 'top_right', 'bottom_right', 'bottom_left'].map((c) => p('corner_radius_' + c));
        const exp = sides.map((s) => -p('expand_margin_' + s));
        if (!sb.props.bg_color) throw new Error('game_theme.tres ' + id + ' has no bg_color');
        target.setProperty(pre + 'bg', slotColor(bind, id + '.bg_color', sb.props.bg_color));
        target.setProperty(pre + 'border', sb.props.border_color ? slotColor(bind, id + '.border_color', sb.props.border_color) : 'transparent');
        target.setProperty(pre + 'bw', bw.map((x) => x + 'px').join(' '));
        target.setProperty(pre + 'bw-top', bw[0] + 'px'); // one width, for rings drawn as a box shadow
        target.setProperty(pre + 'pad', pad.map((x) => x + 'px').join(' '));
        target.setProperty(pre + 'radius', rad.map((x) => x + 'px').join(' '));
        target.setProperty(pre + 'inset', exp.map((x) => x + 'px').join(' '));
        const off = sb.props.shadow_offset ? gv(sb.props.shadow_offset) : [0, 0];
        target.setProperty(pre + 'shadow', sb.props.shadow_color && p('shadow_size') > 0
          ? `${off[0]}px ${off[1]}px ${p('shadow_size')}px ${slotColor(bind, id + '.shadow_color', sb.props.shadow_color)}` : 'none');
      }
      for (const key of Object.keys(theme.colors).filter((k) => k.startsWith(type + '/')).map((k) => k.split('/')[2])) {
        target.setProperty(`--wo-${type}-${key}`, slotColor(bind, `${type}/colors/${key}`, theme.colors[`${type}/colors/${key}`]));
      }
      // Inherited font colours (a TerminalButton draws Button's), so every type has its set.
      for (const k of Object.keys(theme.colors)) {
        const [owner, , key] = k.split('/');
        for (let t = theme.base[type]; t; t = theme.base[t]) {
          if (t === owner && theme.colors[type + '/colors/' + key] === undefined) target.setProperty(`--wo-${type}-${key}`, slotColor(bind, k, theme.colors[k]));
        }
      }
    }
  }

  // Fonts --------------------------------------------------------------------------------------

  /** Registered font families: {familyName: {file, fallbacks: [familyName]}}. */
  const fontFamilies = {};
  /** The CSS font-family list for a token face ("Roboto" -> "Roboto", "Montserrat-Symbols-Subset"). */
  function fontStack(face) {
    const f = fontFamilies[face];
    if (!f) throw new Error('font face "' + face + '" is not a base font of any theme FontVariation');
    return ['"' + face + '"'].concat(f.fallbacks.map((x) => '"' + x + '"')).join(', ');
  }
  /**
   * Finds the game fonts the way Godot does: each FontVariation .tres the theme and the scenes
   * load, its base_font .ttf, and that file's import fallbacks (Roboto's symbol subset). Each base
   * font registers under the name before its first "-" (the token faces' names); each fallback
   * under its whole file stem. Weight comes from font-variation-settings in wo.css, so no weight
   * range is declared here.
   */
  async function loadFonts() {
    const variationPaths = new Set();
    const addExts = (text) => {
      for (const s of parseSections(text).filter((x) => x.tag === 'ext_resource' && x.attrs.type === 'FontVariation')) variationPaths.add(s.attrs.path.replace('res://', ''));
    };
    addExts(files[CORE.theme]);
    addExts(files[SOURCES['main.tscn']]);
    addExts(files[SOURCES['studio_logo.tscn']]);
    const failed = await fetchAll([...variationPaths]);
    if (failed.length) return failed;
    const ttfs = new Set();
    for (const p of variationPaths) {
      const secs = parseSections(files[p]);
      const ext = Object.fromEntries(secs.filter((x) => x.tag === 'ext_resource').map((x) => [x.attrs.id, x.attrs.path.replace('res://', '')]));
      ttfs.add(ext[gv(secs.find((x) => x.tag === 'resource').props.base_font).ext]);
    }
    const imports = [...ttfs].map((t) => t + '.import');
    const failed2 = await fetchAll(imports);
    if (failed2.length) return failed2;
    const loads = [];
    const register = (family, file) => {
      const face = new FontFace(family, `url("${GAME + file}")`);
      document.fonts.add(face);
      loads.push(face.load().catch((e) => problem('font failed to load: ' + file + ' (' + e.message + ')')));
    };
    for (const ttf of ttfs) {
      const stem = ttf.split('/').pop().replace(/\.\w+$/, '');
      const family = stem.split('-')[0];
      const fb = [].concat(...parseSections(files[ttf + '.import']).map((s) => (s.props.fallbacks ? gv(s.props.fallbacks) : [])));
      const fallbacks = [...new Set(fb.filter((x) => x && x.res).map((x) => x.res.replace('res://', '')))];
      fontFamilies[family] = { file: ttf, fallbacks: fallbacks.map((f) => f.split('/').pop().replace(/\.\w+$/, '')) };
      register(family, ttf);
      for (const f of fallbacks) register(f.split('/').pop().replace(/\.\w+$/, ''), f);
    }
    await Promise.all(loads);
    return [];
  }
  WO.fonts = fontFamilies;

  // ---------------------------------------------------------------------------------------------
  // 7. Today readers: values that still live in a script or scene (brief 2.7 "Kept out")
  // ---------------------------------------------------------------------------------------------

  const parsed = {};
  /** Parsed form of a source by its short name (main.gd, main.tscn, ...), cached. */
  function src(name) {
    if (parsed[name]) return parsed[name];
    const text = files[SOURCES[name] || name];
    if (text === undefined) throw new Error('source not loaded: ' + name);
    if (name.endsWith('.gd')) parsed[name] = gdConsts(text);
    else if (name.endsWith('.tscn')) parsed[name] = sceneNodes(parseSections(text));
    else if (name.endsWith('.gdshader')) parsed[name] = shaderUniforms(text);
    return parsed[name];
  }
  /**
   * Today readers. Each returns the parsed value from its home or throws (no fallback):
   * - konst(file, NAME): a GDScript constant or variable (number, colour, vector, array);
   * - node(file, path): a scene node {type, props}; prop(file, path, key, dflt);
   * - rect(file, path): a Control's offsets as {x, y, w, h} in canvas px;
   * - match(file, regex): the captures of [regex] in the raw text, as raw strings (one capture
   *   gives one string);
   * - uniform(name): a post_grade.gdshader uniform default;
   * - project(key): a project.godot setting ("display/window/size/viewport_width").
   */
  const today = {
    konst(file, name) {
      const raw = src(file)[name];
      if (raw === undefined) throw new Error(file + ' has no ' + name);
      return gv(raw);
    },
    node(file, path) {
      const n = src(file)[path];
      if (!n) throw new Error(file + ' has no node ' + path);
      return n;
    },
    prop(file, path, key, dflt) {
      const v = today.node(file, path).props[key];
      if (v === undefined) { if (dflt !== undefined) return dflt; throw new Error(file + ' ' + path + ' has no ' + key); }
      return gv(v);
    },
    rect(file, path) {
      const p = (k) => today.prop(file, path, k, 0);
      return { x: p('offset_left'), y: p('offset_top'), w: p('offset_right') - p('offset_left'), h: p('offset_bottom') - p('offset_top') };
    },
    match(file, re) {
      const m = (files[SOURCES[file]] || '').match(re);
      if (!m) throw new Error(file + ' does not match ' + re);
      return m.length > 2 ? m.slice(1) : m[1];
    },
    uniform(name) {
      const raw = src('post_grade.gdshader')[name];
      if (raw === undefined) throw new Error('post_grade.gdshader has no uniform ' + name);
      return gv(raw);
    },
    project(key) {
      if (!today._project) {
        today._project = {};
        for (const s of parseSections(files[CORE.project])) {
          for (const [k, v] of Object.entries(s.props)) today._project[(s.tag ? s.tag + '/' : '') + k] = v;
        }
      }
      const raw = today._project[key];
      if (raw === undefined) throw new Error('project.godot has no ' + key);
      return gv(raw);
    },
  };
  WO.today = today;

  /**
   * The scene and script values the CSS needs as variables, each read from its one home. Kind:
   * "color" (a Color), "ms" (seconds, to ms), "px", "num". Read is [reader, ...arguments]. These
   * are scene or script literals until B26 moves the colours into theme type variations.
   */
  const TODAY_VARS = [
    ['accent', 'color', 'konst', 'main.gd', 'TOP_CARD_ACCENT'],
    ['accent-rule', 'color', 'prop', 'main.tscn', 'CanvasLayer/TitleScreen/TitleLine', 'color'],
    ['accent-hint', 'color', 'prop', 'main.tscn', 'CanvasLayer/ContextHint/Accent', 'color'],
    ['text-hint', 'color', 'prop', 'main.tscn', 'CanvasLayer/ContextHint/Text', 'theme_override_colors/font_color'],
    ['text-sub', 'color', 'prop', 'main.tscn', 'CanvasLayer/TitleScreen/Subtitle', 'theme_override_colors/font_color'],
    ['text-note', 'color', 'prop', 'main.tscn', 'CanvasLayer/TitleScreen/ContinueNote', 'theme_override_colors/font_color'],
    ['text-brand', 'color', 'prop', 'main.tscn', 'CanvasLayer/TitleScreen/Brand', 'theme_override_colors/font_color'],
    ['text-muted', 'color', 'konst', 'game_settings.gd', 'MUTED_TEXT'],
    ['title-bg', 'color', 'prop', 'main.tscn', 'CanvasLayer/TitleScreen', 'color'],
    ['pause-backdrop', 'color', 'prop', 'main.tscn', 'CanvasLayer/PauseOverlay', 'color'],
    ['speaker-rule', 'color', 'prop', 'main.tscn', 'CanvasLayer/BottomBar/SpeakerRule', 'color'],
    ['logo-bg', 'color', 'prop', 'studio_logo.tscn', 'Background', 'color'],
    ['logo-name', 'color', 'prop', 'studio_logo.tscn', 'CompanyName', 'theme_override_colors/font_color'],
    ['bar-track', 'color', 'prop', 'studio_logo.tscn', 'LoadBar', 'color'],
    ['bar-fill', 'color', 'prop', 'studio_logo.tscn', 'LoadBar/Fill', 'color'],
    ['fade-color', 'color', 'konst', 'studio_logo.gd', 'FADE_COLOR'],
    ['label-text', 'color', 'konst', 'palette.gd', 'LABEL_TEXT'],
    ['label-alert', 'color', 'konst', 'palette.gd', 'LABEL_ALERT'],
    ['plate-bg', 'color', 'konst', 'palette.gd', 'PLATE_BG'],
    ['plate-edge', 'color', 'konst', 'palette.gd', 'PLATE_EDGE'],
    ['amber', 'color', 'konst', 'palette.gd', 'AMBER'],
    ['done', 'color', 'konst', 'palette.gd', 'GREEN'],
    ['lamp-shut', 'color', 'konst', 'palette.gd', 'LAMP_SHUT'],
    ['beacon', 'color', 'konst', 'room_depth.gd', 'WARNING_RED'],
    ['speaker-wolf', 'color', 'konst', 'palette.gd', 'CYAN'],
    ['speaker-engineer', 'color', 'konst', 'main.gd', 'ENGINEER_TINT'],
    ['accent-w', 'px', 'rectW', 'main.tscn', 'CanvasLayer/TopBar/Accent'],
    ['sweep-w', 'px', 'rectW', 'studio_logo.tscn', 'LoadBar'],
    ['sweep-h', 'px', 'rectH', 'studio_logo.tscn', 'LoadBar'],
    ['bar-segment', 'num', 'konst', 'studio_logo.gd', 'BAR_SEGMENT'],
    ['bar-sweep', 'ms', 'konst', 'studio_logo.gd', 'BAR_SWEEP_SECONDS'],
    ['top-card-fade', 'ms', 'konst', 'main.gd', 'TOP_CARD_FADE_SECONDS'],
    ['reveal', 'ms', 'konst', 'main.gd', 'MENU_REVEAL_SECONDS'],
    ['reveal-offset', 'px', 'konstY', 'main.gd', 'MENU_REVEAL_OFFSET'],
    ['arrow-w', 'px', 'rectW', 'main.tscn', 'CanvasLayer/TouchControls/Left'],
    ['arrow-h', 'px', 'rectH', 'main.tscn', 'CanvasLayer/TouchControls/Left'],
    ['use-w', 'px', 'rectW', 'main.tscn', 'CanvasLayer/TouchControls/Use'],
    ['use-h', 'px', 'rectH', 'main.tscn', 'CanvasLayer/TouchControls/Use'],
    ['pause-w', 'px', 'rectW', 'main.tscn', 'CanvasLayer/PauseButton'],
    ['pause-h', 'px', 'rectH', 'main.tscn', 'CanvasLayer/PauseButton'],
    ['choice-h', 'px', 'rectH', 'main.tscn', 'CanvasLayer/TouchControls/Choice1'],
    ['title-col-w', 'px', 'rectW', 'main.tscn', 'CanvasLayer/TitleScreen/TitleLine'],
    ['settings-w', 'px', 'rectW', 'main.tscn', 'CanvasLayer/PauseOverlay/Panel/SettingsMenu'],
    ['settings-h', 'px', 'rectH', 'main.tscn', 'CanvasLayer/PauseOverlay/Panel/SettingsMenu'],
    ['title-mark', 'px', 'rectW', 'main.tscn', 'CanvasLayer/TitleScreen/LogoMark'],
    ['world-label-size', 'px', 'prop', 'main.tscn', 'BreakerLabel', 'theme_override_font_sizes/font_size'],
  ];
  /** The speaker tints Main picks in one expression (main.gd, the "var tint" line): WOLF's is
   *  Palette.CYAN (read above), the Director's and every other speaker's are literals there. */
  const TINT_LINE = /var tint: Color = Palette\.CYAN if id == "WOLF" else \(Color\("(#\w+)"\) if id\.begins_with\("DIRECTOR"\) else \(ENGINEER_TINT if id == human_name else Color\("(#\w+)"\)\)\)/;

  /** Sets --wo-today-* on :root from TODAY_VARS, the tint line and the studio logo's glow, and
   *  --wo-launch-bg (the launch image's backdrop). */
  function todayVars(target) {
    for (const [name, kind, reader, file, path, key] of TODAY_VARS) {
      try {
        let v;
        if (reader === 'konst') v = today.konst(file, path);
        else if (reader === 'konstY') v = today.konst(file, path)[1];
        else if (reader === 'prop') v = today.prop(file, path, key);
        else if (reader === 'rectW') v = today.rect(file, path).w;
        else if (reader === 'rectH') v = today.rect(file, path).h;
        const css = kind === 'color' ? rgba(v.color) : kind === 'ms' ? v * 1000 + 'ms' : kind === 'px' ? v + 'px' : String(v);
        target.setProperty('--wo-today-' + name, css);
      } catch (e) { problem(e.message); }
    }
    try {
      const [director, other] = today.match('main.gd', TINT_LINE);
      target.setProperty('--wo-today-speaker-director', rgba(hexColor(director)));
      target.setProperty('--wo-today-speaker-other', rgba(hexColor(other)));
    } catch (e) { problem(e.message); }
    // The studio logo's glow (studio_logo.tscn Glow, a GradientTexture2D of that scene) and the launch
    // colour: the logo's navy Background (proposal, brief 5.2 step 1), or with ?splash=today today's
    // application/boot_splash/bg_color (project.godot).
    try {
      const subs = Object.fromEntries(parseSections(files[SOURCES['studio_logo.tscn']]).filter((x) => x.tag === 'sub_resource').map((x) => [x.attrs.id, x]));
      target.setProperty('--wo-today-logo-glow', gradientCss(subs, gv(today.node('studio_logo.tscn', 'Glow').props.texture).sub));
      const c = url.get('splash') === 'today' ? today.project('application/boot_splash/bg_color').color : today.prop('studio_logo.tscn', 'Background', 'color').color;
      target.setProperty('--wo-launch-bg', rgba(c));
    } catch (e) { problem(e.message); }
  }

  // ---------------------------------------------------------------------------------------------
  // 8. Devices, screen shape (brief 2.5) and profiles (2.2-2.4)
  // ---------------------------------------------------------------------------------------------

  /** The reference device names, in the token file's order (devices.<name>.width exists). */
  function deviceNames() {
    return [...tokens.flat.keys()].filter((p) => /^devices\.[\w-]+\.width$/.test(p)).map((p) => p.split('.')[1]);
  }
  /** A device's label: its $description up to the first ": " or ", " ("ROG Ally (2023)"). */
  function deviceLabel(name) {
    const d = tokens.file.devices[name].$description || name;
    return d.split(/: |, /)[0];
  }
  /** The base canvas (project.godot), the play zoom (main.gd) and the room (room_depth.gd). */
  function stage() {
    return {
      baseW: today.project('display/window/size/viewport_width'),
      baseH: today.project('display/window/size/viewport_height'),
      zoom: today.konst('main.gd', 'GAMEPLAY_ZOOM'),
      roomW: today.konst('room_depth.gd', 'ROOM_WIDTH'),
      floorY: today.konst('room_depth.gd', 'FLOOR_Y'),
      bleed: today.konst('room_depth.gd', 'BOTTOM_BLEED'),
      midBleed: today.konst('room_depth.gd', 'MID_BLEED'),
      shake: today.konst('impact.gd', 'MAX_SHAKE_PX'),
      cameraY: today.konst('main.gd', 'GAMEPLAY_CAMERA_Y'),
      cameraYTouch: today.konst('main.gd', 'GAMEPLAY_CAMERA_Y_TOUCH'),
    };
  }
  /**
   * ScreenShape (brief 2.5.3 step 2) for a screen W x H device px: the canvas size in canvas px,
   * the mode ("expand" or "keep"), s = device px per canvas px, and the bars in device px.
   * The wide bound is computed, never stored: room width x zoom / canvas height (2.4 at today's
   * numbers); the tall bound is the devices.aspect-min token (4:3).
   */
  function screenShape(W, H) {
    const st = stage();
    const maxA = (st.roomW * st.zoom) / st.baseH;
    const minA = num('devices.aspect-min');
    const a = W / H;
    let cw, ch, mode;
    if (a > maxA) { cw = Math.round(st.baseH * maxA); ch = st.baseH; mode = 'keep'; }
    else if (a < minA) { cw = st.baseW; ch = Math.round(st.baseW / minA); mode = 'keep'; }
    else { const s0 = Math.min(W / st.baseW, H / st.baseH); cw = W / s0; ch = H / s0; mode = 'expand'; }
    const s = Math.min(W / cw, H / ch);
    return { cw, ch, mode, s, barX: (W - cw * s) / 2, barY: (H - ch * s) / 2, maxA, minA };
  }
  /** Everything about one reference device: size, scale, shape, profile and safe insets. */
  function device(name) {
    const g = 'devices.' + name + '.';
    const has = (k) => tokens.flat.has(g + k);
    const W = num(g + 'width'), H = num(g + 'height'), scale = num(g + 'scale');
    const shape = screenShape(W, H);
    const k = shape.s / scale; // CSS px (pt on iOS) per canvas px
    const d = { name, label: deviceLabel(name), W, H, scale, cssW: W / scale, cssH: H / scale, shape, k, profile: choice(g + 'profile') };
    d.ppi = has('ppi') ? num(g + 'ppi') : null;
    d.dpi = has('density-dpi') ? num(g + 'density-dpi') : null;
    d.android = d.dpi !== null;
    // The panel's refresh rate in Hz, where the token file has it (devices.<name>.refresh-hz); null
    // means not known, and nothing is hidden for it (data-wo-min-refresh).
    d.refresh = has('refresh-hz') ? num(g + 'refresh-hz') : null;
    // Safe insets in canvas px: measured points where the token file has them (iPhone), else 0.
    const inset = (side) => (has('inset-' + side) ? num(g + 'inset-' + side) / k : 0);
    d.insets = { left: inset('left'), right: inset('right'), top: inset('top'), bottom: inset('bottom') };
    d.insetsMeasured = has('inset-left') || has('inset-bottom');
    return d;
  }
  WO.devices = { names: deviceNames, device, shape: screenShape, stage };

  /** Physical size of Apple's point on the reference iPhone, in inches (Android matches it, 2.2). */
  function applePointInches() {
    return num('devices.iphone.scale') / num('devices.iphone.ppi');
  }
  /** [pt] points in canvas px on [d]: iOS uses its own points; Android the iPhone's physical point. */
  function ptToCanvas(d, pt) {
    return d.android ? (pt * applePointInches() * d.ppi) / d.shape.s : pt / d.k;
  }
  /** [mm] millimetres in canvas px on [d] (needs the device's ppi). */
  function mmToCanvas(d, mm) {
    return ((mm / 25.4) * d.ppi) / d.shape.s;
  }
  /** Android's dp in canvas px: dp x densityDpi / 160 device px (160 is Android's baseline density,
   *  its definition of a dp); iOS has no dp, so its physical ppi stands in (2.3). */
  function dpToCanvas(d, dp) {
    return ((dp * (d.dpi || d.ppi)) / 160) / d.shape.s;
  }
  /** The phone touch density (2.3): the larger of 44 pt and 48 dp, never under the touch floor. */
  function phoneDensity(d) {
    const pt = d.android ? 0 : ptToCanvas(d, num('density.phone-min-pt'));
    const dp = dpToCanvas(d, num('density.phone-min-dp'));
    return Math.max(num('density.touch-floor'), Math.ceil(Math.max(pt, dp)));
  }
  /** The phone text scale (2.2): Body reaches body-pt, never below text-scale-min. */
  function phoneTextScale(d) {
    return Math.max(num('profile.phone.text-scale-min'), ptToCanvas(d, num('profile.phone.body-pt')) / num('type.body.size'));
  }
  /** TextSize's default factor (text_size.gd "static var factor"), as a percentage. */
  function defaultTextSize() { return today.konst('text_size.gd', 'factor') * 100; }
  /** TEXT SIZE steps as percentages (text_size.gd STEPS). */
  function textSteps() { return today.konst('text_size.gd', 'STEPS').map((x) => Math.round(x * 100)); }
  /** The type roles: every type.<role> group that has a size token. */
  function roles() {
    return [...tokens.flat.keys()].filter((p) => /^type\.[\w-]+\.size$/.test(p)).map((p) => p.split('.')[1]);
  }

  /**
   * The profile values for device [d] (brief 2.2-2.4): text scale, TEXT SIZE, role sizes
   * (round(base x profile scale x TEXT SIZE) as TextSize.px rounds, but up when round() would
   * break a floor), density, the minimum hit size, HUD edges (Android: widened by ?cutout= and
   * ?edge=), phone control sizes, and the text floors that apply.
   * [opts.text] overrides TEXT SIZE (%); [opts.touched] says a desktop frame takes handheld
   * density because a real touch reached it (layoutFrames applies density.touch-switch).
   */
  function profile(d, opts = {}) {
    const p = d.profile;
    const P = { device: d, kind: p };
    P.textScale = p === 'phone' ? phoneTextScale(d) : num('profile.' + p + '.text-scale');
    P.textSize = opts.text || (p === 'handheld' ? num('profile.handheld.text-size') : defaultTextSize());
    P.floors = textFloors(d, p);
    // round(base x profile scale x TEXT SIZE), as TextSize.px rounds, except that rounding never
    // takes a role under a floor it applies to: then it rounds up (iPhone Body: 21.34 rounds to 21,
    // under the 17 pt floor of 21.35, so it becomes 22). TextSize.px needs the same rule (M04, M10).
    P.roles = {};
    for (const r of roles()) {
      const x = num('type.' + r + '.size') * P.textScale * (P.textSize / 100);
      const v = Math.round(x);
      P.roles[r] = P.floors.some((f) => (!f.role || f.role === r) && v < f.px - 1e-9) ? Math.ceil(x) : v;
    }
    if (p === 'phone') P.density = phoneDensity(d);
    else if (p === 'handheld') P.density = num('profile.handheld.density');
    else P.density = opts.touched ? num('profile.handheld.density') : num('profile.desktop.density');
    P.hitMin = p === 'desktop' && !opts.touched ? num('density.pointer-hit-min') : P.density;
    P.hitMargin = p === 'phone' ? dpToCanvas(d, num('density.gap-phone-dp')) : 0;
    const m = num('profile.hud-margin');
    P.edges = { left: Math.max(m, d.insets.left), right: Math.max(m, d.insets.right), top: Math.max(m, d.insets.top), bottom: Math.max(m, d.insets.bottom) };
    // Android (2.6): the cutout (drawn on the left) and the back-gesture strip (both sides) widths come
    // from ?cutout= and ?edge= in canvas px until a device log measures them; the HUD and the move pad
    // keep out of both, as the game's safe rect will (2.5.3 step 3, 2.6 step 1).
    if (d.android) {
      const cut = Number(url.get('cutout')) || 0, edge = Number(url.get('edge')) || 0;
      P.edges.left = Math.max(P.edges.left, cut, edge);
      P.edges.right = Math.max(P.edges.right, edge);
    }
    if (p === 'phone') {
      P.useSize = Math.max(num('profile.phone.use-size-min'), mmToCanvas(d, num('profile.phone.use-size-mm')));
      P.pauseSize = P.density;
    }
    return P;
  }
  /** The text floors for a profile, as [{px, label, hard, role?}] (2.2 "Floors these must clear"). */
  function textFloors(d, p) {
    if (p === 'desktop') return [{ px: num('profile.desktop.text-min'), label: 'XAG PC body ' + num('profile.desktop.text-min'), hard: true }];
    if (p === 'handheld') {
      return [
        { px: num('profile.handheld.text-min'), label: 'Xbox handheld minimum ' + num('profile.handheld.text-min'), hard: true },
        { px: num('profile.handheld.text-recommended'), label: 'recommended ' + num('profile.handheld.text-recommended'), hard: true },
      ];
    }
    return [
      { px: ptToCanvas(d, num('profile.phone.text-min-pt')), label: num('profile.phone.text-min-pt') + ' pt', hard: true },
      { px: ptToCanvas(d, num('profile.phone.body-pt')), label: num('profile.phone.body-pt') + ' pt Body', hard: false, role: 'body' },
    ];
  }
  /** Which floors [px] of [role] breaks under profile [P]: [{floor, hard}] (empty when clear). */
  function floorsBroken(P, role, px) {
    return P.floors.filter((f) => (!f.role || f.role === role) && px < f.px - 1e-9);
  }
  WO.profile = { of: profile, floorsBroken, roles, textSteps, defaultTextSize, ptToCanvas, mmToCanvas, dpToCanvas, phoneDensity, phoneTextScale };

  // ---------------------------------------------------------------------------------------------
  // 9. Input mode (brief 4.4): last input wins; glyphs, focus ring and density follow it
  // ---------------------------------------------------------------------------------------------

  /**
   * The last input class: "pointer", "keyboard", "pad" or "touch" (the URL's "mouse" is pointer).
   * Before any input it is null and each frame uses its profile's default (4.4 "Before the first
   * input": handheld pad, desktop keyboard, phone touch). Real events switch it; mouse motion alone
   * does not (today's rule, C1 section 2). Events inside the mockup chrome are ignored.
   */
  const input = { mode: null, touched: false, focusShown: false };
  WO.input = input;
  const PROFILE_INPUT = { desktop: 'keyboard', handheld: 'pad', phone: 'touch' };
  /** Sets the input class (from a real event or the strip) and re-renders what depends on it. */
  function setInput(mode, fromEvent) {
    if (mode === 'mouse') mode = 'pointer';
    if (input.mode === mode) return;
    const wasPointer = input.mode === 'pointer' || input.mode === 'touch';
    input.mode = mode;
    if (mode === 'touch') input.touched = true;
    if (fromEvent) url.set('input', mode === 'pointer' ? 'mouse' : mode);
    // First key or pad press after pointer use only reveals the ring (6.2 B7 rule 4).
    input.revealOnly = wasPointer && (mode === 'keyboard' || mode === 'pad');
    applyInput();
  }
  const inChrome = (el) => el && el.closest && el.closest('.mk-strip, .mk-tune, .mk-notice');
  function applyInput() {
    document.documentElement.dataset.input = input.mode || '';
    for (const f of frames) frameInput(f);
    renderGlyphs(document);
    syncStrip();
  }
  addEventListener('keydown', (e) => { if (!inChrome(e.target)) setInput('keyboard', true); }, true);
  addEventListener('pointerdown', (e) => {
    if (inChrome(e.target)) return;
    setInput(e.pointerType === 'mouse' ? 'pointer' : 'touch', true);
  }, true);
  /**
   * One "wo:press" event (detail {kind: "key"|"mouse"|"touch"|"pad"}) for every fresh press a
   * player of the screen would make: a key (not a held repeat, not in the mockup chrome), a pointer
   * press on a device frame, or a pad button or stick push (padLoop). The boot and sequence clocks
   * (section 17) listen to this one event, so no page polls the Gamepad API itself.
   */
  addEventListener('keydown', (e) => { if (readyState && !e.repeat && !inChrome(e.target)) emit('press', { kind: 'key' }); }, true);
  addEventListener('pointerdown', (e) => {
    if (readyState && e.target.closest && e.target.closest('.mk-device')) emit('press', { kind: e.pointerType === 'mouse' ? 'mouse' : 'touch' });
  }, true);

  /** Navigation keys on a game-screen page (<body data-wo-nav>) or inside a frame: arrows move
   *  focus, Esc is back (4.2 Menus). Sheet pages keep arrow-key scrolling. */
  addEventListener('keydown', (e) => {
    if (inChrome(e.target) || !readyState) return;
    if (!document.body.hasAttribute('data-wo-nav') && !(document.activeElement && document.activeElement.closest('.wo-frame'))) return;
    const dir = { ArrowUp: -1, ArrowLeft: -1, ArrowDown: 1, ArrowRight: 1 }[e.key];
    if (dir) { e.preventDefault(); nav(dir); }
    // A pause key that just opened an overlay prevents the default, so the same Esc does not close it.
    if (e.key === 'Escape' && !e.defaultPrevented) emit('back');
  });

  /** Fires a mockup event on document ("wo:back", "wo:tab", "wo:accept", ...). */
  function emit(name, detail) { document.dispatchEvent(new CustomEvent('wo:' + name, { detail })); }
  /** The frame the player is in: the one holding focus, else the last one pressed, else the first. */
  let lastFrame = null;
  addEventListener('pointerdown', (e) => { const c = e.target.closest && e.target.closest('.wo-frame'); if (c) lastFrame = c; }, true);
  function activeFrame() {
    const a = document.activeElement && document.activeElement.closest && document.activeElement.closest('.wo-frame');
    return a || (lastFrame && lastFrame.isConnected ? lastFrame : null) || document.querySelector('.wo-frame');
  }
  /** Focusable game controls in the active frame (or the page), in DOM order. Hidden, disabled and
   *  unselected tabs are skipped: only the selected tab is a focus stop (LB and RB switch tabs). */
  function focusables() {
    const scope = activeFrame() || document;
    return [...scope.querySelectorAll('.wo-btn, .wo-tab, .wo-touch, .wo-answer, [data-wo-focus]')].filter((el) => !el.disabled
      && el.getAttribute('aria-disabled') !== 'true' && el.offsetParent !== null && !(el.matches('.wo-tab') && el.getAttribute('aria-selected') !== 'true'));
  }
  /**
   * Moves focus [dir] (-1 or 1) in focusables(), wrapping (XAG112). With nothing focused in the frame
   * it moves from the frame's current item (data-wo-current), as Godot moves from the control that
   * holds hidden focus. The first press after pointer use only shows the ring on the focused item.
   */
  function nav(dir) {
    const list = focusables();
    if (!list.length) return;
    let cur = list.indexOf(document.activeElement);
    if (cur < 0) cur = list.indexOf(currentItem(activeFrame()));
    if (input.revealOnly && cur >= 0) { input.revealOnly = false; list[cur].focus({ preventScroll: true }); return; }
    input.revealOnly = false;
    const next = cur < 0 ? list[0] : list[(cur + dir + list.length) % list.length];
    next.focus({ preventScroll: true });
  }
  /** Hover moves the (hidden) focus, so there is only ever one highlight (6.2 B7 rule 3). */
  addEventListener('pointerover', (e) => {
    const el = e.target.closest && e.target.closest('.wo-frame .wo-btn, .wo-frame .wo-tab, .wo-frame .wo-answer, .wo-frame [data-wo-focus]');
    if (el && !el.disabled && input.mode === 'pointer') el.focus({ preventScroll: true });
  });

  // Current item (the control that holds focus in a frame) -------------------------------------

  /**
   * The item that holds focus in frame canvas [c]: the element whose data-wo-id the canvas (or its
   * host) names in data-wo-current, else the first [data-wo-autofocus] (an autofocus in a template
   * copy, fillTemplates). null when there is none.
   */
  function currentItem(c) {
    if (!c) return null;
    const host = c.closest('.mk-device');
    const id = c.dataset.woCurrent || (host && host.dataset.woCurrent);
    return (id && c.querySelector('[data-wo-id="' + id + '"]')) || c.querySelector('[data-wo-autofocus]');
  }
  /**
   * Marks each frame's current item with .is-current (wo.css draws it with the hover look and the
   * focus ring only while the frame's ring is on, so a still capture shows where focus is without
   * focusing anything). On a page with data-wo-nav the first frame's current item also takes real
   * focus, so the first arrow or D-pad press moves from it. Real focus moving inside a frame moves
   * the mark with it (focusin), so there is only one highlight.
   */
  function markCurrent() {
    for (const f of frames) {
      f.canvas.querySelectorAll('.is-current').forEach((x) => x.classList.remove('is-current'));
      const el = currentItem(f.canvas);
      if (el) el.classList.add('is-current');
    }
    const first = frames.length && currentItem(frames[0].canvas);
    if (first && document.body.hasAttribute('data-wo-nav') && !(document.activeElement && document.activeElement.closest('.wo-frame'))) first.focus({ preventScroll: true });
  }
  addEventListener('focusin', (e) => {
    const c = e.target.closest && e.target.closest('.wo-frame');
    if (!c || !e.target.matches('.wo-btn, .wo-tab, .wo-touch, .wo-answer, [data-wo-focus]')) return;
    c.querySelectorAll('.is-current').forEach((x) => x !== e.target && x.classList.remove('is-current'));
    e.target.classList.add('is-current');
  });

  // Gamepad (secure contexts only: localhost; brief 7.1 Serve) ---------------------------------

  /** Standard-mapping button indexes, named as Godot's JOY_BUTTON_* and the Xbox glyphs. */
  const PAD = { A: 0, B: 1, X: 2, Y: 3, LB: 4, RB: 5, LT: 6, RT: 7, View: 8, Menu: 9, DPadUp: 12, DPadDown: 13, DPadLeft: 14, DPadRight: 15 };
  /** The wo: event each pad button fires (4.2 button map); D-pad buttons move focus instead. */
  const PAD_EVENTS = { A: 'accept', B: 'back', X: 'answer', Y: 'answer', LB: 'tab', RB: 'tab', LT: 'page', RT: 'page', Menu: 'menu', View: 'view' };
  /**
   * What one pad button press does, written once for the Gamepad loop and for scripted captures
   * (WO.pad.press, capture.mjs @pad=): it sets pad input, ends entrances, fires wo:press, then moves
   * focus (D-pad) or clicks the focused control (A) and fires the button's wo: event
   * (detail {button, dir}: dir -1 for LB and LT, else 1). [fresh] is false for a held repeat.
   */
  function padPress(name, fresh = true) {
    if (!readyState) return;
    setInput('pad', true);
    finishEntrances();
    if (fresh) emit('press', { kind: 'pad' });
    const dir = { DPadUp: -1, DPadLeft: -1, DPadDown: 1, DPadRight: 1 }[name];
    if (dir) { nav(dir); return; }
    if (name === 'A' && document.activeElement && document.activeElement.closest('.wo-frame')) document.activeElement.click();
    if (PAD_EVENTS[name]) emit(PAD_EVENTS[name], { button: name, dir: name === 'LB' || name === 'LT' ? -1 : 1 });
  }
  WO.pad = { press: (name) => padPress(name), buttons: PAD };
  /** Polls the Gamepad API each frame: any press or a stick past main.gd's switch threshold sets
   *  "pad" and fires one wo:press; D-pad and stick move focus with the timing.input-repeat delay and
   *  rate; every other button goes through padPress once per press (LT and RT repeat). A held A
   *  on a [data-wo-hold] control fills it (holdInput). */
  function padLoop() {
    if (!window.isSecureContext || !navigator.getGamepads) return;
    const held = {};
    let threshold, was = false;
    try { threshold = Number(today.match('main.gd', /JoypadMotion and absf\(event\.axis_value\) > ([\d.]+)/)); } catch (e) { problem(e.message); return; }
    const step = (now) => {
      let anyPad = false;
      for (const pad of navigator.getGamepads()) {
        if (!pad) continue;
        const pressed = (i) => pad.buttons[i] && pad.buttons[i].pressed;
        const ax = pad.axes[0] || 0, ay = pad.axes[1] || 0;
        const any = pad.buttons.some((b) => b.pressed) || Math.abs(ax) > threshold || Math.abs(ay) > threshold;
        anyPad = anyPad || any;
        if (any && readyState && !was) { setInput('pad', true); finishEntrances(); emit('press', { kind: 'pad' }); }
        const dirs = { DPadUp: pressed(PAD.DPadUp) || ay < -threshold, DPadDown: pressed(PAD.DPadDown) || ay > threshold, DPadLeft: pressed(PAD.DPadLeft) || ax < -threshold, DPadRight: pressed(PAD.DPadRight) || ax > threshold };
        for (const [name, on] of Object.entries(dirs)) repeat(held, name, on, now, () => padPress(name, false));
        for (const [name, i] of Object.entries(PAD)) {
          if (name.startsWith('DPad')) continue;
          repeat(held, name, pressed(i), now, () => padPress(name, false), name !== 'LT' && name !== 'RT');
        }
        holdInput(document.activeElement, pressed(PAD.A), 'pad');
      }
      was = anyPad;
      requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }
  /** Held-input repeat (4.5: pads send no echo): fires on press, then after the repeat delay at
   *  the repeat rate while [on]; [once] fires only on the press. */
  function repeat(held, key, on, now, fire, once) {
    if (!on) { delete held[key]; return; }
    if (!held[key]) { held[key] = { next: now + num('timing.input-repeat.delay') }; fire(); return; }
    if (once) return;
    if (now >= held[key].next) { held[key].next = now + 1000 / num('timing.input-repeat.rate'); fire(); }
  }

  // ---------------------------------------------------------------------------------------------
  // 10. Bindings and glyphs (brief 4.2, 4.4)
  // ---------------------------------------------------------------------------------------------

  /** Godot key and pad enum names to glyph names. These are the engine's names, not game values. */
  const KEY_NAMES = { KEY_ESCAPE: 'Esc', KEY_ENTER: 'Enter', KEY_SPACE: 'Space', KEY_TAB: 'Tab', KEY_LEFT: '←', KEY_RIGHT: '→', KEY_UP: '↑', KEY_DOWN: '↓' };
  const JOY_NAMES = { JOY_BUTTON_A: 'A', JOY_BUTTON_B: 'B', JOY_BUTTON_X: 'X', JOY_BUTTON_Y: 'Y', JOY_BUTTON_START: 'Menu', JOY_BUTTON_BACK: 'View', JOY_BUTTON_LEFT_SHOULDER: 'LB', JOY_BUTTON_RIGHT_SHOULDER: 'RB', JOY_BUTTON_DPAD_LEFT: 'DPadLeft', JOY_BUTTON_DPAD_RIGHT: 'DPadRight', JOY_BUTTON_DPAD_UP: 'DPadUp', JOY_BUTTON_DPAD_DOWN: 'DPadDown' };
  /** Godot's built-in ui_accept and ui_cancel keys (engine defaults, no file in the project). */
  const ENGINE_UI = { ui_accept: { keys: ['Enter', 'Space'], pad: [] }, ui_cancel: { keys: ['Esc'], pad: [] } };
  /** Actions the brief adds that the build does not have yet (4.2, 4.7 step 1): proposals. */
  const PROPOSED_ACTIONS = { tab_prev: { keys: [], pad: ['LB'] }, tab_next: { keys: [], pad: ['RB'] }, page_up: { keys: [], pad: ['LT'] }, page_down: { keys: [], pad: ['RT'] }, objective: { keys: ['Tab'], pad: ['View'] } };
  /**
   * The bindings, read from main.gd's _install_inputs (the build's one home for them), plus the
   * engine's ui_* defaults and the brief's proposed actions: {action: {keys: [...], pad: [...]}}.
   * [scope] is an element: remaps on it or an ancestor (data-wo-bind) apply, after the URL's.
   */
  function bindings(scope) {
    const text = files[SOURCES['main.gd']];
    const body = (text.match(/func _install_inputs\(\) -> void:\n((?:\t.*\n)+)/) || [])[1];
    if (!body) throw new Error('main.gd has no _install_inputs');
    const b = JSON.parse(JSON.stringify(ENGINE_UI));
    for (const m of body.matchAll(/_add_action\(&"(\w+)", (KEY_\w+)(?:, (KEY_\w+))?\)/g)) {
      b[m[1]] = b[m[1]] || { keys: [], pad: [] };
      for (const k of [m[2], m[3]].filter(Boolean)) b[m[1]].keys.push(KEY_NAMES[k] || k.replace('KEY_', ''));
    }
    for (const m of body.matchAll(/_add_joy_button\(&"(\w+)", (JOY_BUTTON_\w+)\)/g)) {
      b[m[1]] = b[m[1]] || { keys: [], pad: [] };
      b[m[1]].pad.push(JOY_NAMES[m[2]] || m[2]);
    }
    // The stick: _add_joy_axis binds the left stick's X axis (its body sets JOY_AXIS_LEFT_X), drawn as LS.
    const axisHelper = (text.match(/func _add_joy_axis\([^)]*\)[^\n]*\n((?:\t.*\n)+)/) || [])[1] || '';
    if (/JOY_AXIS_LEFT_X/.test(axisHelper)) {
      for (const m of body.matchAll(/_add_joy_axis\(&"(\w+)", -?[\d.]+\)/g)) {
        b[m[1]] = b[m[1]] || { keys: [], pad: [] };
        if (!b[m[1]].pad.includes('LS')) b[m[1]].pad.push('LS');
      }
    }
    // Copies, so a remap below never edits the PROPOSED_ACTIONS constant.
    for (const [k, v] of Object.entries(PROPOSED_ACTIONS)) b[k] = b[k] || JSON.parse(JSON.stringify(v));
    // Remaps (4.6; XAG 107: a remap updates every prompt and controller map): the page's ?bind=,
    // then the nearest data-wo-bind around [scope]. "key:F" sets the key, anything else the pad.
    const scoped = scope && scope.closest ? scope.closest('[data-wo-bind]') : null;
    for (const [action, to] of parseRemaps(url.get('bind')).concat(parseRemaps(scoped && scoped.dataset.woBind))) {
      if (!b[action]) { problem('a remap names an unknown action: ' + action); continue; }
      if (to.startsWith('key:')) b[action].keys = [to.slice(4)];
      else b[action].pad = [to];
    }
    return b;
  }
  /** A remap list, "interact=RT, choice_1=key:F" (?bind= or data-wo-bind), as [[action, input]]. */
  function parseRemaps(s) {
    return (s || '').split(/[,;]/).map((p) => p.trim()).filter(Boolean).map((p) => p.split('=').map((x) => x.trim()));
  }
  WO.bindings = (scope) => bindings(scope);

  /**
   * SVG glyphs, drawn once here (brief 4.4: no glyph art in the repo until Q12). [name] is an Xbox
   * name (A B X Y LB RB LT RT View Menu Guide DPad DPadUp DPadDown DPadLeft DPadRight LS RS),
   * "key:<label>" for a keycap or "mouse:left|right". Drawn in currentColor only (no new colours).
   * "mark:wolf" and "mark:engineer" are the speaker marks (decision, November 9: name tab, colour
   * and a small mark). Geometry is in a 100-unit-tall box; the letter is 100 / the Body line height, so with the
   * glyph as tall as a Body line (wo.css) every letter in every glyph is exactly the Body size
   * (4.4, XAG101: glyph letters meet the body minimum); shapes widen to fit longer labels.
   */
  function glyph(name) {
    const lh = num('type.body.line-height');
    const H = 100, fs = H / lh, sw = 7;
    const text = (t, x, y, size = fs) => h('svg:text', { x, y, 'text-anchor': 'middle', 'dominant-baseline': 'central', 'font-size': fmt(size, 2), class: 'wo-glyph-text' }, t);
    let w = H, parts = [];
    const ring = (r) => h('svg:circle', { cx: w / 2, cy: H / 2, r, fill: 'none', stroke: 'currentColor', 'stroke-width': sw });
    if (/^(A|B|X|Y)$/.test(name)) parts = [ring(H / 2 - sw), text(name, w / 2, H / 2 + 2)];
    else if (/^(LB|RB)$/.test(name)) {
      w = H * 1.8;
      parts = [h('svg:path', { d: `M${sw} ${H - sw} L${sw} ${H * 0.42} Q${sw} ${sw} ${H * 0.4} ${sw} L${w - H * 0.4} ${sw} Q${w - sw} ${sw} ${w - sw} ${H * 0.42} L${w - sw} ${H - sw} Z`, fill: 'none', stroke: 'currentColor', 'stroke-width': sw, 'stroke-linejoin': 'round' }), text(name, w / 2, H * 0.58)];
    } else if (/^(LT|RT)$/.test(name)) {
      w = H * 1.6;
      parts = [h('svg:path', { d: `M${sw} ${H - sw} L${sw} ${H * 0.36} Q${w / 2} ${-H * 0.12} ${w - sw} ${H * 0.36} L${w - sw} ${H - sw} Z`, fill: 'none', stroke: 'currentColor', 'stroke-width': sw, 'stroke-linejoin': 'round' }), text(name, w / 2, H * 0.62)];
    } else if (name === 'View') {
      parts = [ring(H / 2 - sw), h('svg:rect', { x: 28, y: 30, width: 30, height: 26, rx: 4, fill: 'none', stroke: 'currentColor', 'stroke-width': 6 }), h('svg:rect', { x: 42, y: 44, width: 30, height: 26, rx: 4, fill: 'currentColor' })];
    } else if (name === 'Guide') {
      // The logo button, drawn generic (a ring in a ring): the Xbox logo is Microsoft's trademark.
      parts = [ring(H / 2 - sw), h('svg:circle', { cx: w / 2, cy: H / 2, r: H * 0.18, fill: 'none', stroke: 'currentColor', 'stroke-width': sw })];
    } else if (name === 'Menu') {
      parts = [ring(H / 2 - sw)].concat([36, 50, 64].map((y) => h('svg:rect', { x: 29, y: y - 3.5, width: 42, height: 7, rx: 3, fill: 'currentColor' })));
    } else if (/^DPad/.test(name)) {
      const arm = name.slice(4).toLowerCase();
      const a = H * 0.34, c = H / 2;
      parts = [h('svg:path', { d: `M${c - a / 2} ${sw} h${a} v${c - a / 2 - sw} h${c - a / 2 - sw} v${a} h${-(c - a / 2 - sw)} v${c - a / 2 - sw} h${-a} v${-(c - a / 2 - sw)} h${-(c - a / 2 - sw)} v${-a} h${c - a / 2 - sw} Z`, fill: 'none', stroke: 'currentColor', 'stroke-width': sw, 'stroke-linejoin': 'round' })];
      const at = { up: [c, sw + a / 2], down: [c, H - sw - a / 2], left: [sw + a / 2, c], right: [H - sw - a / 2, c] }[arm];
      if (at) parts.push(h('svg:circle', { cx: at[0], cy: at[1], r: a * 0.32, fill: 'currentColor' }));
    } else if (/^(LS|RS)$/.test(name)) {
      // A stick: a ridged ring (the thumb grip) around its side letter.
      parts = [h('svg:circle', { cx: w / 2, cy: H / 2, r: H / 2 - sw, fill: 'none', stroke: 'currentColor', 'stroke-width': sw, 'stroke-dasharray': '6 4' }), text(name[0], w / 2, H / 2 + 2)];
    } else if (name.startsWith('key:')) {
      const label = name.slice(4);
      w = Math.max(H, label.length * fs * 0.66 + H * 0.5);
      parts = [h('svg:rect', { x: sw / 2 + 2, y: sw / 2 + 2, width: w - sw - 4, height: H - sw - 4, rx: 16, fill: 'none', stroke: 'currentColor', 'stroke-width': sw }), h('svg:line', { x1: 16, y1: H - 18, x2: w - 16, y2: H - 18, stroke: 'currentColor', 'stroke-width': 3, opacity: 0.5 }), text(label, w / 2, H * 0.47)];
    } else if (name.startsWith('mouse:')) {
      const right = name.endsWith('right');
      w = H * 0.72;
      parts = [h('svg:rect', { x: sw, y: sw, width: w - 2 * sw, height: H - 2 * sw, rx: (w - 2 * sw) / 2, fill: 'none', stroke: 'currentColor', 'stroke-width': sw }),
        h('svg:line', { x1: w / 2, y1: sw, x2: w / 2, y2: H * 0.42, stroke: 'currentColor', 'stroke-width': sw * 0.6 }),
        h('svg:path', { d: right ? `M${w / 2} ${sw} A ${(w - 2 * sw) / 2} ${(w - 2 * sw) / 2} 0 0 1 ${w - sw} ${w / 2} L${w - sw} ${H * 0.42} L${w / 2} ${H * 0.42} Z` : `M${w / 2} ${sw} A ${(w - 2 * sw) / 2} ${(w - 2 * sw) / 2} 0 0 0 ${sw} ${w / 2} L${sw} ${H * 0.42} L${w / 2} ${H * 0.42} Z`, fill: 'currentColor' })];
    } else if (name === 'mark:wolf') {
      // WOLF's mark: his cyan eye (the one light painted on him, wolf_lights.gd), as an almond.
      w = H * 1.4;
      parts = [h('svg:path', { d: `M${sw} ${H / 2} Q${w / 2} ${sw - 6} ${w - sw} ${H / 2} Q${w / 2} ${H - sw + 6} ${sw} ${H / 2} Z`, fill: 'none', stroke: 'currentColor', 'stroke-width': sw }), h('svg:circle', { cx: w / 2, cy: H / 2, r: H * 0.2, fill: 'currentColor' })];
    } else if (name === 'mark:hint') {
      // A system hint's mark: a terminal prompt (chevron and cursor bar), so the line reads as the
      // game's own and not a speaker's (6.3: hints use the same box with a terminal mark).
      w = H * 1.1;
      parts = [h('svg:path', { d: `M${sw * 2} ${H * 0.24} L${w * 0.46} ${H / 2} L${sw * 2} ${H * 0.76}`, fill: 'none', stroke: 'currentColor', 'stroke-width': sw * 1.6, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }),
        h('svg:rect', { x: w * 0.54, y: H * 0.68, width: w * 0.4, height: sw * 1.6, rx: 2, fill: 'currentColor' })];
    } else if (name === 'mark:engineer') {
      // The engineer's mark: a clip-on ID badge (slot, photo square, two text lines).
      w = H * 0.78;
      parts = [h('svg:rect', { x: sw, y: sw * 2, width: w - 2 * sw, height: H - 3 * sw, rx: 10, fill: 'none', stroke: 'currentColor', 'stroke-width': sw }),
        h('svg:rect', { x: w / 2 - 12, y: sw * 2 + 8, width: 24, height: 6, rx: 3, fill: 'currentColor' }),
        h('svg:rect', { x: w / 2 - 14, y: H * 0.36, width: 28, height: 24, rx: 4, fill: 'currentColor' }),
        h('svg:rect', { x: sw + 10, y: H * 0.7, width: w - 2 * sw - 20, height: 5, fill: 'currentColor' }),
        h('svg:rect', { x: sw + 10, y: H * 0.8, width: (w - 2 * sw - 20) * 0.6, height: 5, fill: 'currentColor' })];
    } else throw new Error('no glyph named ' + name);
    const svg = h('svg:svg', { viewBox: `0 0 ${fmt(w)} ${H}`, class: 'wo-glyph-svg', role: 'img', 'aria-label': name.replace(/^\w+:/, '') }, ...parts);
    svg.dataset.aspect = fmt(w / H, 4);
    svg.style.setProperty('--wo-glyph-aspect', fmt(w / H, 4));
    return svg;
  }
  /** The glyph names for [action] under input [mode]: [] on touch (the control is the button).
   *  [scope] is the element asking (its data-wo-bind remaps apply); [all] gives every binding of
   *  that input class, not only the first (a CONTROLS row shows D-pad left and the stick). */
  function glyphsFor(action, mode, scope, all) {
    if (mode === 'touch') return [];
    const b = bindings(scope)[action];
    if (!b) throw new Error('no binding for action ' + action);
    const list = mode === 'pad' ? b.pad : b.keys.map((k) => 'key:' + k);
    return all ? list : list.slice(0, 1);
  }
  /**
   * Fills every [data-wo-glyph] element under [root]. Its value is an action name ("interact",
   * "ui_accept", "tab_prev") or a fixed glyph ("pad:A", "key:E", "mouse:left"). The input class
   * is the element's data-wo-glyph-input ("pad" or "keyboard": a controller or keyboard column
   * whatever the last input), else its frame's (or the page's). data-wo-glyph-all shows every
   * binding. An element with no glyph for the input is hidden.
   */
  function renderGlyphs(root) {
    for (const el of root.querySelectorAll('[data-wo-glyph]')) {
      const spec = el.dataset.woGlyph;
      const frame = el.closest('.wo-frame');
      const mode = el.dataset.woGlyphInput || (frame && frame.dataset.input) || input.mode || 'keyboard';
      let names;
      try {
        names = spec.startsWith('pad:') ? [spec.slice(4)] : spec.includes(':') ? [spec] : glyphsFor(spec, mode, el, el.hasAttribute('data-wo-glyph-all'));
        el.replaceChildren(...names.map(glyph));
      } catch (e) { problem(e.message); names = []; }
      el.classList.add('wo-glyph');
      el.hidden = names.length === 0;
    }
  }
  WO.glyph = { draw: glyph, for: glyphsFor, render: renderGlyphs };

  // ---------------------------------------------------------------------------------------------
  // 10b. Controller map (brief 4.2, 7.3 M11; XAG 107: remaps update controller maps)
  // ---------------------------------------------------------------------------------------------

  /** The pad drawing's box in drawing units (like a glyph's 100-unit box; not UI values). */
  const PAD_BOX = { w: 400, h: 260 };
  /**
   * The Xbox pad drawing's geometry in PAD_BOX units. Each button has its centre (x, y), its
   * shape and the side its callout takes: "left" and "right" columns beside the pad, "top" above
   * it. Only the buttons Microsoft guarantees on every handheld are drawn (4.1); stick clicks,
   * paddles, M1/M2 and gyro have no spot, so nothing can be placed on them. A trigger sits half
   * behind its bumper (drawn first, so the bumper covers its foot), as on the real pad.
   * [lean] is the slope a leader takes from its button outwards (units down per unit across;
   * default 0: level). X is boxed in by Y, B and A, so from the right it is reachable only
   * through the gap between B and A: a leader dropping 1 unit per 3 passes that gap and clears
   * both by about 4 units (centres 28 units apart, 12-unit radius plus half the 3-unit stroke).
   * A and the right stick lie further down-left, so their leaders drop 1 per 3 as well: the three
   * lower leaders run parallel and can never cross, whichever of them a context uses.
   */
  const PAD_SPOTS = {
    LT: { x: 96, y: 20, shape: 'trigger', side: 'left' }, LB: { x: 100, y: 38, shape: 'bumper', side: 'left' },
    LS: { x: 118, y: 102, shape: 'stick', side: 'left' }, DPad: { x: 156, y: 158, shape: 'dpad', side: 'left' },
    View: { x: 172, y: 102, shape: 'small', side: 'top' }, Guide: { x: 200, y: 72, shape: 'guide', side: 'top' }, Menu: { x: 228, y: 102, shape: 'small', side: 'top' },
    RT: { x: 304, y: 20, shape: 'trigger', side: 'right' }, RB: { x: 300, y: 38, shape: 'bumper', side: 'right' },
    Y: { x: 300, y: 74, shape: 'face', side: 'right' }, X: { x: 272, y: 102, shape: 'face', side: 'right', lean: 1 / 3 },
    B: { x: 328, y: 102, shape: 'face', side: 'right' }, A: { x: 300, y: 130, shape: 'face', side: 'right', lean: 1 / 3 },
    RS: { x: 244, y: 158, shape: 'stick', side: 'right', lean: 1 / 3 },
  };
  /** The pad body outline in the same box: grips, a straight bottom between them, a shallow top. */
  const PAD_BODY = 'M80 52 C120 36 160 40 200 40 C240 40 280 36 320 52 C352 64 372 100 384 150 C396 200 398 238 372 250 C350 260 330 246 314 224 C300 206 284 196 262 196 L138 196 C116 196 100 206 86 224 C70 246 50 260 28 250 C2 238 4 200 16 150 C28 100 48 64 80 52 Z';

  /** The Xbox pad drawing: the body and one <g class="wo-pad-spot" data-button> per button,
   *  stroked in currentColor (wo.css colours them). */
  function padDrawing() {
    const sw = 3;
    const spot = (name) => {
      const s = PAD_SPOTS[name];
      const g = h('svg:g', { class: 'wo-pad-spot', 'data-button': name });
      if (s.shape === 'face') g.append(h('svg:circle', { cx: s.x, cy: s.y, r: 12, 'stroke-width': sw }));
      else if (s.shape === 'small') g.append(h('svg:circle', { cx: s.x, cy: s.y, r: 8, 'stroke-width': sw }));
      else if (s.shape === 'guide') g.append(h('svg:circle', { cx: s.x, cy: s.y, r: 14, 'stroke-width': sw }));
      else if (s.shape === 'stick') g.append(h('svg:circle', { cx: s.x, cy: s.y, r: 24, 'stroke-width': sw }), h('svg:circle', { cx: s.x, cy: s.y, r: 14, 'stroke-width': sw }));
      else if (s.shape === 'bumper') g.append(h('svg:rect', { x: s.x - 36, y: s.y - 7, width: 72, height: 14, rx: 7, 'stroke-width': sw }));
      else if (s.shape === 'trigger') g.append(h('svg:rect', { x: s.x - 22, y: s.y - 14, width: 44, height: 28, rx: 9, 'stroke-width': sw }));
      else if (s.shape === 'dpad') {
        const a = 15, c = 30;
        g.append(h('svg:path', { d: `M${s.x - a / 2} ${s.y - c} h${a} v${c - a / 2} h${c - a / 2} v${a} h${-(c - a / 2)} v${c - a / 2} h${-a} v${-(c - a / 2)} h${-(c - a / 2)} v${-a} h${c - a / 2} Z`, 'stroke-width': sw, 'stroke-linejoin': 'round' }));
      }
      return g;
    };
    return h('svg:svg', { class: 'wo-padmap-pad', viewBox: `0 0 ${PAD_BOX.w} ${PAD_BOX.h}`, role: 'img', 'aria-label': 'Xbox controller' },
      h('svg:path', { class: 'wo-pad-body', d: PAD_BODY, 'stroke-width': sw }), ...Object.keys(PAD_SPOTS).map(spot));
  }

  /**
   * Fills every [data-wo-padmap="<source selector>"] with the controller map of one context
   * (the nearest data-wo-padmap-context): the pad drawing, each of the source's callouts for that
   * context beside its button with a leader line, and one line of the buttons with nothing to do
   * there (its words are the element's data-wo-padmap-free).
   * - Source: cells [data-wo-context~=context] holding .wo-callout elements, each with
   *   data-wo-button (one or two Xbox button names) and optionally data-wo-action. A callout with an
   *   action sits on that action's current pad binding (bindings() with remaps), so a remap moves
   *   it (XAG 107). A .is-none callout is a placeholder: it never holds a button.
   * - Two callouts on one button get .is-clash (4.6: never bind two actions silently).
   * - A .is-system callout (a button the system keeps: the Guide button, 4.2) goes in the bottom
   *   line after the unused buttons, with no leader: the game never reads it. Any other callout
   *   on the Guide button is an error.
   * - Side callouts sit level with their buttons (stackColumn), so leaders cross nothing.
   * - [data-wo-padmap-name] elements in the same frame get the context's name from the source's
   *   [data-wo-context-name] header.
   * Side effects: replaces the element's children; sets data-wo-slot and data-wo-button-now on each
   * placed callout, and style.top on side callouts. Positions and leaders are in the map's own
   * layout px, so they stay right however the frame is scaled.
   */
  function renderPadmaps(root = document) {
    for (const el of root.querySelectorAll('[data-wo-padmap]')) {
      try { renderPadmap(el); } catch (e) { problem('controller map: ' + e.message); }
    }
  }
  function renderPadmap(el) {
    const src = document.querySelector(el.dataset.woPadmap);
    if (!src) throw new Error('no source ' + el.dataset.woPadmap);
    const holder = el.closest('[data-wo-padmap-context]');
    const ctx = holder ? holder.dataset.woPadmapContext : '';
    const head = src.querySelector(`[data-wo-context-name="${ctx}"]`);
    if (!head) throw new Error('the source has no context "' + ctx + '"');
    (el.closest('.wo-frame') || document).querySelectorAll('[data-wo-padmap-name]').forEach((n) => { n.textContent = head.textContent.trim(); });
    const b = bindings(el);
    const placed = [];
    for (const cell of src.querySelectorAll('[data-wo-context]')) {
      if (!cell.dataset.woContext.split(/\s+/).includes(ctx)) continue;
      for (const c of cell.querySelectorAll('.wo-callout')) {
        let inputs = c.dataset.woButton.split(/\s+/);
        const action = c.dataset.woAction;
        if (action) {
          if (!b[action]) throw new Error('no binding for action ' + action);
          if (b[action].pad.length) inputs = [b[action].pad[0]];
        }
        for (const i of inputs) if (!PAD_SPOTS[i]) throw new Error('"' + i + '" is not on the pad (4.1: no stick clicks, paddles, M1/M2 or gyro)');
        const system = c.classList.contains('is-system');
        if (!system && inputs.includes('Guide')) throw new Error('the Guide button is the system\'s (4.2): only a .is-system callout may name it');
        placed.push({ src: c, inputs, none: c.classList.contains('is-none'), system });
      }
    }
    const real = placed.filter((p) => !p.none && !p.system);
    const system = placed.filter((p) => p.system);
    const held = {};
    for (const p of real) for (const i of p.inputs) (held[i] = held[i] || []).push(p);
    const free = Object.keys(PAD_SPOTS).filter((i) => i !== 'Guide' && !held[i]);
    // One callout node per callout: its glyphs re-pointed to the buttons it holds now.
    const node = (p) => {
      const n = p.src.cloneNode(true);
      n.querySelectorAll('[data-wo-glyph]').forEach((g) => g.remove());
      n.prepend(...p.inputs.map((i) => h('span', { 'data-wo-glyph': 'pad:' + i })));
      n.dataset.woButtonNow = p.inputs.join(' ');
      if (p.inputs.some((i) => held[i] && held[i].length > 1)) n.classList.add('is-clash');
      return n;
    };
    const lead = (p) => PAD_SPOTS[p.inputs[0]];
    const top = h('div', { class: 'wo-padmap-top' }, h('div', { class: 'wo-padmap-top-l' }), h('div', { class: 'wo-padmap-top-r' }));
    const cols = { top, left: h('div', { class: 'wo-padmap-left' }), right: h('div', { class: 'wo-padmap-right' }) };
    // Reading order: top callouts left to right, side callouts top to bottom.
    const order = { top: (p) => lead(p).x, left: (p) => Math.min(...p.inputs.map((i) => PAD_SPOTS[i].y)), right: (p) => lead(p).y * 1000 + lead(p).x };
    for (const side of Object.keys(cols)) {
      real.filter((p) => lead(p).side === side).sort((a, c) => order[side](a) - order[side](c)).forEach((p) => {
        const n = node(p);
        n.dataset.woSlot = side;
        // Above the pad, a callout for a button left of the centre line goes in the left half
        // (glyph nearest the centre), the others in the right half, so each leader runs almost
        // straight down instead of across the other leaders.
        (side === 'top' ? top.children[lead(p).x < PAD_BOX.w / 2 ? 0 : 1] : cols[side]).append(n);
      });
    }
    const drawing = padDrawing();
    // A button the game uses lights up; one the system keeps (the Guide button) is marked as such.
    for (const i of Object.keys(held)) drawing.querySelector(`[data-button="${i}"]`).classList.add('is-used');
    for (const p of system) for (const i of p.inputs) drawing.querySelector(`[data-button="${i}"]`).classList.add('is-system');
    const freeLine = h('div', { class: 'wo-padmap-free' }, h('span', { class: 'wo-padmap-free-label' }, el.dataset.woPadmapFree || ''), ...free.map((i) => h('span', { 'data-wo-glyph': 'pad:' + i, 'data-wo-free': i })),
      ...system.map((p) => { const n = node(p); n.dataset.woSlot = 'system'; return n; }));
    const lines = h('svg:svg', { class: 'wo-padmap-lines', 'aria-hidden': 'true' });
    el.replaceChildren(cols.top, cols.left, h('div', { class: 'wo-padmap-mid' }, drawing), cols.right, freeLine, lines);
    renderGlyphs(el);
    const geo = mapGeometry(el);
    if (!geo) return;
    stackColumn(cols.left, geo, 'left');
    stackColumn(cols.right, geo, 'right');
    drawLeaders(el, lines, geo);
  }
  /**
   * Layout facts of a rendered map, or null while it is not laid out (a hidden frame): [k] the
   * map's on-screen scale, [local(x, y)] client px to map layout px, [spot(name)] a button's
   * centre in map layout px.
   */
  function mapGeometry(el) {
    const box = el.getBoundingClientRect();
    if (!el.offsetWidth || !box.width) return null;
    const k = box.width / el.offsetWidth;
    const local = (x, y) => [(x - box.left) / k, (y - box.top) / k];
    const spot = (name) => { const r = el.querySelector(`.wo-pad-spot[data-button="${name}"]`).getBoundingClientRect(); return local(r.left + r.width / 2, r.top + r.height / 2); };
    return { el, k, local, spot };
  }
  /**
   * Places the callouts of one side column ([side] "left" or "right") level with their buttons,
   * so each leader runs flat and crosses no other button: a callout's wanted centre is the mean of
   * its buttons' centres, moved by a button's [lean] times the run to the column's inner edge.
   * Callouts that would overlap are pushed apart by the column's row gap (top-down), then pulled
   * back inside the column (bottom-up). Side effects: sets each callout's style.top in the
   * column's layout px (wo.css positions side callouts absolutely).
   */
  function stackColumn(col, geo, side) {
    const cr = col.getBoundingClientRect();
    const [colX, colY] = geo.local(side === 'left' ? cr.right : cr.left, cr.top);
    const gap = parseFloat(getComputedStyle(col).rowGap) || 0;
    const items = [...col.children].map((n) => {
      const ys = n.dataset.woButtonNow.split(' ').map((name) => {
        const [sx, sy] = geo.spot(name);
        return sy + (PAD_SPOTS[name].lean || 0) * Math.abs(colX - sx);
      });
      return { n, h: n.offsetHeight, want: ys.reduce((a, y) => a + y, 0) / ys.length - colY };
    }).sort((a, c) => a.want - c.want);
    let y = 0;
    for (const it of items) { it.top = Math.max(it.want - it.h / 2, y); y = it.top + it.h + gap; }
    let limit = col.clientHeight;
    for (const it of items.slice().reverse()) { it.top = Math.min(it.top, limit - it.h); limit = it.top - gap; }
    for (const it of items) it.n.style.top = Math.max(0, it.top) + 'px';
  }
  /** Draws one leader per placed callout, from its first glyph's inner edge to its button's
   *  centre, with a dot on that centre, in the map's layout px. */
  function drawLeaders(el, lines, geo) {
    lines.setAttribute('viewBox', `0 0 ${el.offsetWidth} ${el.offsetHeight}`);
    for (const c of el.querySelectorAll('.wo-callout[data-wo-slot]:not([data-wo-slot="system"])')) {
      const g = c.querySelector('[data-wo-glyph]');
      if (!g) continue;
      const gr = g.getBoundingClientRect();
      const side = c.dataset.woSlot;
      const [ax, ay] = side === 'left' ? geo.local(gr.right, gr.top + gr.height / 2) : side === 'right' ? geo.local(gr.left, gr.top + gr.height / 2) : geo.local(gr.left + gr.width / 2, gr.bottom);
      for (const name of c.dataset.woButtonNow.split(' ')) {
        const [sx, sy] = geo.spot(name);
        lines.append(h('svg:line', { x1: fmt(ax, 2), y1: fmt(ay, 2), x2: fmt(sx, 2), y2: fmt(sy, 2), 'stroke-width': 1 }), h('svg:circle', { cx: fmt(sx, 2), cy: fmt(sy, 2), r: 2 }));
      }
    }
  }
  /** A click on [data-wo-padmap-cycle] shows the next context of its frame's map (the in-game
   *  selector; D-pad left and right do the same in the game). */
  addEventListener('click', (e) => {
    const btn = e.target.closest && e.target.closest('[data-wo-padmap-cycle]');
    if (!btn || !readyState) return;
    const holder = btn.closest('[data-wo-padmap-context]');
    const map = holder && holder.querySelector('[data-wo-padmap]');
    const src = map && document.querySelector(map.dataset.woPadmap);
    if (!src) return;
    const names = [...src.querySelectorAll('[data-wo-context-name]')].map((x) => x.dataset.woContextName);
    holder.dataset.woPadmapContext = names[(names.indexOf(holder.dataset.woPadmapContext) + 1) % names.length];
    renderPadmap(map);
  });
  WO.padmap = { render: renderPadmaps, spots: PAD_SPOTS };

  // ---------------------------------------------------------------------------------------------
  // 11. Frames (brief 7.1 Frame): a device screen with the game canvas scaled inside it
  // ---------------------------------------------------------------------------------------------

  /** Every mounted frame: {host: .mk-device, screen, canvas: .wo-frame, d, P}. */
  const frames = [];
  /** Pages fetched for "page.html#id" templates, parsed once (cache "no-store", like every home). */
  const includePages = new Map();
  /** The <template> element [ref] names: "id" on this page or "page.html#id" on another mockup
   *  page. Throws when it is missing (the problem list shows it). */
  async function templateFor(ref) {
    const i = ref.indexOf('#');
    if (i < 0) { const t = document.getElementById(ref); if (!t) throw new Error('no <template id="' + ref + '">'); return t; }
    const page = ref.slice(0, i), id = ref.slice(i + 1);
    if (!includePages.has(page)) {
      includePages.set(page, fetch(page, { cache: 'no-store' }).then((r) => { if (!r.ok) throw new Error('HTTP ' + r.status + ' ' + page); return r.text(); })
        .then((t) => new DOMParser().parseFromString(t, 'text/html')));
    }
    const tpl = (await includePages.get(page)).getElementById(id);
    if (!tpl) throw new Error(page + ' has no <template id="' + id + '">');
    return tpl;
  }
  /**
   * Fills every [data-wo-template] element once, before frames mount, so pages share markup instead
   * of copying it (brief 7.1: no copies).
   * - The value is a space-separated list of refs, appended in order: "a b" stacks the world of a and
   *   the card of b in one frame (M07). A ref is "id" (a <template> on this page) or "page.html#id"
   *   (another page's, so M02 and M04 show M03's real title).
   * - Any element may carry it, not only a frame canvas. Filled copies are searched again, so
   *   templates may nest (at most 4 deep: deeper is reported as a loop).
   * - An [autofocus] in a copy becomes [data-wo-autofocus]: a copy never grabs real focus on
   *   insertion (that would scroll the page to it); the frame's current item reads it instead.
   * - A <script type="application/json" data-wo-include-set> child changes this copy only:
   *   {selector: {attribute: value | null}}; null removes the attribute, "class" adds classes, any
   *   other value sets it. A selector that matches nothing is a problem, not a silent miss.
   */
  async function fillTemplates(root = document) {
    for (let depth = 0; ; depth++) {
      const todo = [...root.querySelectorAll('[data-wo-template]')].filter((el) => !el._woFilled);
      if (!todo.length) return;
      if (depth >= 4) { problem('templates nest deeper than 4 (a loop?): ' + todo.map((el) => el.dataset.woTemplate).join(', ')); return; }
      for (const el of todo) {
        el._woFilled = true;
        try {
          for (const ref of el.dataset.woTemplate.split(/\s+/).filter(Boolean)) {
            const frag = document.importNode((await templateFor(ref)).content, true);
            frag.querySelectorAll('[autofocus]').forEach((x) => { x.removeAttribute('autofocus'); x.setAttribute('data-wo-autofocus', ''); });
            el.append(frag);
          }
          const setEl = el.querySelector(':scope > script[data-wo-include-set]');
          for (const [sel, attrs] of Object.entries(setEl ? JSON.parse(setEl.textContent) : {})) {
            const hits = el.querySelectorAll(sel);
            if (!hits.length) { problem('include set: "' + sel + '" matches nothing in ' + el.dataset.woTemplate); continue; }
            for (const x of hits) for (const [a, v] of Object.entries(attrs)) {
              if (v === null) x.removeAttribute(a);
              else if (a === 'class') x.classList.add(...String(v).split(/\s+/).filter(Boolean));
              else x.setAttribute(a, v);
            }
          }
        } catch (e) { problem('template ' + el.dataset.woTemplate + ': ' + e.message); }
      }
    }
  }
  /**
   * Mounts each .mk-device on the page. Markup: <section class="mk-device" data-wo-device="url">
   * <div class="wo-frame">...canvas content in canvas px...</div></section>. data-wo-device is a
   * device name or "url" (the strip's device). The canvas is sized to the device's canvas shape,
   * scaled to the screen and centred (bars outside the 4:3..2.4:1 bounds), and the whole screen
   * is fitted into the host's parent. Safe-area overlays are added per device. Templates are
   * filled before this runs (fillTemplates). data-wo-input on the host pins that one frame's input
   * class (frameInput).
   */
  function mountFrames() {
    for (const host of document.querySelectorAll('.mk-device')) {
      if (host._wo) continue;
      const canvas = host.querySelector(':scope > .wo-frame');
      const screen = h('div', { class: 'mk-screen' });
      host.prepend(screen);
      screen.append(canvas);
      const f = { host, screen, canvas };
      host._wo = f;
      frames.push(f);
      if (fitObserver) fitObserver.observe(host.parentElement);
    }
    layoutFrames();
  }
  /**
   * Places every [data-wo-node="<scene>:<node path>"] element at that Control's rect, in canvas px,
   * inside its DOM parent (which stands for the node's parent): left = anchor_left x parent width +
   * offset_left, width = (anchor_right - anchor_left) x parent width + offset_right - offset_left,
   * the same on y (Godot's anchors and offsets). The scene is a SOURCES name (studio_logo.tscn,
   * main.tscn). Runs after layout, parents before children (document order).
   */
  function placeNodes(root = document) {
    for (const el of root.querySelectorAll('[data-wo-node]')) {
      try {
        const i = el.dataset.woNode.indexOf(':');
        const scene = el.dataset.woNode.slice(0, i), path = el.dataset.woNode.slice(i + 1);
        const a = (k) => today.prop(scene, path, k, 0);
        const r = today.rect(scene, path), pw = el.parentElement.offsetWidth, ph = el.parentElement.offsetHeight;
        Object.assign(el.style, { position: 'absolute', left: a('anchor_left') * pw + r.x + 'px', top: a('anchor_top') * ph + r.y + 'px',
          width: (a('anchor_right') - a('anchor_left')) * pw + r.w + 'px', height: (a('anchor_bottom') - a('anchor_top')) * ph + r.h + 'px' });
      } catch (e) { problem('data-wo-node ' + el.dataset.woNode + ': ' + e.message); }
    }
  }
  /** Lays out every frame for the current tokens, URL and window size. */
  function layoutFrames() {
    for (const f of frames) {
      const name = f.host.dataset.woDevice === 'url' ? url.get('device') || 'desktop' : f.host.dataset.woDevice;
      if (!deviceNames().includes(name)) { problem('unknown device "' + name + '"'); continue; }
      const d = device(name);
      f.d = d;
      const text = Number(url.get('text')) || 0;
      // density.touch-switch (2.3): a desktop frame takes touch density after a real touch, at once
      // or only on the next screen open (a touch already made when this page opened), or never.
      const sw = choice('density.touch-switch');
      const touched = sw === 'immediate' ? input.touched : sw === 'next-screen' ? !!f.touchedAtOpen : false;
      f.P = profile(d, { text, touched });
      const avail = f.host.parentElement.getBoundingClientRect();
      const fit = Math.min(1, avail.width / d.cssW, (f.host.dataset.woFit === 'width' ? Infinity : avail.height / d.cssH) || 1);
      f.fit = fit;
      f.host.style.width = d.cssW * fit + 'px';
      f.host.style.height = d.cssH * fit + 'px';
      f.screen.style.width = d.cssW + 'px';
      f.screen.style.height = d.cssH + 'px';
      f.screen.style.transform = `scale(${fit})`;
      const sh = d.shape;
      f.canvas.style.width = sh.cw + 'px';
      f.canvas.style.height = sh.ch + 'px';
      f.canvas.style.transform = `translate(${sh.barX / d.scale}px, ${sh.barY / d.scale}px) scale(${d.k})`;
      f.host.dataset.profile = d.profile;
      f.canvas.dataset.profile = d.profile;
      f.canvas.dataset.device = name;
      frameVars(f);
      frameInput(f);
      safeOverlay(f);
      const cap = f.host.nextElementSibling && f.host.nextElementSibling.classList.contains('mk-device-cap') ? f.host.nextElementSibling : null;
      if (cap) cap.textContent = `${d.label}: ${d.W}×${d.H}, canvas ${fmt(sh.cw, 1)}×${fmt(sh.ch, 1)} (${sh.mode}), ${d.profile}, TEXT SIZE ${f.P.textSize}%`;
    }
  }
  /** Sets the per-frame profile variables on the canvas (they override the :root ones inside). */
  function frameVars(f) {
    const s = f.canvas.style, P = f.P, d = f.d;
    for (const [r, px] of Object.entries(P.roles)) s.setProperty('--wo-fs-' + r, px + 'px');
    s.setProperty('--wo-glyph-h', P.roles.body * num('type.body.line-height') + 'px');
    s.setProperty('--wo-density', P.density + 'px');
    s.setProperty('--wo-hit-min', P.hitMin + 'px');
    s.setProperty('--wo-hit-margin', P.hitMargin + 'px');
    s.setProperty('--wo-canvas-w', d.shape.cw + 'px');
    s.setProperty('--wo-canvas-h', d.shape.ch + 'px');
    for (const side of ['left', 'right', 'top', 'bottom']) {
      s.setProperty('--wo-edge-' + side, P.edges[side] + 'px');
      s.setProperty('--wo-inset-' + side, d.insets[side] + 'px');
    }
    // Phone USE and PAUSE sizes come from the profile; elsewhere today's scene sizes stand.
    s.setProperty('--wo-touch-use', (P.useSize || today.rect('main.tscn', 'CanvasLayer/TouchControls/Use').h) + 'px');
    s.setProperty('--wo-touch-pause', (P.pauseSize || today.rect('main.tscn', 'CanvasLayer/PauseButton').h) + 'px');
    s.setProperty('--wo-row-ch', langField('en', 'row_characters') + 'ch');
    s.setProperty('--wo-move-zone', num('profile.phone.move-zone') * 100 + '%');
    // Phone targets keep the 8 dp gap between them (2.3: density.gap-phone-dp), so every gap built
    // on --wo-density-gap (answer cards, rows, tabs) is at least that on a phone.
    if (d.profile === 'phone') s.setProperty('--wo-density-gap', Math.max(num('density.gap'), P.hitMargin) + 'px');
    else s.removeProperty('--wo-density-gap');
  }
  /**
   * The input class a frame shows, set as data-input on its canvas: the host's data-wo-input when it
   * pins one ("pad", "keyboard", "mouse", "touch": M10 state 4 is always pad), else the last real
   * input, else its profile's default (4.4). data-ring is "on" for keys and pads, except on a desktop
   * frame before any real input: there focus is held without its ring (6.2 B7: grab_focus(true)),
   * while the glyphs already show keycaps; a handheld leads with the pad, so its ring is on at once.
   */
  function frameInput(f) {
    if (!f.d) return;
    const pin = f.host.dataset.woInput;
    const mode = pin ? (pin === 'mouse' ? 'pointer' : pin) : input.mode || PROFILE_INPUT[f.d.profile];
    f.canvas.dataset.input = mode;
    const real = pin || input.mode || f.d.profile !== 'desktop';
    f.canvas.dataset.ring = (mode === 'keyboard' || mode === 'pad') && real ? 'on' : 'off';
  }
  /** Draws the safe-area and unmeasured-area overlays for a frame (brief 7.1 Frame). */
  function safeOverlay(f) {
    f.screen.querySelectorAll('.mk-safe').forEach((x) => x.remove());
    const d = f.d, k = d.k;
    const band = (cls, x, y, w, hgt, label) => {
      const el = h('div', { class: 'mk-safe ' + cls, text: label });
      Object.assign(el.style, { left: x + 'px', top: y + 'px', width: w + 'px', height: hgt + 'px' });
      f.screen.append(el);
    };
    const cx = d.shape.barX / d.scale, cy = d.shape.barY / d.scale;
    const cw = d.shape.cw * k, ch = d.shape.ch * k;
    if (d.insetsMeasured) {
      if (d.insets.left) band('is-inset', cx, cy, d.insets.left * k, ch, 'safe area');
      if (d.insets.right) band('is-inset', cx + cw - d.insets.right * k, cy, d.insets.right * k, ch, 'safe area');
      if (d.insets.bottom) band('is-inset', cx, cy + ch - d.insets.bottom * k, cw, d.insets.bottom * k, 'safe area');
    } else if (d.profile === 'phone' && !d.android) {
      band('is-unknown is-label', cx, cy, cw, 0, 'safe-area insets: not measured');
    }
    if (d.android) {
      const cut = Number(url.get('cutout')) || 0, edge = Number(url.get('edge')) || 0;
      if (cut) band('is-unknown', cx, cy, cut * k, ch, 'cutout (not measured)');
      if (edge) { band('is-gesture', cx, cy, edge * k, ch, 'back gesture (not measured)'); band('is-gesture', cx + cw - edge * k, cy, edge * k, ch, 'back gesture (not measured)'); }
      if (!cut && !edge) band('is-unknown is-label', cx, cy, cw, 0, 'cutout and back-gesture strip: not measured (?cutout=&edge= in canvas px)');
    }
  }
  WO.frames = frames;

  // ---------------------------------------------------------------------------------------------
  // 11b. Screen behaviour: overlays, answers, tabs, lists, rows, sliders, holds (6.2, 6.3, 3.1)
  // ---------------------------------------------------------------------------------------------

  /** True for a key event whose key is one of [action]'s bound keys (bindings(), remaps included). */
  function keyIs(e, action) {
    const b = bindings(e.target)[action];
    const k = e.key.length === 1 ? e.key.toUpperCase() : e.key === ' ' ? 'Space' : e.key === 'Escape' ? 'Esc' : e.key;
    return !!b && b.keys.includes(k);
  }

  // Overlays (6.2 Pause; 6.7.5 phone interruption) -----------------------------------------------

  /**
   * Opens or closes overlay [el] ([data-wo-overlay]: a pause or a dialog over the screen). Opening
   * shows it, replays its open motion ([data-wo-open], wo.css), focuses its frame's current item and
   * starts its guard ([data-wo-guard]: pointer presses on it are swallowed for
   * timing.resume-card.guard, so the first tap after a return lands on nothing, 6.7.5). Closing hides it.
   */
  function setOverlay(el, open) {
    el.hidden = !open;
    if (!open) return;
    replayOpen(el);
    if (el.hasAttribute('data-wo-guard')) el._woGuardUntil = performance.now() + num('timing.resume-card.guard');
    const c = el.closest('.wo-frame'), cur = currentItem(c);
    if (cur && document.activeElement && document.activeElement.closest('.wo-frame') === c) cur.focus({ preventScroll: true });
  }
  /** Restarts the open motion of [el] and every [data-wo-open] inside it (wo.css .is-opening). */
  function replayOpen(el) {
    for (const x of [el, ...el.querySelectorAll('[data-wo-open]')].filter((y) => y.hasAttribute('data-wo-open'))) {
      x.classList.remove('is-opening');
      void x.offsetWidth;
      x.classList.add('is-opening');
    }
  }
  /** The overlays of the active frame: [open] true gives the shown ones, false the hidden ones. */
  const overlays = (open) => [...((activeFrame() || document).querySelectorAll('[data-wo-overlay]'))].filter((el) => el.hidden !== open);
  /** B or Esc (wo:back) closes the active frame's open list first, then its open overlay. */
  document.addEventListener('wo:back', () => {
    const list = (activeFrame() || document).querySelector('.wo-popup.is-open');
    if (list) { setList(list, false); return; }
    const o = overlays(true);
    if (o.length) setOverlay(o[o.length - 1], false);
  });
  /** The pause key (pause_game: Esc today) and pad Menu toggle the active frame's overlay (4.2). */
  function togglePause() {
    const open = overlays(true), shut = overlays(false);
    if (open.length) setOverlay(open[open.length - 1], false); else if (shut.length) setOverlay(shut[0], true);
  }
  document.addEventListener('wo:menu', togglePause);
  addEventListener('keydown', (e) => {
    if (!readyState || inChrome(e.target) || e.repeat || !keyIs(e, 'pause_game')) return;
    // Esc is also ui_cancel: when it closes an open list or overlay, the wo:back it fires does that.
    if (overlays(true).length || (activeFrame() || document).querySelector('.wo-popup.is-open')) return;
    if (!overlays(false).length) return;
    e.preventDefault();
    togglePause();
  }, true);
  /** A click on [data-wo-close] closes its overlay (RESUME); one on [data-wo-open-overlay] opens the
   *  first overlay of its frame (a PAUSE button). Guarded overlays swallow pointer presses. */
  for (const type of ['pointerdown', 'click']) {
    addEventListener(type, (e) => {
      const o = e.target.closest && e.target.closest('[data-wo-overlay]');
      if (o && o._woGuardUntil && performance.now() < o._woGuardUntil) { e.preventDefault(); e.stopPropagation(); }
    }, true);
  }
  addEventListener('click', (e) => {
    if (!readyState || !e.target.closest) return;
    const close = e.target.closest('[data-wo-close]'), open = e.target.closest('[data-wo-open-overlay]');
    if (close && close.closest('[data-wo-overlay]')) setOverlay(close.closest('[data-wo-overlay]'), false);
    else if (open) { const c = open.closest('.wo-frame'), o = c && c.querySelector('[data-wo-overlay]'); if (o) setOverlay(o, true); }
  });

  // Answer cards (6.3 Choices, 4.2: X and Y answer; D-pad + A, click and tap also work) ---------

  /** Presses answer [n] (1 or 2) of the active frame: focus, the pressed look for
   *  motion.press.duration, then a click, so one path serves X/Y, the 1/2 keys, A and taps. */
  function pickAnswer(n) {
    const el = (activeFrame() || document).querySelector('[data-wo-answer="' + n + '"]');
    if (!el || el.offsetParent === null || el.disabled) return;
    el.focus({ preventScroll: true });
    el.classList.add('is-pressed');
    setTimeout(() => el.classList.remove('is-pressed'), num('motion.press.duration'));
    el.click();
  }
  document.addEventListener('wo:answer', (e) => {
    const b = bindings();
    const n = b.choice_1.pad.includes(e.detail.button) ? 1 : b.choice_2.pad.includes(e.detail.button) ? 2 : 0;
    if (n) pickAnswer(n);
  });
  addEventListener('keydown', (e) => {
    if (!readyState || inChrome(e.target) || e.repeat) return;
    if (keyIs(e, 'choice_1')) pickAnswer(1); else if (keyIs(e, 'choice_2')) pickAnswer(2);
  });

  // Tabs (3.1 step 6: LB and RB, a click or a tap) --------------------------------------------

  /**
   * Selects tab [tab]: aria-selected and tabindex move to it (only the selected tab is a focus
   * stop), the page with the same key (data-wo-tab="x" on the tab, data-wo-page="x" on the page, in
   * the same .wo-settings or frame) shows and the others hide, and the tab strip scrolls so the tab
   * shows whole between the LB and RB glyphs pinned at its ends.
   */
  function selectTab(tab) {
    const bar = tab.closest('.wo-tabs');
    for (const t of bar.querySelectorAll('.wo-tab')) { t.setAttribute('aria-selected', String(t === tab)); t.tabIndex = t === tab ? 0 : -1; }
    const key = tab.dataset.woTab, scope = tab.closest('.wo-settings, .wo-frame') || document;
    if (key) for (const pg of scope.querySelectorAll('[data-wo-page]')) pg.hidden = pg.dataset.woPage !== key;
    tabIntoView(bar, tab);
  }
  /** Scrolls tab strip [bar] (canvas px) so [tab] is whole beside its sticky end glyphs. */
  function tabIntoView(bar, tab) {
    if (bar.scrollWidth <= bar.clientWidth) return;
    const lead = bar.querySelector(':scope > [data-wo-glyph]:first-child'), tail = bar.querySelector(':scope > [data-wo-glyph]:last-child');
    const gap = parseFloat(getComputedStyle(bar).columnGap) || 0;
    const x0 = tab.offsetLeft - (lead ? lead.offsetWidth + gap : 0);
    const x1 = tab.offsetLeft + tab.offsetWidth + (tail ? tail.offsetWidth + gap : 0) - bar.clientWidth;
    if (bar.scrollLeft > x0) bar.scrollLeft = x0; else if (bar.scrollLeft < x1) bar.scrollLeft = x1;
  }
  addEventListener('click', (e) => {
    const tab = readyState && e.target.closest && e.target.closest('.wo-frame .wo-tab');
    if (tab && tab.getAttribute('aria-disabled') !== 'true') selectTab(tab);
  });
  /** LB and RB (wo:tab, detail.dir -1 or 1) step the active frame's tab strip, wrapping and
   *  skipping disabled tabs, and keep focus on the tab strip if it was there. */
  document.addEventListener('wo:tab', (e) => {
    const bar = (activeFrame() || document).querySelector('.wo-tabs');
    if (!bar) return;
    const tabs = [...bar.querySelectorAll('.wo-tab')].filter((t) => t.getAttribute('aria-disabled') !== 'true');
    const i = tabs.findIndex((t) => t.getAttribute('aria-selected') === 'true');
    if (!tabs.length) return;
    const next = tabs[(i + (e.detail && e.detail.dir < 0 ? -1 : 1) + tabs.length) % tabs.length];
    const hadFocus = document.activeElement && document.activeElement.matches('.wo-tab');
    selectTab(next);
    if (hadFocus) next.focus({ preventScroll: true });
  });
  /** Each render: ?tab=<key> selects that tab wherever a strip has it, and every strip shows its
   *  selected tab (a capture of any page is a URL). */
  function syncTabs() {
    const want = url.get('tab');
    for (const bar of document.querySelectorAll('.wo-tabs')) {
      const tab = (want && bar.querySelector('.wo-tab[data-wo-tab="' + want + '"]')) || bar.querySelector('.wo-tab[aria-selected="true"]');
      if (tab) selectTab(tab);
    }
  }

  // Lists (OptionButton popups, 3.1) -------------------------------------------------------------

  /** Opens or closes list [list] (.wo-popup) and sets aria-expanded on its select. */
  function setList(list, open) {
    list.classList.toggle('is-open', open);
    const sel = list.parentElement && list.parentElement.querySelector('.wo-select');
    if (sel) sel.setAttribute('aria-expanded', String(open));
    if (open) placeList(list);
  }
  /**
   * Places an open list under its select, or above it when it would cross the safe rect's bottom and
   * there is more room above (Godot's PopupMenu flips the same way), then slides it sideways to stay
   * inside the safe rect. Measured in canvas px from the frame canvas.
   */
  function placeList(list) {
    const c = list.closest('.wo-frame'), f = c && frames.find((x) => x.canvas === c);
    if (!f || !f.P) return;
    list.classList.remove('is-above');
    list.style.translate = '';
    const cr = c.getBoundingClientRect(), k = cr.width / f.d.shape.cw;
    const r = list.getBoundingClientRect(), sel = list.parentElement.getBoundingClientRect();
    const E = f.P.edges, bottom = f.d.shape.ch - E.bottom, right = f.d.shape.cw - E.right;
    const top = (r.top - cr.top) / k, h0 = r.height / k, selTop = (sel.top - cr.top) / k;
    if (top + h0 > bottom && selTop - h0 >= E.top) list.classList.add('is-above');
    const left = (r.left - cr.left) / k, w = r.width / k;
    const dx = left < E.left ? E.left - left : left + w > right ? right - left - w : 0;
    if (dx) list.style.translate = dx + 'px 0';
  }
  addEventListener('click', (e) => {
    if (!readyState || !e.target.closest) return;
    const item = e.target.closest('.wo-frame .wo-popup-item');
    if (item) {
      if (item.getAttribute('aria-disabled') === 'true') return;
      const list = item.closest('.wo-popup');
      list.querySelectorAll('.wo-popup-item').forEach((x) => x.setAttribute('aria-selected', String(x === item)));
      setList(list, false);
      return;
    }
    const sel = e.target.closest('.wo-frame .wo-select');
    const list = sel && sel.parentElement.querySelector(':scope > .wo-popup');
    if (list) setList(list, !list.classList.contains('is-open'));
  });
  /** Each render: a frame's data-wo-list="<name>" (on the canvas or its host) or ?list=<name> opens
   *  the .wo-popup[data-wo-list] of that name (a capture of an open list), and open lists are placed. */
  function syncLists() {
    for (const f of frames) {
      const name = f.canvas.dataset.woList || f.host.dataset.woList || url.get('list');
      const named = name && f.canvas.querySelector('.wo-popup[data-wo-list="' + name + '"]');
      if (named) named.classList.add('is-open');
      f.canvas.querySelectorAll('.wo-popup.is-open').forEach(placeList);
    }
  }

  // Rows, switches, sliders, holds, countdowns, scroll (3.1, 3.2) --------------------------------

  /** A click or tap anywhere on a settings row works its control (the whole row is the target, so a
   *  phone switch drawn smaller than 44 pt still has a full-size target); a switch flips. */
  addEventListener('click', (e) => {
    if (!readyState || !e.target.closest) return;
    const sw = e.target.closest('.wo-frame .wo-toggle');
    if (sw) { if (sw.getAttribute('aria-disabled') !== 'true') sw.setAttribute('aria-checked', String(sw.getAttribute('aria-checked') !== 'true')); return; }
    const row = e.target.closest('.wo-frame .wo-row');
    if (!row || e.target.closest('.wo-row-control, .wo-popup')) return;
    const ctl = row.querySelector('.wo-row-control :is(.wo-toggle, .wo-select, .wo-btn, .wo-slider)');
    if (!ctl) return;
    ctl.focus({ preventScroll: true });
    if (!ctl.matches('.wo-slider')) ctl.click();
  });
  /** The share 0..1 a slider shows, from aria-valuenow between aria-valuemin and aria-valuemax
   *  (the one convention for sliders; WAI-ARIA's own). */
  function sliderShare(el) {
    const v = Number(el.getAttribute('aria-valuenow')), lo = Number(el.getAttribute('aria-valuemin') || 0), hi = Number(el.getAttribute('aria-valuemax') || 1);
    return hi > lo ? Math.min(1, Math.max(0, (v - lo) / (hi - lo))) : 0;
  }
  /** Sets --fill (a percentage) on every slider and hold control: sliders from sliderShare, a
   *  [data-wo-hold] from its live hold or its data-wo-value (0..1, a still state for captures). */
  function fills(root = document) {
    for (const el of root.querySelectorAll('.wo-slider[aria-valuenow]')) el.style.setProperty('--fill', fmt(sliderShare(el) * 100, 3) + '%');
    for (const el of root.querySelectorAll('[data-wo-hold]')) if (!holds.has(el)) el.style.setProperty('--fill', fmt(Math.min(1, Math.max(0, Number(el.dataset.woValue) || 0)) * 100, 3) + '%');
  }
  /** Live holds: control -> {start, src}. */
  const holds = new Map();
  /**
   * Hold to confirm (3.2: RESTORE DEFAULT CONTROLS, RESET ALL SETTINGS): while [on], the [data-wo-hold]
   * control around [el] fills over timing.hold-confirm; full adds .is-complete and fires wo:hold
   * (detail {el}); letting go first empties it. [src] ("pointer", "key", "pad") keeps one input's
   * release from ending another's hold.
   */
  function holdInput(el, on, src) {
    const ctl = el && el.closest && el.closest('[data-wo-hold]');
    if (on && ctl && !holds.has(ctl) && readyState) {
      const h0 = { start: performance.now(), src };
      holds.set(ctl, h0);
      ctl.classList.remove('is-complete');
      const step = () => {
        if (holds.get(ctl) !== h0) return;
        const t = Math.min(1, (performance.now() - h0.start) / num('timing.hold-confirm'));
        ctl.style.setProperty('--fill', fmt(t * 100, 3) + '%');
        if (t >= 1) { holds.delete(ctl); ctl.classList.add('is-complete'); emit('hold', { el: ctl }); return; }
        requestAnimationFrame(step);
      };
      requestAnimationFrame(step);
    }
    if (!on) for (const [c, x] of holds) if (x.src === src) { holds.delete(c); fills(c.parentElement); }
  }
  addEventListener('pointerdown', (e) => holdInput(e.target, true, 'pointer'));
  for (const t of ['pointerup', 'pointercancel', 'pointerleave']) addEventListener(t, () => holdInput(null, false, 'pointer'), true);
  addEventListener('keydown', (e) => { if (!e.repeat && ['Enter', ' '].includes(e.key)) holdInput(document.activeElement, true, 'key'); });
  addEventListener('keyup', (e) => { if (['Enter', ' '].includes(e.key)) holdInput(null, false, 'key'); });
  /**
   * Keep-or-revert countdowns (3.1 step 8): a [data-wo-countdown] element counts down
   * timing.keep-revert; its [data-wo-countdown-left] children show the whole seconds left, and at 0
   * it hides itself and fires wo:revert. ?countdown=<ms> holds it that far in (a capture).
   */
  function countdowns() {
    const hold = url.get('countdown');
    for (const el of document.querySelectorAll('[data-wo-countdown]')) {
      if (el._woCount && hold === null) continue;
      const start = performance.now() - (hold === null ? 0 : Number(hold));
      const run = (el._woCount = { start });
      const tick = () => {
        if (el._woCount !== run) return;
        const left = Math.max(0, num('timing.keep-revert') - (performance.now() - start));
        el.querySelectorAll('[data-wo-countdown-left]').forEach((x) => { x.textContent = String(Math.ceil(left / 1000)); });
        if (left <= 0) { el.hidden = true; emit('revert', { el }); return; }
        if (hold === null) setTimeout(tick, 100);
      };
      tick();
    }
  }
  /** Opens every [data-wo-scroll="v"] scroller v (0..1) of the way down its range, so a still shows
   *  that the page scrolls. scrollTop is in canvas px (the frame's scale is a transform above it). */
  function scrolls() {
    for (const el of document.querySelectorAll('[data-wo-scroll]')) el.scrollTop = Number(el.dataset.woScroll) * (el.scrollHeight - el.clientHeight);
  }
  /** Hides each [data-wo-min-refresh="hz"] choice on a frame whose device refresh rate is known and
   *  lower (3.2: 120 only on screens of 119 Hz or more). Unknown rates hide nothing. */
  function refreshChoices() {
    for (const f of frames) {
      for (const el of f.canvas.querySelectorAll('[data-wo-min-refresh]')) el.hidden = f.d.refresh !== null && Number(el.dataset.woMinRefresh) > f.d.refresh;
    }
  }
  /** Gives each dialogue box its name tab's height as --wo-nametab-h, so a box in the flow keeps
   *  exactly that much room above it for the tab (wo.css .wo-box.is-inline). */
  function nameTabRoom(root = document) {
    for (const b of root.querySelectorAll('.wo-box')) {
      const t = b.querySelector(':scope > .wo-nametab');
      if (t) b.style.setProperty('--wo-nametab-h', t.offsetHeight + 'px');
    }
  }
  /** Everything above that reads the laid-out screen, run on every render after layoutFrames. */
  function screens() {
    markCurrent();
    syncTabs();
    syncLists();
    fills();
    refreshChoices();
    nameTabRoom();
    scrolls();
    countdowns();
    for (const el of document.querySelectorAll('[data-wo-open]:not(.is-opening)')) replayOpen(el);
    // A guarded overlay shown when the page opens stands for the return from the background (6.7.5).
    for (const el of document.querySelectorAll('[data-wo-overlay][data-wo-guard]:not([hidden])')) {
      if (!el._woGuardUntil) el._woGuardUntil = performance.now() + num('timing.resume-card.guard');
    }
  }
  WO.screen = { overlay: setOverlay, answer: pickAnswer, tab: selectTab, list: setList, current: currentItem, hold: holdInput };

  // ---------------------------------------------------------------------------------------------
  // 12. Motion (brief 6.1, 6.2 B8, 5.9): entrance stagger, idle loop, reduced motion
  // ---------------------------------------------------------------------------------------------

  /** A small seeded random source (?seed=, default 1), so captures of idle motion repeat. */
  let seed = Number(url.get('seed')) || 1;
  const rand = () => ((seed = (seed * 16807) % 2147483647) - 1) / 2147483646;
  /**
   * Entrance stagger for every [data-wo-enter] group: its children get --wo-enter-delay so the
   * whole group lands within motion.stagger.total (each item takes motion.panel.in). Any input
   * completes it at once (6.1 stagger; 5.2 step 7).
   */
  function stagger(root = document) {
    const dur = num('motion.panel.in'), total = num('motion.stagger.total');
    for (const g of root.querySelectorAll('[data-wo-enter]')) {
      const items = [...g.children];
      const step = items.length > 1 ? Math.max(0, total - dur) / (items.length - 1) : 0;
      items.forEach((el, i) => { el.classList.add('wo-enter'); el.style.setProperty('--wo-enter-delay', fmt(i * step, 3) + 'ms'); });
      // Drop is-entering too, so a replay restarts the animation (re-adding a class that is still
      // there changes nothing, so the CSS animation would not run again).
      g.classList.remove('is-entered', 'is-entering');
      void g.offsetWidth;
      g.classList.add('is-entering');
    }
  }
  /** Ends every entrance at once (the first input does this). */
  function finishEntrances() { document.querySelectorAll('[data-wo-enter]').forEach((g) => g.classList.add('is-entered')); }
  addEventListener('keydown', finishEntrances, true);
  addEventListener('pointerdown', (e) => { if (!inChrome(e.target)) finishEntrances(); }, true);
  /** Each [data-wo-idle] element's pending timer, so a re-render never schedules it twice. */
  const idleTimers = new Map();
  /**
   * The idle loop (6.2 B8): every [data-wo-idle] element ticks on its own seeded, irregular timer
   * between motion.idle.period-min and -max, so the logo blink, the rule sweep and each lamp keep
   * their own irregular rhythm instead of firing as one (they can still land close by chance;
   * measured in M03: 74 ms apart once in 30 s, about 0.7 ticks a second over five loops). A tick
   * adds "is-tick" until every animation it starts in the element (or its pseudo-elements and
   * children) ends, or for 2 x motion.focus.in when it starts none. It never moves focus or takes
   * input. Stops under REDUCED MOTION; elements that left the page are dropped.
   */
  function idleLoop() {
    for (const [el, t] of idleTimers) if (reduced() || !el.isConnected) { clearTimeout(t); idleTimers.delete(el); }
    if (reduced()) return;
    const lo = num('motion.idle.period-min'), hi = num('motion.idle.period-max');
    const arm = (el) => idleTimers.set(el, setTimeout(() => tick(el), lo + rand() * (hi - lo)));
    const tick = (el) => {
      if (!el.isConnected || reduced()) { idleTimers.delete(el); return; }
      el.classList.add('is-tick');
      const anims = el.getAnimations({ subtree: true });
      const done = anims.length ? Promise.all(anims.map((a) => a.finished.catch(() => 0))) : new Promise((r) => setTimeout(r, num('motion.focus.in') * 2));
      done.then(() => el.classList.remove('is-tick'));
      arm(el);
    };
    document.querySelectorAll('[data-wo-idle]').forEach((el) => { if (!idleTimers.has(el)) arm(el); });
  }
  /** REDUCED MOTION from the URL (?motion=reduced). */
  const reduced = () => url.get('motion') === 'reduced';
  WO.motion = { stagger, finishEntrances, idle: idleLoop, reduced };

  // ---------------------------------------------------------------------------------------------
  // 12b. Scenes: a screen page shows one moment at a time (?scene=, the strip's Scene control)
  // ---------------------------------------------------------------------------------------------

  /** The scenes a page declares, in order, as [name, label]: <body data-wo-scenes="talk:Conversation;
   *  bark:Bark">. A screen page uses them so one frame (true size in a capture) shows each state
   *  of the brief in turn; capture.mjs --states "talk:scene=talk;..." takes one PNG per scene. */
  function scenes() {
    return (document.body.dataset.woScenes || '').split(';').map((s) => s.trim()).filter(Boolean).map((s) => { const i = s.indexOf(':'); return i < 0 ? [s, s] : [s.slice(0, i), s.slice(i + 1)]; });
  }
  /** The current scene: ?scene= when the page declares it, else the page's first ('' without any). */
  function scene() {
    const list = scenes(), want = url.get('scene');
    return list.some(([n]) => n === want) ? want : list.length ? list[0][0] : '';
  }
  /** True when the space-separated scene list [spec] holds the current scene (an empty list is every
   *  scene). Used by [data-wo-scene] elements and by world pieces' "scene" and "when". */
  function inScene(spec) { return !spec || spec.split(/\s+/).includes(scene()); }
  /** Marks html[data-scene] and hides every [data-wo-scene] element outside the current scene (wo.css
   *  makes [hidden] win over a component's own display). JS, not CSS: CSS cannot match one attribute's
   *  word against another attribute's value. */
  function applyScenes() {
    document.documentElement.dataset.scene = scene();
    for (const el of document.querySelectorAll('[data-wo-scene]')) el.hidden = !inScene(el.dataset.woScene);
  }
  WO.scene = { list: scenes, current: scene, has: inScene };

  // ---------------------------------------------------------------------------------------------
  // 12c. Dialogue reveal (6.3 "Reveal and advance")
  // ---------------------------------------------------------------------------------------------

  /**
   * Types each shown [data-wo-reveal] element in at TEXT SPEED Normal (dialogue.text-speed.normal,
   * characters a second), waiting dialogue.punctuation-pause after a . ? or ! that ends a sentence
   * (followed by a space or a row break), then adds "is-complete" to its .wo-box (the continue mark
   * shows). Rows break at the row rule (rows(); [data-wo-rows] elements get it without typing). The
   * whole line is laid out from the start and the untyped rest kept invisible, as the game's
   * RichTextLabel.visible_characters does, so rows never reflow while it types. REDUCED MOTION shows
   * it at once (6.3 step 6). ?reveal=<ms> holds every reveal that long after it starts (a capture of
   * a line part-typed; a large number shows it complete). Runs on boot and on a scene change; an
   * element that is already typing or done keeps going.
   */
  function startReveals() {
    for (const el of document.querySelectorAll('[data-wo-rows]')) {
      const full = el.dataset.woText || (el.dataset.woText = el.textContent);
      el.replaceChildren(...withBreaks(rows(full)));
    }
    for (const el of document.querySelectorAll('[data-wo-reveal]')) {
      if (!el.getClientRects().length) { el._reveal = null; continue; }
      if (!el._reveal || el._reveal.limit !== rowLimit() || el._reveal.size !== getComputedStyle(el).fontSize) reveal(el);
    }
  }
  /** English's row limit in characters: languages.json "row_characters" (the Tune panel's lang.en). */
  function rowLimit() { return langField('en', 'row_characters'); }
  /**
   * [text] broken into rows of at most rowLimit() characters at spaces, joined by "\n": the row rule
   * DialogueBoxes applies (dialogue_boxes.gd wrap_width narrows the column until no row holds more;
   * 2.2 "Line length"). A browser's "ch" column is not that rule: Roboto's "0" is wider than most
   * letters, so a 42ch column fits about 47 characters of English. A null limit (CJK) leaves the
   * text to the column. Words longer than the limit keep their own row.
   */
  function rows(text, limit = rowLimit()) {
    if (!limit) return text;
    const out = [];
    let row = '';
    for (const word of text.split(/\s+/).filter(Boolean)) {
      if (row && row.length + 1 + word.length > limit) { out.push(row); row = word; } else row = row ? row + ' ' + word : word;
    }
    if (row) out.push(row);
    return out.join('\n');
  }
  /** Text nodes for [s] with a <br> at each "\n". */
  const withBreaks = (s) => s.split('\n').flatMap((part, i) => (i ? [h('br', {}), part] : [part]));
  /**
   * The boxes [text] is shown as in [el]'s column (DialogueBoxes.split, 6.3 step 7): when it takes
   * more than dialogue_boxes.gd MAX_ROWS rows there (a long line, or TEXT SIZE 200% on a phone), it
   * splits between sentences, as many to a box as fit. A sentence too long alone keeps its own box
   * (the game would split it at a clause; no line on these pages needs that). Measures the laid-out
   * element, so it changes [el]'s content.
   */
  function boxesOf(el, text) {
    const max = today.konst('dialogue_boxes.gd', 'MAX_ROWS');
    const fits = (t) => { el.replaceChildren(...withBreaks(rows(t))); return Math.round(el.offsetHeight / parseFloat(getComputedStyle(el).lineHeight)) <= max; };
    if (fits(text)) return [text];
    const out = [];
    let cur = '';
    for (const sentence of text.split(/(?<=[.?!])\s+/)) {
      if (cur && !fits(cur + ' ' + sentence)) { out.push(cur); cur = sentence; } else cur = cur ? cur + ' ' + sentence : sentence;
    }
    if (cur) out.push(cur);
    return out;
  }
  /** Starts (or restarts) the reveal of box [index] of one element; see startReveals. Rows follow
   *  rows(); boxes follow boxesOf(). */
  function reveal(el, index = 0) {
    const chunks = boxesOf(el, el.dataset.woText || (el.dataset.woText = el.textContent));
    const i = index % chunks.length;
    const full = rows(chunks[i]);
    const box = el.closest('.wo-box');
    const step = 1000 / num('dialogue.text-speed.normal'), pause = num('dialogue.punctuation-pause');
    const at = [];
    let t = 0;
    for (let i = 0; i < full.length; i++) { at.push(t); t += step + (/[.?!]/.test(full[i]) && /[ \n]/.test(full[i + 1] || '') ? pause : 0); }
    const hold = url.get('reveal') === null ? null : Number(url.get('reveal'));
    const start = performance.now();
    const run = (el._reveal = { start, limit: rowLimit(), size: getComputedStyle(el).fontSize, index: i });
    const show = (n) => {
      el.replaceChildren(...withBreaks(full.slice(0, n)), h('span', { class: 'wo-reveal-rest' }, ...withBreaks(full.slice(n))));
      if (box) box.classList.toggle('is-complete', n >= full.length);
    };
    run.complete = () => { run.done = true; show(full.length); };
    if (reduced()) { run.complete(); return; }
    const tick = () => {
      if (el._reveal !== run || run.done) return;
      const n = at.filter((x) => x <= (hold === null ? performance.now() - start : hold)).length;
      show(n);
      if (n >= full.length) run.done = true;
      else if (hold === null) requestAnimationFrame(tick);
    };
    tick();
  }
  /** The first press on a box (a click or tap on it, the interact key, pad A) completes its line; the
   *  next one shows the line's next box, and after the last replays the first (the mockup's stand-in
   *  for "advance", 6.3 step 3, 6.4 step 8). */
  function pressBox(box) {
    const el = box && box.querySelector('[data-wo-reveal]');
    if (!el || !el._reveal) return;
    if (el._reveal.done) reveal(el, el._reveal.index + 1); else el._reveal.complete();
  }
  addEventListener('click', (e) => { if (!inChrome(e.target) && e.target.closest) pressBox(e.target.closest('.wo-box')); });
  document.addEventListener('wo:accept', () => pressBox(document.querySelector('.wo-box:not([hidden])')));
  addEventListener('keydown', (e) => {
    if (inChrome(e.target) || !readyState) return;
    const keys = bindings().interact.keys.concat(ENGINE_UI.ui_accept.keys);
    if (keys.includes(e.key.length === 1 ? e.key.toUpperCase() : e.key === ' ' ? 'Space' : e.key)) pressBox(document.querySelector('.wo-box:not([hidden])'));
  });

  // ---------------------------------------------------------------------------------------------
  // 13. World frames (brief 7.1 "World frames", C3 sections 3-4, 2.5.3 steps 4-7)
  // ---------------------------------------------------------------------------------------------

  /**
   * The play view for a canvas cw x ch and a framing ("keyboard" or "touch") per 2.5.3: the view
   * is the canvas / zoom; the camera y is min(today's y, bottom limit - view height / 2) for keys
   * and pads (bottom limit = 540 + BOTTOM_BLEED - MAX_SHAKE_PX), and for touch it puts the floor
   * the same gap above the touch controls' top as today's scene does (main.tscn button tops at
   * GAMEPLAY_CAMERA_Y_TOUCH), so today's layout reproduces today's 392. The camera x is clamped
   * between half a view from each room end, or centred when the view is wider than the room.
   * Returns {cx, cy, vw, vh, left, top, zoom, gap} in world px.
   */
  function playView(cw, ch, framing, wantX, controlsTop) {
    const st = stage();
    const vw = cw / st.zoom, vh = ch / st.zoom;
    const bottom = st.baseH + st.bleed - st.shake;
    let cy, gap = null;
    if (framing === 'touch') {
      const todayTop = today.rect('main.tscn', 'CanvasLayer/TouchControls/Left').y;
      gap = todayTop - (st.floorY - (st.cameraYTouch - st.baseH / 2 / st.zoom)) * st.zoom;
      const top = controlsTop === undefined ? todayTop + (ch - st.baseH) : controlsTop;
      cy = st.floorY - (top - gap - ch / 2) / st.zoom;
    } else cy = Math.min(st.cameraY, bottom - vh / 2);
    // Either framing stays on the plates: low touch controls on a tall canvas (the iPad's 80 px USE)
    // would otherwise lift the view's top above world y 0, where nothing is painted.
    cy = Math.min(bottom - vh / 2, Math.max(vh / 2, cy));
    const lo = vw / 2, hi = st.roomW - vw / 2;
    let cx = wantX === 'left' ? lo : wantX === 'right' ? hi : Number(wantX);
    cx = vw >= st.roomW ? st.roomW / 2 : Math.min(hi, Math.max(lo, cx));
    return { cx, cy, vw, vh, left: cx - vw / 2, top: cy - vh / 2, zoom: st.zoom, gap };
  }
  /** Loads an image and resolves with it decoded (natural size known). */
  const images = new Map();
  function loadImage(srcUrl) {
    if (!images.has(srcUrl)) {
      images.set(srcUrl, new Promise((res, rej) => { const im = new Image(); im.onload = () => res(im); im.onerror = () => rej(new Error('image failed: ' + srcUrl)); im.src = srcUrl; }));
    }
    return images.get(srcUrl);
  }
  /** The texture file of a main.tscn node (Sprite2D or TextureRect), as a path under the game
   *  folder, from the node's texture ExtResource. */
  function nodeTexture(nodePath) {
    const tex = gv(today.node('main.tscn', nodePath).props.texture).ext;
    const ext = parseSections(files[SOURCES['main.tscn']]).find((s) => s.tag === 'ext_resource' && s.attrs.id === tex);
    if (!ext) throw new Error('main.tscn ' + nodePath + ' has no texture');
    return ext.attrs.path.replace('res://', '');
  }
  /** A Sprite2D node from main.tscn as {src, x, y, w, h, flip} in world px (centered sprites per
   *  Godot: top-left = position + offset x scale - size x scale / 2). [at] replaces the parent's
   *  position (an actor placed elsewhere); [flip] mirrors it. */
  async function spritePiece(piece) {
    const node = today.node('main.tscn', piece.node);
    const pos = gv(node.props.position || 'Vector2(0, 0)');
    const parentPath = piece.node.includes('/') ? piece.node.split('/').slice(0, -1).join('/') : null;
    const parentPos = piece.at || (parentPath ? gv(today.node('main.tscn', parentPath).props.position || 'Vector2(0, 0)') : [0, 0]);
    const scale = gv(node.props.scale || 'Vector2(1, 1)');
    const path = nodeTexture(piece.node);
    const im = await loadImage(GAME + path);
    const region = node.props.region_enabled && gv(node.props.region_enabled) ? gv(node.props.region_rect) : [0, 0, im.naturalWidth, im.naturalHeight];
    const w = region[2] * scale[0], hh = region[3] * scale[1];
    const centered = node.props.centered === undefined ? true : gv(node.props.centered);
    const x = parentPos[0] + pos[0] - (centered ? w / 2 : 0), y = parentPos[1] + pos[1] - (centered ? hh / 2 : 0);
    return Object.assign({}, piece, { src: path, x, y, w, h: hh });
  }
  /** A world piece with each "<script>.gd:<NAME>" string in its placement fields (x, y, w, h,
   *  brightness, drop and the at pair) replaced by that constant (today.konst), so a value with a
   *  home in a script is named, never copied: "brightness": "door_kit.gd:WALL_LIFT". */
  function namedValues(piece) {
    const read = (v) => (typeof v === 'string' && /^[\w]+\.gd:[A-Za-z_]\w*$/.test(v) ? today.konst(...v.split(':')) : v);
    const out = Object.assign({}, piece);
    for (const k of ['x', 'y', 'w', 'h', 'brightness', 'drop']) if (k in out) out[k] = read(out[k]);
    if (Array.isArray(out.at)) out.at = out.at.map(read);
    return out;
  }
  /** Shared room files (data-wo-world="data/<room>.json"), fetched once each with no-store. */
  const worldFiles = new Map();
  /**
   * The world data of [el]: its data-wo-world file (a room shared by every page that shows it,
   * mockups/data/<room>.json) merged with its own <script type="application/json">, or the script
   * alone when the attribute is empty.
   * - Top-level keys of the page's script (camera, cameras, framing, grade, anchor) replace the
   *   file's.
   * - A page piece with an "id" and no art (no src, node, beacons or reach) changes the file's
   *   piece of that id (a tap, a "when", another bleed).
   * - Every other page piece is drawn at the file's {"slot": "<name>"} marker named by its own
   *   "slot" (default "actors"), in page order, so the back-to-front order stays the file's.
   * An unknown id or slot is a problem, never a silent miss. Returns a fresh object each call.
   */
  async function worldConfig(el) {
    const script = el.querySelector(':scope > script[type="application/json"]');
    const own = script ? JSON.parse(script.textContent) : {};
    const ref = el.dataset.woWorld;
    if (!ref) { if (!script) throw new Error('a world needs data-wo-world="<file>" or a JSON script'); return own; }
    if (!worldFiles.has(ref)) worldFiles.set(ref, fetch(ref, { cache: 'no-store' }).then((r) => { if (!r.ok) throw new Error('HTTP ' + r.status + ' ' + ref); return r.text(); }));
    const base = JSON.parse(await worldFiles.get(ref));
    const out = Object.assign({}, base, own, { pieces: [] });
    const byId = {}, slots = {};
    for (const pc of base.pieces) if (pc.id) byId[pc.id] = pc;
    for (const pc of own.pieces || []) {
      if (!pc.src && !pc.node && !pc.beacons && !pc.reach) {
        if (!byId[pc.id]) problem(ref + ' has no piece with id "' + pc.id + '"'); else Object.assign(byId[pc.id], pc);
        continue;
      }
      (slots[pc.slot || 'actors'] = slots[pc.slot || 'actors'] || []).push(pc);
    }
    for (const pc of base.pieces) {
      if (pc.slot && !pc.src && !pc.node) { out.pieces.push(...(slots[pc.slot] || [])); delete slots[pc.slot]; } else out.pieces.push(pc);
    }
    for (const k of Object.keys(slots)) problem(ref + ' has no slot "' + k + '"');
    return out;
  }
  /**
   * Composes every [data-wo-world] element from worldConfig (a shared room file and/or the page's
   * JSON script): {camera: "left"|"right"|x, framing: "auto"|"keyboard"|"touch",
   * anchor: "fixed"|"today", grade: true, pieces: [...]}. A piece is {src: "<assets path>", x, y,
   * w, h} in world px, or {node: "<main.tscn Sprite2D path>", at: [x, y]}; options: layer
   * "far"|"near" (parallax), flip, brightness, bleed ("bottom", "sides"), tap (a hit area).
   * The far plate moves (1 - scroll) x (cx - base width / 2): the fixed anchor of 2.5.3 step 7;
   * anchor "today" uses today's (cx - canvas width / 2) for comparison.
   * Scenes (section 12b): "cameras": {scene: camera} overrides "camera" in that scene; a piece's
   * "scene": "a b" keeps it to those scenes; "when": {class: "a b"} adds the class in those scenes
   * (is-usable, is-hover). More piece kinds: "id" names the piece for [data-wo-at] anchors;
   * "quad": [[x, y] x 4] maps the image onto that world quad (top-left, top-right, bottom-right,
   * bottom-left; the seal curtain's mesh, C3 layer 5); {"beacons": "<RoomDepth node>"} and
   * {"reach": "corridor"} are read from the game (beaconPieces, reachBands).
   * The touch framing follows the frame's laid-out touch controls (touchControlsTop).
   */
  async function composeWorlds(root = document) {
    for (const el of root.querySelectorAll('[data-wo-world]')) {
      const f = frames.find((x) => x.canvas.contains(el));
      if (!f) { problem('a world must sit inside a .wo-frame'); continue; }
      let cfg;
      try { cfg = await worldConfig(el); } catch (e) { problem('world data: ' + e.message); continue; }
      const st = stage();
      const top = touchControlsTop(f);
      const touch = f.canvas.dataset.input === 'touch' && top !== null;
      const framing = cfg.framing === 'auto' || !cfg.framing ? (touch ? 'touch' : 'keyboard') : cfg.framing;
      const cam = cfg.cameras && cfg.cameras[scene()] !== undefined ? cfg.cameras[scene()] : cfg.camera;
      const v = playView(f.d.shape.cw, f.d.shape.ch, framing, cam === undefined ? 'left' : cam, top === null ? undefined : top);
      el._view = v;
      el.dataset.framing = framing;
      const world = h('div', { class: 'wo-world' });
      world.style.transform = `scale(${v.zoom}) translate(${-v.left}px, ${-v.top}px)`;
      const farScroll = today.konst('room_depth.gd', 'BACKDROP_SCROLL')[0], nearScroll = today.konst('room_depth.gd', 'NEAR_SCROLL')[0];
      const anchorX = cfg.anchor === 'today' ? f.d.shape.cw / 2 : st.baseW / 2;
      const rects = {};
      for (let piece of cfg.pieces) {
        if (piece.scene && !inScene(piece.scene)) continue;
        try {
          piece = namedValues(piece);
          if (piece.beacons) { await beaconPieces(piece, world, (1 - farScroll) * (v.cx - anchorX)); continue; }
          if (piece.reach) { reachBands(piece, world); continue; }
          if (piece.node) piece = await spritePiece(piece);
          const im = await loadImage(GAME + (piece.node ? '' : 'assets/') + piece.src);
          const shift = piece.layer === 'far' ? (1 - farScroll) * (v.cx - anchorX) : piece.layer === 'near' ? (1 - nearScroll) * (v.cx - anchorX) : 0;
          const srcUrl = GAME + (piece.node ? '' : 'assets/') + piece.src;
          const place = (cls, x, y, w, hgt) => { const d = h('div', { class: 'wo-piece ' + cls }); Object.assign(d.style, { left: x + 'px', top: y + 'px', width: w + 'px', height: hgt + 'px' }); return d; };
          const img = () => { const i = h('img', { src: srcUrl, alt: '', draggable: 'false' }); if (piece.brightness) i.style.filter = `brightness(${piece.brightness})`; return i; };
          if (piece.quad) {
            const q = place('wo-quad', 0, 0, im.naturalWidth, im.naturalHeight);
            q.style.transform = quadMatrix(im.naturalWidth, im.naturalHeight, piece.quad);
            q.append(img());
            world.append(q);
            const xs = piece.quad.map((p) => p[0]), ys = piece.quad.map((p) => p[1]);
            if (piece.id) rects[piece.id] = { x: Math.min(...xs), y: Math.min(...ys), w: Math.max(...xs) - Math.min(...xs), h: Math.max(...ys) - Math.min(...ys) };
            continue;
          }
          const box = place(piece.flip ? 'is-flip' : '', piece.x + shift, piece.y, piece.w, piece.h);
          box.append(img());
          if (piece.tap) { box.classList.add('wo-tap'); box.dataset.woTap = piece.tap; }
          for (const [cls, list] of Object.entries(piece.when || {})) if (inScene(list)) box.classList.add(cls);
          if (piece.id) rects[piece.id] = { x: piece.x + shift, y: piece.y, w: piece.w, h: piece.h };
          world.append(box);
          const bleeds = (piece.bleed || '').split(' ');
          if (bleeds.includes('bottom')) { const b = place('wo-bleed is-bottom', piece.x + shift, piece.y + piece.h, piece.w, st.bleed); const i = img(); i.style.height = piece.h + 'px'; b.append(i); world.append(b); }
          if (bleeds.includes('sides')) {
            const l = place('wo-bleed is-left', piece.x + shift - st.midBleed, piece.y, st.midBleed, piece.h), r = place('wo-bleed is-right', piece.x + shift + piece.w, piece.y, st.midBleed, piece.h);
            for (const b of [l, r]) { const i = img(); i.style.width = piece.w + 'px'; b.append(i); world.append(b); }
          }
        } catch (e) { problem('world piece ' + (piece.src || piece.node) + ': ' + e.message); }
      }
      el.querySelectorAll('.wo-world, .wo-grade').forEach((x) => x.remove());
      el.append(world);
      if (cfg.grade !== false) el.append(gradeLayer(f.d.shape.cw, f.d.shape.ch));
      el._rects = rects;
      placeAnchors(f, v, rects);
      hitLayer(f, el);
      placeBoxes(f, v);
    }
  }
  /**
   * Moves frame [f]'s dialogue boxes to the top when, at the bottom, they would cover the speakers'
   * feet (6.3 Position: "moves to the top when the speakers or the target stand in the lower third";
   * Celeste anchors per line). The test is the box's top against the floor line, (FLOOR_Y - view top)
   * x zoom in canvas px; at TEXT SIZE 200% on a phone the box grows past it.
   */
  function placeBoxes(f, v) {
    const floor = (stage().floorY - v.top) * v.zoom;
    for (const b of f.canvas.querySelectorAll('.wo-box:not(.is-inline)')) {
      b.classList.remove('is-top');
      if (b.getClientRects().length && f.d.shape.ch - f.P.edges.bottom - b.offsetHeight < floor) b.classList.add('is-top');
    }
  }
  /**
   * The hit-area overlay of world [el] in frame [f] (?hits=1; 6.4 step 2): one box per tap piece in
   * canvas px, the art grown to the profile's minimum hit size (density.pointer-hit-min with a
   * pointer, the touch density otherwise) plus the phone margin (density.gap-phone-dp) on each side,
   * shown as an inner band. The boxes sit in a layer the size of the OS safe area with overflow
   * hidden: a tap in an inset never reaches the world (M05: nothing interactive in the insets).
   * The shown touch controls win over the world (6.4 step 13: USE, the move ring and PAUSE take
   * their own taps), so each box is cut back to the largest part clear of them (clearOf); a box
   * whose clear part is under the minimum on either side gets .is-short and data-wo-short, which
   * the probe reads (the part a finger can reach must still meet the minimum).
   */
  function hitLayer(f, el) {
    el.querySelectorAll('.wo-hits').forEach((x) => x.remove());
    const d = f.d, P = f.P, v = el._view, ins = d.insets;
    const layer = h('div', { class: 'wo-hits' });
    Object.assign(layer.style, { left: ins.left + 'px', top: ins.top + 'px', right: ins.right + 'px', bottom: ins.bottom + 'px' });
    const cr = f.canvas.getBoundingClientRect(), k = cr.width / d.shape.cw;
    const controls = [...f.canvas.querySelectorAll('.wo-touch, .wo-move-ring')].filter((x) => x.getClientRects().length).map((x) => {
      const r = x.getBoundingClientRect();
      return { x: (r.left - cr.left) / k, y: (r.top - cr.top) / k, w: r.width / k, h: r.height / k };
    });
    for (const t of el.querySelectorAll('.wo-tap')) {
      const w = parseFloat(t.style.width) * v.zoom, hgt = parseFloat(t.style.height) * v.zoom;
      const cx = (parseFloat(t.style.left) - v.left) * v.zoom + w / 2, cy = (parseFloat(t.style.top) - v.top) * v.zoom + hgt / 2;
      const W = Math.max(w, P.hitMin) + 2 * P.hitMargin, H = Math.max(hgt, P.hitMin) + 2 * P.hitMargin;
      const r = clearOf({ x: cx - W / 2, y: cy - H / 2, w: W, h: H }, controls);
      if (!r) continue;
      const box = h('div', { class: 'wo-hit', 'data-wo-tap': t.dataset.woTap }, t.dataset.woTap);
      const short = r.w - 2 * P.hitMargin < P.hitMin - 1e-6 || r.h - 2 * P.hitMargin < P.hitMin - 1e-6;
      if (short) { box.classList.add('is-short'); box.dataset.woShort = ''; }
      Object.assign(box.style, { left: r.x - ins.left + 'px', top: r.y - ins.top + 'px', width: r.w + 'px', height: r.h + 'px' });
      layer.append(box);
    }
    el.append(layer);
  }
  /**
   * Rect [r] cut back clear of every rect in [blocks] (all {x, y, w, h} in canvas px): for each block
   * it overlaps, the largest of the four parts left, right, above or below the block is kept. null
   * when nothing is left. A cut, not a hole: a world tap area is one rectangle in the game too.
   */
  function clearOf(r, blocks) {
    for (const b of blocks) {
      if (b.x >= r.x + r.w || b.x + b.w <= r.x || b.y >= r.y + r.h || b.y + b.h <= r.y) continue;
      const parts = [
        { x: r.x, y: r.y, w: b.x - r.x, h: r.h }, { x: b.x + b.w, y: r.y, w: r.x + r.w - b.x - b.w, h: r.h },
        { x: r.x, y: r.y, w: r.w, h: b.y - r.y }, { x: r.x, y: b.y + b.h, w: r.w, h: r.y + r.h - b.y - b.h },
      ].filter((q) => q.w > 0 && q.h > 0);
      if (!parts.length) return null;
      r = parts.reduce((a, q) => (q.w * q.h > a.w * a.h ? q : a));
    }
    return r;
  }
  /**
   * The top of frame [f]'s laid-out bottom touch controls (USE, the move ring, the arrows; PAUSE sits
   * at the top and does not count), in canvas px: the "controls' top" of 2.5.3 step 6. Returns null
   * when the frame has such controls but none shows (another input, or tap to walk: keyboard framing)
   * and undefined when it has none at all (playView then keeps today's button top).
   */
  function touchControlsTop(f) {
    const els = [...f.canvas.querySelectorAll('.wo-touch:not(.is-pause), .wo-move-ring')];
    if (!els.length) return undefined;
    const shown = els.filter((x) => x.getClientRects().length);
    if (!shown.length) return null;
    const c = f.canvas.getBoundingClientRect(), k = c.height / f.d.shape.ch;
    return Math.min(...shown.map((x) => (x.getBoundingClientRect().top - c.top) / k));
  }
  /**
   * Places every [data-wo-at] element of frame [f] over its world (view [v]) in canvas px (6.3: the
   * pill and the bark live over the thing, not in a HUD box). "<piece id> [dx dy]" is the top centre
   * of that world piece moved dx, dy world px; "x y" is a world point. The element's own CSS picks
   * which of its points sits there (.wo-pill and .wo-bark: bottom centre, kept inside the safe
   * rect, and a pill stacked above an earlier one it would overlap). An anchor whose piece is
   * not in the current scene is skipped when the element is hidden, and reported when it shows.
   */
  function placeAnchors(f, v, rects) {
    const placed = [];
    for (const el of f.canvas.querySelectorAll('[data-wo-at]')) {
      const p = el.dataset.woAt.trim().split(/\s+/);
      let wx, wy;
      if (Number.isNaN(Number(p[0]))) {
        const r = rects[p[0]];
        if (!r) { if (!el.hidden) problem('no world piece with id "' + p[0] + '" for data-wo-at'); continue; }
        wx = r.x + r.w / 2 + Number(p[1] || 0);
        wy = r.y + Number(p[2] || 0);
      } else { wx = Number(p[0]); wy = Number(p[1]); }
      let x = (wx - v.left) * v.zoom, y = (wy - v.top) * v.zoom;
      // A pill or bark is HUD text: it slides along to stay whole inside the safe rect (its CSS
      // anchor is its bottom centre). A floor mark stays on its world point.
      if (el.matches('.wo-pill, .wo-bark') && el.offsetWidth) {
        const E = f.P.edges, half = el.offsetWidth / 2;
        x = Math.min(f.d.shape.cw - E.right - half, Math.max(E.left + half, x));
        y = Math.max(E.top + el.offsetHeight, y);
        // Pills never overlap: one that would lands a target gap above the earlier one it meets
        // (labels stacked as Thimbleweed Park's TAB view does; DOM order is the priority).
        const gap = Math.max(num('density.gap'), f.P.hitMargin);
        for (let moved = true; moved && el.matches('.wo-pill');) {
          moved = false;
          for (const o of placed) {
            if (Math.abs(o.x - x) < o.half + half && y > o.y - o.h - gap && y - el.offsetHeight < o.y + gap) { y = o.y - o.h - gap; moved = true; }
          }
        }
        if (el.matches('.wo-pill') && !el.hidden) placed.push({ x, y, half, h: el.offsetHeight });
      }
      el.style.left = x + 'px';
      el.style.top = y + 'px';
    }
  }
  /**
   * CSS matrix3d that maps a w x h element (transform-origin 0 0) onto the world quad [q] (top-left,
   * top-right, bottom-right, bottom-left): the square-to-quad projective map (Heckbert 1989), scaled
   * by 1/w and 1/h. CSS keeps the projective divide when it flattens the 3D matrix into the plane.
   */
  function quadMatrix(w, hgt, q) {
    const [[x0, y0], [x1, y1], [x2, y2], [x3, y3]] = q;
    const dx1 = x1 - x2, dx2 = x3 - x2, dx3 = x0 - x1 + x2 - x3, dy1 = y1 - y2, dy2 = y3 - y2, dy3 = y0 - y1 + y2 - y3;
    const den = dx1 * dy2 - dx2 * dy1;
    const g = den ? (dx3 * dy2 - dx2 * dy3) / den : 0, k = den ? (dx1 * dy3 - dx3 * dy1) / den : 0;
    const a = x1 - x0 + g * x1, b = x3 - x0 + k * x3, d = y1 - y0 + g * y1, e = y3 - y0 + k * y3;
    return `matrix3d(${[a / w, d / w, 0, g / w, b / hgt, e / hgt, 0, k / hgt, 0, 0, 1, 0, x0, y0, 0, 1].map((n) => fmt(n, 8)).join(', ')})`;
  }
  /**
   * The painted lockdown beacons of RoomDepth node [piece.beacons] in main.tscn (room_depth.gd
   * _build, "painted beacons"), appended to [world]. Per lamp, from the node's beacon_atlas,
   * beacon_regions and beacon_offsets at BEACON_ART_SCALE, BEACON_ART_PARTS regions each: the
   * fixture and the guard cut from the atlas, the globe filled with the warning colour (WARNING_RED,
   * --wo-today-beacon) through its alpha, and the light, at beacon_peak_alpha, pulsing at
   * alert.beacon-rate (6.5; steady under FLASHING LIGHTS Reduced, wo.css). Lamp i runs
   * BEACON_FLASH_PHASE_SECONDS x i behind the first, as in the game. Anchors are the node's
   * warning_lamps as fractions of the far plate (room width x base height), [shift] world px of far
   * parallax, and [piece.drop] world px lower: B23's Proposal to bring them into the view.
   */
  async function beaconPieces(piece, world, shift) {
    const st = stage();
    const node = today.node('main.tscn', piece.beacons).props;
    const lamps = gv(node.warning_lamps), regions = gv(node.beacon_regions), offsets = gv(node.beacon_offsets), peak = gv(node.beacon_peak_alpha);
    const atlasId = gv(node.beacon_atlas).ext;
    const path = parseSections(files[SOURCES['main.tscn']]).find((s) => s.tag === 'ext_resource' && s.attrs.id === atlasId).attrs.path.replace('res://', '');
    const im = await loadImage(GAME + path);
    const scale = today.konst('room_depth.gd', 'BEACON_ART_SCALE'), parts = today.konst('room_depth.gd', 'BEACON_ART_PARTS');
    const phase = today.konst('room_depth.gd', 'BEACON_FLASH_PHASE_SECONDS');
    const aw = im.naturalWidth * scale, ah = im.naturalHeight * scale;
    const rect = (el, x, y, w, hgt) => { Object.assign(el.style, { left: x + 'px', top: y + 'px', width: w + 'px', height: hgt + 'px' }); return el; };
    // The atlas region [r] shown through an element: its alpha as a mask, or the image cropped.
    const masked = (el, r) => { Object.assign(el.style, { maskImage: `url("${GAME + path}")`, maskSize: `${aw}px ${ah}px`, maskPosition: `${-r[0] * scale}px ${-r[1] * scale}px`, maskRepeat: 'no-repeat' }); return el; };
    const cropped = (r) => { const i = h('img', { src: GAME + path, alt: '', draggable: 'false' }); Object.assign(i.style, { width: aw + 'px', height: ah + 'px', left: -r[0] * scale + 'px', top: -r[1] * scale + 'px' }); return i; };
    for (let i = 0; i < lamps.length / 2; i++) {
      const ax = lamps[2 * i] * st.roomW + shift, ay = lamps[2 * i + 1] * st.baseH + (piece.drop || 0);
      const at = (j) => [ax + offsets[2 * (i * parts + j)] * scale, ay + offsets[2 * (i * parts + j) + 1] * scale, regions[i * parts + j][2] * scale, regions[i * parts + j][3] * scale];
      const [fixture, globe, guard, light] = [0, 1, 2, 3].map((j) => [at(j), regions[i * parts + j]]);
      world.append(rect(h('div', { class: 'wo-crop' }, cropped(fixture[1])), ...fixture[0]));
      world.append(masked(rect(h('div', { class: 'wo-lens' }), ...globe[0]), globe[1]));
      world.append(rect(h('div', { class: 'wo-crop' }, cropped(guard[1])), ...guard[0]));
      const glow = rect(h('div', { class: 'wo-piece' }), ...light[0]);
      glow.style.opacity = String(peak);
      const pulse = masked(h('div', { class: 'wo-beacon', 'data-wo-probe': 'beacon' }), light[1]);
      pulse.style.animationDelay = fmt(phase * i * 1000, 3) + 'ms';
      glow.append(pulse);
      world.append(glow);
    }
  }
  /**
   * The corridor stations' reach and USE buffer as floor bands (6.4 hit areas, 6.7.2 #4), appended
   * to [world] and shown only with the hit-area overlay. Reach: main.gd CORRIDOR_STATIONS (x and
   * reach of each Vector4; a name stands for a main.gd constant) and the MANUAL BYPASS
   * (BYPASS_WHEEL x, BYPASS_REACH). Buffer: the distance walked in [piece.buffer] s (6.7.2's
   * Proposal; not in the build yet) at M0Actor.WALK_SPEED (the build's one speed, the jog) and at
   * [piece.walk] px/s (the planned walk, 6.7.2 #4). [piece.y], [piece.h]: the bands' world rows.
   */
  function reachBands(piece, world) {
    const named = (s) => (Number.isNaN(Number(s)) ? today.konst('main.gd', s) : Number(s));
    const raw = src('main.gd').CORRIDOR_STATIONS;
    if (!raw) throw new Error('main.gd has no CORRIDOR_STATIONS');
    const stations = [...raw.matchAll(/Vector4\(([^()]*)\)/g)].map((m) => splitTop(m[1])).map((a) => [named(a[0]), named(a[2])]);
    stations.push([today.konst('main.gd', 'BYPASS_WHEEL')[0], today.konst('main.gd', 'BYPASS_REACH')]);
    const jog = today.konst('m0_actor.gd', 'WALK_SPEED') * piece.buffer, walk = piece.walk * piece.buffer;
    for (const [x, r] of stations) {
      for (const [cls, half] of [['is-jog', r + jog], ['is-walk', r + walk], ['is-reach', r]]) {
        const b = h('div', { class: 'wo-band ' + cls });
        Object.assign(b.style, { left: x - half + 'px', top: piece.y + 'px', width: 2 * half + 'px', height: piece.h + 'px' });
        world.append(b);
      }
    }
  }
  /**
   * The post grade (assets/shaders/post_grade.gdshader) drawn into a small canvas from the
   * shader's own uniforms and fragment formula, then stretched over the world with multiply,
   * as the game's blend_mul quad does: colour = grade x (1 - v x strength), with
   * v = smoothstep(start, 1, length((uv - 0.5) x aspectFix) x reach).
   */
  function gradeLayer(cw, ch) {
    const g = today.uniform('grade'), strength = today.uniform('vignette_strength'), start = today.uniform('vignette_start');
    const [ax, ay, reach] = today.match('post_grade.gdshader', /\(UV - vec2\(0\.5\)\) \* vec2\(([\d.]+), ([\d.]+)\);\s*float v = smoothstep\(vignette_start, 1\.0, length\(d\) \* ([\d.]+)\)/).map(Number);
    const W = Math.round(cw / 4), H = Math.round(ch / 4);
    const c = h('canvas', { class: 'wo-grade', width: W, height: H });
    const ctx = c.getContext('2d'), img = ctx.createImageData(W, H);
    const ss = (e0, e1, x) => { const t = Math.min(1, Math.max(0, (x - e0) / (e1 - e0))); return t * t * (3 - 2 * t); };
    for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
      const dx = ((x + 0.5) / W - 0.5) * ax, dy = ((y + 0.5) / H - 0.5) * ay;
      const v = ss(start, 1, Math.hypot(dx, dy) * reach), m = 1 - v * strength, i = (y * W + x) * 4;
      img.data[i] = g[0] * m * 255; img.data[i + 1] = g[1] * m * 255; img.data[i + 2] = g[2] * m * 255; img.data[i + 3] = 255;
    }
    ctx.putImageData(img, 0, 0);
    return c;
  }
  /**
   * Cover art for every [data-wo-cover] element (2.5.3 step 14: a TextureRect with
   * STRETCH_KEEP_ASPECT_COVERED). Its <script type="application/json"> holds {node: "<main.tscn
   * TextureRect path>"} or {src: "<assets path>"}, focus: [fx, fy] (the share of the overflow
   * cropped from the left and the top; 0.5 centres) and spots: [{x, y, w, h}], a light's centre and
   * size in the art's own pixels. The art is scaled by max(canvas w / art w, canvas h / art h), so
   * it keeps its shape and covers the canvas; each spot becomes a .wo-spot in the art's proportions
   * with its own idle timer (6.2 B8). Re-placed on every render (the canvas shape follows the device).
   */
  async function composeCovers(root = document) {
    for (const el of root.querySelectorAll('[data-wo-cover]')) {
      const f = frames.find((x) => x.canvas.contains(el));
      if (!f || !f.d) { problem('a cover must sit inside a .wo-frame'); continue; }
      try {
        const cfg = JSON.parse(el.querySelector('script[type="application/json"]').textContent);
        if (!Array.isArray(cfg.focus)) throw new Error('cover data has no focus [fx, fy]');
        const srcUrl = GAME + (cfg.node ? nodeTexture(cfg.node) : 'assets/' + cfg.src);
        const im = await loadImage(srcUrl);
        const W = im.naturalWidth, H = im.naturalHeight, cw = f.d.shape.cw, ch = f.d.shape.ch;
        const s = Math.max(cw / W, ch / H), [fx, fy] = cfg.focus;
        Object.assign(el.style, { width: W * s + 'px', height: H * s + 'px', left: (cw - W * s) * fx + 'px', top: (ch - H * s) * fy + 'px' });
        el._cover = { W, H, s, src: srcUrl };
        if (el.querySelector(':scope > img')) continue;
        const pct = (v, of) => (v / of) * 100 + '%';
        const spots = (cfg.spots || []).map((sp) => {
          const d = h('i', { class: 'wo-spot', 'data-wo-idle': '', 'data-wo-spot': sp.name });
          Object.assign(d.style, { left: pct(sp.x, W), top: pct(sp.y, H), width: pct(sp.w, W), height: pct(sp.h, H) });
          return d;
        });
        el.append(h('img', { src: srcUrl, alt: '', draggable: 'false' }), ...spots);
        idleLoop();
      } catch (e) { problem('cover: ' + e.message); }
    }
  }
  WO.world = { view: playView, compose: composeWorlds, covers: composeCovers };

  // ---------------------------------------------------------------------------------------------
  // 13b. Values shown as text, and inline SVG art
  // ---------------------------------------------------------------------------------------------

  /**
   * Fills every [data-wo-text] element with a value read from its one home, so a page never writes
   * it: "project:<setting>" (project.godot, for example application/config/version, the single
   * source of the version) or "konst:<file>:<NAME>" (a script constant such as main.gd
   * NO_CHECKPOINT_NOTE). Throws into the problem list when the home has no such value.
   */
  function renderTexts(root = document) {
    for (const el of root.querySelectorAll('[data-wo-text]')) {
      const [kind, ...rest] = el.dataset.woText.split(':');
      try {
        let v;
        if (kind === 'project') v = today.project(rest.join(':'));
        else if (kind === 'konst') v = today.konst(rest[0], rest[1]);
        else throw new Error('unknown data-wo-text "' + el.dataset.woText + '"');
        el.textContent = String(v);
      } catch (e) { problem(e.message); }
    }
  }
  /** The text of each inlined SVG by its assets path, fetched once. */
  const svgTexts = new Map();
  /**
   * Inlines every [data-wo-svg] element's SVG (a path under apps/game/assets), so CSS can move one
   * part of the real art (the logo mark's eye, 6.2 B8) without a copy of its geometry. The art is
   * decorative there (aria-hidden; its <title> and <desc> are dropped so they never tooltip).
   * data-wo-part="name=selector[;name2=selector2]" marks the svg's matching children with
   * data-wo-part="name"; a selector that matches nothing is a problem, not a silent miss.
   */
  async function inlineSvgs(root = document) {
    for (const el of root.querySelectorAll('[data-wo-svg]')) {
      if (el.querySelector(':scope > svg')) continue;
      const path = el.dataset.woSvg;
      try {
        if (!svgTexts.has(path)) svgTexts.set(path, fetch(GAME + 'assets/' + path).then((r) => { if (!r.ok) throw new Error('HTTP ' + r.status); return r.text(); }));
        const doc = new DOMParser().parseFromString(await svgTexts.get(path), 'image/svg+xml');
        const svg = document.importNode(doc.documentElement, true);
        svg.querySelectorAll('title, desc').forEach((n) => n.remove());
        svg.removeAttribute('aria-labelledby');
        svg.removeAttribute('role');
        svg.setAttribute('aria-hidden', 'true');
        for (const pair of (el.dataset.woPart || '').split(';').filter(Boolean)) {
          const i = pair.indexOf('=');
          const hits = svg.querySelectorAll(':scope > ' + pair.slice(i + 1));
          if (!hits.length) throw new Error(path + ' has no part ' + pair);
          hits.forEach((p) => p.setAttribute('data-wo-part', pair.slice(0, i)));
        }
        el.replaceChildren(svg);
      } catch (e) { problem('svg ' + path + ': ' + e.message); }
    }
  }

  // ---------------------------------------------------------------------------------------------
  // 14. Control strip (brief 7.1 Control strip)
  // ---------------------------------------------------------------------------------------------

  let strip = null;
  /** The extra strip controls a page asks for in <body data-wo-strip="speaker touch loading">. */
  const pageStrip = () => (document.body.dataset.woStrip || '').split(/\s+/).filter(Boolean);
  /** Choice controls: [URL key, label, options] (options [value, label]). Options come from the
   *  token file where it has them; the rest are the brief's URL vocabulary (7.1). */
  function stripControls() {
    const c = [
      ['device', 'Device', deviceNames().map((n) => [n, deviceLabel(n)])],
      ['input', 'Input', [['', 'auto'], ['mouse', 'mouse'], ['keyboard', 'keyboard'], ['pad', 'pad'], ['touch', 'touch']]],
      ['text', 'TEXT SIZE', [['', 'profile default']].concat(textSteps().map((p) => [String(p), p + '%']))],
      ['motion', 'Motion', [['', 'full'], ['reduced', 'reduced']]],
    ];
    const extra = {
      speaker: ['speaker', 'Speaker', [['', 'name tab'], ['portrait', 'placeholder portrait']]],
      touch: ['touch', 'Phone controls', [['', 'move pad + tap'], ['tapwalk', 'tap to walk']]],
      loading: ['loading', 'Loading', [['', 'M04'], ['m04b', 'M04b'], ['compare', 'compare']]],
      load: ['load', 'Load (s)', [['', 'measured'], ['0.003', '0.003'], ['0.8', '0.8'], ['3', '3'], ['12', '12']]],
      tip: ['tip', 'Tip', [['', 'off'], ['1', 'placeholder']]],
      art: ['art', 'Card art', [['', 'room'], ['key', 'key art']]],
      flashing: ['flashing', 'FLASHING LIGHTS', [['', 'on'], ['reduced', 'reduced']]],
      scene: ['scene', 'Scene', scenes()],
    };
    return c.concat(pageStrip().map((k) => extra[k]).filter(Boolean));
  }
  /** Builds the strip once; syncStrip() refreshes its values. Hidden with ?clean=1. */
  function buildStrip() {
    if (url.get('clean') === '1') return;
    strip = h('nav', { class: 'mk-strip', 'aria-label': 'Mockup controls' });
    strip.append(h('a', { class: 'mk-home', href: 'index.html', 'data-wo-carry': '' }, 'WOLF OVERRIDE mockups'));
    for (const [key, label, opts] of stripControls()) {
      const sel = h('select', { 'data-key': key, onchange: (e) => {
        url.set(key, e.target.value || null);
        if (key === 'input') {
          const v = e.target.value;
          input.mode = v ? (v === 'mouse' ? 'pointer' : v) : null;
          if (input.mode === 'touch') input.touched = true;
          applyInput();
        }
        rerender();
      } }, ...opts.map(([v, l]) => h('option', { value: v }, l)));
      strip.append(h('label', { class: 'mk-field' }, h('span', {}, label), sel));
    }
    const hits = h('input', { type: 'checkbox', 'data-key': 'hits', onchange: (e) => { url.set('hits', e.target.checked ? '1' : null); rerender(); } });
    strip.append(h('label', { class: 'mk-field is-check' }, hits, h('span', {}, 'hit areas')));
    strip.append(h('button', { class: 'mk-btn', type: 'button', onclick: () => { url.set('tune', url.get('tune') === '1' ? null : '1'); syncTune(); } }, 'Tune'));
    strip.append(h('span', { class: 'mk-status', 'data-role': 'status' }));
    document.body.prepend(strip);
  }
  /** Puts the URL's values into the strip's controls. */
  function syncStrip() {
    if (!strip) return;
    for (const sel of strip.querySelectorAll('select')) {
      const k = sel.dataset.key;
      sel.value = k === 'scene' ? scene() : url.get(k) || (k === 'device' ? 'desktop' : '');
    }
    strip.querySelector('[data-key="hits"]').checked = url.get('hits') === '1';
    const status = strip.querySelector('[data-role="status"]');
    status.textContent = 'input: ' + (input.mode || 'profile default') + (tokens.overrides.size || tokens.langOverrides.size ? ' · ' + (tokens.overrides.size + tokens.langOverrides.size) + ' tuned' : '');
  }

  /** Every link marked data-wo-carry keeps device, input, text, motion, hits, tune, speaker,
   *  touch, bind (remaps) and every t.* and lang.* parameter (M00: tuned values carried across pages). clean
   *  is not carried: it is for one capture, not a browsing state. */
  function carryLinks() {
    const keep = ['device', 'input', 'text', 'motion', 'hits', 'tune', 'speaker', 'touch', 'bind'];
    for (const a of document.querySelectorAll('a[data-wo-carry]')) {
      const base = a.getAttribute('href').split('?')[0];
      const q = new URLSearchParams();
      for (const [k, v] of url.params) if (keep.includes(k) || k.startsWith('t.') || k.startsWith('lang.')) q.set(k, v);
      const s = q.toString();
      a.setAttribute('href', base + (s ? '?' + s : ''));
    }
  }

  // ---------------------------------------------------------------------------------------------
  // 15. Tune panel (brief 7.2)
  // ---------------------------------------------------------------------------------------------

  let tunePanel = null;
  /** Unlocked rows ("sourced" and "today" tokens opened for a deliberate experiment). */
  const unlocked = new Set();
  /** This tab's id on the BroadcastChannel, so it ignores its own messages. */
  const tabId = Math.random().toString(36).slice(2);
  const channel = 'BroadcastChannel' in window ? new BroadcastChannel('wo-tune') : null;

  /** The token's $value shape for a scalar [v] (dimension and duration keep their unit). */
  function shaped(t, v) {
    const base = t.node.$value;
    if (base && typeof base === 'object' && 'unit' in base) return { value: v, unit: base.unit };
    return v;
  }
  /** The scalar a URL or control holds for a token's $value ([v]). */
  function scalarOf(t, v) {
    if (v && typeof v === 'object' && 'value' in v) return v.value;
    if (t.type === 'number' && t.ext.options) return t.ext.options[v];
    return v;
  }
  /** Parses a URL or control string for token [t] into its $value shape. */
  function parseFor(t, s) {
    if (t.type === 'number' && t.ext.options) { const i = t.ext.options.indexOf(s); return i >= 0 ? i : Number(s); }
    if (t.type === 'fontFamily' || t.type === 'color') return s;
    return shaped(t, Number(s));
  }
  const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
  /**
   * Sets (or clears, when [v] equals the file) the override of token [path], clamped to its
   * hard limits, then updates the URL (t.<path>), tells other tabs and re-renders. [from] is
   * "channel" (another tab sent it: not sent back) or "drag" (a slider moving: the Tune rows are
   * not rebuilt under the pointer, only their live parts).
   */
  function setOverride(path, v, from) {
    const t = rec(path);
    if (v !== null && typeof scalarOf(t, v) === 'number' && !(t.type === 'number' && t.ext.options)) {
      let n = scalarOf(t, v);
      if (t.ext.hard_min !== undefined) n = Math.max(t.ext.hard_min, n);
      if (t.ext.hard_max !== undefined) n = Math.min(t.ext.hard_max, n);
      v = shaped(t, n);
    }
    if (v === null || same(v, t.node.$value)) { tokens.overrides.delete(path); url.set('t.' + path, null); }
    else { tokens.overrides.set(path, v); url.set('t.' + path, scalarOf(t, v)); }
    if (from !== 'channel' && channel) channel.postMessage({ from: tabId, kind: 't', path, value: v });
    rerender(from === 'drag' ? 'live' : 'full');
  }
  /** Sets (or clears) a languages.json override (lang.<code>.<field>). */
  function setLangOverride(key, v, from) {
    const [code, field] = key.split('.');
    const fileV = tokens.lang.languages[code][field];
    if (v === null || same(v, fileV)) { tokens.langOverrides.delete(key); url.set('lang.' + key, null); }
    else { tokens.langOverrides.set(key, v); url.set('lang.' + key, v); }
    if (from !== 'channel' && channel) channel.postMessage({ from: tabId, kind: 'lang', path: key, value: v });
    rerender('full');
  }
  if (channel) {
    channel.onmessage = (e) => {
      const m = e.data;
      if (!m || m.from === tabId || !readyState) return;
      if (m.kind === 't' && tokens.flat.has(m.path)) setOverride(m.path, m.value, 'channel');
      if (m.kind === 'lang') setLangOverride(m.path, m.value, 'channel');
    };
  }
  /** Reads t.* and lang.* from the URL into the override maps (unknown tokens are reported). */
  function readUrlOverrides() {
    for (const [k, s] of url.entries('t.')) {
      const path = k.slice(2);
      if (!tokens.flat.has(path)) { problem('URL tunes an unknown token: ' + path); continue; }
      const v = parseFor(rec(path), s);
      if (!same(v, rec(path).node.$value)) tokens.overrides.set(path, v);
    }
    for (const [k, s] of url.entries('lang.')) {
      const key = k.slice(5);
      tokens.langOverrides.set(key, s === 'null' ? null : Number.isNaN(Number(s)) ? s : Number(s));
    }
  }

  /** Builds or removes the Tune panel to match ?tune=1 (and ?clean=1 hides it). */
  function syncTune() {
    const want = url.get('tune') === '1' && url.get('clean') !== '1';
    if (!want) { if (tunePanel) tunePanel.remove(); tunePanel = null; document.documentElement.dataset.tune = ''; return; }
    document.documentElement.dataset.tune = 'open';
    if (!tunePanel) buildTune();
    refreshTune();
  }
  /** One control row for token [t] (brief 7.2 "What it does" step 2). */
  function tuneRow(t) {
    const st = t.ext.status;
    const locked = (st === 'sourced' || st === 'today') && !unlocked.has(t.path) && !tokens.overrides.has(t.path);
    const isAlias = typeof t.node.$value === 'string' && ALIAS.test(t.node.$value);
    const row = h('div', { class: 'mk-trow', 'data-path': t.path, 'data-status': st });
    const head = h('div', { class: 'mk-trow-head' },
      h('code', {}, t.path),
      h('span', { class: 'mk-chip is-' + st }, st),
      t.ext.source ? h('span', { class: 'mk-src', title: t.ext.source }, t.ext.source) : null);
    row.append(head);
    if (t.desc) row.append(h('div', { class: 'mk-desc' }, t.desc));
    const ctl = h('div', { class: 'mk-ctl' });
    row.append(ctl);
    const fileV = t.node.$value, cur = rawOf(t.path);
    const fileTxt = 'file: ' + showValue(t, fileV) + (isAlias ? ' = ' + showValue(t, resolved(t.path)) : '');
    if (st === 'computed') {
      ctl.append(h('span', { class: 'mk-val' }, fileTxt), h('span', { class: 'mk-live', 'data-live': t.path }));
      return row;
    }
    if (locked || (isAlias && !t.ext.options)) {
      ctl.append(h('span', { class: 'mk-val' }, fileTxt));
      if (!isAlias || t.ext.options) ctl.append(h('label', { class: 'mk-unlock' }, h('input', { type: 'checkbox', onchange: () => { unlocked.add(t.path); refreshTune(true); } }), 'unlock'));
      return row;
    }
    const opts = t.ext.options;
    if (opts) {
      const sel = h('select', { onchange: (e) => setOverride(t.path, parseFor(t, e.target.value)) }, ...opts.map((o) => h('option', { value: String(o) }, String(o))));
      sel.value = String(scalarOf(t, cur));
      ctl.append(sel, h('span', { class: 'mk-val' }, fileTxt));
    } else if (typeof scalarOf(t, cur) === 'number') {
      const lo = Math.max(t.ext.min ?? -Infinity, t.ext.hard_min ?? -Infinity), hi = Math.min(t.ext.max ?? Infinity, t.ext.hard_max ?? Infinity);
      const v = scalarOf(t, cur);
      const step = t.ext.step || 'any';
      if (isFinite(lo) && isFinite(hi)) {
        const range = h('input', { type: 'range', min: lo, max: hi, step, value: v, 'data-ctl': 'range',
          oninput: (e) => setOverride(t.path, shaped(t, Number(e.target.value)), 'drag'),
          onchange: (e) => setOverride(t.path, shaped(t, Number(e.target.value))) });
        if (t.ext.band) { range.style.setProperty('--band-a', ((t.ext.band[0] - lo) / (hi - lo)) * 100 + '%'); range.style.setProperty('--band-b', ((t.ext.band[1] - lo) / (hi - lo)) * 100 + '%'); range.classList.add('has-band'); }
        ctl.append(range);
      }
      const box = h('input', { type: 'number', step, value: v, 'data-ctl': 'number', onchange: (e) => setOverride(t.path, shaped(t, Number(e.target.value))) });
      if (t.ext.hard_min !== undefined) box.min = t.ext.hard_min;
      if (t.ext.hard_max !== undefined) box.max = t.ext.hard_max;
      ctl.append(box, h('span', { class: 'mk-unit' }, (fileV && fileV.unit) || ''), h('span', { class: 'mk-val' }, fileTxt));
      const lim = [t.ext.hard_min !== undefined ? 'hard ≥ ' + t.ext.hard_min : '', t.ext.hard_max !== undefined ? 'hard ≤ ' + t.ext.hard_max : '', t.ext.band ? 'band ' + t.ext.band.join('–') : ''].filter(Boolean).join(' · ');
      if (lim) ctl.append(h('span', { class: 'mk-lim' }, lim));
    } else {
      ctl.append(h('span', { class: 'mk-val' }, fileTxt));
    }
    if (tokens.overrides.has(t.path)) ctl.append(h('button', { class: 'mk-btn is-small', type: 'button', onclick: () => setOverride(t.path, null) }, 'reset'));
    if (/^type\.[\w-]+\.size$/.test(t.path)) row.append(h('div', { class: 'mk-floors', 'data-floors': t.path.split('.')[1] }));
    return row;
  }
  /** Builds the panel: header, Copy JSON diff, the language rows, then one group per token group. */
  function buildTune() {
    tunePanel = h('aside', { class: 'mk-tune', 'aria-label': 'Tune' });
    const head = h('div', { class: 'mk-tune-head' },
      h('strong', {}, 'Tune'),
      h('label', { class: 'mk-field is-check' }, h('input', { type: 'checkbox', 'data-role': 'all', onchange: () => refreshTune(true) }), h('span', {}, 'show locked')),
      h('button', { class: 'mk-btn', type: 'button', onclick: copyDiff }, 'Copy JSON diff'),
      h('button', { class: 'mk-btn', type: 'button', onclick: () => { for (const p of [...tokens.overrides.keys()]) setOverride(p, null); for (const k of [...tokens.langOverrides.keys()]) setLangOverride(k, null); } }, 'Reset all'),
      h('button', { class: 'mk-btn', type: 'button', onclick: () => { url.set('tune', null); syncTune(); } }, 'Close'));
    tunePanel.append(head, h('div', { class: 'mk-diff', 'data-role': 'diff' }), h('div', { class: 'mk-tune-body', 'data-role': 'body' }));
    document.body.append(tunePanel);
  }
  /** Rebuilds the rows ([full]) or only the live parts (floors, computed values, diff count). */
  function refreshTune(full) {
    if (!tunePanel) return;
    const body = tunePanel.querySelector('[data-role="body"]');
    const showAll = tunePanel.querySelector('[data-role="all"]').checked;
    if (full || !body.childElementCount) {
      // Keep keyboard focus on the same control across the rebuild.
      const act = document.activeElement;
      const keep = act && act.closest && act.closest('.mk-trow') ? [act.closest('.mk-trow').dataset.path, act.dataset.ctl || act.tagName] : null;
      const open = new Set([...body.querySelectorAll('details[open]')].map((d) => d.dataset.group));
      body.replaceChildren();
      const groups = {};
      for (const t of tokens.flat.values()) {
        const g = t.path.split('.')[0];
        const st = t.ext.status;
        if (!showAll && !(st === 'proposal' || st === 'computed' || tokens.overrides.has(t.path) || unlocked.has(t.path))) continue;
        (groups[g] = groups[g] || []).push(t);
      }
      // A group starts open when it holds a tuned value, and stays as the viewer left it.
      const tunedGroups = new Set([...tokens.overrides.keys()].map((p) => p.split('.')[0]).concat(tokens.langOverrides.size ? ['languages'] : []));
      const isOpen = (g) => (open.size ? open.has(g) : tunedGroups.has(g)) || null;
      const langDetails = h('details', { 'data-group': 'languages', open: isOpen('languages') }, h('summary', {}, 'languages.json'));
      for (const code of Object.keys(tokens.lang.languages).filter((c) => tokens.lang.languages[c].enabled)) {
        const rc = langField(code, 'row_characters'), cps = langField(code, 'reading_cps');
        const row = h('div', { class: 'mk-trow' }, h('div', { class: 'mk-trow-head' }, h('code', {}, 'lang.' + code), h('span', { class: 'mk-chip is-today' }, 'languages.json')));
        const ctl = h('div', { class: 'mk-ctl' }, h('span', {}, 'row_characters'));
        if (rc === null) ctl.append(h('span', { class: 'mk-val' }, 'null (rows run to the column)'));
        else ctl.append(h('input', { type: 'number', min: 1, step: 1, value: rc, onchange: (e) => setLangOverride(code + '.row_characters', Number(e.target.value)) }), h('span', { class: 'mk-val' }, 'file: ' + tokens.lang.languages[code].row_characters));
        ctl.append(h('span', { class: 'mk-val' }, 'reading_cps ' + (cps === null ? 'null (English speed)' : cps) + ' (sourced, read-only)'));
        row.append(ctl);
        langDetails.append(row);
      }
      body.append(langDetails);
      for (const [g, list] of Object.entries(groups)) {
        const det = h('details', { 'data-group': g, open: isOpen(g) }, h('summary', {}, g + ' (' + list.length + ')'));
        for (const t of list) det.append(tuneRow(t));
        body.append(det);
      }
      if (keep) {
        const row = body.querySelector(`.mk-trow[data-path="${keep[0]}"]`);
        const el = row && (row.querySelector(`[data-ctl="${keep[1]}"]`) || row.querySelector(keep[1]));
        if (el) el.focus({ preventScroll: true });
      }
    }
    // Live parts: floors per profile, computed results, diff summary.
    const refs = ['desktop', 'ally', 'iphone'].filter((n) => deviceNames().includes(n)).map((n) => profile(device(n), { text: Number(url.get('text')) || 0 }));
    for (const el of body.querySelectorAll('[data-floors]')) {
      const role = el.dataset.floors;
      el.replaceChildren(...refs.map((P) => {
        const px = P.roles[role];
        const broken = floorsBroken(P, role, px);
        const pt = P.kind === 'phone' && !P.device.android ? ' = ' + fmt(px * P.device.k, 1) + ' pt' : '';
        const txt = `${role} ${fmt(px, 1)} canvas px on ${P.device.label}${pt}` + (broken.length ? ' < ' + broken.map((f) => fmt(f.px, 1) + ' (' + f.label + ')').join(', ') : '');
        return h('div', { class: broken.some((f) => f.hard) ? 'is-bad' : broken.length ? 'is-warn' : 'is-ok' }, txt);
      }));
    }
    for (const el of body.querySelectorAll('[data-live]')) el.textContent = liveComputed(el.dataset.live);
    const n = tokens.overrides.size + tokens.langOverrides.size;
    tunePanel.querySelector('[data-role="diff"]').textContent = n ? n + ' tuned value' + (n > 1 ? 's' : '') + ': ' + diffList().join('; ') : 'Nothing tuned yet: every value equals the files.';
  }
  /** The live result of a computed token for the reference devices (7.2 step 2 "computed"). */
  function liveComputed(path) {
    const phones = deviceNames().map(device).filter((d) => d.profile === 'phone');
    if (path === 'density.phone') return 'live: ' + phones.map((d) => d.label + ' ' + phoneDensity(d)).join(', ');
    if (path === 'profile.phone.text-scale') return 'live: ' + phones.map((d) => d.label + ' ' + fmt(phoneTextScale(d), 3)).join(', ');
    return 'no live inputs in the token file: shows the stored reference';
  }
  /** "path: old -> new" lines for every tuned value (the commit message and changelog list). */
  function diffList() {
    const out = [];
    for (const [p, v] of tokens.overrides) out.push(`${p}: ${showValue(rec(p), rec(p).node.$value)} -> ${showValue(rec(p), v)}`);
    for (const [k, v] of tokens.langOverrides) { const [c, f] = k.split('.'); out.push(`languages.${c}.${f}: ${tokens.lang.languages[c][f]} -> ${v}`); }
    return out;
  }
  /** JSON Pointer for a dot path's $value (RFC 6901: "~" is "~0", "/" is "~1"). */
  const pointer = (parts) => '/' + parts.map((p) => String(p).replace(/~/g, '~0').replace(/\//g, '~1')).join('/');
  /**
   * The RFC 6902 patch set: one {file, patch} per changed file, a "test" of the file's current
   * value and a "replace" with the tuned one for each change (7.2 step 6).
   */
  function buildPatch() {
    const out = [];
    if (tokens.overrides.size) {
      const patch = [];
      for (const [p, v] of tokens.overrides) {
        const ptr = pointer(p.split('.').concat('$value'));
        patch.push({ op: 'test', path: ptr, value: rec(p).node.$value }, { op: 'replace', path: ptr, value: v });
      }
      out.push({ file: REPO_FILE.tokens, patch });
    }
    if (tokens.langOverrides.size) {
      const patch = [];
      for (const [k, v] of tokens.langOverrides) {
        const [c, f] = k.split('.');
        const ptr = pointer(['languages', c, f]);
        patch.push({ op: 'test', path: ptr, value: tokens.lang.languages[c][f] }, { op: 'replace', path: ptr, value: v });
      }
      out.push({ file: REPO_FILE.languages, patch });
    }
    return out;
  }
  /**
   * Copy JSON diff (7.2 step 6-7): copies the patch to the clipboard in a secure context; without
   * one (a LAN IP) it shows the patch selected in a read-only box with a "Download tune.json" link.
   * The old -> new list shows in both cases. It never fails silently.
   */
  async function copyDiff() {
    const box = tunePanel.querySelector('[data-role="diff"]');
    const json = JSON.stringify(buildPatch(), null, 2) + '\n';
    const list = diffList();
    box.replaceChildren(h('div', {}, list.length ? list.join('\n') : 'Nothing tuned: the patch is empty.'));
    let copied = false;
    if (window.isSecureContext && navigator.clipboard) {
      try { await navigator.clipboard.writeText(json); copied = true; } catch (e) { copied = false; }
    }
    if (copied) { box.append(h('div', { class: 'is-ok' }, 'Copied the JSON diff. Paste it into the chat.')); return; }
    const ta = h('textarea', { readonly: true, rows: 10, class: 'mk-patch' });
    ta.value = json;
    const a = h('a', { download: 'tune.json', href: URL.createObjectURL(new Blob([json], { type: 'application/json' })) }, 'Download tune.json');
    box.append(h('div', { class: 'is-warn' }, window.isSecureContext ? 'The clipboard refused. Copy the text below, or download it.' : 'No secure context here (a LAN address), so there is no clipboard. Copy the text below, or download it.'), ta, a);
    ta.focus();
    ta.select();
  }
  WO.tune = { set: setOverride, setLang: setLangOverride, patch: buildPatch, list: diffList, copy: copyDiff };

  // ---------------------------------------------------------------------------------------------
  // 16. Sheets for M01 (data-wo-sheet="type|colors|literals|densities|glyphs|motion|fonts")
  // ---------------------------------------------------------------------------------------------

  /** Relative luminance (WCAG 2) of an sRGB colour [r, g, b] in 0..1. */
  function luminance(c) {
    const f = (x) => (x <= 0.04045 ? x / 12.92 : Math.pow((x + 0.055) / 1.055, 2.4));
    return 0.2126 * f(c[0]) + 0.7152 * f(c[1]) + 0.0722 * f(c[2]);
  }
  /** [fg] composited over [bg] (both [r, g, b, a]), opaque result. */
  const over = (fg, bg) => [0, 1, 2].map((i) => fg[i] * fg[3] + bg[i] * (1 - fg[3])).concat(1);
  /** WCAG contrast ratio of two opaque colours. */
  function contrast(a, b) {
    const la = luminance(a), lb = luminance(b);
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
  }
  WO.contrast = contrast;

  /** A table for a sheet: [head labels], rows of cells (strings or nodes). */
  const table = (head, rows) => h('table', { class: 'mk-table' }, h('thead', {}, h('tr', {}, ...head.map((x) => h('th', {}, x)))), h('tbody', {}, ...rows.map((r) => h('tr', {}, ...r.map((c) => (c && c.tagName === 'TD' ? c : h('td', {}, c)))))));

  const SHEETS = {
    /** Type roles per reference profile with live px, pt and floor checks (M01). */
    type() {
      const refs = ['desktop', 'ally', 'iphone'].map((n) => profile(device(n), { text: Number(url.get('text')) || 0 }));
      const head = ['Role', 'Base', 'Face'].concat(refs.map((P) => `${P.device.label} (${P.kind}, TEXT SIZE ${P.textSize}%, scale ${fmt(P.textScale, 3)})`));
      const rows = roles().map((r) => {
        const sample = h('span', { class: 'mk-type-sample', 'data-role': r }, r);
        const cells = refs.map((P) => {
          const px = P.roles[r];
          const broken = floorsBroken(P, r, px);
          const shown = P.kind === 'phone' && !P.device.android ? `${px} canvas px = ${fmt(px * P.device.k, 1)} pt` : `${px} canvas px = ${fmt(px * P.device.shape.s, 1)} px on screen`;
          return h('td', { class: broken.some((f) => f.hard) ? 'is-bad' : broken.length ? 'is-warn' : '' }, shown, broken.length ? h('div', {}, 'under ' + broken.map((f) => fmt(f.px, 1) + ' (' + f.label + ')').join(', ')) : null);
        });
        return [sample, num('type.' + r + '.size') + ' px', resolved('type.' + r + '.face') + ' ' + resolved('type.' + r + '.weight')].concat(cells);
      });
      return [table(head, rows), h('p', { class: 'mk-note' }, 'Size = round(base × profile text scale × TEXT SIZE), as TextSize.px rounds. Floors: ' + refs.map((P) => P.device.label + ' ' + P.floors.map((f) => fmt(f.px, 1) + ' (' + f.label + ')').join(', ')).join('; ') + '.')];
    },
    /** Colour roles: swatch, alias, theme slots, and contrast of text roles (M01). */
    colors() {
      const bgTitle = today.prop('main.tscn', 'CanvasLayer/TitleScreen', 'color').color;
      const panel = over(color('color.role.menu-panel.bg'), bgTitle), card = over(color('color.role.hud-card.bg'), bgTitle);
      const textRoles = { 'color.role.control.text': 'text', 'color.role.control.text-active': 'text', 'color.role.control.text-disabled': 'disabled' };
      const rows = [...tokens.flat.values()].filter((t) => t.path.startsWith('color.role.')).map((t) => {
        const c = color(t.path);
        const sw = h('span', { class: 'mk-swatch' }); sw.style.setProperty('--sw', rgba(c));
        let cr = '';
        if (textRoles[t.path]) {
          const need = textRoles[t.path] === 'disabled' ? num('type.contrast.large') : num('type.contrast.text');
          const a = contrast(over(c, panel), panel), b = contrast(over(c, card), card);
          cr = h('td', { class: a < need || b < need ? 'is-bad' : '' }, `${fmt(a, 2)}:1 on MenuPanel, ${fmt(b, 2)}:1 on HudCard (need ${need}:1)`);
        }
        return [h('span', {}, sw, ' ', t.path.replace('color.role.', '')), t.node.$value + ' ' + hexOf(c) + (c[3] < 1 ? ' @ ' + fmt(c[3], 2) : ''), (t.ext.theme || []).join(', '), cr];
      });
      return [table(['Role', 'Alias and value', 'Theme slots it fills', 'Contrast'], rows), h('p', { class: 'mk-note' }, 'Panels with alpha are composited over the title backdrop (main.tscn TitleScreen, ' + hexOf(bgTitle) + '). A HUD card over the world must be checked on the frame itself (M05).')];
    },
    /** Scene and script colour literals that B26 will move into the theme (read from their homes). */
    literals() {
      const rows = TODAY_VARS.filter((r) => r[1] === 'color').map(([name, , reader, file, path, key]) => {
        let c;
        try { c = reader === 'konst' ? today.konst(file, path).color : today.prop(file, path, key).color; } catch (e) { return [name, 'not found', file]; }
        const sw = h('span', { class: 'mk-swatch' }); sw.style.setProperty('--sw', rgba(c));
        return [h('span', {}, sw, ' --wo-today-' + name), hexOf(c) + (c[3] < 1 ? ' @ ' + fmt(c[3], 2) : ''), file + ' ' + path + (key ? ' ' + key : '')];
      });
      return [table(['Variable', 'Value', 'Home today'], rows), h('p', { class: 'mk-note' }, 'The three cyans (TopBar accent, ContextHint accent, title rule) are scene and script literals, not theme colours yet. The one-accent choice waits for B26, which moves them into theme type variations; the Tune panel offers it then.')];
    },
    /** The densities and hit sizes per reference device (M01). */
    densities() {
      const rows = deviceNames().map(device).map((d) => {
        const P = profile(d, {});
        const bar = h('span', { class: 'mk-density' }); bar.style.setProperty('--d', P.density + 'px');
        return [d.label, d.profile, h('span', {}, bar, ' ' + P.density + ' canvas px'), fmt(P.density * d.k, 1) + (d.profile === 'phone' && !d.android ? ' pt' : ' CSS px') + ' = ' + (d.ppi ? fmt((P.density * d.shape.s / d.ppi) * 25.4, 2) + ' mm' : 'size unknown (no ppi)'), P.hitMin + ' canvas px' + (P.hitMargin ? ' + ' + fmt(P.hitMargin, 1) + ' margin' : '')];
      });
      return [table(['Device', 'Profile', 'Row and button height', 'On screen', 'Minimum hit area'], rows)];
    },
    /** Every glyph, in the Xbox set and the keyboard keycaps the build binds (M01). */
    glyphs() {
      const pad = ['A', 'B', 'X', 'Y', 'LB', 'RB', 'LT', 'RT', 'View', 'Menu', 'DPad', 'DPadUp', 'DPadDown', 'DPadLeft', 'DPadRight', 'LS', 'RS'];
      const b = bindings();
      const keys = [...new Set(Object.values(b).flatMap((x) => x.keys))];
      const cell = (n) => h('figure', { class: 'mk-glyph-cell' }, h('span', { class: 'wo-glyph', 'data-wo-glyph': n.includes(':') ? n : 'pad:' + n }), h('figcaption', {}, n.replace('key:', '')));
      const acts = Object.entries(b).map(([a, x]) => [a, x.keys.join(' / ') || '—', x.pad.join(' / ') || '—', PROPOSED_ACTIONS[a] ? 'proposal (brief 4.2)' : ENGINE_UI[a] ? 'Godot default' : 'main.gd _install_inputs']);
      return [h('h3', {}, 'Xbox'), h('div', { class: 'mk-glyph-grid' }, ...pad.map(cell)), h('h3', {}, 'Keyboard and mouse'), h('div', { class: 'mk-glyph-grid' }, ...keys.map((k) => cell('key:' + k)), cell('mouse:left'), cell('mouse:right')), h('h3', {}, 'Bindings'), table(['Action', 'Keys', 'Pad', 'Home'], acts)];
    },
    /** The motion tokens, each playing on a loop (M01). */
    motion() {
      const demos = [
        ['press', 'motion.press.duration / scale', 'is-press'],
        ['focus', 'motion.focus.in / out / scale', 'is-lift'],
        ['panel', 'motion.panel.in / out', 'is-panel'],
        ['screen', 'motion.screen.in / out', 'is-screen'],
        ['fade', 'timing.fade.out / hold / in', 'is-fade'],
        ['idle', 'motion.idle.period-min / max (blink)', 'is-idle'],
        ['sweep', 'studio_logo.gd BAR_SEGMENT / BAR_SWEEP_SECONDS', 'is-sweep'],
        ['beacon', 'alert.beacon-rate', 'is-beacon'],
      ];
      return [h('div', { class: 'mk-motion-grid' }, ...demos.map(([n, label, cls]) => h('figure', { class: 'mk-motion-cell' },
        n === 'sweep' ? h('div', { class: 'wo-sweep is-running' }, h('div', { class: 'wo-sweep-seg' }))
          : n === 'beacon' ? h('div', { class: 'mk-beacon-demo' }, h('div', { class: 'wo-beacon' }))
            : h('div', { class: 'mk-motion-demo ' + cls, 'data-wo-idle': n === 'idle' ? '' : null }, n),
        h('figcaption', {}, label + ': ' + motionText(n))))),
      h('div', { class: 'mk-motion-stagger' }, h('div', { class: 'mk-stagger-row', 'data-wo-enter': '' }, ...['NEW GAME', 'CONTINUE', 'SETTINGS', 'CREDITS', 'CHANGELOG'].map((x) => h('span', { class: 'wo-btn is-static' }, x))), h('button', { class: 'mk-btn', type: 'button', onclick: () => stagger() }, 'Replay entrance'), h('span', { class: 'mk-note' }, 'motion.stagger.total ' + num('motion.stagger.total') + ' ms; each item motion.panel.in ' + num('motion.panel.in') + ' ms; any input completes it.'))];
    },
    /** The game fonts the way the theme and scenes load them (M01 assets). */
    fonts() {
      return Object.entries(fontFamilies).map(([fam, f]) => h('div', { class: 'mk-font' }, h('div', { class: 'mk-font-sample', 'data-face': fam }, 'WOLF OVERRIDE — ' + fam + ' ◀ ▶'), h('div', { class: 'mk-note' }, f.file + (f.fallbacks.length ? ' + fallback ' + f.fallbacks.join(', ') : ''))));
    },
  };
  /** Display text of one motion demo's numbers. */
  function motionText(n) {
    switch (n) {
      case 'press': return num('motion.press.duration') + ' ms, scale ' + num('motion.press.scale');
      case 'focus': return num('motion.focus.in') + ' / ' + num('motion.focus.out') + ' ms, scale ' + num('motion.focus.scale');
      case 'panel': return num('motion.panel.in') + ' / ' + num('motion.panel.out') + ' ms';
      case 'screen': return num('motion.screen.in') + ' / ' + num('motion.screen.out') + ' ms';
      case 'fade': return num('timing.fade.out') + ' / ' + num('timing.fade.hold') + ' / ' + num('timing.fade.in') + ' ms';
      case 'idle': return num('motion.idle.period-min') + '–' + num('motion.idle.period-max') + ' ms';
      case 'sweep': return today.konst('studio_logo.gd', 'BAR_SEGMENT') + ' of the track per ' + today.konst('studio_logo.gd', 'BAR_SWEEP_SECONDS') + ' s';
      case 'beacon': return num('alert.beacon-rate') + ' Hz' + (reduced() ? ' (reduced: steady)' : '');
      default: return '';
    }
  }
  /** Renders every [data-wo-sheet] element. */
  function renderSheets() {
    for (const el of document.querySelectorAll('[data-wo-sheet]')) {
      try { el.replaceChildren(...SHEETS[el.dataset.woSheet]()); } catch (e) { problem('sheet ' + el.dataset.woSheet + ': ' + e.message); }
    }
    renderGlyphs(document);
  }

  // ---------------------------------------------------------------------------------------------
  // 17. Clocks: the boot (M02) and screen changes (M04, M04b) on one clock (brief 5, 7.1 "Loading
  //     compare", 7.3 M02, M04, M04b). Each has one plan function that both plays the screen and
  //     states its numbers, so a table or readout cannot drift from what plays. One rAF loop
  //     (clockLoop) paints both; both take presses from the one wo:press event (section 9).
  // ---------------------------------------------------------------------------------------------

  /**
   * Shows an element with [data-wo-when="<key>=<a>|<b>"] only while the URL's <key> is one of the
   * listed values ("" stands for an absent key), so one page can hold several views of one screen
   * (M04, M04b, compare). Runs before layoutFrames, so a frame is fitted to the space it shows in.
   * Side effect: sets the hidden attribute both ways (pages start such elements hidden).
   */
  function whenPass() {
    for (const el of document.querySelectorAll('[data-wo-when]')) {
      const i = el.dataset.woWhen.indexOf('=');
      const k = el.dataset.woWhen.slice(0, i), vals = el.dataset.woWhen.slice(i + 1);
      el.hidden = !vals.split('|').includes(url.get(k) || '');
    }
  }

  /**
   * The shared indicator's contract (brief 5.8 begin()/end()), written once for both plans: work
   * pending from [from] to [to] ms shows the indicator only after it has waited
   * timing.indicator.delay, and once shown keeps it for at least timing.indicator.min-show. Returns
   * {on, off} in ms, or null when the work ends before the delay (the indicator never shows).
   */
  function indicatorSpan(from, to) {
    const on = from + num('timing.indicator.delay');
    if (to <= on) return null;
    return { on, off: Math.max(to, on + num('timing.indicator.min-show')) };
  }
  /**
   * Pauses every CSS animation in [el] (its pseudo-elements and children too) at [ms] of its own
   * time, delays included, so a frozen frame shows that exact moment: the sweep's segment, the
   * entrance stagger, an open motion. Re-run it after any class change that restarts an animation.
   */
  function seekAnimations(el, ms) {
    for (const a of el.getAnimations({ subtree: true })) { a.pause(); a.currentTime = Math.max(0, ms); }
  }
  /** Lets every animation in [el] run again from where it is (a frame that stopped being frozen). */
  function playAnimations(el) {
    for (const a of el.getAnimations({ subtree: true })) if (a.playState === 'paused') a.play();
  }

  /** The players the clock paints each frame: {tick(now ms)}; section 17a and 17b add theirs. */
  const players = [];
  /** One requestAnimationFrame loop for every player on the page (started on the first render that
   *  has one). A player that throws is reported once and dropped, so one bad plan cannot freeze the
   *  others. */
  function clockLoop() {
    if (clockLoop.running || !players.length) return;
    clockLoop.running = true;
    const step = (now) => {
      for (const pl of players.slice()) {
        try { pl.tick(now); } catch (e) { players.splice(players.indexOf(pl), 1); problem(pl.name + ': ' + e.message, e); }
      }
      requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }
  /** Shows [el] at opacity [v]; at 0 it is also invisible, so it takes no click and no focus. */
  const showAt = (el, v) => { el.hidden = false; el.style.opacity = fmt(v, 3); el.style.visibility = v > 0 ? '' : 'hidden'; };

  // 17a. Boot (M02): studio_logo.gd's timeline --------------------------------------------------

  /** studio_logo.gd's timeline in seconds, read from the script each call (no copies). END_AT is
   *  FADE_AT + FADE_SECONDS in the script, so it is computed the same way here. */
  function logoConsts() {
    const k = (n) => today.konst('studio_logo.gd', n);
    const c = { swap: k('SWAP_AT'), hopS: k('BOUNCE_SECONDS'), hopPx: k('BOUNCE_PX'), nameAt: k('NAME_IN_AT'), nameS: k('NAME_IN_SECONDS'),
      fadeAt: k('FADE_AT'), fadeS: k('FADE_SECONDS'), skipRate: k('SKIP_FADE_RATE'), handS: k('HANDOVER_SECONDS'), guardS: k('INPUT_GUARD_SECONDS'),
      sweepS: k('BAR_SWEEP_SECONDS') };
    c.end = c.fadeAt + c.fadeS;
    return c;
  }
  /** GLSL / Godot smoothstep. */
  const smoothstep = (e0, e1, x) => { const t = Math.min(1, Math.max(0, (x - e0) / (e1 - e0))); return t * t * (3 - 2 * t); };
  /**
   * The boot plan: the whole boot as times (seconds of wall time from the logo's first frame) for
   * cfg {load, skip}: load = when the title scene has loaded; skip = when a skip press lands (null:
   * none). Rules, from studio_logo.gd and brief 5.2 / 5.8:
   * - the logo plays to FADE_AT (or jumps there on a skip) and holds whole until the title loads;
   * - the shared indicator (indicatorSpan) begins when the logo starts to wait (holdAt);
   * - the fade runs FADE_SECONDS, SKIP_FADE_RATE times faster once skipping;
   * - the hand-over cover clears over HANDOVER_SECONDS; input is swallowed until
   *   INPUT_GUARD_SECONDS after the cut; the title entrance takes motion.stagger.total.
   * Returns {c, load, skip, holdAt, fadeStart, handover, clear, guardEnd, entranceEnd, ind:
   * {beginAt, showAt, readyAt, hideAt, shown}}; ind.shown is how long the line is up (s).
   */
  function bootPlan(cfg) {
    const c = logoConsts();
    const L = Math.max(0, cfg.load), S = cfg.skip === null || cfg.skip === undefined ? null : Math.max(0, cfg.skip);
    const holdAt = S !== null && S < c.fadeAt ? S : c.fadeAt;
    const span = indicatorSpan(holdAt * 1000, L * 1000);
    const ind = { beginAt: L > holdAt ? holdAt : null, showAt: span ? span.on / 1000 : null, readyAt: L, hideAt: null, shown: 0 };
    const fadeStart = Math.max(holdAt, L, span ? span.off / 1000 : 0);
    let handover;
    if (S !== null && S <= fadeStart) handover = fadeStart + c.fadeS / c.skipRate;
    else if (S !== null && S < fadeStart + c.fadeS) handover = S + (1 - (S - fadeStart) / c.fadeS) * (c.fadeS / c.skipRate);
    else handover = fadeStart + c.fadeS;
    if (ind.showAt !== null) { ind.hideAt = handover; ind.shown = handover - ind.showAt; }
    return { c, load: L, skip: S !== null && S < handover ? S : null, holdAt, fadeStart, handover, clear: handover + c.handS, guardEnd: handover + c.guardS,
      entranceEnd: handover + num('motion.stagger.total') / 1000, ind };
  }
  /** What the boot screen shows at wall time [w] (s) on plan [tl]; [reduced] drops the hop. */
  function bootStateAt(tl, w, reduced) {
    const c = tl.c;
    if (w < 0) return { phase: 'launch' };
    if (w >= tl.handover) {
      return { phase: w < tl.clear ? 'handover' : w < tl.guardEnd ? 'guard' : 'title', cover: Math.min(1, Math.max(0, 1 - (w - tl.handover) / c.handS)), entrance: w - tl.handover, guard: w < tl.guardEnd };
    }
    let e = tl.skip !== null && w >= tl.skip && tl.skip < c.fadeAt ? c.fadeAt : Math.min(w, c.fadeAt);
    if (w > tl.fadeStart) {
      const S = tl.skip;
      let p;
      if (S !== null && S <= tl.fadeStart) p = ((w - tl.fadeStart) * c.skipRate) / c.fadeS;
      else if (S !== null && w > S) p = (S - tl.fadeStart) / c.fadeS + ((w - S) * c.skipRate) / c.fadeS;
      else p = (w - tl.fadeStart) / c.fadeS;
      e = c.fadeAt + c.fadeS * Math.min(1, Math.max(0, p));
    }
    const hop = Math.min(1, Math.max(0, (e - c.swap) / c.hopS));
    const ind = tl.ind;
    return {
      phase: w < tl.holdAt ? 'logo' : w < tl.fadeStart ? 'hold' : 'fade', e,
      grin: e >= c.swap, lift: reduced ? 0 : c.hopPx * Math.sin(Math.PI * hop),
      name: smoothstep(c.nameAt, c.nameAt + c.nameS, e), fade: Math.min(1, Math.max(0, (e - c.fadeAt) / c.fadeS)),
      bar: ind.showAt !== null && w >= ind.showAt ? (w >= ind.readyAt ? 'done' : 'running') : 'hidden', barTime: ind.showAt !== null ? w - ind.showAt : 0,
    };
  }
  /** The boot page's state: its frames, the live clock (t0, skip), a frozen time from a seek, its
   *  data (<script data-wo-boot-data>: load, engine, measured) and the live frame's event log. */
  const boot = { frames: [], log: [], data: null, t0: null, skip: null, frozenAt: null, marks: {} };
  /** A boot frame's config: its data-wo-boot ("t=0.45 load=3 skip=0.2"), then the URL (t, load,
   *  skip), then the page data's load. A frame with t is frozen at that time. */
  function bootCfg(canvas) {
    const own = Object.fromEntries((canvas.dataset.woBoot || '').split(/\s+/).filter(Boolean).map((kv) => kv.split('=')));
    const pick = (k) => (own[k] !== undefined ? Number(own[k]) : url.get(k) !== null && url.get(k) !== '' ? Number(url.get(k)) : undefined);
    const t = pick('t'), load = pick('load'), skip = pick('skip');
    return { frozen: t !== undefined, t, load: load !== undefined ? load : boot.data.load, skip: skip !== undefined ? skip : null };
  }
  /** Boot part [n] ([data-wo-boot-part]) of a frame canvas. */
  const bootPart = (root, n) => root.querySelector(`[data-wo-boot-part="${n}"]`);
  /** Draws boot state [st] into a frame canvas; a [frozen] frame seeks the sweep and the title's
   *  entrance to their times and pauses them (seekAnimations). */
  function bootDraw(canvas, st, frozen) {
    const live = ['logo', 'hold', 'fade'].includes(st.phase);
    const show = (el, on) => { if (el) el.hidden = !on; };
    show(bootPart(canvas, 'launch'), st.phase === 'launch');
    show(bootPart(canvas, 'logo'), live);
    const title = bootPart(canvas, 'title');
    show(title, !live && st.phase !== 'launch');
    bootPart(canvas, 'cover').style.opacity = st.phase === 'launch' || live ? 0 : fmt(st.cover, 4);
    if (live) {
      bootPart(canvas, 'grin').style.visibility = st.grin ? 'visible' : 'hidden';
      bootPart(canvas, 'mascot').style.transform = `translateY(${fmt(-st.lift, 3)}px)`;
      bootPart(canvas, 'name').style.opacity = fmt(st.name, 4);
      bootPart(canvas, 'fade').style.opacity = fmt(st.fade, 4);
      const bar = bootPart(canvas, 'bar');
      bar.style.visibility = st.bar === 'hidden' ? 'hidden' : 'visible';
      bar.classList.toggle('is-running', st.bar === 'running');
      bar.classList.toggle('is-done', st.bar === 'done');
      if (frozen) seekAnimations(bar, st.barTime * 1000);
    }
    if (title && !live && st.phase !== 'launch') {
      // The title entrance (5.2 step 7): played once live; a frozen frame seeks it to its time.
      if (!frozen) { if (!title._woEntered) { title._woEntered = true; playAnimations(title); stagger(title); } return; }
      if (title._woTau === st.entrance) return;
      title._woTau = st.entrance;
      stagger(title);
      seekAnimations(title, st.entrance * 1000);
    }
  }
  /** Starts (or restarts) the live boot at the launch image, the page data's engine s before the logo. */
  function bootStart() {
    boot.t0 = performance.now() + boot.data.engine * 1000;
    boot.skip = null;
    boot.frozenAt = null;
    boot.log = [{ at: -boot.data.engine, what: 'launch image' }];
    boot.marks = {};
    for (const f of boot.frames) if (!f.cfg.frozen) { const t = bootPart(f.canvas, 'title'); if (t) t._woEntered = false; }
  }
  /** Wall time on the live boot clock (s from the logo's first frame). */
  const bootNow = () => (performance.now() - boot.t0) / 1000;
  /** The live frames' plan with the presses so far. */
  function bootLivePlan() {
    const f = boot.frames.find((x) => !x.cfg.frozen);
    return bootPlan({ load: f ? f.cfg.load : boot.data.load, skip: boot.skip });
  }
  /** A press (wo:press) on the live boot: a skip before the hand-over, swallowed during the input
   *  guard, the title's after it (all logged for WO.boot.log). */
  document.addEventListener('wo:press', (e) => {
    if (!boot.data || boot.frozenAt !== null) return;
    const w = Math.max(0, bootNow()), tl = bootLivePlan(), kind = e.detail.kind;
    if (w < tl.handover) { if (boot.skip === null) { boot.skip = w; boot.log.push({ at: w, what: 'skip (' + kind + ')' }); } }
    else boot.log.push({ at: w, what: (w < tl.guardEnd ? 'swallowed by the input guard (' : 'title takes it (') + kind + ')' });
  });
  /** Boot seek buttons: [data-wo-boot-seek="<s>"] freezes the live frames at that time; "replay"
   *  plays the boot again from the launch image. */
  addEventListener('click', (e) => {
    const b = e.target.closest && e.target.closest('[data-wo-boot-seek]');
    if (!b || !boot.data) return;
    if (b.dataset.woBootSeek === 'replay') bootStart(); else boot.frozenAt = Number(b.dataset.woBootSeek);
  });
  /** One clock step: draws every live frame and logs each phase change once, then the readout. */
  function bootTick() {
    const w = boot.frozenAt !== null ? boot.frozenAt : bootNow();
    const reduced = WO.motion.reduced();
    for (const f of boot.frames) {
      if (f.cfg.frozen) continue;
      const st = bootStateAt(bootPlan({ load: f.cfg.load, skip: boot.skip }), w, reduced);
      bootDraw(f.canvas, st, boot.frozenAt !== null);
      const key = st.phase + (st.bar ? ':' + st.bar : '');
      if (boot.frozenAt === null && boot.marks[f.i] !== key) { boot.marks[f.i] = key; boot.log.push({ at: Number(fmt(w, 3)), what: key }); }
    }
    const out = document.querySelector('[data-wo-boot-readout]');
    if (!out) return;
    const tl = bootLivePlan(), st = bootStateAt(tl, w, reduced);
    const does = w < 0 ? 'engine starting' : w < tl.handover ? 'a press skips' : w < tl.guardEnd ? 'presses are swallowed (input guard)' : 'the title takes input';
    out.textContent = `t ${fmt(w, 2)} s · ${st.phase}${st.bar && st.bar !== 'hidden' ? ' · sweep ' + st.bar : ''} · ${does}` + (boot.skip !== null ? ` · skipped at ${fmt(boot.skip, 2)} s` : '');
  }
  /** The boot's accept numbers from bootPlan (also WO.boot.check() for --eval): the unskipped and
   *  skipped sequences, a 3 s slow load, the shortest indicator ever shown over loads 0 to 12 s and
   *  six skip times, and the fastest repeat (sweep and reduced pulse) against 3 a second. */
  function bootCheck() {
    const d = boot.data, c = logoConsts();
    const plain = bootPlan({ load: d.load, skip: null }), first = bootPlan({ load: d.load, skip: 0 }), slow = bootPlan({ load: 3, skip: null });
    let minShown = Infinity, worst = null, maxSeq = 0;
    for (let i = 0; i <= 1200; i++) {
      const L = i / 100;
      for (const S of [null, 0, 0.3, 1.0, 1.7, 1.9]) {
        const tl = bootPlan({ load: L, skip: S });
        if (tl.ind.showAt !== null && tl.ind.shown < minShown) { minShown = tl.ind.shown; worst = { load: L, skip: S }; }
        if (L <= c.fadeAt && S === null) maxSeq = Math.max(maxSeq, tl.handover);
      }
    }
    const sweepHz = 1 / c.sweepS, pulseHz = 1000 / (2 * num('motion.reduced-pulse'));
    return {
      unskipped: { handover: plain.handover, clear: plain.clear, input: plain.guardEnd, entranceEnd: plain.entranceEnd, indicator: plain.ind.showAt !== null },
      skippedFrame1: { handover: first.handover, input: first.guardEnd, indicatorShown: first.ind.shown },
      slow3s: { showAt: slow.ind.showAt, readyAt: slow.ind.readyAt, fadeStart: slow.fadeStart, handover: slow.handover, shown: slow.ind.shown },
      sequenceMax: maxSeq, sequenceLimit: c.end + c.handS,
      indicatorMinShown: minShown === Infinity ? null : minShown, indicatorWorst: worst, indicatorMinRule: num('timing.indicator.min-show') / 1000,
      flashesPerSecond: { sweep: sweepHz, reducedPulse: pulseHz, limit: 3 },
      measured: d.measured,
    };
  }
  /** The boot timing table ([data-wo-boot-sheet]), every cell from bootCheck. */
  function bootSheet() {
    const el = document.querySelector('[data-wo-boot-sheet]');
    if (!el) return;
    const k = bootCheck(), d = boot.data;
    const s2 = (x) => (x === null ? 'never' : fmt(x, 2) + ' s');
    const ok = (b) => h('span', { class: b ? 'is-ok' : 'is-bad' }, b ? 'pass' : 'FAIL');
    const td = (...parts) => h('td', {}, ...parts);
    const fast = Math.max(k.flashesPerSecond.sweep, k.flashesPerSecond.reducedPulse);
    el.replaceChildren(table(['Moment', 'This mockup', 'Check'], [
      ['Title loads (measured median)', s2(d.load), d.loadSource],
      ['Logo ends, cut to the title', s2(k.unskipped.handover), 'studio_logo.gd FADE_AT + FADE_SECONDS'],
      ['Cover clear', s2(k.unskipped.clear), td(ok(k.unskipped.clear <= k.sequenceLimit + 1e-9), ' whole sequence ≤ ' + s2(k.sequenceLimit) + ' (2.0 s + 0.3 s hand-over)')],
      ['Title takes input', s2(k.unskipped.input), 'measured today ' + d.measured.inputUnskipped.join(' to ') + ' s (adds the hand-over frame and 1/30 s steps)'],
      ['Skip on the first frame: cut', s2(k.skippedFrame1.handover), 'measured today ' + d.measured.handoverSkippedFrame1.join(' to ') + ' s' + (k.skippedFrame1.indicatorShown ? '; the line shows ' + s2(k.skippedFrame1.indicatorShown) : '')],
      ['Skip on the first frame: input', s2(k.skippedFrame1.input), 'measured today ' + d.measured.inputSkippedFrame1.join(' to ') + ' s'],
      ['Slow load 3 s: line shows', s2(k.slow3s.showAt), 'waits timing.indicator.delay after the hold at ' + s2(logoConsts().fadeAt)],
      ['Slow load 3 s: cut', s2(k.slow3s.handover), 'line up ' + s2(k.slow3s.shown)],
      ['Shortest line ever shown (loads 0 to 12 s, 6 skip times)', s2(k.indicatorMinShown), td(ok(k.indicatorMinShown === null || k.indicatorMinShown >= k.indicatorMinRule - 1e-9), ' ≥ ' + s2(k.indicatorMinRule))],
      ['Fastest repeat', fmt(fast, 2) + ' per s', td(ok(fast <= 3), ' sweep ' + fmt(k.flashesPerSecond.sweep, 2) + ' Hz, reduced pulse ' + fmt(k.flashesPerSecond.reducedPulse, 2) + ' Hz; limit 3')],
    ]));
  }
  /** Sets up the boot page on each render: its data, frames (canvases with data-wo-boot), the frozen
   *  frames, the table, and on the first render the live clock. */
  function boots() {
    const dataEl = document.querySelector('script[data-wo-boot-data]');
    if (!dataEl) return;
    boot.data = JSON.parse(dataEl.textContent);
    boot.frames = frames.map((f, i) => ({ i, canvas: f.canvas })).filter((f) => f.canvas.hasAttribute('data-wo-boot')).map((f) => Object.assign(f, { cfg: bootCfg(f.canvas) }));
    for (const f of boot.frames) if (f.cfg.frozen) bootDraw(f.canvas, bootStateAt(bootPlan(f.cfg), f.cfg.t, WO.motion.reduced()), true);
    bootSheet();
    if (boot.t0 === null) { bootStart(); players.push({ name: 'boot', tick: bootTick }); }
  }
  Object.assign(boot, { plan: bootPlan, stateAt: bootStateAt, check: bootCheck });
  WO.boot = boot;

  // 17b. Screen changes (M04, M04b): door-led fades, resume card, loading view or card ----------

  /**
   * DialogueBoxes.read_seconds (dialogue_boxes.gd) in ms, written once here: the base plus one
   * character's time at the language's reading_cps (languages.json), capped, or the base plus a time
   * per word, whichever is longer. The constants are read from dialogue_boxes.gd. [code] is a
   * languages.json code; a language with no reading_cps uses English's, as the game does.
   */
  function readMs(text, code = 'en') {
    const k = (name) => today.konst('dialogue_boxes.gd', name);
    const base = k('READ_SECONDS_BASE');
    const en = langField('en', 'reading_cps');
    const cps = langField(code, 'reading_cps') || en;
    const t = text.replace(/\n/g, ' ');
    const cap = base + (k('READ_SECONDS_MAX_BY_CHARACTERS') - base) * (en / cps);
    const byChars = Math.min(base + t.length / cps, cap);
    const words = t.split(' ').filter(Boolean).length;
    return Math.max(byChars, base + k('READ_SECONDS_PER_WORD') * words) * 1000;
  }
  /** Today's location card hold in ms: the literal in main.gd's _show_top_card(location / objective,
   *  <seconds>) call (no constant holds it yet). */
  const topCardHoldMs = () => Number(today.match('main.gd', /_show_top_card\("%s\\n%s" % \[location, _objective\(\)\], ([\d.]+)\)/)) * 1000;

  /** Adds keyframe [t ms, v] to track [k] of [map]. Keys go in time order; two keys at one time make
   *  a step (the later one holds from that time). */
  const addKey = (map, k, t, v) => (map[k] = map[k] || []).push([t, v]);
  /** A track's value at [t] ms: linear between keys, the last key's value after it, 0 when empty. */
  function sampleTrack(kf, t) {
    if (!kf || !kf.length) return 0;
    let prev = kf[0];
    for (const cur of kf) {
      if (t < cur[0]) return cur[0] > prev[0] ? prev[1] + ((cur[1] - prev[1]) * (t - prev[0])) / (cur[0] - prev[0]) : prev[1];
      prev = cur;
    }
    return prev[1];
  }
  /** A step list's value at [t] ms: the value of the last step at or before [t] ("" before any). */
  const stepAt = (steps, t) => steps.reduce((v, [ti, vi]) => (t >= ti ? vi : v), '');

  /**
   * The plan of one screen change. [mode]: "today" (a cut: the top card shows over live play),
   * "m04" (door-led fades, the resume card after Continue, the first-visit name, a loading view only
   * past timing.loading-view.delay) or "m04b" (a loading card on every change: comparison only).
   * [moment]: "continue" (from the title) or "room" (through a door). [o]: load (ms of work behind
   * the change, starting in the dark), tip (text or ""), art ("room" or "key", M04b Continue only),
   * presses (ms from the moment's start).
   *
   * Every time is in ms from the moment's start (CONTINUE pressed, or the door done). Returns
   * {tracks, bits, sweep, marks}: tracks are opacities of the abstract parts from (the old screen),
   * to (the new room), card (resume card, first-visit name or top card), view (the loading view or
   * card) and fade (the dark); bits are opacities inside the view (dim, name, sweep, status, tip,
   * prompt, keyart); sweep is [[ms, ""|"running"|"percent"|"done"]]. marks: out (dark), ready (fade-in starts),
   * guard [from, to] (presses ignored) or null, closeAt, canClose, indicator {on, off} or null,
   * view {on, full} or null, percent {from, start, end} or null, controlAt (play answers again),
   * added (max(controlAt, end of the last fade into play): the time the brief's tables count),
   * end (the last change). Values come from the token file, main.gd and dialogue_boxes.gd.
   */
  function seqPlan(mode, moment, o = {}) {
    const tracks = {}, bits = {}, sweep = [];
    const m = { mode, moment, load: o.load || 0, guard: null, indicator: null, view: null, percent: null };
    if (mode === 'today') {
      addKey(tracks, 'to', 0, 1);
      return { tracks, bits, sweep, marks: Object.assign(m, { out: 0, ready: 0, closeAt: 0, canClose: 0, controlAt: 0, added: 0, end: 0 }) };
    }
    const fadeOut = num('timing.fade.out'), fadeIn = num('timing.fade.in');
    // The dark hold is a room change's (its token says so); Continue fades straight back in (5.3).
    const hold = moment === 'room' ? num('timing.fade.hold') : 0;
    const ret = num('timing.fade.control-return');
    const minShow = num('timing.indicator.min-show');
    const panelIn = num('motion.panel.in'), panelOut = num('motion.panel.out');
    const guardMs = num('timing.resume-card.guard');
    const dim = num('loading.dim');
    const presses = (o.presses || []).slice().sort((a, b) => a - b);
    const loadStart = fadeOut, loadEnd = fadeOut + m.load;
    m.out = fadeOut;
    // The shared indicator (5.8) over the work. Past timing.loading-view.percent-after a real
    // percent joins (5.6).
    const ind = indicatorSpan(loadStart, loadEnd);
    m.indicator = ind;
    if (m.load > num('timing.loading-view.percent-after')) m.percent = { from: loadStart + num('timing.loading-view.percent-after'), start: loadStart, end: loadEnd };
    // Out: the old screen fades to dark; the rooms swap in the dark.
    addKey(tracks, 'fade', 0, 0); addKey(tracks, 'fade', fadeOut, 1);
    addKey(tracks, 'from', 0, 1); addKey(tracks, 'from', fadeOut, 1); addKey(tracks, 'from', fadeOut, 0);
    addKey(tracks, 'to', 0, 0); addKey(tracks, 'to', fadeOut, 0); addKey(tracks, 'to', fadeOut, 1);
    // The sweep: the rule only, then running while the work is pending past the delay, then a still
    // fill to the real progress once the percent joins (5.1: a looped indicator for 2 to 10 s, a
    // percent bar past 10 s), then lit and still the moment the work ends, so nothing keeps moving
    // as if work were pending (APL-PROG).
    sweep.push([0, '']);
    if (ind) sweep.push([ind.on, 'running']);
    if (m.percent) sweep.push([m.percent.from, 'percent']);
    sweep.push([loadEnd, 'done']);

    if (mode === 'm04') {
      // The loading view joins only past its delay (5.6), the next room dimmed under it.
      const view = m.load > num('timing.loading-view.delay') ? { on: loadStart + num('timing.loading-view.delay') } : null;
      if (view) view.full = view.on + panelIn;
      m.view = view;
      // The view, once fully in, stays its minimum show like the indicator (AX-CLPB).
      const ready = Math.max(fadeOut + hold, loadEnd, ind ? ind.off : 0, view ? view.full + minShow : 0);
      if (view) {
        // The dark gives way to the dimmed room: the dim steps in under the full dark and only the
        // dark lifts, so the screen brightens once (one dark dip, 7.3 M04b accept 4); the words fade
        // in with it. The view then cross-fades into the room.
        addKey(tracks, 'fade', view.on, 1); addKey(tracks, 'fade', view.full, 0);
        addKey(bits, 'dim', view.on, 0); addKey(bits, 'dim', view.on, dim);
        // M04's view has one line of words: the room name as "RESTORING <ROOM>" over the indicator
        // (5.6; 7.3 M04 states). The H1 name above it is M04b's card layout; here it would say the
        // name twice. The line names the place, so it stays until the view leaves; the lit, still
        // rule is what says the work is done (APL-PROG).
        addKey(bits, 'status', view.on, 0); addKey(bits, 'status', view.full, 1);
      } else {
        addKey(tracks, 'fade', ready, 1); addKey(tracks, 'fade', ready + fadeIn, 0);
      }
      if (ind) {
        // On the dark the indicator shows alone, where it will sit in the view (no jump).
        const off = view ? ready + fadeIn : ind.off;
        addKey(tracks, 'view', ind.on, 0); addKey(tracks, 'view', ind.on, 1);
        if (view) { addKey(tracks, 'view', ready, 1); addKey(tracks, 'view', off, 0); } else { addKey(tracks, 'view', off, 1); addKey(tracks, 'view', off, 0); }
        addKey(bits, 'sweep', ind.on, 0); addKey(bits, 'sweep', ind.on, 1);
      }
      // After a loading view the card waits for it to leave, so the room name never shows twice.
      const shown = view ? ready + fadeIn : ready;
      if (moment === 'continue') {
        // The resume card (5.3): today's top card restyled over the paused room, closed by a press
        // after its guard or by its hold; the hold and guard start once it is fully in. It rises with
        // the room under the fade, or after a loading view fades in over motion.panel.in.
        const cardIn = view ? shown + panelIn : ready + fadeIn, auto = cardIn + num('timing.resume-card.hold');
        m.guard = [cardIn, cardIn + guardMs];
        const press = presses.find((p) => p >= m.guard[1] && p < auto);
        m.canClose = m.guard[1];
        m.closeAt = press === undefined ? auto : press;
        addKey(tracks, 'card', shown, 0);
        if (!view) addKey(tracks, 'card', shown, 1);
        addKey(tracks, 'card', cardIn, 1); addKey(tracks, 'card', m.closeAt, 1); addKey(tracks, 'card', m.closeAt + panelOut, 0);
        m.controlAt = m.closeAt;
      } else {
        // The first-visit name over live play (5.5 step 4): never blocks input, no tips.
        const fv = num('timing.first-visit.fade'), fvHold = num('timing.first-visit.hold');
        addKey(tracks, 'card', shown, 0); addKey(tracks, 'card', shown + fv, 1); addKey(tracks, 'card', shown + fv + fvHold, 1); addKey(tracks, 'card', shown + 2 * fv + fvHold, 0);
        m.closeAt = m.canClose = ready;
        m.controlAt = ready + ret * fadeIn;
      }
      m.ready = ready;
      m.added = Math.max(m.controlAt, ready + fadeIn);
    } else if (mode === 'm04b') {
      // The loading card on every change (7.3 M04b, comparison only): in over motion.panel.in, held
      // H = max(minimum show, load, read(tip)), out by a cross-fade into the room.
      const cardIn = fadeOut + panelIn;
      m.guard = [cardIn, cardIn + guardMs];
      m.read = o.tip ? readMs(o.tip) : 0;
      // It may close once it has shown its minimum, the work is done and the indicator, if it showed,
      // has had its own minimum show; a press then closes it at once.
      const earliest = Math.max(cardIn + minShow, loadEnd, ind ? ind.on + minShow : 0);
      m.canClose = Math.max(earliest, m.guard[1]);
      const auto = Math.max(earliest, cardIn + m.read);
      const press = presses.find((p) => p >= m.guard[1] && p < auto);
      m.closeAt = press === undefined ? auto : Math.max(press, earliest);
      // In: the card steps in under the full dark with its dim, then only the dark lifts while its words
      // fade in, so the screen brightens once (one dark dip, accept 4). The title key art (art=key,
      // Continue only) covers the room, so it fades in itself and the dark lifts behind it.
      const keyArt = moment === 'continue' && o.art === 'key';
      if (keyArt) { addKey(tracks, 'fade', cardIn, 1); addKey(tracks, 'fade', cardIn, 0); addKey(bits, 'keyart', fadeOut, 0); addKey(bits, 'keyart', cardIn, 1); } else addKey(tracks, 'fade', cardIn, 0);
      addKey(tracks, 'view', fadeOut, 0); addKey(tracks, 'view', fadeOut, 1); addKey(tracks, 'view', m.closeAt, 1); addKey(tracks, 'view', m.closeAt + fadeIn, 0);
      addKey(bits, 'dim', 0, dim);
      for (const b of ['name', 'sweep'].concat(o.tip ? ['tip'] : [])) { addKey(bits, b, fadeOut, 0); addKey(bits, b, cardIn, 1); }
      // The status line shows only while the indicator runs (7.3 M04b layout 4).
      if (ind) { addKey(bits, 'status', ind.on, 0); addKey(bits, 'status', ind.on, 1); addKey(bits, 'status', loadEnd, 1); addKey(bits, 'status', loadEnd, 0); }
      // The prompt only once a press would close the card (layout 6).
      if (m.canClose < m.closeAt) { addKey(bits, 'prompt', m.canClose, 0); addKey(bits, 'prompt', m.canClose, 1); }
      // Then today's top card repeats the name over the room for its own hold and fade (main.gd),
      // shown as today's is (at once), once the card has left, so the name never shows twice.
      const topIn = m.closeAt + fadeIn, topFade = today.konst('main.gd', 'TOP_CARD_FADE_SECONDS') * 1000;
      addKey(tracks, 'card', topIn, 0); addKey(tracks, 'card', topIn, 1); addKey(tracks, 'card', topIn + topCardHoldMs(), 1); addKey(tracks, 'card', topIn + topCardHoldMs() + topFade, 0);
      m.ready = m.closeAt;
      m.controlAt = m.closeAt + ret * fadeIn;
      m.added = m.closeAt + fadeIn;
    } else throw new Error('no sequence mode "' + mode + '"');
    m.end = Math.max(0, ...[...Object.values(tracks), ...Object.values(bits)].flat().map((k) => k[0]), ...sweep.map((x) => x[0]));
    return { tracks, bits, sweep, marks: m };
  }
  /** The added time of [mode] at [moment] with options [o], in ms: {min, max, control}. min is with a
   *  press at the first moment one counts, max with no press (the ranges of brief 7.3's table). */
  function seqCost(mode, moment, o) {
    const slow = seqPlan(mode, moment, Object.assign({}, o, { presses: [] }));
    const g = slow.marks.guard;
    const fast = g ? seqPlan(mode, moment, Object.assign({}, o, { presses: [g[1]] })) : slow;
    return { min: fast.marks.added, max: slow.marks.added, control: fast.marks.controlAt };
  }

  /** The page's sequence data (<script type="application/json" data-wo-seq-data>), parsed once:
   *  script (moment order), beat-ms, measured-load-ms, run and moments {label, from, to, ...words}:
   *  from and to name the moment's [data-wo-seq-part] rooms; every other key is a word the moment
   *  shows in its [data-wo-seq-text="<key>"] elements. */
  function seqData() {
    if (seqData.cache === undefined) {
      const el = document.querySelector('script[data-wo-seq-data]');
      seqData.cache = el ? JSON.parse(el.textContent) : null;
    }
    return seqData.cache;
  }
  /** The tip text on the page (its first [data-wo-seq-bit="tip"]), a <br> read as a line break, as
   *  read_seconds counts it; "" when the page has none. */
  function seqTip() {
    const el = document.querySelector('[data-wo-seq-bit="tip"]');
    return el ? [...el.childNodes].map((n) => (n.nodeName === 'BR' ? '\n' : n.textContent)).join('').trim() : '';
  }
  /** Plan options for [moment] from the URL: load (?load= in s, else the page's measured ms), tip
   *  (?tip=1) and art (?art=key). */
  function seqOptions(moment) {
    const d = seqData(), s = url.get('load');
    return { load: s ? Number(s) * 1000 : d['measured-load-ms'][moment], tip: url.get('tip') === '1' ? seqTip() : '', art: url.get('art') === 'key' ? 'key' : 'room' };
  }
  /** The URL's single-stage mode: M04 (the chosen path) unless ?loading=m04b. */
  const autoMode = () => (url.get('loading') === 'm04b' ? 'm04b' : 'm04');
  /** A stage's mode: data-wo-seq="m04" or "m04b", or "auto" (autoMode). */
  const stageMode = (el) => (el.dataset.woSeq === 'auto' ? autoMode() : el.dataset.woSeq);
  /** The stages that are showing: every frame canvas with data-wo-seq outside a hidden section. */
  const seqStages = () => frames.filter((f) => f.canvas.dataset.woSeq !== undefined && !f.host.closest('[hidden]')).map((f) => ({ el: f.canvas, mode: stageMode(f.canvas) }));

  /** The page clock: start (performance.now() of the loop's start), presses ({i: moment index, ms}),
   *  the cached schedule and the last painted time. */
  const seq = { start: null, presses: null, sched: null, now: null };
  /** Presses from ?press=<moment>:<ms>[,...] (for captures of the "pressed" path). */
  function urlPresses() {
    const d = seqData();
    return (url.get('press') || '').split(',').filter(Boolean).map((x) => {
      const [a, b] = x.split(':');
      return { i: d.script.indexOf(a), ms: Number(b) };
    });
  }
  /**
   * The schedule: the script's moments one after another. A moment lasts as long as its slowest
   * stage's plan plus the page's beat of play, so side-by-side stages start every moment together on
   * one clock (7.3 M04b accept 11). Returns rows {i, moment, start, span, plans: {mode: plan}} and
   * .total (ms).
   */
  function seqSchedule() {
    const d = seqData(), modes = [...new Set(seqStages().map((x) => x.mode))];
    let t = 0;
    const rows = d.script.map((moment, i) => {
      const presses = seq.presses.filter((p) => p.i === i).map((p) => p.ms);
      const plans = {};
      for (const mode of modes) plans[mode] = seqPlan(mode, moment, Object.assign(seqOptions(moment), { presses }));
      const span = Math.max(0, ...Object.values(plans).map((p) => p.marks.end)) + d['beat-ms'];
      const row = { i, moment, start: t, span, plans };
      t += span;
      return row;
    });
    rows.total = t;
    return rows;
  }
  /** ?at= as an absolute clock time: ms, or "<moment>:<ms>" from that moment's start. null when absent. */
  function seqAt(sched) {
    const at = url.get('at');
    if (!at) return null;
    const [a, b] = at.split(':');
    if (b === undefined) return Number(a);
    const row = sched.find((r) => r.moment === a);
    if (!row) throw new Error('at=' + at + ': no moment "' + a + '"');
    return row.start + Number(b);
  }
  /** The parts every moment shares, by their plan track: the card (resume card, first-visit name or
   *  today's top card), the loading view or card, and the screen fade. Rooms come from the data. */
  const SHARED_PARTS = { card: 'card', load: 'view', fade: 'fade' };
  /**
   * A location name as the player fills it: each " / " separator is glued to the word before it
   * (a no-break space), so a long name breaks after the slash, never before it ("RECORDS ACCESS /"
   * then "FIRST COPY"). Godot needs the same rule where a Label wraps a location name.
   */
  const glueSlashes = (word) => word.replace(/ \/ /g, ' / ');
  /**
   * Paints stage [s] at [local] ms into [row]'s moment: the moment's from and to rooms and the shared
   * parts follow their tracks and every other [data-wo-seq-part] is hidden; each [data-wo-seq-text]
   * shows the moment's word of that key (glueSlashes; a missing key is a problem, not a blank);
   * inside the load part each [data-wo-seq-bit] follows its bit track (a bit with no track is hidden
   * and takes no room), the sweep gets is-running, is-percent (with --wo-sweep-done, the share of
   * the work done, 0 to 1) or is-done, and [data-wo-seq-percent] the same share as a whole percent
   * past 10 s. A frozen clock ([frozen]) seeks the running sweep to its own time.
   */
  function paintStage(s, row, local, frozen) {
    const map = seqData().moments[row.moment], p = row.plans[s.mode];
    const byPart = Object.assign({ [map.from]: 'from', [map.to]: 'to' }, SHARED_PARTS);
    for (const el of s.el.querySelectorAll('[data-wo-seq-part]')) {
      const track = byPart[el.dataset.woSeqPart];
      showAt(el, track ? sampleTrack(p.tracks[track], local) : 0);
    }
    for (const el of s.el.querySelectorAll('[data-wo-seq-text]')) {
      const word = map[el.dataset.woSeqText];
      if (typeof word !== 'string') throw new Error('moment "' + row.moment + '" has no word "' + el.dataset.woSeqText + '"');
      if (el.textContent !== glueSlashes(word)) el.textContent = glueSlashes(word);
    }
    const view = s.el.querySelector('[data-wo-seq-part="load"]');
    if (!view) return;
    // A bit this plan never shows takes no room (hidden), so the view's column centres on what it
    // does show (no space kept for a tip that is off). A bit that shows later keeps its room while
    // at 0, so nothing in the column jumps when it appears.
    for (const b of view.querySelectorAll('[data-wo-seq-bit]')) {
      const kf = p.bits[b.dataset.woSeqBit];
      if (kf) showAt(b, sampleTrack(kf, local));
      else { showAt(b, 0); b.hidden = true; }
    }
    const st = stepAt(p.sweep, local);
    const pc = p.marks.percent;
    const done = pc ? Math.min(1, Math.max(0, (local - pc.start) / (pc.end - pc.start))) : 0;
    for (const sw of view.querySelectorAll('.wo-sweep')) {
      for (const k of ['running', 'percent', 'done']) sw.classList.toggle('is-' + k, st === k);
      sw.style.setProperty('--wo-sweep-done', fmt(done, 4));
      if (frozen && st === 'running') seekAnimations(sw, local - p.marks.indicator.on);
    }
    for (const el of view.querySelectorAll('[data-wo-seq-percent]')) el.textContent = st === 'percent' ? ' ' + Math.floor(100 * done) + '%' : '';
  }
  /** Paints every stage at the clock's time (frozen at ?at=, else running and looping). */
  function seqRender() {
    if (seq.presses === null) seq.presses = urlPresses();
    let sched = seq.sched || (seq.sched = seqSchedule());
    let c = seqAt(sched);
    const frozen = c !== null;
    if (!frozen) {
      const now = performance.now();
      if (seq.start === null) seq.start = now;
      c = now - seq.start;
      if (c >= sched.total) {
        // A new loop: presses belong to the loop they were made in.
        seq.start = now;
        seq.presses = urlPresses();
        sched = seq.sched = seqSchedule();
        c = 0;
      }
    }
    const row = sched.find((r) => c >= r.start && c < r.start + r.span) || sched[sched.length - 1];
    const local = c - row.start;
    for (const s of seqStages()) paintStage(s, row, local, frozen);
    seq.now = { c, i: row.i, moment: row.moment, local };
    const clock = strip && strip.querySelector('[data-role="seq-clock"]');
    if (clock) clock.textContent = 't ' + fmt(c / 1000, 2) + ' s · ' + seqData().moments[row.moment].label + ' +' + fmt(local / 1000, 2) + ' s';
  }
  /** A press (wo:press) lands in the moment that is playing. The plan decides whether it counts
   *  (the guards), and the schedule is remade. A frozen clock (?at=) takes no presses. */
  document.addEventListener('wo:press', () => {
    if (!seq.now || url.get('at')) return;
    seq.presses.push({ i: seq.now.i, ms: seq.now.local });
    seq.sched = null;
  });
  /** Seek buttons: [data-wo-seq-seek="<moment>:<ms>"] stops the clock at that moment (it sets ?at=,
   *  so a reload or a shared link keeps it); "live" clears ?at= and plays from the loop's start. */
  addEventListener('click', (e) => {
    const b = e.target.closest && e.target.closest('[data-wo-seq-seek]');
    if (!b || !seqData()) return;
    const v = b.dataset.woSeqSeek;
    url.set('at', v === 'live' ? null : v);
    seq.start = null;
    seq.presses = null;
    seq.sched = null;
    for (const s of seqStages()) playAnimations(s.el);
    seqRender();
  });

  /** "+0.70 s" for [ms] (display only). */
  const secs = (ms) => (ms < -0.5 ? '−' : '+') + (Math.abs(ms) / 1000).toFixed(2) + ' s';
  /** One number, or both ends named when they differ by 5 ms or more: [a] is with a press at the
   *  first moment one counts, [b] with no press. Named ends, because a difference of two ranges can
   *  run backwards ("+0.40 s to −1.30 s" reads as nonsense). */
  const span2 = (a, b) => (Math.abs(a - b) < 5 ? secs(a) : secs(a) + ' pressed at once, ' + secs(b) + ' if left alone');
  /**
   * The added-time lines for [mode] with the URL's options (7.3 M04b accept 5): per moment, "+X vs
   * today" (today is a cut, so its own plan adds nothing), "+Y vs M04" for M04b, when control comes
   * back, and the per-run total over the page's run. Ranges run from a press at the first moment it
   * counts to no press.
   */
  function seqReadout(mode) {
    const d = seqData(), costs = {};
    for (const moment of Object.keys(d.moments)) {
      const o = seqOptions(moment);
      costs[moment] = { c: seqCost(mode, moment, o), t: seqCost('today', moment, o), b: seqCost('m04', moment, o) };
    }
    const lines = Object.entries(costs).map(([moment, x]) => d.moments[moment].label + ': ' + span2(x.c.min - x.t.min, x.c.max - x.t.max) + ' vs today' + (mode === 'm04' ? '' : ', ' + span2(x.c.min - x.b.min, x.c.max - x.b.max) + ' vs M04') + '. Control back at ' + secs(x.c.control) + '.');
    const sum = (k, e) => Object.entries(d.run).reduce((a, [moment, n]) => a + n * costs[moment][k][e], 0);
    const runName = Object.entries(d.run).map(([moment, n]) => n + ' × ' + d.moments[moment].label.toLowerCase()).join(', ');
    lines.push('One run (' + runName + '): ' + span2(sum('c', 'min'), sum('c', 'max')) + ' vs today' + (mode === 'm04' ? '' : ', ' + span2(sum('c', 'min') - sum('b', 'min'), sum('c', 'max') - sum('b', 'max')) + ' vs M04') + '.');
    return { title: mode === 'm04' ? 'M04 (chosen)' : 'M04b (comparison only)', lines };
  }
  /** The added-time table (7.3 M04b): each moment and the run for today, M04, M04b without and with
   *  the tip, at the measured load. Every cell comes from seqCost, the function that plays them. */
  function seqTable() {
    const d = seqData();
    const cols = [['Today', 'today', false], ['M04 (chosen)', 'm04', false], ['M04b, no tip', 'm04b', false], ['M04b, tip read', 'm04b', true]];
    const opt = (moment, tip) => ({ load: d['measured-load-ms'][moment], tip: tip ? seqTip() : '', art: 'room' });
    const cost = (mode, moment, tip) => seqCost(mode, moment, opt(moment, tip));
    const rows = Object.keys(d.moments).map((moment) => [d.moments[moment].label].concat(cols.map(([, mode, tip]) => {
      const c = cost(mode, moment, tip);
      return span2(c.min, c.max) + (mode === 'today' ? ' (a cut)' : ', control back at ' + secs(c.control));
    })));
    rows.push(['One run'].concat(cols.map(([, mode, tip]) => {
      const sum = (e) => Object.entries(d.run).reduce((a, [moment, n]) => a + n * cost(mode, moment, tip)[e], 0);
      return span2(sum('min'), sum('max'));
    })));
    const tip = seqTip();
    return [table(['Moment'].concat(cols.map((c) => c[0])), rows), h('p', { class: 'mk-note' }, '"Pressed at once" is a press at the first moment one counts; "if left alone" is no press. Work behind each change (measured headless): ' + Object.entries(d['measured-load-ms']).map(([k, v]) => d.moments[k].label + ' ' + v + ' ms').join(', ') + '. Tip read time: ' + fmt(readMs(tip) / 1000, 2) + ' s for ' + tip.length + ' characters in ' + tip.split('\n').length + ' rows (DialogueBoxes.read_seconds).')];
  }
  /** Fills the readouts, the table and the strip line, and adds the sequence player to the clock
   *  (runs on every rerender). */
  function sequences() {
    if (!seqData()) return;
    seq.sched = null;
    for (const el of document.querySelectorAll('[data-wo-seq-readout]')) {
      const mode = el.dataset.woSeqReadout === 'auto' ? autoMode() : el.dataset.woSeqReadout;
      const r = seqReadout(mode);
      el.replaceChildren(h('strong', {}, r.title), ...r.lines.flatMap((l) => [h('br'), l]));
    }
    for (const el of document.querySelectorAll('[data-wo-seq-table]')) el.replaceChildren(...seqTable());
    if (strip) {
      let line = strip.querySelector('[data-role="seq"]');
      if (!line) {
        line = h('span', { class: 'mk-field', 'data-role': 'seq' });
        strip.querySelector('[data-role="status"]').before(line, h('span', { class: 'mk-field', 'data-role': 'seq-clock' }));
      }
      const modes = url.get('loading') === 'compare' ? ['m04', 'm04b'] : [autoMode()];
      line.textContent = modes.map((mode) => { const r = seqReadout(mode); return r.title + ': ' + r.lines.join(' '); }).join(' | ');
    }
    seqRender();
    if (!players.some((pl) => pl.name === 'sequence')) players.push({ name: 'sequence', tick: seqRender });
  }
  WO.seq = { plan: seqPlan, cost: seqCost, indicator: indicatorSpan, readMs, readout: seqReadout, schedule: () => seq.sched || seqSchedule(), now: () => seq.now };

  // ---------------------------------------------------------------------------------------------
  // 18. Root variables, rendering and live reload
  // ---------------------------------------------------------------------------------------------

  /** Sets every token's variable, the theme's, the today values', and motion helpers on :root. */
  function rootVars() {
    const s = document.documentElement.style;
    for (const p of tokens.flat.keys()) {
      try { s.setProperty(cssVar(p), tokenCss(p)); } catch (e) { problem(p + ': ' + e.message); }
    }
    themeVars(s);
    todayVars(s);
    // Derived motion values: a beacon pulse period from its rate (Hz), the reduced pulse.
    s.setProperty('--wo-beacon-period', fmt(1000 / num('alert.beacon-rate'), 3) + 'ms');
    // The dialogue backing (6.3): the HudCard colour at exactly the DIALOGUE BACKING opacity.
    s.setProperty('--wo-dialogue-backing-color', rgba(color('color.role.hud-card.bg').slice(0, 3).concat(num('dialogue.backing'))));
    // Outside frames (sheets, chrome) the current device's profile applies.
    const P = profile(device(deviceNames().includes(url.get('device')) ? url.get('device') : 'desktop'), { text: Number(url.get('text')) || 0 });
    for (const [r, px] of Object.entries(P.roles)) s.setProperty('--wo-fs-' + r, px + 'px');
    s.setProperty('--wo-glyph-h', P.roles.body * num('type.body.line-height') + 'px');
    s.setProperty('--wo-density', P.density + 'px');
    s.setProperty('--wo-hit-min', P.hitMin + 'px');
    s.setProperty('--wo-hit-margin', '0px');
    // The base canvas (project.godot) for scenes laid out at its size (.wo-scene-base, 2.5.3 step 15).
    const st = stage();
    s.setProperty('--wo-base-w', st.baseW + 'px');
    s.setProperty('--wo-base-h', st.baseH + 'px');
    const html = document.documentElement;
    html.dataset.motion = reduced() ? 'reduced' : 'full';
    html.dataset.hits = url.get('hits') === '1' ? 'on' : 'off';
    html.dataset.speaker = url.get('speaker') === 'portrait' ? 'portrait' : 'tab';
    html.dataset.touchScheme = url.get('touch') === 'tapwalk' ? 'tapwalk' : 'pad';
    html.dataset.flashing = url.get('flashing') === 'reduced' ? 'reduced' : 'on';
    html.dataset.clean = url.get('clean') === '1' ? '1' : '';
    applyScenes();
  }
  let readyState = false;
  /** The last composeWorlds() run: markReady waits for it, since a world requests its images one
   *  piece at a time and is appended only when the last one has loaded. */
  let composing = Promise.resolve();
  /** Re-applies everything after a token, URL or input change. [tune] is "full" (rebuild the Tune
   *  rows) or "live" (only their live parts, while a slider is dragged). */
  function rerender(tune = 'full') {
    if (!readyState) return;
    problems.length = 0;
    renderProblems();
    try {
      rootVars();
      whenPass();
      layoutFrames();
      placeNodes();
      renderSheets();
      renderTexts();
      composing = Promise.all([composeWorlds(), composeCovers()]);
      renderPadmaps();
      screens();
      boots();
      sequences();
      syncStrip();
      refreshTune(tune === 'full');
      carryLinks();
      idleLoop();
      startReveals();
      clockLoop();
    } catch (e) { problem(e.message, e); }
    document.dispatchEvent(new CustomEvent('wo:render'));
  }
  WO.rerender = rerender;
  /** Frames re-fit whenever the space they sit in changes (window, strip wrap, Tune panel). */
  const fitObserver = 'ResizeObserver' in window ? new ResizeObserver(() => { if (readyState) requestAnimationFrame(layoutFrames); }) : null;

  /** The problem list under the strip (reader errors; never silent). */
  function renderProblems() {
    let box = document.querySelector('.mk-problems');
    if (!problems.length) { if (box) box.remove(); return; }
    if (!box) { box = h('div', { class: 'mk-problems', role: 'alert' }); document.body.prepend(box); }
    box.replaceChildren(h('strong', {}, 'Value not read from its home (no fallback): '), ...problems.map((p) => h('div', {}, p)));
  }
  /**
   * Live reload (7.1): re-reads the token and language files once a second with cache
   * "no-store" and re-applies them when their text changed. URL overrides still win. A file that
   * does not parse (caught mid-save) keeps the last good one and says so in the strip.
   */
  function liveReload() {
    setInterval(async () => {
      for (const [key, path] of [['text', tokensPath()], ['langText', CORE.languages]]) {
        let text;
        try { text = await fetchText(path); } catch (e) { continue; }
        if (text === tokens[key]) continue;
        try {
          const json = JSON.parse(text);
          tokens[key] = text;
          if (key === 'text') { tokens.file = json; flatten(); } else tokens.lang = json;
          rerender();
          const st = strip && strip.querySelector('[data-role="status"]');
          if (st) st.textContent += ' · reloaded ' + new Date().toLocaleTimeString();
        } catch (e) {
          const st = strip && strip.querySelector('[data-role="status"]');
          if (st) st.textContent = path + ' does not parse yet: ' + e.message;
        }
      }
    }, 1000);
  }
  /** The token file path (the ?tokens= test hook may point elsewhere). */
  const tokensPath = () => url.get('tokens') || CORE.tokens;

  // ---------------------------------------------------------------------------------------------
  // 19. Probes for capture.mjs (--eval "WO.probe()") and Godot parity (M00 accept)
  // ---------------------------------------------------------------------------------------------

  /**
   * Measures every [data-wo-probe] element (or [selector]): its computed font size in canvas px,
   * its rect in canvas px relative to its frame (or CSS px on the page) and its text.
   */
  WO.probe = function (selector = '[data-wo-probe]') {
    return [...document.querySelectorAll(selector)].map((el) => {
      const f = frames.find((x) => x.canvas.contains(el));
      const r = el.getBoundingClientRect();
      const out = { probe: el.dataset.woProbe || el.className, fontSize: parseFloat(getComputedStyle(el).fontSize), text: el.textContent.trim().slice(0, 80) };
      if (f) {
        const c = f.canvas.getBoundingClientRect(), k = c.width / f.d.shape.cw;
        Object.assign(out, { device: f.d.name, x: fmt((r.left - c.left) / k), y: fmt((r.top - c.top) / k), w: fmt(r.width / k), h: fmt(r.height / k) });
      } else Object.assign(out, { x: r.left, y: r.top, w: r.width, h: r.height });
      return out;
    });
  };
  /** Resolved role sizes, densities and colours for the reference devices at each TEXT SIZE. */
  WO.report = function () {
    const out = {};
    for (const n of deviceNames()) for (const t of textSteps()) {
      const P = profile(device(n), { text: t });
      out[n + '@' + t] = { roles: P.roles, density: P.density, textScale: fmt(P.textScale, 4) };
    }
    out.colors = Object.fromEntries([...tokens.flat.values()].filter((t) => t.type === 'color').map((t) => [t.path, hexOf(color(t.path)) + (color(t.path)[3] < 1 ? '@' + fmt(color(t.path)[3], 3) : '')]));
    return out;
  };

  // ---------------------------------------------------------------------------------------------
  // 20. Boot
  // ---------------------------------------------------------------------------------------------

  /** Shows the no-fallback notice (7.1) with what failed, and keeps the page unstyled. */
  function notLoaded(failed) {
    document.documentElement.dataset.woState = 'error';
    const box = h('div', { class: 'mk-notice', role: 'alert' }, h('strong', {}, 'Tokens not loaded: serve the repo root over http (7.1)'), h('ul', {}, ...failed.map((f) => h('li', {}, f))));
    document.body.prepend(box);
    console.warn('[wo] tokens not loaded: ' + failed.join('; '));
  }
  /** Waits for fonts and every image on the page, then marks html[data-wo-ready="1"]. */
  async function markReady() {
    await document.fonts.ready;
    // Text measured before the game fonts loaded is re-measured: node boxes, controller maps, lists,
    // scroll offsets and name-tab room all read laid-out sizes.
    try { placeNodes(); renderPadmaps(); screens(); } catch (e) { problem(e.message, e); }
    await composing;
    await Promise.all([...document.images].map((im) => (im.complete ? 0 : new Promise((r) => { im.onload = im.onerror = r; }))));
    await Promise.all([...images.values()].map((p) => p.catch(() => 0)));
    await new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));
    document.documentElement.dataset.woReady = '1';
  }
  /** Starts the page: reads every home, then (only when all loaded) fills templates, mounts frames,
   *  renders, and marks the page ready for capture.mjs. */
  async function start() {
    document.documentElement.dataset.woState = 'loading';
    const failed = await fetchAll([tokensPath(), CORE.languages, CORE.theme, CORE.project].concat(Object.values(SOURCES)));
    let json = null, lang = null;
    if (!failed.length) {
      try { json = JSON.parse(files[tokensPath()]); } catch (e) { failed.push(tokensPath() + ' (' + e.message + ')'); }
      try { lang = JSON.parse(files[CORE.languages]); } catch (e) { failed.push(CORE.languages + ' (' + e.message + ')'); }
    }
    if (!failed.length) failed.push(...(await loadFonts()));
    if (failed.length) { notLoaded(failed); return; }
    tokens.file = json; tokens.text = files[tokensPath()];
    tokens.lang = lang; tokens.langText = files[CORE.languages];
    flatten();
    readTheme();
    readUrlOverrides();
    if (url.get('input')) input.mode = url.get('input') === 'mouse' ? 'pointer' : url.get('input');
    if (input.mode === 'touch') input.touched = true;
    buildStrip();
    await fillTemplates();
    mountFrames();
    for (const f of frames) f.touchedAtOpen = input.touched;
    // Entrances start before the first render, so a frame frozen by a clock (section 17) seeks them.
    stagger();
    document.documentElement.dataset.woState = 'ready';
    readyState = true;
    rerender();
    applyInput();
    syncTune();
    await inlineSvgs();
    padLoop();
    liveReload();
    await markReady();
  }
  WO.ready = new Promise((res) => document.addEventListener('wo:render', res, { once: true }));
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
  else start();
})();
