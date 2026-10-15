#!/usr/bin/env python3
"""Find copied code: runs of 6 or more matching lines in two places.

The repository rule (AGENTS.md, "Don't duplicate code") is that shared logic
lives in one file that every user imports, and nothing merges with new copies.
This check enforces it. It reads the tracked code files of a git ref straight
from git objects, so it can check any branch without a checkout.

A copy is a run of at least --min-lines consecutive normalised lines that
appears in two files, or twice in one file. Normalising drops comments
(whole-line, trailing and /* */ ones) and every space outside string quotes
(so `a=b` matches `a = b`), and skips blank lines and trivial lines (a lone
bracket, pass, else:, fi, done, docstring quotes, imports and the like), so
comments, blank lines, indentation and spacing do not hide a copy. It compares text,
not meaning: a copy with renamed variables still passes, so reviewers read
for those.

With --base, a copy fails when the branch adds one of its lines, or when the
branch adds, changes or deletes a code line inside one place of a copy that
was already at the merge base and six or more lines there still match a copy:
editing one copy of an old block makes the two drift apart.

Usage (from the repository root):
    python3 scripts/check-copies.py                      # every copy in HEAD; exit 1 if any
    python3 scripts/check-copies.py --base origin/main   # only copies the branch adds or
                                                         # edits since the merge base; exit 1 if any
    python3 scripts/check-copies.py --report             # whole-repository summary; exit 0
    python3 scripts/check-copies.py --ref BRANCH --base main
    python3 scripts/check-copies.py --self-test

Exit status: 0 no (new) copies, 1 copies found, 2 usage or git error.

.copies-allow at the repository root (read from the scanned ref) lists path
pairs that may share code, one pair per line, each with a reason:
    path/one.gd  path/two.gd  reason the two must stay separate
Paths may use shell wildcards; "#" starts a comment line. Keep it short:
an entry is an exception, not a way around the rule.

Python 3 standard library only.
"""

from __future__ import annotations

import argparse
import collections
import fnmatch
import os
import re
import subprocess
import sys
import tempfile
import time

CODE_EXTS = ('.gd', '.gdshader', '.ts', '.tsx', '.js', '.mjs', '.css', '.py', '.sh')
ALLOW_FILE = '.copies-allow'
ADVICE = 'move it into one shared file that both use, and delete the copy'

# Comment syntax per file type: line-comment marker, whether /* */ blocks apply,
# whether "#" needs a space before it (shell, where $# and ${#x} are not comments;
# in GDScript and Python any "#" outside a string starts a comment), and whether
# triple-quoted strings run across lines.
HASH = ('#', False, False, True)  # GDScript, Python
SHELL = ('#', False, True, False)
SLASH = ('//', True, False, False)  # GDShader, TypeScript, JavaScript
CSS = (None, True, False, False)
SYNTAX = {'.gd': HASH, '.py': HASH, '.sh': SHELL, '.gdshader': SLASH, '.ts': SLASH,
          '.tsx': SLASH, '.js': SLASH, '.mjs': SLASH, '.css': CSS}

# Lines that carry no logic of their own: closing brackets, bare keywords, docstring
# quotes and imports (two files that import the same modules share no code).
TRIVIAL = re.compile(
    r'^(?:[\[\](){};,]+|"""|\'\'\'|import \S.*|from \S+ import .*|@import .*'
    r'|pass|else:?|\} ?else ?\{|elif|try:|finally:|except:|return;?|break;?|continue;?'
    r'|end|fi|done|esac|then|do|default:)$')
SPACES = re.compile(r'\s+')
QUOTES = re.compile('["\'`]')
HASH_COMMENT = re.compile(r'(?:^|(?<=[ \t]))#')
TRIPLE_QUOTES = ('"""', "'''")


def git(repo, *args, data=None):
    proc = subprocess.run(['git', '-C', repo, *args], input=data, capture_output=True)
    if proc.returncode != 0:
        raise GitError(f"git {' '.join(args)}: {proc.stderr.decode(errors='replace').strip()}")
    return proc.stdout


