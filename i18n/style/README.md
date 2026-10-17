# Translating WOLF OVERRIDE: the shared style guide

Read this first, then the guide for your language in this folder and the terms in
[`../glossary.json`](../glossary.json). These rules hold in every language. Your language's guide adds only
what is different for it. Every wording choice is a proposal for native reviewers, and every final word
belongs to Nathanial Henniges, the game's author.

The guides are named by glossary key: `es-419` (Latin-American Spanish, file `es.po`), `es-ES` (Spain,
`es_ES.po`), `pt-BR`, `de`, `fr`, `pl`, `ru`, `ja`, `ko`, `zh-Hans` and `zh-Hant`. The files they belong to
are in `apps/game/i18n/`, and the template every file is made from is [`../messages.pot`](../messages.pot).

## The game and its people

WOLF OVERRIDE is a grounded military sci-fi game with a dark-horror edge, set inside a sealed base.
- **The engineer** is the only playable character, a systems engineer the player names Rowan, Alex or
  Morgan. The engineer is non-binary and uses they/them. **No language may show the engineer's gender**
  (decision D9).
- **WOLF** is a robotic wolf and an independent companion, never a pet or a tool. WOLF is **he** in
  every language. His name stays `WOLF`, in Latin capitals, everywhere, and is never declined.
- **The Director** runs the base. He is a person (he/him).
- **The sentry** is a patrolling security robot (it).

## Rules no translation may break

The checker (`scripts/i18n/i18n_tool.py check`) fails a language that breaks one of these.
- **Placeholders.** Keep every `%s`, `%d`, `%02d` or `%.1f` in the same order, and every `{name}`-style
  placeholder (any order). `%s` is usually the engineer's first name. A stray `%%` is an error.
- **Speaker tag.** A line that starts with `WOLF: ` keeps that exact tag at its start.
- **Line breaks.** A line marked `i18n: keep-breaks` keeps the English number of breaks (`\n`). Any other
  break is English layout: you may drop it, and the game breaks rows for your language, but never add one.
- **The key token.** `E:` (and `HOLD E:`, `Press E`) stays a Latin capital `E`, never a Cyrillic `Е` or a
  full-width `Ｅ`: the game puts the player's bound key there.
- **Tags.** BBCode such as `[b]` or `[color=#ff8800]` stays exactly, properly nested.
- **Alphabet.** No Cyrillic letters in a Latin or CJK text, and no Latin letters in a Cyrillic text
  except the words in the glossary's `keep` list (WOLF, `E:`, the studio and author names).
- **Glossary.** Use each term's required form from `../glossary.json` whenever the English line uses the
  term, and never one of its `avoid` forms. A term whose status is `open` is a reviewer's word: choose one,
  note it on the line, and propose it for the glossary.
- **The engineer's gender.** See "The engineer" below and your language's guide.
- **The word "fuzzy".** Never write it in a comment: Godot skips the next line after any comment
  containing it.

## The engineer

Rephrase; never pick a gender. The game has no gendered form for the engineer to fall back on.
- Use the name, the second person ("you"), or a construction that shows no gender.
- Name the department or the field, not the person: "maintenance engineering", not "the engineer
  (m/f)".
- No neopronouns (French iel, Spanish elle) unless Nathanial chooses them.
- Each line says how the engineer appears in it with an `i18n:` note: `engineer=name` (the name fills
  `%s` or `{name}`), `you` (addressed), `third` (referred to without the name) or `self` (speaking).
  `slot=key` or `slot=choice` says a `%s` holds something else. Lines with these notes are where gender
  can slip in.
- If a rephrasing cannot keep the line's meaning, flag it rather than guess: only Nathanial changes the
  English.
- The checker's gender gate is a heuristic. A correct line it flags is cleared by rewording or by a
  reviewer's comment on the line: `# gender-ok: <your name> <date>`.

## WOLF's voice

Calm, direct, terse and dry. A peer, never a servant. He can refuse. No exclamation marks and no slang.
He speaks informally to the engineer (tú, du, tu, ty, ты). Keep his lines as short as the English.

## Station plates, buttons and length

- Station plates (BREAKER, SAFE POINT, TANK RELEASE and the others) are 12 px labels on the machines. Keep
  them ALL CAPS and as short as you can. A hint that names a plate uses the plate's exact words.
- Buttons and objectives use the infinitive (or your language's usual form for a command on a button).
- Stay within about 130% of the English length where you can. Dialogue boxes are 440 px wide at 23 px.
  The layout checks have the last word: the prototype's German SETTINGS became OPTIONEN because
  EINSTELLUNGEN did not fit.
- Two spaces after an end-card recap topic ("SENTRY  ...") stay two spaces.

## Words painted into the art

DOOR 4B-07, SECTOR 4B and RESTRICTED AREA are painted on a door and stay English as signage on the base
(decision D3). If a line quotes one, keep it in English.

## Machine translation and review

Every language starts as a machine translation by Claude (Anthropic), cross-checked by an independent
back-translation by Codex (OpenAI), and is labelled "machine translation" in the game, the credits and
the store until native speakers review it (decisions D2 and D8).
- Each machine line carries `# machine-translated by Claude (Anthropic), unreviewed`.
- A reviewed line carries `# reviewed-by: <name> <date>`. A language counts as reviewed when every
  story-critical line (marked `i18n: story`) has a stamp. A changed English line loses its stamp.
- Reviewers check first: the engineer's gender (Russian and Polish above all), WOLF's voice, and the
  glossary's open terms.
- The credits name the people who review, and never anyone who did not.

## Where the rules come from

The localization research (`codex/localization-research` at `520cad1`,
`docs/research-2026-10/localization/PIPELINE.md`, "Style rules", and `DECISIONS.md`, D1-D11; in Notion as
"Localization") and its pipeline trial's style packet (`pipeline/style_packet.md` on that branch). PR L5
of the localization plan turned them into these guides with decisions D9 and D11 at their defaults,
which Nathanial approved on October 16, 2026.
