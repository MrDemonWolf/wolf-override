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
 * Public API (window.WO): tokens, today, devices, profile, input, glyph, motion, world, tune,
 * probe(), report(). Each section below starts with its own doc comment.
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
    if (tex.props.fill && gv(tex.props.fill) === 1) {
      return `radial-gradient(circle at ${fmt(from[0] * 100)}% ${fmt(from[1] * 100)}%, ${stops})`;
    }
    const deg = 90 + (Math.atan2(to[1] - from[1], to[0] - from[0]) * 180) / Math.PI;
    return `linear-gradient(${fmt(deg)}deg, ${stops})`;
  }
  /**
   * Sets one set of variables per theme type and state, following base_type when a state is
   * missing: --wo-<Type>-<state>-{bg, border, bw, radius, pad, shadow, inset} for a StyleBoxFlat,
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
    ['world-label-size', 'px', 'prop', 'main.tscn', 'BreakerLabel', 'theme_override_font_sizes/font_size'],
  ];
  /** The speaker tints Main picks in one expression (main.gd, the "var tint" line): WOLF's is
   *  Palette.CYAN (read above), the Director's and every other speaker's are literals there. */
  const TINT_LINE = /var tint: Color = Palette\.CYAN if id == "WOLF" else \(Color\("(#\w+)"\) if id\.begins_with\("DIRECTOR"\) else \(ENGINEER_TINT if id == human_name else Color\("(#\w+)"\)\)\)/;

  /** Sets --wo-today-* on :root from TODAY_VARS and the tint line. */
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
   * (round(base x profile scale x TEXT SIZE), the same rounding as TextSize.px), density, the
   * minimum hit size, HUD edges, phone control sizes, and the text floors that apply.
   * [opts.text] overrides TEXT SIZE (%); [opts.touched] says a desktop frame takes handheld
   * density because a real touch reached it (layoutFrames applies density.touch-switch).
   */
  function profile(d, opts = {}) {
    const p = d.profile;
    const P = { device: d, kind: p };
    P.textScale = p === 'phone' ? phoneTextScale(d) : num('profile.' + p + '.text-scale');
    P.textSize = opts.text || (p === 'handheld' ? num('profile.handheld.text-size') : defaultTextSize());
    P.roles = {};
    for (const r of roles()) P.roles[r] = Math.round(num('type.' + r + '.size') * P.textScale * (P.textSize / 100));
    if (p === 'phone') P.density = phoneDensity(d);
    else if (p === 'handheld') P.density = num('profile.handheld.density');
    else P.density = opts.touched ? num('profile.handheld.density') : num('profile.desktop.density');
    P.hitMin = p === 'desktop' && !opts.touched ? num('density.pointer-hit-min') : P.density;
    P.hitMargin = p === 'phone' ? dpToCanvas(d, num('density.gap-phone-dp')) : 0;
    const m = num('profile.hud-margin');
    P.edges = { left: Math.max(m, d.insets.left), right: Math.max(m, d.insets.right), top: Math.max(m, d.insets.top), bottom: Math.max(m, d.insets.bottom) };
    if (p === 'phone') {
      P.useSize = Math.max(num('profile.phone.use-size-min'), mmToCanvas(d, num('profile.phone.use-size-mm')));
      P.pauseSize = P.density;
    }
    P.floors = textFloors(d, p);
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

  /** Navigation keys on a game-screen page (<body data-wo-nav>) or inside a frame: arrows move
   *  focus, Esc is back (4.2 Menus). Sheet pages keep arrow-key scrolling. */
  addEventListener('keydown', (e) => {
    if (inChrome(e.target) || !readyState) return;
    if (!document.body.hasAttribute('data-wo-nav') && !(document.activeElement && document.activeElement.closest('.wo-frame'))) return;
    const dir = { ArrowUp: -1, ArrowLeft: -1, ArrowDown: 1, ArrowRight: 1 }[e.key];
    if (dir) { e.preventDefault(); nav(dir); }
    if (e.key === 'Escape') emit('back');
  });

  /** Fires a mockup event on document ("wo:back", "wo:tab", "wo:accept", ...). */
  function emit(name, detail) { document.dispatchEvent(new CustomEvent('wo:' + name, { detail })); }
  /** Focusable game controls in the frame that holds focus (or the first frame), in DOM order. */
  function focusables() {
    const active = document.activeElement && document.activeElement.closest('.wo-frame');
    const scope = active || document.querySelector('.wo-frame') || document;
    return [...scope.querySelectorAll('.wo-btn, .wo-tab, .wo-touch, [data-wo-focus]')].filter((el) => !el.disabled && !el.hasAttribute('aria-disabled') && el.offsetParent !== null);
  }
  /** Moves focus [dir] (-1 or 1) in focusables(), wrapping (XAG112); the first press after pointer
   *  use only shows the ring on the hovered or focused item. */
  function nav(dir) {
    const list = focusables();
    if (!list.length) return;
    const cur = list.indexOf(document.activeElement);
    if (input.revealOnly && cur >= 0) { input.revealOnly = false; return; }
    input.revealOnly = false;
    const next = list[(cur + dir + list.length) % list.length] || list[0];
    next.focus({ preventScroll: true });
  }
  /** Hover moves the (hidden) focus, so there is only ever one highlight (6.2 B7 rule 3). */
  addEventListener('pointerover', (e) => {
    const el = e.target.closest && e.target.closest('.wo-frame .wo-btn, .wo-frame .wo-tab, .wo-frame [data-wo-focus]');
    if (el && !el.disabled && input.mode === 'pointer') el.focus({ preventScroll: true });
  });

  // Gamepad (secure contexts only: localhost; brief 7.1 Serve) ---------------------------------

  /** Standard-mapping button indexes, named as Godot's JOY_BUTTON_* and the Xbox glyphs. */
  const PAD = { A: 0, B: 1, X: 2, Y: 3, LB: 4, RB: 5, LT: 6, RT: 7, View: 8, Menu: 9, DPadUp: 12, DPadDown: 13, DPadLeft: 14, DPadRight: 15 };
  /** Polls the Gamepad API each frame: any press or a stick past main.gd's switch threshold sets
   *  "pad"; D-pad and stick move focus with the timing.input-repeat delay and rate; A clicks;
   *  B, LB/RB, LT/RT, Menu, View, X and Y fire wo: events for the page. */
  function padLoop() {
    if (!window.isSecureContext || !navigator.getGamepads) return;
    const held = {};
    let threshold;
    try { threshold = Number(today.match('main.gd', /JoypadMotion and absf\(event\.axis_value\) > ([\d.]+)/)); } catch (e) { problem(e.message); return; }
    const step = (now) => {
      for (const pad of navigator.getGamepads()) {
        if (!pad) continue;
        const pressed = (i) => pad.buttons[i] && pad.buttons[i].pressed;
        const ax = pad.axes[0] || 0, ay = pad.axes[1] || 0;
        const any = pad.buttons.some((b) => b.pressed) || Math.abs(ax) > threshold || Math.abs(ay) > threshold;
        if (any && readyState) setInput('pad', true);
        const dirs = { up: pressed(PAD.DPadUp) || ay < -threshold, down: pressed(PAD.DPadDown) || ay > threshold, left: pressed(PAD.DPadLeft) || ax < -threshold, right: pressed(PAD.DPadRight) || ax > threshold };
        for (const [name, on] of Object.entries(dirs)) repeat(held, name, on, now, () => nav(name === 'up' || name === 'left' ? -1 : 1));
        for (const [name, i] of Object.entries(PAD)) {
          if (name.startsWith('DPad')) continue;
          repeat(held, name, pressed(i), now, () => {
            if (name === 'A' && document.activeElement && document.activeElement.closest('.wo-frame')) document.activeElement.click();
            emit({ A: 'accept', B: 'back', X: 'answer', Y: 'answer', LB: 'tab', RB: 'tab', LT: 'page', RT: 'page', Menu: 'menu', View: 'view' }[name], { button: name, dir: name === 'LB' || name === 'LT' ? -1 : 1 });
          }, name !== 'LT' && name !== 'RT');
        }
      }
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
   */
  function bindings() {
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
    for (const [k, v] of Object.entries(PROPOSED_ACTIONS)) b[k] = b[k] || v;
    return b;
  }
  WO.bindings = () => bindings();

  /**
   * SVG glyphs, drawn once here (brief 4.4: no glyph art in the repo until Q12). [name] is an Xbox
   * name (A B X Y LB RB LT RT View Menu DPad DPadUp DPadDown DPadLeft DPadRight LS RS),
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
  /** The glyph names for [action] under input [mode]: [] on touch (the control is the button). */
  function glyphsFor(action, mode) {
    if (mode === 'touch') return [];
    const b = bindings()[action];
    if (!b) throw new Error('no binding for action ' + action);
    if (mode === 'pad') return b.pad.slice(0, 1);
    return b.keys.slice(0, 1).map((k) => 'key:' + k);
  }
  /**
   * Fills every [data-wo-glyph] element under [root]. Its value is an action name ("interact",
   * "ui_accept", "tab_prev") or a fixed glyph ("pad:A", "key:E", "mouse:left"). The input class
   * is the element's frame's (or the page's). An element with no glyph for the input is hidden.
   */
  function renderGlyphs(root) {
    for (const el of root.querySelectorAll('[data-wo-glyph]')) {
      const spec = el.dataset.woGlyph;
      const frame = el.closest('.wo-frame');
      const mode = (frame && frame.dataset.input) || input.mode || 'keyboard';
      let names;
      try {
        names = spec.startsWith('pad:') ? [spec.slice(4)] : spec.includes(':') ? [spec] : glyphsFor(spec, mode);
        el.replaceChildren(...names.map(glyph));
      } catch (e) { problem(e.message); names = []; }
      el.classList.add('wo-glyph');
      el.hidden = names.length === 0;
    }
  }
  WO.glyph = { draw: glyph, for: glyphsFor, render: renderGlyphs };

  // ---------------------------------------------------------------------------------------------
  // 11. Frames (brief 7.1 Frame): a device screen with the game canvas scaled inside it
  // ---------------------------------------------------------------------------------------------

  /** Every mounted frame: {host: .mk-device, screen, canvas: .wo-frame, d, P}. */
  const frames = [];
  /**
   * Mounts each .mk-device on the page. Markup: <section class="mk-device" data-wo-device="url">
   * <div class="wo-frame">...canvas content in canvas px...</div></section>. data-wo-device is a
   * device name or "url" (the strip's device). The canvas is sized to the device's canvas shape,
   * scaled to the screen and centred (bars outside the 4:3..2.4:1 bounds), and the whole screen
   * is fitted into the host's parent. Safe-area overlays are added per device. A canvas with
   * data-wo-template="<id>" is filled from that <template>, so several frames on one page share
   * one block of markup instead of copies.
   */
  function mountFrames() {
    for (const host of document.querySelectorAll('.mk-device')) {
      if (host._wo) continue;
      const canvas = host.querySelector(':scope > .wo-frame');
      if (canvas.dataset.woTemplate) {
        const tpl = document.getElementById(canvas.dataset.woTemplate);
        if (!tpl) { problem('no <template id="' + canvas.dataset.woTemplate + '">'); continue; }
        canvas.append(tpl.content.cloneNode(true));
      }
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
  }
  /** The input class a frame shows: the last real input, else its profile's default. */
  function frameInput(f) {
    if (!f.d) return;
    const mode = input.mode || PROFILE_INPUT[f.d.profile];
    f.canvas.dataset.input = mode;
    f.canvas.dataset.ring = mode === 'keyboard' || mode === 'pad' ? 'on' : 'off';
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
      g.classList.remove('is-entered');
      void g.offsetWidth;
      g.classList.add('is-entering');
    }
  }
  /** Ends every entrance at once (the first input does this). */
  function finishEntrances() { document.querySelectorAll('[data-wo-enter]').forEach((g) => g.classList.add('is-entered')); }
  addEventListener('keydown', finishEntrances, true);
  addEventListener('pointerdown', (e) => { if (!inChrome(e.target)) finishEntrances(); }, true);
  /**
   * The idle loop for [data-wo-idle] elements: a "tick" class for one motion.focus.in at an
   * irregular period between motion.idle.period-min and -max (seeded). Stops under REDUCED MOTION.
   */
  function idleLoop() {
    clearTimeout(idleLoop.timer);
    if (reduced()) return;
    const lo = num('motion.idle.period-min'), hi = num('motion.idle.period-max');
    idleLoop.timer = setTimeout(() => {
      document.querySelectorAll('[data-wo-idle]').forEach((el) => { el.classList.add('is-tick'); setTimeout(() => el.classList.remove('is-tick'), num('motion.focus.in') * 2); });
      idleLoop();
    }, lo + rand() * (hi - lo));
  }
  /** REDUCED MOTION from the URL (?motion=reduced). */
  const reduced = () => url.get('motion') === 'reduced';
  WO.motion = { stagger, finishEntrances, idle: idleLoop, reduced };

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
  /** A Sprite2D node from main.tscn as {src, x, y, w, h, flip} in world px (centered sprites per
   *  Godot: top-left = position + offset x scale - size x scale / 2). [at] replaces the parent's
   *  position (an actor placed elsewhere); [flip] mirrors it. */
  async function spritePiece(piece) {
    const node = today.node('main.tscn', piece.node);
    const pos = gv(node.props.position || 'Vector2(0, 0)');
    const parentPath = piece.node.includes('/') ? piece.node.split('/').slice(0, -1).join('/') : null;
    const parentPos = piece.at || (parentPath ? gv(today.node('main.tscn', parentPath).props.position || 'Vector2(0, 0)') : [0, 0]);
    const scale = gv(node.props.scale || 'Vector2(1, 1)');
    const tex = gv(node.props.texture).ext;
    const path = parseSections(files[SOURCES['main.tscn']]).find((s) => s.tag === 'ext_resource' && s.attrs.id === tex).attrs.path.replace('res://', '');
    const im = await loadImage(GAME + path);
    const region = node.props.region_enabled && gv(node.props.region_enabled) ? gv(node.props.region_rect) : [0, 0, im.naturalWidth, im.naturalHeight];
    const w = region[2] * scale[0], hh = region[3] * scale[1];
    const centered = node.props.centered === undefined ? true : gv(node.props.centered);
    const x = parentPos[0] + pos[0] - (centered ? w / 2 : 0), y = parentPos[1] + pos[1] - (centered ? hh / 2 : 0);
    return Object.assign({}, piece, { src: path, x, y, w, h: hh });
  }
  /**
   * Composes every [data-wo-world] element. Its first child <script type="application/json">
   * holds the per-screen data: {camera: "left"|"right"|x, framing: "auto"|"keyboard"|"touch",
   * anchor: "fixed"|"today", grade: true, pieces: [...]}. A piece is {src: "<assets path>", x, y,
   * w, h} in world px, or {node: "<main.tscn Sprite2D path>", at: [x, y]}; options: layer
   * "far"|"near" (parallax), flip, brightness, bleed ("bottom", "sides"), tap (a hit area).
   * The far plate moves (1 - scroll) x (cx - base width / 2): the fixed anchor of 2.5.3 step 7;
   * anchor "today" uses today's (cx - canvas width / 2) for comparison.
   */
  async function composeWorlds(root = document) {
    for (const el of root.querySelectorAll('[data-wo-world]')) {
      const f = frames.find((x) => x.canvas.contains(el));
      if (!f) { problem('a world must sit inside a .wo-frame'); continue; }
      let cfg;
      try { cfg = JSON.parse(el.querySelector('script[type="application/json"]').textContent); } catch (e) { problem('world data: ' + e.message); continue; }
      const st = stage();
      const framing = cfg.framing === 'auto' || !cfg.framing ? (f.canvas.dataset.input === 'touch' ? 'touch' : 'keyboard') : cfg.framing;
      const v = playView(f.d.shape.cw, f.d.shape.ch, framing, cfg.camera === undefined ? 'left' : cfg.camera);
      el._view = v;
      el.dataset.framing = framing;
      const world = h('div', { class: 'wo-world' });
      world.style.transform = `scale(${v.zoom}) translate(${-v.left}px, ${-v.top}px)`;
      const farScroll = today.konst('room_depth.gd', 'BACKDROP_SCROLL')[0], nearScroll = today.konst('room_depth.gd', 'NEAR_SCROLL')[0];
      const anchorX = cfg.anchor === 'today' ? f.d.shape.cw / 2 : st.baseW / 2;
      for (let piece of cfg.pieces) {
        try {
          if (piece.node) piece = await spritePiece(piece);
          else await loadImage(GAME + 'assets/' + piece.src);
          const shift = piece.layer === 'far' ? (1 - farScroll) * (v.cx - anchorX) : piece.layer === 'near' ? (1 - nearScroll) * (v.cx - anchorX) : 0;
          const srcUrl = GAME + (piece.node ? '' : 'assets/') + piece.src;
          const place = (cls, x, y, w, hgt) => { const d = h('div', { class: 'wo-piece ' + cls }); Object.assign(d.style, { left: x + 'px', top: y + 'px', width: w + 'px', height: hgt + 'px' }); return d; };
          const img = () => { const i = h('img', { src: srcUrl, alt: '', draggable: 'false' }); if (piece.brightness) i.style.filter = `brightness(${piece.brightness})`; return i; };
          const box = place(piece.flip ? 'is-flip' : '', piece.x + shift, piece.y, piece.w, piece.h);
          box.append(img());
          if (piece.tap) { box.classList.add('wo-tap'); box.dataset.woTap = piece.tap; }
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
  WO.world = { view: playView, compose: composeWorlds };

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
      sel.value = url.get(k) || (k === 'device' ? 'desktop' : '');
    }
    strip.querySelector('[data-key="hits"]').checked = url.get('hits') === '1';
    const status = strip.querySelector('[data-role="status"]');
    status.textContent = 'input: ' + (input.mode || 'profile default') + (tokens.overrides.size || tokens.langOverrides.size ? ' · ' + (tokens.overrides.size + tokens.langOverrides.size) + ' tuned' : '');
  }

  /** Every link marked data-wo-carry keeps device, input, text, motion, hits, tune, speaker,
   *  touch and every t.* and lang.* parameter (M00: tuned values carried across pages). clean
   *  is not carried: it is for one capture, not a browsing state. */
  function carryLinks() {
    const keep = ['device', 'input', 'text', 'motion', 'hits', 'tune', 'speaker', 'touch'];
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
  // 17. Root variables, rendering and live reload
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
    const html = document.documentElement;
    html.dataset.motion = reduced() ? 'reduced' : 'full';
    html.dataset.hits = url.get('hits') === '1' ? 'on' : 'off';
    html.dataset.speaker = url.get('speaker') === 'portrait' ? 'portrait' : 'tab';
    html.dataset.touchScheme = url.get('touch') === 'tapwalk' ? 'tapwalk' : 'pad';
    html.dataset.flashing = url.get('flashing') === 'reduced' ? 'reduced' : 'on';
    html.dataset.clean = url.get('clean') === '1' ? '1' : '';
  }
  let readyState = false;
  /** Re-applies everything after a token, URL or input change. [tune] is "full" (rebuild the Tune
   *  rows) or "live" (only their live parts, while a slider is dragged). */
  function rerender(tune = 'full') {
    if (!readyState) return;
    problems.length = 0;
    renderProblems();
    try {
      rootVars();
      layoutFrames();
      renderSheets();
      composeWorlds();
      syncStrip();
      refreshTune(tune === 'full');
      carryLinks();
      idleLoop();
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
  // 18. Probes for capture.mjs (--eval "WO.probe()") and Godot parity (M00 accept)
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
  // 19. Boot
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
    await Promise.all([...document.images].map((im) => (im.complete ? 0 : new Promise((r) => { im.onload = im.onerror = r; }))));
    await Promise.all([...images.values()].map((p) => p.catch(() => 0)));
    await new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));
    document.documentElement.dataset.woReady = '1';
  }
  async function boot() {
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
    mountFrames();
    for (const f of frames) f.touchedAtOpen = input.touched;
    document.documentElement.dataset.woState = 'ready';
    readyState = true;
    rerender();
    applyInput();
    syncTune();
    stagger();
    padLoop();
    liveReload();
    await markReady();
  }
  WO.ready = new Promise((res) => document.addEventListener('wo:render', res, { once: true }));
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
