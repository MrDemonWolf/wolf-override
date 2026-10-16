# Pipeline: translating, checking, reviewing and updating

How the translations are made, checked, reviewed, labelled and kept up to date. The research-pipeline
step tried each translator on 12 real game lines (`pipeline/`). The prototype then ran the chosen
pipeline on 34 msgids in four languages (`prototype/`).

## The decision: AI translates at build time; the game ships fixed files

Nathanial said on October 15: "we can do the translations on the device using AI, whatever works".
The recommendation reads "on the device" as **on our machine, at build time**:
1. AI agents translate the catalogs on the developer's Mac.
2. Every line passes the automated checks.
3. People review the lines.
4. The game ships fixed `.po` files.

**Nothing is translated on the player's device while they play.** The pipeline step found six reasons:
1. **No engine support.** Godot has no OS translation API, so each platform would need its own
   GDExtension:
   - Apple's Translation framework;
   - Android's ML Kit, which downloads language packs and is "intended for casual and simple
     translations" (developers.google.com/ml-kit/language/translation);
   - nothing found for Windows apps (Edge's Translator API is web-only).
2. **Nothing to pin.** The output is not deterministic and changes with OS updates, so no test,
   still or approved-wording check could pin it.
3. **Downloads.** Language packs can be missing offline, and downloading one needs a consent prompt.
4. **Quality.** Apple's framework failed in the trial (next table).
5. **Layout.** Boxes are split at 440 px and 42 characters, and runtime text could not be checked for
   overflow ahead of time.
6. **Disclosure.** Valve's January 2026 rules treat content generated live during play as its own AI
   disclosure category, apart from content made during development (VGC, January 17, 2026).

## What the trial and the prototype measured

**The trial** (`pipeline/out/side_by_side.md`, `scores.json` and `judgments.json`): 12 real lines from
`main`, each translated into es-419, de and ja.

| Translator | Hard failures | Glossary misses | Gender failures | Meaning errors | Use it as |
|---|---|---|---|---|---|
| Claude agents, with the style packet and glossary | 0 | 0 | 0 | 1-3 minor per language | the translator |
| Codex (ChatGPT subscription) | 0 | 0 | 0 | 1-3 minor per language | the independent back-translator and critic |
| Apple Translation, on the device (macOS 27.0.1) | 3-4 per language | 5-7 per language | 1 (es made the engineer masculine) | 3-6 per language | an optional third signal on Macs, never a gate |

Apple's hard failures included:
- every authored `\n` doubled;
- Japanese `%%dの%d`, which breaks Godot's `%` format;
- "draw it" (the lure) read as "draw a picture";
- Japanese "out in the open" rendered as "naked".

Two more options were ruled out on paper:
- **Local open models.** NLLB-200 is CC-BY-NC 4.0, so it cannot be used for a game that may be sold.
  MADLAD-400 3B is Apache 2.0 but takes no glossary or context. Gemma- and Qwen-class models would load
  Nathanial's Mac and still need a quality trial.
- **Crowdin's free open-source plan.** It requires "no commercial products related to the project",
  and a paid Steam release would break that.

**The prototype** ran the pipeline on the 34 msgids its stills show (`prototype/evidence/po_check.json`).

| | es (Latin America) | de | ja | ru |
|---|---|---|---|---|
| Translated by | Claude | Claude | Claude | Claude (design step) |
| `msgfmt --check-format --check-header` | rc 0 | rc 0 | rc 0 | rc 0 |
| Gate failures (every gate below, re-run by the fix-2 step) | 0 | 0 | 0 | 0 |
| Back-translation's `engineer_gendered` (fix-2 run) | false on 34 | false on 34 | false on 34 | false on 34 |
| Drift flags (chrF under 35 on lines over 4 words; fix-2 run) | 2 ("interruptor" reads as "switch") | 0 | 1 | 1 |
| Mean chrF of Codex's back-translation against the English (fix-2 run) | 77.4 | 71.3 | 78.3 | 62.4 |

The fix-2 step ran the back-translation again (Codex session `01a146cf-4beb-7f42-8d61-726071ffb149`,
`prototype/evidence/codex/codex_back_prompt_fix2.txt`), because the earlier answers had no
`engineer_gendered` field and were keyed by list position. The earlier runs gave mean chrF 77.1, 70.5,
77.4 and 64.0 and only the 2 es drift flags (this file at commit 9a59e0e). The new ja and ru flags are
literal round trips of correct lines ("WOLF wakes up on his own"; "the safety valve was blown off"):
chrF moves by a few points from one back-translation to the next, which is why it only flags.

**The checks catch what they should.** Broken copies were run as negative controls:

| Copy | Breaks put in | Caught |
|---|---|---|
| `es` | `%s` dropped; `%s` changed to `%d`; `E:` removed | all 3 (msgfmt 2, the placeholder check 2, the token check 1) |
| `ru` (design step) | a Cyrillic `Е:` for the Latin key token; a Latin `A` inside `ПАУЗА`; a dropped `%d` | all 3 (the token check, the script guard, msgfmt and the placeholder check) |
| `ru` and `es` (fix step) | the engineer gendered: ru "%s стояла на решётке" (feminine past tense), es "%s estaba sola" (agreeing adjective); and a back-translation that answers `engineer_gendered: true` | all 3 (the gender gate 2, the back-translation's field 1) |
| `ru`, `de`, `ja` and a planted `es_ES` (fix-2 step) | ru "Ты нашла рубильник" on a hint that addresses the engineer (no name slot); ru "заметил %sа" (a case ending glued to the name); de "%s ... gesehen.\nSie soll ..." and ja "彼女は..." (a gendered pronoun after the name); an `es_ES` copy of `es` with NEW GAME left empty and CONTINUE fuzzy | all 6: the gender gate caught the three gendered lines, the name-case gate the glued ending (the gender gate also flags that line, through the sentry's verb beside the name), and the sibling gate both es_ES lines |
| `i18n_tool.py selftest` | 54 fixed cases: printf and named placeholders (`%02d`, `%.1f`, `{0}`, a misspelt `{total}`); BBCode tags dropped, recoloured or crossed; 27 gender lines in ru, pl, es, fr, de, ja and zh, the reviewers' 7 planted lines of October 16 among them (WOLF's "you" in the past tense, the vocative, pronouns, the German job noun); the name-case ending; a ru plural with a missing form or a dropped `%d`; 5 sibling-file cases; and the clean lines each gate must pass | 54 of 54 as expected |

The reports are `prototype/evidence/po_check_negative_control*.json` (all four re-run by the fix-2 step
with its tool) and `prototype/evidence/gate_selftest.json`. Every report with a planted error makes
`check` exit 1. The prototype's real 136 lines pass every gate with 0 failures, and `check` exits 0
(`prototype/evidence/po_check.json`).

**What each gate has been proved on, honestly:**
- **On real lines:** placeholders, tag, breaks, key token, script, glossary, msgfmt, and the gender
  checks as far as the 34 msgids reach. Those hold 2 lines that name the engineer (the two knockdown
  cards), 6 hints that address them and the name card. The gender checks flagged none of them, and
  Codex answered `engineer_gendered: false` on all 136 rows, a real run, not a planted one.
- **Only on planted cases:** named and printf-width placeholders, BBCode, plural forms, the name-case
  gate and the sibling gate, because no prototype msgid has a named insert, a tag, a plural or a sibling
  file. 24 of the game's 26 gender-risk lines are not among the 34 msgids, so the gender checks have not
  met them in a real translation yet; L11 (pl and ru) is where they do.

**chrF on its own is not a gate.**
- Among the lines Apple back-translated, Apple's own output scored the highest mean chrF (59.55 over its 36 lines, against
  51.2-51.8 for the other translators' lines it back-translated), although Apple's translations were the
  worst. A round trip through the same engine confirms itself. (Across all pairings, Claude's lines
  back-translated by Codex and Codex's by Claude score higher still, 62.39 and 62.75; means recomputed from `pipeline/out/scores.json`.)
- Correct short labels score low: TANK RELEASE against "TANK DROP" is 19.6.
- So chrF only flags a line for a person. The real drift check is the back-translator's list of
  meaning differences.

## The steps, for each batch

1. **Extract.** `extract_pot.sh` runs Godot's own generator headless and writes `i18n/messages.pot`
   (DESIGN.md, "One extraction tool").
2. **Batch.** Translate one scene or room at a time, in reading order: the opening, the corridor,
   Records, the Service Junction, menus and settings, and the end card. Each batch carries:
   - the whole scene's English, with the speaker of each line and what the player sees then;
   - the surface each line appears on (dialogue box at 440 px and 23 px, plate at 12 px, button) and
     its length budget;
   - a `#. TRANSLATORS:` note per line (the prototype's `translations/claude.json` "context");
   - the glossary and that language's style guide.
3. **Translate.** A Claude agent translates the batch, through the subscription and never billed API.
4. **Back-translate independently.** Codex, through the ChatGPT subscription and in a read-only
   sandbox, back-translates every line:
   - It is **not shown the English**.
   - Each text comes with who speaks and how the engineer appears in it (named, addressed as "you",
     referred to, or absent), from the line's `#. i18n:` marks, but never with its English.
   - It notes anything ambiguous, unidiomatic or gendered (`i18n_tool.py backprompt`), and answers a
     structured `engineer_gendered` true or false for each line. The free-text notes alone are too
     noisy to gate on: they say "masculine" for WOLF, the Director or the sentry on almost every ru, es
     and de row.
   - Answers are filed by language and a hash of the line's context and English (`entry_key`), not by
     position, so a `msgmerge` between the back-translation and the check never moves an answer onto
     another line.
   - The model that translated a line never back-translates it.
   - Each Codex session is archived when done.
5. **Run the gates.** `i18n_tool.py check` writes one JSON report and exits 1 if any language fails (a
   failed line, a non-zero msgfmt or a sibling gap), so the CI job that runs it fails too. Every gate must
   pass:
   - `msgfmt --check-format --check-header`. The tool adds `#, c-format` itself, since Godot's
     generator writes no format flag.
   - **Placeholders:** the same printf inserts in the same order, compared whole (`%s`, `%d`, `%02d`,
     `%.1f`: every form Godot's `String::sprintf` reads, `core/string/ustring.cpp`), and the same named
     placeholders (`{name}`, `{current}`, `{0}`) in any order. A stray `%%` counts as a mismatch. A
     misspelt named placeholder matters: `String.format` leaves an unknown key on screen as literal text,
     and msgfmt ignores braces.
   - **BBCode tags:** the same tags with the same values (`[b]`, `[color=#ff8800]`), properly nested. The
     credits are one BBCode msgid, so this gate must pass before D4 translates them.
   - **Speaker tag**, until speaker and words are stored apart.
   - **Line breaks.** A msgid marked `#. i18n: keep-breaks` (the name card, a choice list) keeps the
     English count. Every other `\n` is layout sized for English, so a translation may drop it and let
     `DialogueBoxes` break rows for its language, but may never add one (Apple doubled them in the trial).
   - **The `E:` key token**, until it becomes a placeholder.
   - **Script guard**, ported once from ConPaws' locales-script test: no Cyrillic in a Latin-script
     or CJK text, and no Latin letters in a Cyrillic text outside the glossary's keep words.
   - **Glossary:** each term's required form, with stems for Slavic languages.
   - **The engineer's gender.** Each line says how the engineer appears in it, with a `#. i18n:` mark
     written in the source (`engineer=name`, `you`, `third` or `self`; `slot=key` or `slot=choice` when
     a `%s` is not the name). Per language, `prototype/tools/languages.json` holds the gendered word
     forms (ru and uk past tense in -л/-ла, pl -ł/-ła, es and pt -ado/-ada, fr -é/-ée, "alone",
     "ready", job nouns), the second- and first-person pronouns and the gendered third-person pronouns.
     A line fails when:
     - a gendered form sits within 3 words of the name, in the same clause;
     - a clause holds "you" (ты, ty, tú) and a gendered form ("%s, ты была права");
     - on a line that addresses or describes the engineer, a clause without "I" holds a gendered form
       ("Ты нашла другой путь" fails, WOLF's own "Я отказался" passes; Polish -łem/-łam endings are
       WOLF's and pass);
     - a gendered pronoun (он/она, er/sie, 彼女, 她) sits in the name's sentence or the next one;
     - the back-translation answers `engineer_gendered: true`.

     With every gender-risk line marked (PR L7c), the checks reach all 26. A line with no mark is checked
     only next to its name slot, which leaves out the 6 with no slot. It is a heuristic: it flags some
     correct lines (a noun that ends like a verb, a pronoun that means WOLF), and it misses a gendered
     form its lists lack. A flag is cleared by rewording or by a reviewer's `# gender-ok: <name> <date>`
     comment, and native review of the 26 gender-risk lines stays the real check (below).
   - **Name case** (pl, ru, uk): no letter glued to the name slot ("заметил %sа"), since the name stays
     in the nominative.
   - **Plural forms:** one `msgstr[n]` per form of the header's rule, none empty, each with the
     English inserts. Every form is checked, not only `msgstr[0]`.
   - **Sibling files complete:** where a language has two files (es and es_ES, zh_Hans and zh_Hant),
     a line one of them translates must be translated, not fuzzy, in the other. Godot would otherwise
     show the sibling's text (DESIGN.md, "A missing line falls back to its sibling file").
   - **Drift flag:** chrF under 35 on lines over 4 words sends the line to a person.

   An earlier draft also listed a "consistency" gate (the same msgid always gets the same
   translation). Within one PO file that holds by construction, since gettext keeps one entry per msgid
   and `msgctxt`, so there is nothing to check. Consistency across lines is the glossary gate's job.
6. **Check the layout.** `tests/i18n_test.gd` runs headless:
   - every character drawable by the bundled font chain;
   - no overflow on the title, menus, Settings rows, HUD, plates, the end card (its recap rows are the
     longest translated UI text), the choice rows and the credits' RichTextLabel, with the build's
     overflow check (DESIGN.md);
   - every dialogue box fits its rows at every TEXT SIZE step.

   Then `i18n_capture.gd` renders stills per language in the container (`tools/render/render.sh`), for
   a person to look at.
7. **Human review** (below).
8. **Stamp and ship.** A reviewed line carries `# reviewed-by: <name> <date>`. A language counts as
   reviewed when every story-critical line has a stamp.

## Style rules

The pipeline step's style packet (`pipeline/style_packet.md`) and glossary (`pipeline/glossary.json`)
are the starting point. The design step added Russian to both. In the build they become
`i18n/style/<code>.md` and `i18n/glossary.json`. All wording choices stay Nathanial's (decisions D9 and
D11).

### The engineer is never gendered

The engineer is non-binary and uses they/them (`docs/decisions.md` S1-03). English can avoid gender;
most of the 10 cannot. The rule is to rephrase, never to pick a gender:

| Language | Where gender shows | The rule |
|---|---|---|
| es, pt_BR, fr (and it) | Adjectives and participles agree (solo/sola, seul/seule, sozinho/sozinha); job nouns (ingeniero/a) | Rephrase with an adverbial phrase ("sin ayuda", "por su cuenta", "sans aide"). Name the department, not the person: the prototype's name card reads INGENIERÍA DE MANTENIMIENTO. French avoids the passé composé with être about the engineer. Neopronouns (French iel, Spanish elle) only if Nathanial chooses them (D9). |
| de | Nouns and pronouns only; predicative adjectives do not agree | No Ingenieur/Ingenieurin. Name the field: WARTUNGSTECHNIK. Use the name instead of er/sie. |
| ru, pl (and uk, cs) | **Past-tense verbs** (сделал/сделала, zrobił/zrobiła), short adjectives, participles, and "yourself" (сам/сама) | Present tense, a noun phrase, an impersonal construction ("сорвало клапан") or the imperative, which has no gender. The prototype's Russian knockdown card does this: "Сорвало предохранительный клапан, а %s — прямо на решётке." Polish addresses with ty, never Pan/Pani. This is the hardest rule; native review checks it first. |
| ja, ko, zh | Little grammatical gender, but gendered pronouns exist | Never 彼/彼女 (ja), 그/그녀 (ko) or 他/她 (zh) for the engineer; use the name or drop the pronoun. |
| tr (Tier 1) | none | (no rule needed) |

**This affects 26 lines in the game and 44 in the changelog** (STRINGS.md). Seven of the 26 are
past-tense recap and narration lines about the engineer. If a Russian or Polish rewrite cannot keep
their meaning, the English would need restructuring, and only Nathanial can change the English (D9).

### WOLF is he

WOLF is masculine in every language: es él, pt ele, fr il, it lui, de er (which fits der Wolf), ru он,
pl on, with masculine past tense.
- In Chinese, WOLF is 他 and never 它: he is a person, not an object.
- In Japanese, never それ or あれ for WOLF.
- WOLF is never declined in Russian or Polish ("с WOLF", "o WOLF"). The name stays as written in Latin
  letters in every language.

**WOLF's voice:** calm, direct, terse and dry, a peer and never a servant; no exclamation marks and no
slang.
- He uses informal address (tú, du, tu, ты, ty).
- In Japanese he speaks in plain form, without keigo. His first-person pronoun (俺, 私 or 僕) and how
  he refers to the Director are Nathanial's call (D11).
- His Korean speech level is also Nathanial's call (D11).

### Inserting names

The engineer's name comes from a fixed roster of three: Rowan Vale, Alex Bennett and Morgan Reed, all
provisional (`m0_state.gd`). The rules:
- **Slavic languages:** the name stays in the nominative. Make it the subject, or put it after a dash
  or a colon ("Страж заметил: %s на открытом месте"). Never put it where the language needs a case
  ending ("под %s", "у %s"). The prototype's Russian lines follow this, so no declined forms are
  needed for any of the three names.
- **German possessives:** use "von %s", never "%ss". Spanish, French and Portuguese use "de %s".
- **Korean:** particles change with the name's last sound. 로완 and 모건 end in a consonant (은, 이);
  알렉스 ends in a vowel (는, 가). Rephrase so no particle follows the name, or store the particle
  class with each name.
- **Names in other scripts.** In Russian, Japanese, Korean and Chinese text the Latin "Rowan" stands
  out. The default is to store each name per language: Роуэн, ローワン, 로완, 罗温 (samples only,
  D9). The English name stays the internal key.
- **Upper case in Turkish.** The game upper-cases the name and the tags with `to_upper()`, which
  ignores the locale. For Turkish, upper-case with the locale's rules (Tier 1).

### Plates, tokens, quotes and punctuation

**Station plates:**
- They follow the glossary in every line that names them.
- In Russian and Polish a plate is quoted in «» in its own nominative form ("к пульту «СБРОС БАКА»"),
  so the plate's words never change case.
- Whether plates are translated at all is decision D3.

**Key tokens.** Until the hint bar uses placeholders, the Latin "E:" stays exactly as written. A
Cyrillic "Е" looks the same but is never replaced; the token check catches it (measured).

**Placeholders.** Lines with more than one insert get named placeholders (`{current}`, `{total}`,
filled with `String.format`), so a translator can reorder them. Positional `%s` cannot be reordered
(Godot 4.7 "Internationalizing games"). The placeholder gate checks named ones as a set, in any order.

**Quotes:**

| Language | Quotes |
|---|---|
| fr | « … », with no-break spaces inside |
| ru, es | «…» |
| de | „…“ |
| pl | „…” |
| ja, zh_Hant | 「…」 |
| zh_Hans | “…” |

**Punctuation.**
- French puts a no-break space (U+00A0) before `; : ! ?`. Our fonts lack the narrow U+202F.
- Russian and Polish never leave a one-letter word at the end of a row (ru а, в, и, к, о, с, у, я;
  pl a, i, o, u, w, z). The translation binds it to the next word with a no-break space (U+00A0). The
  design step's Russian stills left "а" and "в" at row ends. A gate checks this from the build's first
  Slavic PR (PLAN.md).
- Japanese and Chinese keep 。 and 、 in the game's boxes. Netflix drops them in subtitles; that is a
  style choice the guide states once.

**Register and length.**
- Buttons and objectives use the infinitive.
- Stay within about 130% of the English length where possible, and as short as possible on plates and
  buttons.
- The overflow gate has the last word: it made the prototype's de SETTINGS shorter, OPTIONEN instead
  of EINSTELLUNGEN.

### Open glossary questions found so far

| Term | What the back-translation showed |
|---|---|
| breaker | es "interruptor" reads as "switch" (both es drift flags). The ru sample uses "рубильник", which reads as "knife switch". "Автомат", the everyday Russian word for a circuit breaker, also means an assault rifle, which a military base makes ambiguous. |
| LOCKDOWN | es BLOQUEO reads as "blockage"; ru БЛОКИРОВКА reads as "lockout". |
| TANK RELEASE | ru «СБРОС БАКА» reads as "TANK RESET"; сброс means both drop and reset. |
| the Director | ja 所長 reads as "head of the facility": a title, or a name? |
| SERVICE JUNCTION | de VERSORGUNGSKNOTEN reads as "supply node"; ru СЕРВИСНЫЙ УЗЕЛ reads as "service node". |
| HOLD E: | The de word order "HALTEN E:" is forced by the token. Placeholders fix it. |

## Human review

- **Where.** Weblate's free Libre plan is for public projects (weblate.org/en/hosting, read October
  16, 2026). The repository is public under GPL-3.0. Weblate reads and writes PO files in Git and
  shows each line's context, notes and fuzzy state.
- **Who.**
  - Community native speakers first, in the order of the list (es, de and ja were the pipeline
    trial's first three).
  - Before any paid release, one paid native proofreader per language reads the story lines. Rates
    were not researched: a gap.
- **What is checked first:**
  - the engineer's gender in Russian and Polish;
  - WOLF's voice;
  - the open glossary terms.
- **Shown as reviewed** only when every story-critical line carries a reviewer stamp. A changed line
  loses its stamp.

## Honest labelling

**In the picker.** An unreviewed language carries a short tag in its own language. The default tags
(decision D2) are standard terms, still to be reviewed:

| Language | Tag |
|---|---|
| Deutsch | maschinelle Übersetzung |
| Español (both) | traducción automática |
| Français | traduction automatique |
| Português (Brasil) | tradução automática |
| Polski | tłumaczenie maszynowe |
| Русский | машинный перевод |
| 日本語 | 機械翻訳 |
| 한국어 | 기계 번역 |
| 简体中文 | 机器翻译 |
| 繁體中文 | 機器翻譯 |

**In the credits.** Name the tools and the people, and never invent a translator (AGENT.md; the IGDA
crediting guidelines). For example: "Translations: machine translation by Claude (Anthropic),
cross-checked with Codex (OpenAI); reviewed by <names>", or "not yet reviewed".

**In each PO file:**
- The header names the machine translation (`Last-Translator: Claude (Anthropic), machine translation,
  unreviewed`).
- Each machine line carries `# machine-translated by Claude (Anthropic), unreviewed` until a person
  stamps it.

**On the store pages:**
- Steam's language table lists only languages that ship.
- "About This Game" says "machine-translated, community review in progress" until review is done.
- Valve's January 2026 rules require disclosing AI used "to generate content for the game" (VGC,
  January 17, 2026). They do not name translation. The conservative default is to disclose it in the
  Content Survey (D2).
- No App Store rule was checked: a gap.

## When the English changes

1. Extract the POT again.
2. Run `msgmerge --update` on every PO file.
   - Unchanged lines keep their translation.
   - Changed lines turn `#, fuzzy`.
   - The pipeline step rehearsed this on its German file: msgmerge kept 11 translations and flagged
     the edited line fuzzy ("11 translated messages, 1 fuzzy translation").
3. Godot skips fuzzy entries, so no stale translation ships. What players see instead depends on the
   other files: Godot looks each line up in every loaded file of the language, so a fuzzy line in
   `zh_Hant` would show `zh_Hans`'s text and one in `es_ES` the Latin-American text (measured,
   `godot/evidence/runtime.txt`). The game registers only the chosen language's file (DESIGN.md), so
   the player sees the new English, and the sibling gate fails the build until both files of a pair
   translate the line.
4. The translator re-translates only fuzzy and new lines, given the old translation and the English
   diff.
5. The back-translation and all gates run again.
6. A changed line that was reviewed loses its stamp and goes back to the review queue.
7. CI fails on any fuzzy entry in a language marked reviewed, and on any untranslated story-critical
   line.

## What it costs (measured usage; all through subscriptions)

| Run | Codex session | Input tokens | Output tokens |
|---|---|---|---|
| Pipeline trial: 36 translations and 36 back-translations | `01a143d1-a4b4-7a23-be45-2e550a2fc217` | 35,443 (13,184 cached) | 2,479 |
| Prototype: 102 back-translations | `01a143f0-8b81-7703-972f-13e21953fd61` | 37,015 (13,184 cached) | 3,007 |
| Prototype: 2 shortened buttons | `01a14409-6eb1-7db2-8ef1-f6f3714d953b` | 33,912 (13,184 cached) | 55 |
| Design step: 34 Russian back-translations | `01a14426-2248-7773-8edf-2c4cb6fa3ef8` | 33,534 (13,056 cached) | 1,346 |

Every session is archived. No API key was set and no paid service was used. The Claude translations
were made in the steps' own Claude Code sessions.

## Credits and sources

**Tools:**
- Claude (Claude Code, Anthropic) translated, wrote the tools and wrote these notes.
- Codex (codex-cli 0.162.1, OpenAI, ChatGPT subscription) back-translated.
- Apple's Translation framework (macOS 27.0.1) was probed query-only, with no prompt and no download
  (`pipeline/probe/apple_translate_probe.swift`).
- GNU gettext 1.0 (`msgfmt`, `msgmerge`) and fontTools 4.60.1.
- Godot 4.7.2.

**The chrF metric:** M. Popović, "chrF: character n-gram F-score for automatic MT evaluation", WMT 2015.

**Pages fetched on October 16, 2026:**
- Godot 4.7 docs:
  - https://docs.godotengine.org/en/4.7/tutorials/i18n/localization_using_gettext.html
  - https://docs.godotengine.org/en/4.7/tutorials/i18n/internationalizing_games.html
  - https://docs.godotengine.org/en/4.7/tutorials/i18n/pseudolocalization.html
- Weblate hosting: https://weblate.org/en/hosting/
- Crowdin for open source: https://crowdin.com/product/for-open-source
- ML Kit translation: https://developers.google.com/ml-kit/language/translation
- MADLAD-400: https://huggingface.co/google/madlad400-3b-mt
- Valve's AI disclosure rules, VGC, January 17, 2026:
  https://www.videogameschronicle.com/news/valve-has-significantly-rewritten-steams-rules-for-how-developers-much-disclose-ai-use

**Found through search:**
- NLLB's licence: https://github.com/facebookresearch/fairseq/blob/nllb/README.md
- Edge's Translator API: https://blogs.windows.com/msedgedev/2026/06/02/expanding-on-device-ai-in-microsoft-edge-new-models-and-apis-for-the-web/

**Netflix Timed Text Style Guides** (speeds and line lengths), fetched October 16, 2026 by the
research-godot step: Simplified Chinese, Japanese, Korean, English (USA), and Castilian and
Latin-American Spanish, at partnerhelp.netflixstudios.com.

**ConPaws** (read only): `apps/native/src/locales/*.test.ts`, `src/lib/i18n.ts`, and commits 3147f3d,
380d18f and 2f0a152.