class GitError(Exception):
    pass


def split_code(line, syntax, open_at_start=None):
    """Return the line's code without comments, that code with every space outside
    string quotes removed (the text copies are matched on), and what is still open
    at the end of the line: '/*' for a block comment, a triple quote for a string,
    or None."""
    marker, blocks, spaced, triple = syntax
    if open_at_start is None and not QUOTES.search(line) and not (blocks and '/*' in line):
        # Fast path: no quotes and no block comment on this line.
        if marker == '#' and spaced:
            found = HASH_COMMENT.search(line)
            end = found.start() if found else len(line)
        else:
            end = line.find(marker) if marker else -1
            end = len(line) if end < 0 else end
        return line[:end], SPACES.sub('', line[:end]), None
    in_block = open_at_start == '/*'
    quote = None if in_block else open_at_start
    code = []
    key = []
    i = 0
    n = len(line)
    while i < n:
        if in_block:
            end = line.find('*/', i)
            if end < 0:
                break
            in_block = False
            code.append(' ')
            i = end + 2
            continue
        ch = line[i]
        if quote:
            if ch == '\\':
                code.append(line[i:i + 2])
                key.append(line[i:i + 2])
                i += 2
                continue
            if line.startswith(quote, i):
                code.append(quote)
                key.append(quote)
                i += len(quote)
                quote = None
                continue
            code.append(ch)
            key.append(ch)
        elif ch in '"\'`':
            quote = line[i:i + 3] if triple and line.startswith(ch * 3, i) else ch
            code.append(quote)
            key.append(quote)
            i += len(quote)
            continue
        elif blocks and line.startswith('/*', i):
            in_block = True
            i += 2
            continue
        elif marker and line.startswith(marker, i) and (not spaced or i == 0 or line[i - 1] in ' \t'):
            break
        else:
            code.append(ch)
            if not ch.isspace():
                key.append(ch)
        i += 1
    still_open = '/*' if in_block else quote if quote and len(quote) == 3 else None
    return ''.join(code), ''.join(key), still_open


def normalise(text, ext):
    """Return [(line number, matched text, readable text)] for the lines that count."""
    syntax = SYNTAX.get(ext, HASH)
    out = []
    still_open = None
    for number, raw in enumerate(text.splitlines(), 1):
        line, key, open_after = split_code(raw.strip(), syntax, still_open)
        if still_open in TRIPLE_QUOTES or open_after in TRIPLE_QUOTES:
            # Part of a multi-line string, which often holds code from another file
            # (a patch script quoting GDScript): read the line on its own, with "#"
            # a comment only after a space, so that code still matches where it came from.
            line, key, _ = split_code(raw.strip(), SHELL)
        still_open = open_after
        line = SPACES.sub(' ', line).strip()
        if not line or TRIVIAL.match(line) or TRIVIAL.match(key):  # key: `{/* note */}` is `{}`
            continue
        out.append((number, key, line))
    return out


def read_files(repo, ref):
    """Read every tracked code file of ref through one git cat-file process."""
    listing = git(repo, 'ls-tree', '-r', '-z', '--full-tree', ref).decode('utf-8', 'replace')
    entries = []
    for item in listing.split('\0'):
        if not item:
            continue
        meta, path = item.split('\t', 1)
        mode, kind, sha = meta.split()
        if kind == 'blob' and mode != '120000' and path.endswith(CODE_EXTS):
            entries.append((path, sha))
    data = git(repo, 'cat-file', '--batch', data=''.join(f'{sha}\n' for _, sha in entries).encode())
    files = {}
    pos = 0
    for path, _ in entries:
        header_end = data.index(b'\n', pos)
        size = int(data[pos:header_end].split()[2])
        body = data[header_end + 1:header_end + 1 + size]
        pos = header_end + 1 + size + 1
        if b'\0' in body[:8000]:
            continue  # binary despite its name
        files[path] = body.decode('utf-8', 'replace')
    return files


