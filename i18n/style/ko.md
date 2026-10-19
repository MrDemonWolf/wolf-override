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
- **PR L12's choices (proposals for a reviewer):** SERVICE JUNCTION is 설비 분기점 and the service line
  설비 라인. CONTAINMENT is 격리 구역, maintenance (the place) 정비 구역, records access 기록 접근실 and a
  trace 기록. The seal is 봉인문, the relief vent 압력 배출구, WOLF's readout 판독 화면, the purge 퍼지 (so
  the deletion order stays 삭제 명령), Archive 아카이브, THE DEN 늑대 굴 (보금자리 read back as Home) and
  the slice 체험판. Arm the breaker is 차단기를 올리다.
- **Particles after a slot:** the gate `slot_particles` (`i18n_tool.py`, PR L12) fails any particle glued
  to `%s` or `{name}` that changes with the last sound. The lines use one that never changes (의, 에게),
  end the clause on the name (*정비 포트로 타임스탬프를 복사한 건 {name}.*), or leave a key without 을/를
  (*여기서 다시 %s 누르세요*). The `ko_particles` field in the glossary is not used by the game yet.
- **Register:** status and instruction lines use 합니다/하세요, story narration the plain 한다 style, and
  WOLF and the engineer 반말 to each other. Quotes are “…”.
