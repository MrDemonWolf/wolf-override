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
- A station plate is quoted in «» in its own nominative form: "к пульту «РЕЛЕ…»".

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
- **PR L11's choices (proposals for a reviewer):** the breaker is РУБИЛЬНИК (the glossary's proposal),
  LOCKDOWN ИЗОЛЯЦИЯ, CONTAINMENT ЗОНА СОДЕРЖАНИЯ, TANK RELEASE ОТЦЕПКА БАКА and SERVICE JUNCTION
  СЕРВИСНЫЙ УЗЕЛ. Maintenance, a place, is ТЕХЗОНА; the name card's job is ТЕХОБСЛУЖИВАНИЕ (the field, not
  the person). The seal is *шлюз*, the relief vent *сбросной клапан* and the valve *вентиль*, the mirror
  *зеркало*, the purge *зачистка*, THE DEN ЛОГОВО, WOLF breaking off *Я отхожу* (not the card-game *Я пас*). A plate named in a hint is
  quoted in the nominative: *пульт «ОТЦЕПКА БАКА»*.
- **Latin letters kept:** names, tools, web addresses, FPS, MSAA, V-SYNC and the key labels printed on
  Russian keyboards (Esc, Tab, Enter) stay as written; they are in the glossary's `keep` list.
- **The seven recap and narration lines** keep their meaning without a past tense: the end card tells
  the run in the present (*{name} говорит WOLF о риске*), and the knockdown cards put the name after a
  dash or a colon (*а %s — прямо на решётке*, *Страж заметил: %s*). No English line had to change.
- **Words cut to fit (PR L11):** MRDEMONWOLF, INC. PRESENTS is ОТ MRDEMONWOLF, INC. (ПРЕДСТАВЛЯЕТ ran
  41 px over), CONTINUE is ДАЛЕЕ on the title and touch buttons, the touch PAUSE is СТОП, USE НАЖАТЬ
  and DROP БРОСИТЬ (ИСПОЛЬЗОВАТЬ, ДЕЙСТВИЕ and СБРОСИТЬ widened the 155 px button), the title's credit
  line says *разработка с ИИ*, BACK TO TITLE is В МЕНЮ, TEXT SIZE ТЕКСТ, the controller column says
  *Крест Л/П*, BREAKER USED is РУБИЛЬНИК ИСП. and VALVE USED ВЕНТИЛЬ ИСП. (the longer plates ran into
  their neighbours; ВЫКЛ. would read as switched off, ПУСТ as empty), and the changelog note drops "source-build". Each cut is noted on its line in
  `ru.po`.
- **WOLF's readout** is *дисплей*: Codex read *показания* back as "testimony".
- **SAFE POINT** is УКРЫТИЕ (shelter), on the plate and in the hints; the glossary checks the stem
  УКРЫТИ, so every case passes. The trial's БЕЗОПАСНАЯ ТОЧКА was cut on its left by the door pillar.