def read_allow(repo, ref):
    try:
        text = git(repo, 'show', f'{ref}:{ALLOW_FILE}').decode('utf-8', 'replace')
    except GitError:
        return []
    rules = []
    for number, line in enumerate(text.splitlines(), 1):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        parts = line.split(None, 2)
        if len(parts) < 3:
            raise GitError(f'{ALLOW_FILE}:{number}: needs two paths and a reason')
        rules.append((parts[0], parts[1]))
    return rules


def allowed(rules, a, b):
    for x, y in rules:
        if (fnmatch.fnmatchcase(a, x) and fnmatch.fnmatchcase(b, y)) or \
           (fnmatch.fnmatchcase(a, y) and fnmatch.fnmatchcase(b, x)):
            return True
    return False


def find_copies(norm, k, rules):
    """Return copies as {text tuple: set of (path, first index, last index)}.

    Each matching k-line window gives a pair of positions on a diagonal (same
    offset between the two places); consecutive windows on one diagonal merge
    into one maximal run.
    """
    windows = collections.defaultdict(list)
    for path, lines in norm.items():
        texts = [key for _, key, _ in lines]
        for j in range(len(texts) - k + 1):
            windows[tuple(texts[j:j + k])].append((path, j))
    diagonals = collections.defaultdict(list)
    for spots in windows.values():
        if len(spots) < 2:
            continue
        for a in range(len(spots)):
            pa, ja = spots[a]
            for b in range(a + 1, len(spots)):
                pb, jb = spots[b]
                if (pa, ja) > (pb, jb):
                    pa2, ja2, pb2, jb2 = pb, jb, pa, ja
                else:
                    pa2, ja2, pb2, jb2 = pa, ja, pb, jb
                if pa2 == pb2 and jb2 - ja2 < k:
                    continue  # overlapping windows of one repeating pattern
                diagonals[(pa2, pb2, jb2 - ja2)].append(ja2)
    groups = collections.defaultdict(set)
    for (pa, pb, offset), starts in diagonals.items():
        if allowed(rules, pa, pb):
            continue
        starts.sort()
        lines_a = [key for _, key, _ in norm[pa]]
        run_start = prev = starts[0]
        for s in starts[1:] + [None]:
            if s is not None and s == prev + 1:
                prev = s
                continue
            first, last = run_start, prev + k - 1
            if pa == pb:
                last = min(last, first + offset - 1)  # keep the two places apart
            text = tuple(lines_a[first:last + 1])
            groups[text].add((pa, first, last))
            groups[text].add((pb, first + offset, last + offset))
            if s is not None:
                run_start = prev = s
    return groups


def diff_path(text, prefix):
    """Return the path from a '--- a/x' or '+++ b/x' line's text, or None for /dev/null.

    git ends the path with a tab when it holds a space, and C-quotes it when it holds
    a quote, a backslash or a control character."""
    text = text.rstrip('\t')
    if text == '/dev/null':
        return None
    if len(text) >= 2 and text[0] == '"' and text[-1] == '"':
        raw = text[1:-1].encode('utf-8')
        out = bytearray()
        i = 0
        escapes = {ord('a'): 7, ord('b'): 8, ord('t'): 9, ord('n'): 10, ord('v'): 11,
                   ord('f'): 12, ord('r'): 13, ord('"'): 34, ord('\\'): 92}
        while i < len(raw):
            if raw[i] == 92 and i + 1 < len(raw):
                if raw[i + 1:i + 4].isdigit():
                    out.append(int(raw[i + 1:i + 4], 8))
                    i += 4
                    continue
                out.append(escapes.get(raw[i + 1], raw[i + 1]))
                i += 2
                continue
            out.append(raw[i])
            i += 1
        text = out.decode('utf-8', 'replace')
    return text[len(prefix):] if text.startswith(prefix) else text


