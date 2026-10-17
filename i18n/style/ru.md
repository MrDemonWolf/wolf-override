# Русский: style guide

File `ru.po`, glossary key `ru`. Read [the shared guide](README.md) first. **With Polish, the hardest
language for the engineer's gender; native review checks it first.**

## Address and register

- **ты** between characters and in hints.
- Buttons and objectives in the infinitive (ПРОДОЛЖИТЬ, ВЫЙТИ).

## The engineer

Russian past-tense verbs, short adjectives and participles show gender (сделал/сделала,
уверен/уверена, ранен/ранена), and so do full adjectives next to the name (усталая). So, about the
engineer:
- **No past tense.** Use the present tense, a noun phrase, an impersonal construction ("сорвало клапан")
  or the imperative. The prototype's knockdown card shows the way: "Сорвало предохранительный клапан, а
  %s — прямо на решётке."
- No "сам/сама", no short adjective or participle, no job noun with a feminine suffix (инженерка,
  техничка).
- WOLF's own past ("Я отказался") is fine: it is about him.

## WOLF

WOLF is **он**, with masculine past tense in -л. He is never declined: "с WOLF", "о WOLF".

## Names

- The name stays in the nominative: make it the subject, or put it after a dash or a colon ("Страж
  заметил: %s на открытом месте"). Never "под %s" or "у %s"; the checker fails a letter glued to the name.
- Stored per language (D9): Роуэн, Алекс, Морган (samples in `../glossary.json`).
- A station plate is quoted in «» in its own nominative form: "к пульту «СБРОС…»".

## Quotes and punctuation

- Quotes «…».
- The key token stays a Latin "E:", never a Cyrillic "Е:".
- Never leave a one-letter word (а, в, и, к, о, с, у, я) at the end of a row: bind it to the next word
  with a no-break space (U+00A0).

## Open questions

- **breaker**: not "автомат", the everyday word, because it also means an assault rifle on a military
  base. The trial's "рубильник" reads back as "knife switch"; a reviewer picks (D11).
- **TANK RELEASE**: not «СБРОС БАКА», which reads back as "tank reset" (сброс means both drop and reset).
  ОТЦЕПКА БАКА and СПУСК БАКА are proposals.
- **LOCKDOWN**: БЛОКИРОВКА reads back as "lockout"; a reviewer's word.
- **SERVICE JUNCTION**: СЕРВИСНЫЙ УЗЕЛ reads back as "service node"; a reviewer's word.
- The seven past-tense recap and narration lines, as for Polish.
