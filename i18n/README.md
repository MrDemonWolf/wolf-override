# Translations

This folder holds the parts of the game's translation work that are not shipped with the game. It sits
outside `apps/game` on purpose: a file inside the Godot project is imported and exported.

| File | What it is |
|---|---|
| `messages.pot` | The template every translation file is made from. `scripts/i18n/extract_pot.sh` writes it with Godot's own generator; CI fails when it is out of date. |
| `glossary.json` | The fixed terms for the 10 languages (decisions D1, D9 and D11). Its `_about` field explains every field. |
| `style/README.md` | The rules every language shares: the engineer is never given a gender, WOLF is he, placeholders, tags, line breaks, length. |
| `style/<key>.md` | One guide per language, named by its glossary key (`es-419`, `es-ES`, `pt-BR`, `de`, `fr`, `pl`, `ru`, `ja`, `ko`, `zh-Hans`, `zh-Hant`). |

The translation files themselves are `apps/game/i18n/<code>.po` (`es.po`, `es_ES.po`, `pt_BR.po` and so
on), beside the language table `apps/game/i18n/languages.json`. None exist yet: the first one, Spanish,
comes with localization PR L9.

`python3 -I -B scripts/i18n/i18n_tool.py glossary` checks the glossary and the style guides against each
other and against the language table, and `check` applies the glossary to every translated line. Both run
in CI. `development/testing.mdx` on the site describes every tool.

## Weblate

Native-speaker review happens on [Hosted Weblate](https://hosted.weblate.org)'s free Libre plan, which is
for public open-source projects; this repository is public under GPL-3.0-or-later (decision D8). Weblate
reads and writes the PO files in Git and shows each line's context, notes and state. It is set up to
send its changes as pull requests, so every volunteer's edit passes the same CI gates as any other change
and nothing reaches `main` without review.

The project does not exist yet. These are the settings to create it with. The names are Weblate's own
labels (docs.weblate.org, "Component configuration", read October 17, 2026).

**Project**

| Setting | Value |
|---|---|
| Project name, URL slug | `WOLF//OVERRIDE`, `wolf-override` |
| Project website | `https://github.com/MrDemonWolf/wolf-override` |
| Translation instructions | "Read the shared style guide first, then your language's guide, and use the glossary's words: https://github.com/MrDemonWolf/wolf-override/tree/main/i18n/style. Never give the engineer a gender in any language. Lines are machine-translated until a native speaker reviews them." |
| Enable reviews | On, so a reviewer approves lines. |

**Component**

| Setting | Value | Why |
|---|---|---|
| Component name, URL slug | `Game`, `game` | |
| Version control system | GitHub pull request | Weblate pushes to its own fork and opens a pull request; it never pushes to `main`. |
| Source code repository | `https://github.com/MrDemonWolf/wolf-override.git` | |
| Repository branch | `main` | |
| Push branch | `weblate-translations` | |
| File format | gettext PO file | |
| File mask | `apps/game/i18n/*.po` | The files the game registers. |
| Template for new translations | `i18n/messages.pot` | |
| Language filter | `^(es\|es_ES\|pt_BR\|de\|fr\|pl\|ru\|ja\|ko\|zh_Hans\|zh_Hant)$` | Only the 10 languages' 11 files (D1). |
| Language code style | POSIX style using underscore as a separator | Godot's names: `pt_BR`, `zh_Hans`. |
| Adding new translation | Disable adding new translations | Each language arrives through its own PR (L9 to L12), with its gates and stills. |
| Source language | English | |
| Manage strings | Off | The English comes from the game's source. |
| Translation license | GPL-3.0-or-later | The repository's licence. |
| Long lines wrapping (file format parameter `po_line_wrap`) | No wrapping | The repository's PO files are not wrapped; wrapping would rewrite every line. |
| Add-ons | "Update PO files to match POT (msgmerge)" | Keeps the PO files in step with `messages.pot` the way the research pipeline describes (codex/localization-research at 520cad1, `docs/research-2026-10/localization/PIPELINE.md`). |

**Glossary.** Weblate keeps its glossary as a component of its own. `glossary.json` stays the one source:
`python3 -I -B scripts/i18n/i18n_tool.py weblate-glossary <folder>` writes one TBX file per language,
which is uploaded to that language in Weblate's glossary (Upload, "Add new strings"). Upload them again
whenever `glossary.json` changes. Forms to avoid are written as notes, not as Weblate "forbidden" terms;
CI's glossary gate fails them.

**What Weblate does not do for us.**
- **Review stamps.** Weblate's "approved" state lives in Weblate, not in the PO file. Before a language
  counts as reviewed, its approvals are written into the file as `# reviewed-by: <name> <date>` comments
  (the shared style guide, "Machine translation and review") in a pull request.
- **Machine suggestions.** Weblate can offer machine-translation suggestions. Every line already starts as
  a labelled machine translation (D2); a volunteer's edit should be their own reading.
- **Credits.** Weblate records who changed what. The credits name volunteers and reviewers by their
  consent, and never anyone who did not take part.

**Checking it works.** After the component is created and the first PO file exists (L9, Spanish), open
one line that has notes and confirm Weblate shows its `#.` notes (the translator note and the `i18n:`
marks), its source location, its context and its glossary terms. The parsing library Weblate uses,
translate-toolkit, already reads all of them from a planted test line and the generated TBX files
(localization PR L5).