def diff_hunks(repo, base, ref):
    """Return the merge base and, per changed code file, (old path, new path, hunks),
    each hunk (old start, old count, new start, new count) of a zero-context diff."""
    try:
        merge_base = git(repo, 'merge-base', base, ref).decode().strip()
    except GitError as error:
        raise GitError(f'{error}\n(no merge base of {base} and {ref}: fetch the base branch '
                       'with its history, for example a checkout with fetch-depth 0)') from None
    diff = git(repo, '-c', 'core.quotePath=false', 'diff', '--no-color', '--no-ext-diff',
               '--find-renames', '--unified=0', '--src-prefix=a/', '--dst-prefix=b/',
               merge_base, ref, '--', *(f'*{ext}' for ext in CODE_EXTS)).decode('utf-8', 'replace')
    changes = []
    old_path = None
    pending = 0  # content lines of the current hunk still to skip
    for line in diff.splitlines():
        if pending:
            if not line.startswith('\\'):  # "\ No newline at end of file"
                pending -= 1
            continue
        if line.startswith('--- '):
            old_path = diff_path(line[4:], 'a/')
        elif line.startswith('+++ '):
            changes.append((old_path, diff_path(line[4:], 'b/'), []))
        elif line.startswith('@@') and changes:
            match = re.match(r'@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@', line)
            if match:
                hunk = tuple(int(g) if g is not None else 1 for g in match.groups())
                changes[-1][2].append(hunk)
                pending = hunk[1] + hunk[3]
    return merge_base, changes


def map_span(hunks, first, last):
    """Map old lines first..last through the hunks; return the new (first, last)."""
    start = end = None
    shift_start = shift_end = 0
    for old, old_count, _new, new_count in hunks:
        change = new_count - old_count
        if old_count == 0:  # lines inserted after old line `old`
            if old < first:
                shift_start += change
            if old < last:
                shift_end += change
            continue
        old_last = old + old_count - 1
        if start is None:
            if old_last < first:
                shift_start += change
            elif old <= first:
                start = old + shift_start
        if end is None:
            if old_last <= last:
                shift_end += change
            elif old <= last:
                end = old + shift_end + new_count - 1
    return (first + shift_start if start is None else start,
            last + shift_end if end is None else end)


def touched_old_copies(repo, merge_base, changes, norm, groups, k, rules):
    """Return the copies in ref that overlap a copy at the merge base which the diff
    edits inside (a code line added, changed or deleted between its first and last
    line): editing one copy of an old block, and leaving six or more lines of it
    matching, is drift between the copies."""
    edited = [(old, new, hunks) for old, new, hunks in changes if old and new and hunks]
    if not edited:
        return {}
    base_norm = {p: normalise(t, os.path.splitext(p)[1])
                 for p, t in read_files(repo, merge_base).items()}
    spans = collections.defaultdict(set)
    for places in find_copies(base_norm, k, rules).values():
        for path, first, last in places:
            spans[path].add((base_norm[path][first][0], base_norm[path][last][0]))
    by_path = collections.defaultdict(list)
    for text, places in groups.items():
        for path, first, last in places:
            by_path[path].append((norm[path][first][0], norm[path][last][0], text))
    found = {}
    for old, new, hunks in edited:
        if old not in spans or new not in by_path:
            continue
        base_code = {number for number, _, _ in base_norm[old]}
        ref_code = {number for number, _, _ in norm[new]}
        for first, last in spans[old]:
            inside = False
            for start, count, new_start, new_count in hunks:
                if count:
                    removed = range(max(start, first), min(start + count - 1, last) + 1)
                    lands = len(removed) > 0
                else:
                    removed = ()
                    lands = first <= start < last
                if lands and (any(n in base_code for n in removed) or
                              any(n in ref_code for n in range(new_start, new_start + new_count))):
                    inside = True
                    break
            if not inside:
                continue
            new_first, new_last = map_span(hunks, first, last)
            for copy_first, copy_last, text in by_path[new]:
                if copy_first <= new_last and new_first <= copy_last:
                    found[text] = groups[text]
    return found


