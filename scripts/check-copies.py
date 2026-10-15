#!/usr/bin/env python3
"""Find copied code: runs of 6 or more matching lines in two places.

The repository rule (AGENTS.md, "Don't duplicate code") is that shared logic
lives in one file that every user imports, and nothing merges with new copies.
This check enforces it. It reads the tracked code files of a git ref straight
from git objects, so it can check any branch without a checkout.

A copy is a run of at least --min-lines consecutive normalised lines that
appears in two files, or twice in one file. Normalising trims each line,
collapses runs of spaces, drops trailing comments, and skips blank lines,
comment-only lines and trivial lines (a lone bracket, pass, else:, fi, done,
docstring quotes, imports and the like), so comments, blank lines and
re-indenting do not hide a copy.

Usage (from the repository root):
    python3 scripts/check-copies.py                      # every copy in HEAD; exit 1 if any
    python3 scripts/check-copies.py --base origin/main   # only copies that touch lines added
                                                         # since the merge base; exit 1 if any
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

# Comment syntax per file type: line-comment marker, and whether /* */ blocks apply.
HASH = ('#', False)  # GDScript, Python, shell
SLASH = ('//', True)  # GDShader, TypeScript, JavaScript
CSS = (None, True)
SYNTAX = {'.gd': HASH, '.py': HASH, '.sh': HASH, '.gdshader': SLASH, '.ts': SLASH,
          '.tsx': SLASH, '.js': SLASH, '.mjs': SLASH, '.css': CSS}

# Lines that carry no logic of their own: closing brackets, bare keywords, docstring
# quotes and imports (two files that import the same modules share no code).
TRIVIAL = re.compile(
    r'^(?:[\[\](){};,]+|"""|\'\'\'|import \S.*|from \S+ import .*|@import .*'
    r'|pass|else:?|\} ?else ?\{|elif|try:|finally:|except:|return;?|break;?|continue;?'
    r'|end|fi|done|esac|then|do|default:)$')
SPACES = re.compile(r'\s+')


def git(repo, *args, data=None):
    proc = subprocess.run(['git', '-C', repo, *args], input=data, capture_output=True)
    if proc.returncode != 0:
        raise GitError(f"git {' '.join(args)}: {proc.stderr.decode(errors='replace').strip()}")
    return proc.stdout


class GitError(Exception):
    pass


def strip_trailing_comment(line, marker):
    """Cut a trailing line comment that sits outside string quotes."""
    if not marker or marker not in line:
        return line
    quote = None
    i = 0
    n = len(line)
    while i < n:
        ch = line[i]
        if quote:
            if ch == '\\':
                i += 2
                continue
            if ch == quote:
                quote = None
        elif ch in '"\'`':
            quote = ch
        elif line.startswith(marker, i) and (marker != '#' or i == 0 or line[i - 1] in ' \t'):
            return line[:i]
        i += 1
    return line


def normalise(text, ext):
    """Return [(line number, normalised text)] for the lines that count."""
    marker, blocks = SYNTAX.get(ext, HASH)
    out = []
    in_block = False
    for number, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        if blocks:
            if in_block:
                end = line.find('*/')
                if end < 0:
                    continue
                in_block = False
                line = line[end + 2:].strip()
            if line.startswith('/*'):
                end = line.find('*/', 2)
                if end < 0:
                    in_block = True
                    continue
                line = line[end + 2:].strip()
        line = strip_trailing_comment(line, marker).strip()
        if not line or (marker and line.startswith(marker)):
            continue
        line = SPACES.sub(' ', line)
        if TRIVIAL.match(line):
            continue
        out.append((number, line))
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
        texts = [t for _, t in lines]
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
        lines_a = [t for _, t in norm[pa]]
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


