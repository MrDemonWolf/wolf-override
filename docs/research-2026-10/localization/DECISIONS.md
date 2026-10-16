# Decisions for Nathanial

These are the questions only Nathanial can answer. Each has a recommended default, so the build can
start the day he agrees. If he answers only "go with the defaults", every one below is taken as written.
Nothing in the game or its English changes until he answers.

## On one screen

The PRs (L1 to L13) are the build steps in [PLAN.md](PLAN.md). **The three marked first** are needed
before the work that can start now.

| | Question | Default | Needed before |
|---|---|---|---|
| **D1, first** | Which languages? | The 10 in LANGUAGES.md, as 12 files; Polish over Italian | L1, the first PR |
| D2 | How do we say the translations are by AI? | A tag in the picker, the credits and the store page until native review | L9, the first language |
| D3 | Translate words painted in the art, and the station name plates? | Painted words stay English; plates are translated | L8 |
| D4 | Translate the credits and the in-game changelog? | Credits' role text yes; changelog stays English | L7c |
| D5 | US or British spelling in the English? | US ("off center", "canceled") | L7a |
| D6 | Translate the website? | Later, after the first reviewed languages | can wait |
| **D7, first** | How much font for Chinese, Japanese and Korean? | Fixed common-character sets, about 9-10 MB with line-breaking data | L4 |
| D8 | Who reviews the translations? | Volunteers on Weblate, a paid proofreader before a paid release | L9 |
| **D9, first** | How do languages with gendered grammar stay neutral about the engineer? | Rephrase, never pick a gender | L5 |
| D10 | Where does the LANGUAGE setting go, and how does the title make room? | A new GENERAL tab; wider title buttons | L6 and L8 |
| D11 | WOLF's voice and key terms in other languages | The proposals in D11 below | L5, and they can change later |

## D1. The language list

**Question.** Ship the 10 in LANGUAGES.md: English (US), Chinese, Russian, Spanish, Portuguese (Brazil),
German, Japanese, French, Korean and Polish?

**Default: yes, as listed, as 12 language files.**
- Spanish is one slot with two files: Latin America (`es`) and Spain (`es_ES`).
- Chinese is one slot with two files: Simplified (`zh_Hans`) and Traditional (`zh_Hant`).
- Together they cover 93.8% of Steam users (mean of 14 months; 94.3% in September 2026).
- The 10 hold his three regions: the US, the EU (de, fr, es-ES, pl) and Mexico (es-419, the code for
  Latin-American Spanish).