def area(path):
    for prefix, name in (('apps/game/scripts/', 'game scripts'), ('apps/game/tests/', 'game tests'),
                         ('apps/game/', 'game other'), ('apps/docs/', 'site'),
                         ('docs/', 'docs research tools')):
        if path.startswith(prefix):
            return name
    return 'repository tools'


def describe(norm, text, places):
    spots = []
    for path, first, last in sorted(places):
        lines = norm[path]
        spots.append(f'{path}:{lines[first][0]}-{lines[last][0]}')
    path, first, _ = min(places)
    return f"{' ↔ '.join(spots)}\n    {len(text)} lines, starting: {norm[path][first][2][:100]}"


def run(args):
    started = time.monotonic()
    repo = args.repo
    files = read_files(repo, args.ref)
    norm = {p: normalise(t, os.path.splitext(p)[1]) for p, t in files.items()}
    rules = read_allow(repo, args.ref)
    groups = find_copies(norm, args.min_lines, rules)

    if args.report:
        copied = collections.defaultdict(set)
        for text, places in groups.items():
            for path, first, last in places:
                copied[path].update(range(first, last + 1))
        totals = collections.Counter()
        dup = collections.Counter()
        for path, lines in norm.items():
            totals[area(path)] += len(lines)
            dup[area(path)] += len(copied[path])
        print(f'Copied code in {args.ref} (runs of {args.min_lines}+ matching lines, '
              f'{len(norm)} code files)')
        for name in sorted(totals):
            share = 100 * dup[name] / max(1, totals[name])
            print(f'  {name:22s} {dup[name]:6d} of {totals[name]:6d} lines in copies ({share:.0f}%)')
        print(f"  {'total':22s} {sum(dup.values()):6d} of {sum(totals.values()):6d} lines; "
              f'{len(groups)} copied blocks')
        by_file = collections.defaultdict(list)
        for text, places in groups.items():
            for place in places:
                by_file[place[0]].append((place, text, places))
        for name in sorted(totals):
            paths = sorted((p for p in by_file if area(p) == name), key=lambda p: -len(copied[p]))
            if not paths:
                continue
            print(f'\n== {name} ==')
            for path in paths:
                print(f'{path}: {len(copied[path])} of {len(norm[path])} lines in copies')
                for (_, first, last), text, places in sorted(by_file[path], key=lambda e: e[0][1]):
                    others = sorted(p for p in places if p != (path, first, last))
                    where = ', '.join(f'{p}:{norm[p][f][0]}-{norm[p][l][0]}' for p, f, l in others)
                    print(f'  {norm[path][first][0]}-{norm[path][last][0]} ({len(text)} lines) '
                          f'also in {where}')
        print(f'\n({time.monotonic() - started:.2f} s)')
        return 0

    merge_base = None
    if args.base:
        merge_base, changes = diff_hunks(repo, args.base, args.ref)
        added = collections.defaultdict(set)
        for _, path, hunks in changes:
            for _, _, start, count in hunks:
                added[path].update(range(start, start + count))
        fresh = touched_old_copies(repo, merge_base, changes, norm, groups, args.min_lines, rules)
        for text, places in groups.items():
            touched = any(norm[p][i][0] in added.get(p, ())
                          for p, first, last in places for i in range(first, last + 1))
            if touched:
                fresh[text] = places
        groups = fresh
    found = sorted(groups.items(), key=lambda e: sorted(e[1]))
    scope = f'new since {merge_base[:12]} ({args.base})' if args.base else 'in total'
    elapsed = time.monotonic() - started
    if not found:
        print(f'check-copies: no copied code {scope} in {args.ref} '
              f'({len(norm)} files, {elapsed:.2f} s)')
        return 0
    for text, places in found:
        print(describe(norm, text, places))
    print(f'\ncheck-copies: {len(found)} copied block(s) {scope} in {args.ref} '
          f'({elapsed:.2f} s).')
    print(f'For each one, {ADVICE}. If two places truly must differ, list the pair with a '
          f'reason in {ALLOW_FILE}.')
    return 1