def added_lines(repo, base, ref):
    """Map path -> set of line numbers in ref added since merge-base(base, ref)."""
    try:
        merge_base = git(repo, 'merge-base', base, ref).decode().strip()
    except GitError as error:
        raise GitError(f'{error}\n(no merge base of {base} and {ref}: fetch the base branch '
                       'with its history, for example a checkout with fetch-depth 0)') from None
    diff = git(repo, '-c', 'core.quotePath=false', 'diff', '--no-color', '--no-ext-diff',
               '--find-renames', '--unified=0', '--src-prefix=a/', '--dst-prefix=b/',
               merge_base, ref, '--', *(f'*{ext}' for ext in CODE_EXTS)).decode('utf-8', 'replace')
    added = collections.defaultdict(set)
    path = None
    for line in diff.splitlines():
        if line.startswith('+++ '):
            target = line[4:]
            path = None if target == '/dev/null' else target[2:] if target.startswith('b/') else target
        elif line.startswith('@@') and path:
            match = re.match(r'@@ -\S+ \+(\d+)(?:,(\d+))? @@', line)
            if match:
                start, count = int(match.group(1)), int(match.group(2) or 1)
                added[path].update(range(start, start + count))
    return merge_base, added


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
    return f"{' ↔ '.join(spots)}\n    {len(text)} lines, starting: {text[0][:100]}"


def run(args):
    started = time.monotonic()
    repo = args.repo
    files = read_files(repo, args.ref)
    norm = {p: normalise(t, os.path.splitext(p)[1]) for p, t in files.items()}
    groups = find_copies(norm, args.min_lines, read_allow(repo, args.ref))

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
        merge_base, added = added_lines(repo, args.base, args.ref)
        fresh = {}
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
        sh('init', '-q', '-b', 'main')
        commit('main', {
            'game/a.gd': f'extends Node\n\nfunc a():\n{body}\n',
            'game/old_one.py': 'def f():\n' + '\n'.join(f'    x{i} = y{i} + {i}' for i in range(7)) + '\n',
            'game/old_two.py': 'def g():\n' + '\n'.join(f'    x{i} = y{i} + {i}' for i in range(7)) + '\n',
        })
        commit('unique', {'game/b.gd': f'extends Node\n\nfunc b():\n{unique}\n'})
        commit('planted', {'game/b.gd': f'extends Node\n\nfunc b():\n{body}\n'})
        disguised = '\n'.join(f'  {line.replace(" = ", "   =   ")}  # note {i}\n\n\t# a comment\n'
                              for i, line in enumerate(block))
        commit('disguised', {'game/c.gd': f'extends Node\n\nfunc c():\n{disguised}\n'})
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
        commit('allowed', {'game/b.gd': f'extends Node\n\nfunc b():\n{body}\n',
                           '.copies-allow': 'game/a.gd game/b.gd  fixture pair for the self-test\n'})
        commit('short', {'game/d.gd': 'extends Node\n\nfunc d():\n' + '\n'.join(
            f'\t{line}' for line in block[:5]) + '\n'})

        check('unique block passes', 0, '--ref', 'unique', '--base', 'main')
        check('planted copy is caught', 1, '--ref', 'planted', '--base', 'main')
        check('comments, blank lines and spacing do not hide a copy', 1,
              '--ref', 'disguised', '--base', 'main')
        check('// and /* */ comments do not hide a copy in TypeScript', 1,
              '--ref', 'js-copy', '--base', 'main')
        check('a copy inside one file is caught', 1, '--ref', 'same-file', '--base', 'main')
        check('a new line inside an old copy is caught', 1, '--ref', 'old-copy-edit', '--base', 'main')
        check('an old copy left alone passes', 0, '--ref', 'old-copy-untouched', '--base', 'main')
        check('an allowed pair passes', 0, '--ref', 'allowed', '--base', 'main')
        check('five matching lines are not a copy', 0, '--ref', 'short', '--base', 'main')
        check('without --base the old copy fails', 1, '--ref', 'main')
        check('--report always exits 0', 0, '--ref', 'planted', '--report')
    print('self-test ' + ('passed' if not failures else f'FAILED: {len(failures)} case(s)'))
    return 1 if failures else 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    parser.add_argument('--ref', default='HEAD', help='git ref to scan (default HEAD)')
    parser.add_argument('--base', help='only fail on copies that touch lines added since '
                                       'git merge-base BASE REF')
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
