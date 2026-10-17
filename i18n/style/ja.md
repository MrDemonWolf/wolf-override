# 日本語: style guide

File `ja.po`, glossary key `ja`. Read [the shared guide](README.md) first.

## Address and register

- Plain form (だ/る) for WOLF and in narration; no keigo between the engineer and WOLF.
- UI and hints: short and plain. Avoid second-person pronouns (あなた, 君); leave the subject out.
- Buttons: the usual short UI words (つづける, 設定).

## The engineer

Japanese has little grammatical gender, but words for people and speech style can carry it:
- Never 彼 or 彼女 for the engineer: use the name or drop the pronoun.
- No gendered person words or honorifics (女の子, 少年, くん, ちゃん).
- Speech style counts too: if the engineer speaks, no 僕, あたし or sentence-final わ.

## WOLF

- Never それ or あれ for WOLF: he is a person, not an object.
- His first person is **俺**, used sparingly, in plain form with no keigo (D11 default).
- He refers to the Director as **所長** for now (D11): whether "Director" is a title or a name is still
  open.

## Names

Stored per language (D9): ローワン, アレックス, モーガン (samples in `../glossary.json`).

## Quotes and punctuation

- Quotes 「…」.
- Keep 。 and 、 in the game's boxes (subtitle guides drop them; the game does not).
- Reading speed is slower than English (4 characters a second in Netflix's subtitle guide); keep lines
  short.

## Open questions

- **the Director**: 所長 reads back as "head of the facility". Title or name is Nathanial's call.
- **SERVICE JUNCTION**: a reviewer's word.