**Two sub-questions:**
- **Polish or Italian for slot 10?**
  - The default is Polish: 1.64% of Steam against 0.61%, 2.5-2.8 times Italian in every month.
  - The case for Italian: weaker English (an English-skill score, EF EPI, of 513 against Poland's 600),
    and it ships in more of the 16 similar games we looked at (14 against 9).
  - Whichever is not picked leads Tier 1.
- **Strictly 10 files?** If so, move `zh_Hant` to Tier 1 and keep `es_ES`, because he named the EU.
- **Or the world's 10 most-spoken languages exactly?** If his "top 10" meant that list, the 10 would
  be English, Chinese, Hindi, Spanish, Arabic, French, Bengali, Portuguese, Indonesian and Urdu
  (Ethnologue 2026). That swaps Russian, German, Japanese, Korean and Polish (about 18% of Steam users
  together) for five languages with about 0.14% of Steam between them. It costs two right-to-left
  languages (Arabic, Urdu), three new scripts with new fonts (Devanagari, Bengali, Arabic), and three
  languages Steam's own client does not offer (Hindi, Bengali, Urdu). Costs are in LANGUAGES.md, "What
  the strict world top 10 would cost instead".

**Also known:**
- Mainland China needs a licensed publisher for phones.
- Phone revenue from Russia is near zero, because Google Play billing has been paused there since
  2022.
- Both languages still earn their slot on Steam (LANGUAGES.md, "Risks").

## D2. Disclosing machine translation

**Question.** How openly are the AI translations labelled?

**Default: everywhere, until a native speaker has reviewed the language.**
- **In the picker:** a short tag in the language itself, such as "Deutsch — maschinelle Übersetzung".
  The ten tags are in PIPELINE.md.
- **In the credits:** "machine translation by Claude (Anthropic), cross-checked with Codex (OpenAI)",
  followed by "reviewed by <names>" or "not yet reviewed".
- **In the language files themselves** (their headers and line comments).
- **On the Steam page:** "machine-translated, community review in progress", and a disclosure in
  Steam's Content Survey.
  - Valve's January 2026 rules ask for disclosure of AI that generates game content. They do not name
    translation, so disclosing is the safe reading.
  - No App Store rule was checked.

The tag comes off a language once its story lines carry reviewer stamps.

## D3. Words in the art, and the station plates

**Painted text.** Three phrases are painted into `corridor-seal-atlas.png`: DOOR 4B-07, SECTOR 4B and
RESTRICTED AREA.

**Default: leave them in English** as in-world signage on the base:
- two of them are identifiers;
- the third is a standard sign;
- re-typesetting the atlas per language would add 10 art variants.

The door tools typeset all three in Roboto, so they can be redone later if he wants.

**Station plates** (BREAKER, SAFE POINT, TANK RELEASE and the other 27) are live labels, not art.
**Default: translate them.**
- The hints name them ("Head right to the breaker."), and a hint should use the same word as the
  plate.
- AGENT.md asks for stations a player can recognise.
- Russian and Polish quote a plate in its own nominative form (PIPELINE.md).
- The plate-layout PR (L8) checks that neighbouring plates don't touch. With every text made 30% longer
  as a test (pseudolocalization), the junction's OVERLOAD BREAKER and RELIEF VENT plates already do.

If he prefers English signage for the plates too, every hint keeps the English plate name in quotes.

## D4. The credits and the changelog

**The credits.** The credits screen holds 214 words. **Default: translate the headings and role text;
never names, studio names or titles of works.**

**The in-game changelog.** 13,502 words, 83% of all the game's words, and it changes almost daily.
**Default: keep it in English**, with:
- a translated heading;
- one translated line saying it is in English;
- the link to the online changelog.

Translating it would multiply each language's word count about 6 times, and every update would need a
new translation pass.

## D5. US or British English in the source

The player text is mostly US spelling. The exceptions:
- in the game: "off centre" (`TANK_HIT_OFF_CENTRE_LINE`, approved wording) and "Rebind cancelled.";
- in the changelog: centre, centred, neighbouring, colour, grey and licence.

**Default: normalise player-facing text to US spelling** in the first wiring PR:
- "off center";
- "Rebind canceled.";
- the six changelog words.

There is no separate en-GB file. Steam has one English, and Godot maps `en_GB` to `en`. "Off centre"
is approved wording, so it changes only with his explicit yes. This research changed no English line.

## D6. Localising the website later

The site (`apps/docs`) has 22 pages and about 37,700 words: more than twice the whole game's text.
**Default: not now.**
- Start after the game's first reviewed languages.
- Begin with the landing page, "Get the game" and the controls guide, in es and de.
- Fumadocs, the site's docs framework, documents multi-language support
  (https://fumadocs.dev/docs/internationalization, read October 16, 2026). Whether it works with the
  site's static GitHub Pages export is not checked yet.
- The site stays Tailwind-styled, as now.

## D7. The font budget for Chinese, Japanese and Korean (CJK)

**Default: fixed common-character subsets** of Noto Sans SC, TC, JP and KR (SIL OFL 1.1), about 1 MB each
and 4-5 MB for all four. That figure is an estimate built from these numbers:

| Font | Size | Measured or estimate |
|---|---|---|
| JP: kana + JIS level 1 (Japan's common-kanji set) | 878,736 B | measured |
| SC: GB2312 level 1 (China's common-character set) | about 1.38 MB | measured on an Apple font, so an estimate for Noto |
| TC, KR | | not measured |

- **The other choice** is to subset each font to the characters the game uses: 139 KB for the
  prototype's Japanese. Every English change then needs a new subset and a glyph-test pass.
- **Either way,** each font goes on only while its language is on. Chained always, it grows every
  Latin line by about 19% (measured).

**What the whole download grows by.** The fonts are not the only cost. As soon as any Chinese,
Japanese or Korean file is registered, the export also adds Godot's line-breaking data,
`icudt_godot.dat`, 4,797,472 B (measured, DESIGN.md "Line breaking"). So:

| | Size |
|---|---|
| Today's exported `.pck` | 24.96 MB (lighter-game plan, section 4) |
| The lighter-game plan's goal before its new character sheets | about 22-23 MB (its estimate) |
| Four fixed CJK subsets | about 4-5 MB (estimate) |
| Line-breaking data | 4.8 MB (measured) |
| **The 10 languages add** | **about 9-10 MB (estimate)**, or about 5-6 MB with per-game subsets instead of fixed ones |

That is three to five times what the lighter plan's size work saves (2-3 MB). The line-breaking data is needed for
any CJK language, so the real choice is between fixed subsets (no re-subsetting when the English
changes) and per-game subsets (about 4 MB smaller, a new subset with every English change). The
default stays fixed subsets; Nathanial may prefer the smaller download.

**Settled: the subsets keep the Noto names.** The only Reserved Font Name is "Source": Google Fonts'
licence files for Noto Sans JP, SC, TC and KR all read "Copyright 2014-2021 Adobe
(http://www.adobe.com/), with Reserved Font Name 'Source'" (fetched October 16, 2026), and the font's
own name table records no reserved name (measured). Each bundled licence file starts with that
copyright line, which the OFL asks to travel with every copy.

## D8. Native-speaker review

**Default:**
- **Community review first,** on Weblate's free Libre plan for public projects. It reads and writes the
  PO files in Git.
- **One paid native proofreader per language** reads the story lines (about 1,460 English words, plus
  the knockdown and end cards) before any paid release. Rates were not researched.
- **Every language ships labelled** (D2) until its story lines are stamped.
- **Review order:**
  - Russian and Polish first for the gender rules;
  - then es, de and ja, which the pipeline trial covered;
  - then the rest.

**Note:** Crowdin's free plan excludes projects with commercial products, so a paid Steam release
would rule it out.

## D9. Pronouns, gender and names where a language can't stay neutral

The engineer is they/them. English can stay neutral; Russian and Polish past tenses, and Romance-language
adjectives and job nouns, cannot (PIPELINE.md). **Default: rephrase, never pick a gender.**
- **Russian and Polish:**
  - present tense, noun phrases, impersonal forms or the imperative;
  - the name always in the nominative, the form a name has as the subject, so it never changes its
    ending;
  - informal address (ty, ты).
- **French, Spanish and Portuguese:**
  - adverbial phrases instead of agreeing adjectives;
  - department or field nouns instead of "the engineer";
  - no neopronouns (iel, elle) unless he chooses them.
- **German:** field nouns (WARTUNGSTECHNIK) and the name instead of er or sie.
- **Japanese, Korean and Chinese:** no gendered pronouns for the engineer.
- **If a rewrite cannot keep a line's meaning,** he decides between restructuring the English and
  accepting the rewrite. Seven past-tense recap and narration lines are the likely ones (STRINGS.md).

**Names.** The engineer's three names are a fixed roster (Rowan Vale, Alex Bennett, Morgan Reed, all
provisional). **Default: store each name per language**, with the English name as the key:
- Russian Роуэн, Japanese ローワン, Korean 로완, Chinese 罗温 (samples only);
- each with what the grammar needs: a Korean particle class, and the nominative-only rule for Slavic
  languages.

The hidden name-cycling key (I) works with the stored names.

## D10. Where LANGUAGE lives, and the title layout

**The LANGUAGE row.** The DISPLAY tab has no room for it: "Español (Latinoamérica)" is trimmed. **Default:
a new GENERAL tab** holding LANGUAGE, laid out like the other tabs.

**The title.** The prototype measured overflows in four languages:

| Text | Designed width | Needed |
|---|---|---|
| NEW GAME button | 186 px | es 213 |
| CONTINUE button | 186 px | ru 199 |
| Brand line | 280 px | de 298, ru 321 |
| CONTINUE note | 388 px | es 485, de 510, ja 480, ru 671 |

**Default:**
- widen the title buttons to fit the longest measured word plus padding;
- let the CONTINUE note wrap to two rows;
- fit the Brand line to its width, with smaller type or the logo moved;
- give the touch USE button room for a longer word.

These are visible layout changes to the title, so they get stills and a played check.

## D11. Voice and glossary choices

**Defaults, all changeable:**

| Choice | Default |
|---|---|
| WOLF's Japanese first person | 俺, used sparingly, in plain form with no keigo (the style packet) |
| How WOLF refers to the Director in Japanese | 所長 for now; Codex read it as "head of the facility". Is "Director" a title or a name? |
| WOLF's Korean speech level | plain informal speech (반말), matching his Japanese plain form. No source was checked for peers. |
| breaker | not "interruptor" (es) or "автомат" (ru, which also means an assault rifle). Native reviewers pick from "disyuntor" or "breaker" (es) and "рубильник" (ru, the sample). |
| LOCKDOWN | not es BLOQUEO ("blockage"); for example "CIERRE DE EMERGENCIA" |
| TANK RELEASE | not ru «СБРОС БАКА» ("tank reset"); a reviewer's word |
| SERVICE JUNCTION | a reviewer's word in de and ru |

These are proposals for reviewers. Every final word is his.