def self_test():
    """Plant copies in a throwaway repository and check what --base flags."""
    me = os.path.abspath(__file__)
    env = dict(os.environ, GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull,
               GIT_AUTHOR_NAME='check', GIT_AUTHOR_EMAIL='check@example.invalid',
               GIT_COMMITTER_NAME='check', GIT_COMMITTER_EMAIL='check@example.invalid')
    failures = []
    with tempfile.TemporaryDirectory(prefix='check-copies-') as repo:
        def sh(*args):
            subprocess.run(['git', '-C', repo, *args], env=env, check=True, capture_output=True)

        def write(path, text):
            full = os.path.join(repo, path)
            os.makedirs(os.path.dirname(full), exist_ok=True)
            with open(full, 'w') as handle:
                handle.write(text)

        def commit(branch, files):
            if branch != 'main':
                sh('checkout', '-q', '-B', branch, 'main')
            for path, text in files.items():
                write(path, text)
            sh('add', '-A')
            sh('commit', '-q', '-m', branch)

        def check(name, expect, *extra):
            proc = subprocess.run([sys.executable, '-I', me, '--repo', repo, *extra],
                                  capture_output=True, text=True, env=env)
            ok = proc.returncode == expect
            print(f"  {'ok  ' if ok else 'FAIL'} {name} (exit {proc.returncode}, wanted {expect})")
            if not ok:
                failures.append(name)
                print('    ' + (proc.stdout + proc.stderr).strip().replace('\n', '\n    '))

        block = [f'var total_{i} = speed * {i} + offset' for i in range(8)]
        body = '\n'.join(f'\t{line}' for line in block)
        unique = '\n'.join(f'\tvar other_{i} = {i * 7} - drift' for i in range(8))
        # An old 12-line copy pair, for edits made to one copy only.
        long = [f'\tvar step_{i}: float = lerp(start_{i}, goal, weight * {i}.5)' for i in range(12)]

        def long_file(lines):
            return 'extends Node\n\nfunc run(goal, weight):\n' + '\n'.join(lines) + '\n'

        sh('init', '-q', '-b', 'main')
        commit('main', {
            'game/a.gd': f'extends Node\n\nfunc a():\n{body}\n',
            'game/long_a.gd': long_file(long),
            'game/long_b.gd': long_file(long),
            'game/old_one.py': 'def f():\n' + '\n'.join(f'    x{i} = y{i} + {i}' for i in range(7)) + '\n',
            'game/old_two.py': 'def g():\n' + '\n'.join(f'    x{i} = y{i} + {i}' for i in range(7)) + '\n',
        })
        commit('unique', {'game/b.gd': f'extends Node\n\nfunc b():\n{unique}\n'})
        commit('planted', {'game/b.gd': f'extends Node\n\nfunc b():\n{body}\n'})
        disguised = '\n'.join(f'  {line.replace(" = ", "   =   ")}  # note {i}\n\n\t# a comment\n'
                              for i, line in enumerate(block))
        commit('disguised', {'game/c.gd': f'extends Node\n\nfunc c():\n{disguised}\n'})
        squeezed = '\n'.join(f'\t{line.replace(" ", "")}' for line in block)
        commit('squeezed', {'game/e.gd': f'extends Node\n\nfunc e():\n{squeezed}\n'})
        said = [f'\tsay("part {i} of {i + 1}", {i})' for i in range(7)]
        commit('said', {'game/f.gd': 'extends Node\n\nfunc f():\n' + '\n'.join(said) + '\n'})
        sh('checkout', '-q', 'main')
        sh('merge', '-q', '--ff-only', 'said')
        commit('respelled', {'game/g.gd': 'extends Node\n\nfunc g():\n' + '\n'.join(
            line.replace('part ', 'part') for line in said) + '\n'})
        js = [f'const part{i} = scale("#{i}{i}{i}", {i}) + base;' for i in range(7)]
        commit('js-base', {'site/one.mjs': '\n'.join(js) + '\n'})
        sh('checkout', '-q', 'main')
        sh('merge', '-q', '--ff-only', 'js-base')
        commit('js-copy', {'site/two.ts': '/* header\n * block comment\n */\n' + '\n'.join(
            f'{line}  // why {i}\n/* aside */' for i, line in enumerate(js)) + '\n'})
        commit('same-file', {'game/a.gd': f'extends Node\n\nfunc a():\n{body}\n\nfunc a2():\n{body}\n'})
        grown = '\n'.join(f'    x{i} = y{i} + {i}' + ('\n    z = shared_step()' if i == 3 else '')
                          for i in range(7)) + '\n'
        commit('old-copy-edit', {'game/old_one.py': 'def f():\n' + grown,
                                 'game/old_two.py': 'def g():\n' + grown})
        commit('old-copy-untouched', {'game/elsewhere.py': 'print("unrelated")\n'})
        added = '\tvar gain: float = 1.0'
        commit('one-copy-near-start', {'game/long_a.gd': long_file(long[:2] + [added] + long[2:])})
        commit('one-copy-middle', {'game/long_a.gd': long_file(long[:6] + [added] + long[6:])})
        commit('one-copy-changed', {'game/long_a.gd': long_file(
            long[:2] + ['\tvar step_2: float = 0.0'] + long[3:])})
        commit('one-copy-deleted-line', {'game/long_a.gd': long_file(long[:6] + long[7:])})
        commit('one-copy-comment', {'game/long_a.gd': long_file(
            long[:6] + ['\t# why this step matters'] + long[6:])})
        commit('one-copy-mostly-shared', {'game/long_a.gd': long_file(
            ['\tshared_steps(goal, weight)'] + long[7:])})
        commit('one-copy-removed', {'game/long_a.gd': long_file(['\tshared_steps(goal, weight)'])})
        # The old copy runs from `extends Node` to its last step, so the edges are the
        # file's first line and the line after the last step.
        commit('one-copy-edges', {'game/long_a.gd': 'class_name LongA\n' + long_file(
            long + ['\tvar after: float = 1.0'])})
        commit('ts-trailing-block', {'site/two.ts': '\n'.join(f'{line} /* why */' for line in js) + '\n'})
        commit('ts-open-block', {'site/two.ts': '\n'.join(
            js[:3] + [js[3] + ' /* the next lines', '   are a long comment */'] + js[4:]) + '\n'})
        commit('hash-no-space', {'game/h.gd': 'extends Node\n\nfunc h():\n' + '\n'.join(
            f'{line}#note' for line in body.split('\n')) + '\n'})
        commit('shell-hash', {
            'tools/one.sh': '\n'.join(f'count_{i}=${{#items_{i}}}' for i in range(7)) + '\n',
            'tools/two.sh': '\n'.join(f'count_{i}=${{#names_{i}}}' for i in range(7)) + '\n'})
        commit('triple-string', {
            'tools/one.py': 'TABLE = """\n' + '\n'.join(f'colour_{i}=#{i}{i}{i}aaa' for i in range(7)) + '\n"""\n',
            'tools/two.py': 'TABLE = """\n' + '\n'.join(f'colour_{i}=#{i}{i}{i}bbb' for i in range(7)) + '\n"""\n'})
        commit('space-path', {'game/with space.gd': f'extends Node\n\nfunc s():\n{body}\n'})
        commit('quoted-path', {'game/say "hi".gd': f'extends Node\n\nfunc q():\n{body}\n'})
        commit('allowed', {'game/b.gd': f'extends Node\n\nfunc b():\n{body}\n',
                           '.copies-allow': 'game/a.gd game/b.gd  fixture pair for the self-test\n'})
        commit('short', {'game/d.gd': 'extends Node\n\nfunc d():\n' + '\n'.join(
            f'\t{line}' for line in block[:5]) + '\n'})

        check('unique block passes', 0, '--ref', 'unique', '--base', 'main')
        check('planted copy is caught', 1, '--ref', 'planted', '--base', 'main')
        check('comments, blank lines and spacing do not hide a copy', 1,
              '--ref', 'disguised', '--base', 'main')
        check('spaces removed inside lines (a=b) do not hide a copy', 1,
              '--ref', 'squeezed', '--base', 'main')
        check('spaces inside quoted strings still count', 0, '--ref', 'respelled', '--base', 'main')
        check('// and /* */ comments do not hide a copy in TypeScript', 1,
              '--ref', 'js-copy', '--base', 'main')
        check('a copy inside one file is caught', 1, '--ref', 'same-file', '--base', 'main')
        check('a new line inside an old copy is caught', 1, '--ref', 'old-copy-edit', '--base', 'main')
        check('an old copy left alone passes', 0, '--ref', 'old-copy-untouched', '--base', 'main')
        check('a new line near the start of one old copy is caught', 1,
              '--ref', 'one-copy-near-start', '--base', 'main')
        check('a new line in the middle of one old copy is caught', 1,
              '--ref', 'one-copy-middle', '--base', 'main')
        check('a changed line in one old copy is caught', 1, '--ref', 'one-copy-changed', '--base', 'main')
        check('a deleted line in one old copy is caught', 1,
              '--ref', 'one-copy-deleted-line', '--base', 'main')
        check('a comment added inside one old copy passes', 0,
              '--ref', 'one-copy-comment', '--base', 'main')
        check('one old copy cut below six matching lines passes', 0,
              '--ref', 'one-copy-mostly-shared', '--base', 'main')
        check('one old copy removed passes', 0, '--ref', 'one-copy-removed', '--base', 'main')
        check('lines added just above and below one old copy pass', 0,
              '--ref', 'one-copy-edges', '--base', 'main')
        check('trailing /* */ comments do not hide a copy', 1,
              '--ref', 'ts-trailing-block', '--base', 'main')
        check('a /* comment opened after code does not hide a copy', 1,
              '--ref', 'ts-open-block', '--base', 'main')
        check('a # comment with no space before it does not hide a copy', 1,
              '--ref', 'hash-no-space', '--base', 'main')
        check('${#x} in shell is code, not a comment', 0, '--ref', 'shell-hash', '--base', 'main')
        check('a # inside a multi-line string is not a comment', 0,
              '--ref', 'triple-string', '--base', 'main')
        check('a copy in a path with a space is caught', 1, '--ref', 'space-path', '--base', 'main')
        check('a copy in a path git quotes is caught', 1, '--ref', 'quoted-path', '--base', 'main')
        check('an allowed pair passes', 0, '--ref', 'allowed', '--base', 'main')
        check('five matching lines are not a copy', 0, '--ref', 'short', '--base', 'main')
        check('without --base the old copy fails', 1, '--ref', 'main')
        check('--report always exits 0', 0, '--ref', 'planted', '--report')
    print('self-test ' + ('passed' if not failures else f'FAILED: {len(failures)} case(s)'))
    return 1 if failures else 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('--ref', default='HEAD', help='git ref to scan (default HEAD)')
    parser.add_argument('--base', help='only fail on copies that the branch adds or edits '
                                       'since git merge-base BASE REF')
    parser.add_argument('--report', action='store_true',
                        help='print every copy grouped by area and file, and exit 0')
    parser.add_argument('--min-lines', type=int, default=6, help='shortest copy (default 6)')
    parser.add_argument('--repo', default='.', help='repository to read (default: current folder)')
    parser.add_argument('--self-test', action='store_true', help='check this tool on planted copies')
    args = parser.parse_args(argv)
    if args.self_test:
        return self_test()
    if args.min_lines < 2:
        parser.error('--min-lines must be at least 2')
    try:
        return run(args)
    except GitError as error:
        print(f'check-copies: {error}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
