# Translations

This folder holds the parts of the game's translation work that are not shipped with the game. It sits
outside `apps/game` on purpose: a file inside the Godot project is imported and exported.

| File | What it is |
|---|---|
| `messages.pot` | The template every translation file is made from. `scripts/i18n/extract_pot.sh` writes it with Godot's own generator; CI fails when it is out of date. |
| `glossary.json` | The fixed terms for the 10 languages (decisions D1, D9 and D11). Its `_about` field explains every field. |
| `style/README.md` | The rules every language shares: the engineer is never given a gender, WOLF is he, placeholders, tags, line breaks, length. |
| `style/<key>.md` | One guide per language, named by its glossary key (`es-419`, `es-ES`, `pt-BR`, `de`, `fr`, `pl`, `ru`, `ja`, `ko`, `zh-Hans`, `zh-Hant`). |

The translation files themselves are `apps/game/i18n/<code>.po`, beside the language table
`apps/game/i18n/languages.json`. So far: `es.po` and `es_ES.po` (localization PR L9), and `pt_BR.po`,
`fr.po` and `de.po` (PR L10).

`python3 -I -B scripts/i18n/i18n_tool.py glossary` checks the glossary and the style guides against each
other and against the language table, and `check` applies the glossary to every translated line. Both run
in CI. `development/localization.mdx` on the site describes every tool.

## Review

There is no translation website and no volunteer step (Nathanial, October 17, 2026: no Weblate). Each
language is reviewed this way, in its own pull request:

1. Claude translates the lines, following the style guides and the glossary.
2. Codex back-translates them into English independently.
3. `i18n_tool.py check` runs every gate, with `--back` for the back-translation, and CI runs it again.
4. The language is labelled "machine translation" in the game, the credits and the store until a native
   speaker reviews it (decisions D2 and D8; the stamps are in `style/README.md`, "Machine translation and
   review").

A paid proofreader for a language is optional and later, and it is Nathanial's call.
