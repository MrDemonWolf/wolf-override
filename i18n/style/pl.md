# Polski: style guide

File `pl.po`, glossary key `pl`. Read [the shared guide](README.md) first. **This is the hardest
language for the engineer's gender; native review checks it first.**

## Address and register

- **ty** between characters and in hints, never Pan/Pani.
- Buttons and objectives in the infinitive (KONTYNUOWAĆ, WYJŚĆ).

## The engineer

Polish past-tense verbs, short adjectives and participles show gender (zrobił/zrobiła,
zmęczony/zmęczona, gotowy/gotowa). So, about the engineer:
- **No past tense.** Use the present tense, a noun phrase, an impersonal form (-no/-to: "zerwano
  zawór") or the imperative, which has no gender.
- No participles in -ona/-ony, -ęta, -yta, -ita, -wana and no "sam/sama".
- The future with "będziesz" + participle is gendered too ("będziesz zmęczona").
- WOLF's own first-person past (-łem) is fine: it is about him.

## WOLF

WOLF is **on**, with masculine past tense. He is never declined: "z WOLF", "o WOLF", never "WOLFem".

## Names

- The name always stays in the nominative, its own form: make it the subject, or put it after a dash or
  a colon. Never where Polish needs a case ending ("z %s", "dla %s"); the checker fails a letter glued
  to the name ("%sa").
- A station plate is quoted in its own nominative form („WYŁĄCZNIK”), so its words never change case.

## Quotes and punctuation

- Quotes „…”.
- Never leave a one-letter word (a, i, o, u, w, z) at the end of a row: bind it to the next word with a
  no-break space (U+00A0).

## Open questions

- **TANK RELEASE**: ZRZUT ZBIORNIKA is a proposal.
- **LOCKDOWN**: BLOKADA is a proposal.
- **SERVICE JUNCTION**: a reviewer's word.
- Seven recap and narration lines tell what the engineer did, in the past. If a rewrite cannot keep
  their meaning, flag them: Nathanial decides whether the English changes (D9).
