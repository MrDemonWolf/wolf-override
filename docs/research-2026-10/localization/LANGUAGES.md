# Languages: the recommended list

October 16, 2026. A recommendation for Nathanial's approval. Nothing in the game changes until he
approves it ([DECISIONS.md](DECISIONS.md), D1).

**What he asked:**
- October 15: "support multi langs on our game. Let's do of course USA and EU and Mexican, maybe a
  few."
- October 16: "support the top 10" (relayed to this job by the main Claude Code session; his exact words
  are in that session, not in this repository).

**The answer in one line:** 10 languages, shipped as 12 language files. Together they cover about
**94% of Steam users** (the mean of 14 survey months is 93.8%; September 2026 alone is 94.3%). All three
of his regions are inside the 10.

Every share below comes from our own parse of the Steam Hardware & Software Survey
(`markets/data/steam-table.txt`, made by `markets/tools/steamlang.py` from the pages listed in
`markets/data/steam-captures.txt`). It is the mean of all 14 survey months, August 2025 to September
2026, with the September 2026 value in brackets. Every other number
names its source in [Sources](#sources). Estimates are marked as estimates.

## The 10

| Language | Shown in the game as | Why | Share of Steam users |
|---|---|---|---|
| English (US) | English | The game's own language; #1 on Steam | 36.5% |
| Chinese (Simplified and Traditional) | 简体中文, 繁體中文 | #2 on Steam; #2 in the world | 26.7% + 1.3% |
| Russian | Русский | #3 on Steam | 9.3% |
| Spanish (Latin America and Spain) | Español (Latinoamérica), Español (España) | Mexico and the EU, as he asked | 0.7% + 4.3% |
| Portuguese (Brazil) | Português (Brasil) | Brazil, a big phone market | 3.9% |
| German | Deutsch | Germany is the #5 phone game market | 2.8% |
| Japanese | 日本語 | The #3 phone game market; weak English | 2.5% |
| French | Français | The EU, and Quebec | 2.3% |
| Korean | 한국어 | The #4 phone game market | 1.8% |
| Polish | Polski | The EU; slot 10 against Italian is his call | 1.6% |

Shares are the mean of 14 survey months; the codes, the September 2026 values and the speaker counts
are in "Codes and numbers, for the build" below.

## Nathanial's three regions

| Region | Inside the 10 | Notes |
|---|---|---|
| **USA** | English, US spelling | The source text is mostly US spelling with a few British forms (STRINGS.md). Normalising it is decision D5. Steam has one "English"; Godot maps `en_GB` to `en` (measured), so no separate British file. |
| **EU** | German, French, Spanish (Spain), Polish | Italian is first in Tier 1. Dutch and the Nordic languages wait in Tier 3: their players have the EU's strongest English (EF 603-624). |
| **Mexico** | Spanish (Latin America), shown as "Español (Latinoamérica)" | Tagged `es-419` (the code for Latin-American Spanish) on Steam and Google Play. Apple has no `es-419`, so the App Store's es-MX listing reuses the Latin-American text. Godot reduces `es_419` to `es`, so the game file is `es` (measured, `godot/evidence/locale.txt`). English skill (EF EPI) in Mexico is 440, very low: Mexico is one of the markets that needs the translation most. |

## Ten slots, twelve files, and the coverage

Two slots carry a second file that is an adaptation, not a second
translation:
- **Spanish.** `es` is the Latin-American base, for Mexico and the rest of Latin America. `es_ES` is
  an adaptation pass for Spain (vosotros forms and vocabulary).
  - Both files are needed because Nathanial named both Mexico and the EU.
  - The two variants are mutually intelligible.
  - Steam's "Spanish - Spain" row (4.3%) is far above "Spanish - Latin America" (0.7%). Steam added
    Latin-American Spanish only in October 2018 (PCGamesInsider), so many Latin-American players
    probably still run the Spain option. That is our inference, not a measurement.
  - Peers: 15 of 16 ship Spain's Spanish and 6 of 16 ship Latin America's.
- **Chinese.** `zh_Hant` is a script conversion of `zh_Hans` plus a Taiwan review.
  - Traditional Chinese alone is 1.3% of Steam, more than Italian.
  - Taiwan is the #6 mobile game revenue market (AppMagic 2025).
  - 11 of 16 peers ship it.

If Nathanial wants strictly 10 files, move `zh_Hant` to Tier 1 and keep `es_ES`, because he named
the EU.

**Coverage, measured.** The 12 Steam language rows these files serve add up to 93.8% (mean of 14 months)
and 94.3% (September 2026). Traditional Chinese adds 1.3 points of that. The second Spanish file changes
which Spanish Spain's players see, not how many players are covered: without it they still get Spanish.

**One survey month is an outlier.** Simplified Chinese read 54.6% in February 2026, against 21.9-31.4%
in every other month. The median over the 14 months is 24.0%. That month pulls every other row down,
but it changes no rank.

### Codes and numbers, for the build

| # | Language | Godot file(s) | Store codes | Steam share, mean [September 2026] | Speakers (world rank) |
|---|---|---|---|---|---|
| 1 | English (US) | `en` | en, en-US | 36.5% [34.2] | 1,493M (#1) |
| 2 | Chinese, Simplified and Traditional | `zh_Hans`, `zh_Hant` | zh-Hans / zh-CN, zh-Hant / zh-TW | 26.7% + 1.3% [31.4 + 1.3] | 1,183M Mandarin (#2) |
| 3 | Russian | `ru` | ru | 9.3% [9.05] | 210M (#11) |
| 4 | Spanish, Latin America and Spain | `es` (Latin America), `es_ES` | es-419 (Apple: es-MX), es-ES | 0.7% + 4.3% [0.75 + 4.08] | 561M (#4) |
| 5 | Portuguese (Brazil) | `pt_BR` | pt-BR | 3.9% [3.70] | 269M (#8) |
| 6 | German | `de` | de, de-DE | 2.8% [2.48] | 133M (#12) |
| 7 | Japanese | `ja` | ja | 2.5% [2.41] | 126M (#13) |
| 8 | French | `fr` | fr, fr-FR (reused for fr-CA listings) | 2.3% [2.08] | 334M (#6) |
| 9 | Korean | `ko` | ko | 1.8% [1.37] | 82M (#28) |
| 10 | Polish | `pl` | pl | 1.6% [1.49] | about 40M (estimate; not in the table) |

## Side by side with the world's top 10

The world's top 10 by total speakers (first and second language), from Ethnologue 2026 as tabled on
Wikipedia (checked again on October 16, 2026):

| World rank | Language | Speakers | In the game's 10? |
|---|---|---|---|
| 1 | English | 1,493M | yes |
| 2 | Mandarin Chinese | 1,183M | yes |
| 3 | Hindi | 611M | **swapped for Russian** |
| 4 | Spanish | 561M | yes |
| 5 | Modern Standard Arabic | 335M (all second-language) | **swapped for German** |
| 6 | French | 334M | yes |
| 7 | Bengali | 274M | **swapped for Japanese** |
| 8 | Portuguese | 269M | yes |
| 9 | Indonesian | 255M | **swapped for Korean** |
| 10 | Urdu | 246M | **swapped for Polish** |

Five languages are in both lists: English, Chinese, Spanish, French and Portuguese.

**Why swap at all?** Speakers are not players who need a translation. Each swap was weighed on five
counts:
- how many players use the language on Steam;
- what its countries spend on mobile games;
- how well its players manage in English (EF EPI 2025);
- how many of 16 peer games ship it;
- what it costs us: script, right-to-left layout and grammar.

| Swap | Out (world rank) | In | The numbers |
|---|---|---|---|
| 1 | Hindi (#3, 611M) | Russian (#11, 210M) | **Hindi:** Steam offers Hindi only as a game language, so there is no client language and no survey row. Under 0.1% of web content (W3Techs). India leads mobile game *downloads* (15.7-18% in monthly Sensor Tower reports) but is not in AppMagic's top 10 by revenue. EF India 484 (low). **Russian:** 9.3% of Steam (#3); 15 of 16 peers. |
| 2 | Arabic (#5, 335M) | German (#12, 133M) | **Arabic:** 0.00% of Steam in every month, because Steam's own client is not translated into Arabic. It is right-to-left, has 6 plural forms and gendered verbs, and our fonts lack its glyphs (measured). 2 of 16 peers. **German:** 2.8% of Steam. Germany is the #5 mobile game revenue market (AppMagic 2025), with about EUR 2.7B of mobile game revenue in 2025 (game e.V.). 16 of 16 peers. |
| 3 | Bengali (#7, 274M) | Japanese (#13, 126M) | **Bengali:** no Steam client language, and not in W3Techs' top 15. **Japanese:** 2.5% of Steam. Japan is the #3 mobile revenue market, with 12.7-13% of world mobile game in-app spending (Sensor Tower, June and December 2025). EF Japan 446 (very low). 15 of 16 peers. |
| 4 | Indonesian (#9, 255M) | Korean (#28, 82M) | **Indonesian:** 0.14% of Steam. Indonesia is a top-4 mobile *download* market (6.4% in June 2025) with low revenue. **Korean:** 1.8% of Steam. Korea is the #4 mobile revenue market (AppMagic 2025); Sensor Tower projected $5.3B of Korean mobile game revenue for 2025 (a forecast, October 2025). 13 of 16 peers. Indonesian leads Tier 2 for the phone release. |
| 5 | Urdu (#10, 246M) | Polish (about 40M, estimate) | **Urdu:** no Steam client language. It is right-to-left, and its Nastaliq script is hard to render. EF Pakistan 493 (low). **Polish:** 1.6% of Steam, 2.5 to 2.8 times Italian's share in every surveyed month. An EU language; 9 of 16 peers. |

**What the strict world top 10 would cost instead.**
- **Indonesian:** cheap. Latin script, which our fonts already cover; one plural form; no grammatical
  gender.
- **Hindi and Bengali:** a new font each plus complex-script shaping. Godot's default text server
  (TextServerAdvanced, ICU and HarfBuzz) can already shape them. Hindi verbs carry gender, so the
  they/them engineer needs its own style rule.
- **Arabic:** right-to-left. Godot 4.7.2 has a right-to-left layout mode (`Control.layout_direction`,
  `scene/gui/control.h`), but every mirrored HUD element needs review. Arabic also has 6 plural forms
  and gendered verbs.
- **Urdu:** everything Arabic needs, plus a Nastaliq font. The most expensive language of all.

Three of these five (Hindi, Bengali, Urdu) have no Steam client language at all.

**Polish or Italian for slot 10: Nathanial's call.**

| | Polish | Italian |
|---|---|---|
| Steam share | 1.64% | 0.61% |
| English proficiency (EF EPI 2025) | 600, very high | 513, moderate |
| Peer games that ship it | 9 of 16 | 14 of 16 |

Polish players are 2.7 times as many (14-month means), but they manage better in English. Whichever is not picked leads
Tier 1.

## The language picker

**Names.** Each language is named in its own language, and those names are never translated
(the prototype does the same: `auto_translate_mode` is off on the list).

**Recommended order (a default, not a measured rule):**
1. English first, as the source.
2. Then the Latin-script names A to Z: Deutsch, Español (España), Español (Latinoamérica), Français,
   Polski, Português (Brasil).
3. Then Русский.
4. Then 日本語, 한국어, 简体中文, 繁體中文.

The exact strings, copied from ConPaws' list where it has the language:

```
English
Deutsch
Español (España)
Español (Latinoamérica)
Français
Polski
Português (Brasil)
Русский
日本語
한국어
简体中文
繁體中文
```

**Flags.** None. ConPaws shows flag emoji next to each name, but the game's fonts have no colour emoji,
and a language is not a country. Names only.

**Machine-translated languages are labelled.** Until a language has had native review, its picker
entry carries a short tag in that same language (PIPELINE.md, "Honest labelling"; decision D2).

**The picker needs more width.** The DISPLAY tab trims "Español (Latinoamérica)" (prototype). Where the
row goes is decision D10.

## How the OS language picks a file (measured in Godot 4.7.2)

Godot scores each loaded translation against the OS locale (`compare_locales`: 10 for an exact match,
5 for the same language, plus or minus 1 for each matching or differing script or country). On a tie,
the translation added last wins. Measured with `markets/tools/locale_probe.gd` and
`godot/probe/probe_runtime.gd`:

| OS locale | Plays in | Why |
|---|---|---|
| es_MX, es_AR, es_US; `es-419` as typed | `es` (Latin America) | `es` scores 5, `es_ES` scores 4; `es_419` standardises to `es` |
| es_ES | `es_ES` | exact, 10 |
| pt_PT | `pt_BR` | the only Portuguese file (4) |
| zh_CN, zh_SG, zh | `zh_Hans` | zh_CN scores 10 against zh_Hans |
| zh_TW, zh_HK | `zh_Hant` | zh_TW scores 10; zh_HK scores 5 |
| fr_CA | `fr` | same language, 5 |
| en_GB | `en` | same language, 5 |
| uk_UA | `en` | **never Russian** until Ukrainian ships (Tier 1); measured in the prototype's resolver test |
| anything else | `en` | the fallback, `internationalization/locale/fallback` |

Not measured, but they follow the same rule and go into the resolver's table: zh_MO to `zh_Hant`,
fr_BE and fr_CH to `fr`, en_AU to `en`. With both Portuguese files loaded, the research-godot step
measured plain `pt` and pt_AO picking `pt_PT` only by tie order. If `pt_PT` ever ships, the table
decides those cases on purpose instead.

The game's resolver (DESIGN.md) writes these mappings out as one explicit table, as ConPaws'
`resolveDeviceLocale` does, rather than trusting tie order.

## Tiers after the 10

Each tier is its own later build. Every language in it goes through the same pipeline and gates.

### Tier 1: the next build after the 10

| Language | Picker name | Code | Steam share | Why | Risk | Cost |
|---|---|---|---|---|---|---|
| Italian | Italiano | `it` | 0.61% [0.56] | Main EU language; 66M speakers; EF 513, the lowest of the big EU markets; 14 of 16 peers | Gender agreement for the engineer; about 3 times the English length on short labels | One translation; fonts fine |
| Turkish | Türkçe | `tr` | 1.22% [1.09] | 94M speakers; EF 488 (low); 7 of 16 peers | Dotted and dotless i break `to_upper()` (the game upper-cases the name and the speaker tag in code); suffixes attach to names | One translation; fonts cover ş, ğ, ı (measured) |
| Ukrainian | Українська | `uk` | 0.69% [0.66] | Steam share above Italian's; players in Ukraine should not have to fall back to Russian | Same Slavic gender, case and plural issues as Russian. The translator must be a native Ukrainian speaker, not someone converting from Russian | One translation; reuses the Slavic style rules; fonts cover і, ї, є, ґ (measured) |

### Tier 2: mainly for the phone release

| Language | Picker name | Code | Steam share | Why | Risk | Cost |
|---|---|---|---|---|---|---|
| Thai | ไทย | `th` | 0.85% [0.82] | Above Ukrainian on Steam; EF 402 (very low) | No Thai glyphs in our fonts (measured); no spaces between words, so line breaking needs ICU's dictionary data | New font, line-break checks, one translation |
| Indonesian | Bahasa Indonesia | `id` | 0.14% | World #9 by speakers; 6.4% of mobile game downloads (Sensor Tower, June 2025) | Low spending per player | The cheapest language there is: Latin script, one plural form, no gender |
| Portuguese (Portugal) | Português (Portugal) | `pt_PT` | 0.35% | EU variant; 5 of 16 peers | Players understand the Brazilian file | Adaptation pass of `pt_BR` |
| Vietnamese | Tiếng Việt | `vi` | 0.21% [0.25], growing (0.20% in August 2025, 0.29% in August 2026) | 97M speakers | Stacked diacritics need line-height checks | Fonts cover it (measured); one translation |

### Tier 3: optional; strong English, small Steam share

Dutch (Nederlands, `nl`, 0.25%, EF 624), Swedish (Svenska, `sv`, 0.26%, EF 609), Danish (Dansk, `da`,
0.22%, EF 611), Norwegian Bokmål (Norsk bokmål, `nb`, 0.12%, EF 613; Godot maps `no` to `nb`, measured),
Finnish (Suomi, `fi`, 0.15%, EF 603), Czech (Čeština, `cs`, 0.54%, EF 582), Hungarian (Magyar, `hu`,
0.37%, EF 590), Romanian (Română, `ro`, 0.12%) and Greek (Ελληνικά, `el`, 0.06%; Montserrat lacks most
Greek, Roboto has it, measured).

### Not now

| Language | Why not now |
|---|---|
| Arabic | 0.00% of Steam; right-to-left; 6 plural forms; new font. The most expensive language after Urdu. |
| Hindi | No Steam client language; new font and shaping; low spending per player. |
| Bengali | No Steam client language; new font and shaping. |
| Urdu | No Steam client language; right-to-left Nastaliq; the most expensive language of all. |
| Separate French (Canada) | Quebec's Charter of the French language, s.52.1, asks for game software to be available in French when a French version exists. Shipping `fr` meets it (Osler's guide; the official legisquebec text returned HTTP 403, so this needs a check against it). Reuse `fr` for the fr-CA store listings. |
| Separate English (UK) | Steam has one English; Godot maps `en_GB` to `en` (measured). |
| Malay | 0.00% of Steam (it first appears in the survey in June 2026). ConPaws ships it; the game does not need it yet. |

## Risks that come with the 10

| Risk | Languages | Details |
|---|---|---|
| CJK (Chinese, Japanese and Korean) font | zh, ja, ko | The game's Roboto and Montserrat have no Han, kana or Hangul glyphs (measured). Each needs a bundled, subset Noto fallback font; budget is decision D7. |
| Gender of the engineer | ru, pl most; then fr, es, pt; de only for nouns | Past-tense verbs, adjectives and job nouns show gender. Style rules in PIPELINE.md; decision D9. |
| Names inflect | ru, pl (and uk, cs later) | The name changes its ending by case. The rule is to keep it in the nominative, the subject form, so its ending never changes (proved in Russian by the prototype). |
| Plurals | ru, pl (3 forms); fr, pt_BR (zero counts as singular); ja, ko, zh (1 form) | Godot's `tr_n` with gettext plural forms; Godot's own rules are in `core/string/locales.h`. |
| Text length | de, ru, pl, fr | Short labels of up to 10 characters can grow to 2-3 times their English length in European languages (W3C, citing IBM's guidelines), and W3C's German example runs 2.8 times. Measured on one line at 18 px Roboto: es 1.68x, de 1.96x, fr 1.59x, ru 2.06x, pt_BR 1.44x of the English width. |
| Distribution | zh (mainland), ru | Mainland iOS and Android need a game licence from China's regulator, the NPPA, through a Chinese publisher (6-12 months), and Google Play is absent there. Google Play billing has been paused in Russia since March 2022. Both languages still earn their slot from Steam. |

## Sources

**Our own measurements:**
- `markets/tools/steamlang.py` → `markets/data/steam-table.txt`: the Steam language shares over 14
  survey months, its `--table` output filed as is, recomputed for the sums above on October 16, 2026.
  `markets/data/steam-captures.txt` lists the page behind each month.
- `markets/tools/steamapps.py` → `markets/data/steam-games.tsv` and `steam-games-count.txt`: the 16 peer
  games' language lists from Steam's public appdetails API, fetched October 16, 2026.
- `markets/tools/locale_probe.gd` and `godot/probe/`: the locale codes and glyph coverage, Godot
  4.7.2.stable.official.ed1daf0bf, run headless.

**Steam:**
- Hardware & Software Survey, Language section:
  https://store.steampowered.com/hwsurvey/Steam-Hardware-Software-Survey-Welcome-to-Steam (September
  2026 live, fetched October 16, 2026). Earlier months come from Wayback Machine captures of the same
  URL: one capture per survey month, all 14 months from August 2025 to September 2026, each listed with
  its timestamp and URL in `markets/data/steam-captures.txt`. An earlier step's table had only 10 of
  them; the four it called "not captured" (September 2025, December 2025, March 2026, May 2026) are in
  the Wayback Machine and parse cleanly.
- Supported languages and API codes: https://partner.steamgames.com/doc/store/localization/languages
  (read October 16, 2026).
- Latin-American Spanish added in October 2018:
  https://www.pcgamesinsider.biz/news/67947/steam-now-officially-supports-vietnamese-and-latin-american-spanish-languages

**Speakers, English proficiency and the web:**
- Ethnologue 2026 as tabled on Wikipedia:
  https://en.wikipedia.org/wiki/List_of_languages_by_total_number_of_speakers (read October 16, 2026;
  ethnologue.com returned HTTP 403).
- EF EPI 2025: https://en.wikipedia.org/wiki/EF_English_Proficiency_Index (read October 16, 2026).
- Internet World Stats (March 31, 2020) and W3Techs (December 3, 2025), both via
  https://en.wikipedia.org/wiki/Languages_used_on_the_Internet. W3Techs' own trend page:
  https://w3techs.com/technologies/history_overview/content_language/ms

**Mobile game markets:**
- Sensor Tower, December 2025:
  https://sensortower.com/blog/top-10-worldwide-mobile-games-by-revenue-and-downloads-in-december-2025
- Sensor Tower, June 2025:
  https://sensortower.com/blog/top10-worldwide-mobile-games-revenue-downloads-june-2025
- Sensor Tower, Japan 2025: https://sensortower.com/blog/state-of-japan-gaming-2025
- Sensor Tower State of Mobile 2026, as summarised (January 30, 2026):
  https://gamedevreports.substack.com/p/sensor-tower-the-state-of-the-mobile
- Sensor Tower, "2025 Korean Game Market Insights" (a $5.3B forecast for Korean mobile game revenue in
  2025), as reported by gamebiz.jp (October 22, 2025): https://gamebiz.jp/news/414654 ; the report page:
  https://sensortower.com/ja/report/state-of-gaming-in-korea-2025-report-japan
- AppMagic, as summarised:
  - 2025 monetisation (December 4, 2025): https://gamedevreports.substack.com/p/appmagic-mobile-games-monetization
  - Mobile Market Landscape 2026 (February 6, 2026): https://gamedevreports.substack.com/p/appmagic-mobile-market-landscape
  - The report's PDF text could not be extracted, so per-country dollar figures for Mexico, Brazil,
    Italy and Poland are a gap.
- game e.V., German mobile market 2025 (July 6, 2026): https://www.game.de/en/mobile-games-germany-2026/
- Newzoo 2025, via wnhub (June 19, 2026): https://wnhub.io/news/analytics/item-51168
- Mexico:
  - https://knowledge.antom.com/mexico-gaming-payment-trends-report-social-connection-and-streaming-power-a-mobile-first-market
  - IMARC: https://www.imarcgroup.com/mexico-mobile-gaming-market (an estimate)

**Store listings:**
- Apple App Store localizations: https://developer.apple.com/help/app-store-connect/reference/app-store-localizations
- Google Play listing languages and free machine translation of listings:
  https://support.google.com/googleplay/android-developer/answer/9844778

**Law and distribution:**
- Quebec: Osler, "French language rules",
  https://www.osler.com/osler/media/Osler/downloads/doing-business-in-canada/Osler-DBIC-French-language-rules.pdf ;
  DLA Piper on Bill 96, https://www.dlapiper.com/insights/publications/2022/05/quebec-passes-amended-bill-96
- China:
  - Google Play in China: https://appinchina.co/blog/google-play-store-in-china-everything-you-need-to-know/
  - The game licence process: https://appinchina.co/how-to-get-a-game-license-in-china/
  - NPPA approvals in 2025, Niko Partners (January 15, 2026): https://substack.nikopartners.com/p/chinas-nppa-approved-1771-video-games
  - Apple's approval-number field: https://developer.apple.com/help/app-store-connect/reference/app-information/
- Russia: https://9to5google.com/2022/03/09/google-play-store-russia-purchases/ ;
  https://www.theregister.com/2022/05/10/google_blocks_paid_apps_from/

**Text length:** W3C, "Text size in translation": https://www.w3.org/International/articles/article-text-size

**Godot 4.7.2 source** (tag 4.7.2-stable, ed1daf0bf):
- `core/string/translation_server.cpp` (`Locale::Locale`, `compare_locales`)
- `core/string/locales.h` (scripts and plural rules)
- `scene/gui/control.h` (`LAYOUT_DIRECTION_RTL`)

**ConPaws** (read only, the commit at HEAD on October 16, 2026):
- `apps/native/src/lib/supported-locales.ts`: its 23 locales
- `apps/native/src/lib/i18n.ts`: the native names
- `apps/native/app/(tabs)/settings/language.tsx`: its flags
