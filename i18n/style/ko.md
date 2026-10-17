# 한국어: style guide

File `ko.po`, glossary key `ko`. Read [the shared guide](README.md) first.

## Address and register

- WOLF speaks plain informal speech (**반말**) to the engineer, matching his Japanese plain form (D11
  default; no source on peers was checked).
- UI and hints: the short forms Korean games use (계속하기, 설정).

## The engineer

- Never 그 or 그녀 for the engineer: use the name or drop the pronoun.
- No gendered person or kinship words (여자, 언니, 오빠, 형).

## WOLF

He is a person, not an object (never 그것). Plain informal speech, calm and dry.

## Names

- Stored per language (D9): 로완, 알렉스, 모건 (samples in `../glossary.json`).
- Particles change with the name's last sound: 로완 and 모건 end in a consonant (은, 이, 을), 알렉스 in a
  vowel (는, 가, 를). Rephrase so no particle follows the name slot, or the game stores the particle class
  with each name (`ko_particles` in the glossary).

## Quotes and punctuation

Quotes “…” or 「…」 as Korean UI usually writes them; pick one and keep it.

## Open questions

- WOLF's speech level (반말) and how he names the Director (소장 follows Japanese 所長) are D11
  proposals.
- **SERVICE JUNCTION**: a reviewer's word.
