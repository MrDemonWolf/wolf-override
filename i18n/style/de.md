# Deutsch: style guide

File `de.po`, glossary key `de`. Read [the shared guide](README.md) first.

## Address and register

- **du** between characters and in hints, never Sie.
- Buttons and objectives in the infinitive (FORTSETZEN, BEENDEN).
- German runs long: prefer the shorter word (the prototype's SETTINGS became OPTIONEN, not
  EINSTELLUNGEN, to fit).

## The engineer

German predicative adjectives do not agree, but nouns and pronouns show gender. So:
- No Ingenieur/Ingenieurin or Techniker/Technikerin, and no noun in -erin for the engineer. Name the
  field: the name card reads WARTUNGSTECHNIK.
- Use the name or "du" instead of er or sie.
- Watch nominalised adjectives with an article ("die Neue", "der Verletzte"); the checker does not see
  them.
- "Sie" can mean she, they or formal you; avoid it about the engineer altogether.

## WOLF

WOLF is **er**, which fits der Wolf. He says du. Dry, short sentences; no exclamation marks.

## Names

As written. Possessives with "von %s", never "%ss" (the name may end in a sound that needs an
apostrophe).

## Quotes and punctuation

Quotes „…“.

## Open questions

- **HOLD E:**: the word order "HALTEN E:" is forced by the key token until the hint bar uses placeholders
  (localization PR L7b).
- **SERVICE JUNCTION**: the trial's VERSORGUNGSKNOTEN reads back as "supply node"; a reviewer's word.
- **breaker**: "Schutzschalter" is proposed rather than "Sicherung", which is a fuse.
- **SAFE POINT**: SPEICHERPUNKT (save point), the plate's and the hints' word. PR L10's
  SICHERUNGSPUNKT was cut on its left by the door pillar beside the plate.
- **PR L10's choices (proposals for a reviewer):** SERVICE JUNCTION is VERSORGUNGSKNOTEN; the seal (OPEN
  THE SEAL) is *die Schleuse*; the relief vent is *der Druckablass*, so it is never confused with the
  valve (*das Ventil*); THE DEN is DER WOLFSBAU, since DER BAU read back as "the build". The sentry is
  *der Wächter*, so German calls it *er*, as the noun's grammar needs.
- **PR L10's story words (proposals for a reviewer):** the timestamp is *Zeitstempel*, WOLF's readout
  *Anzeige*, the program logs *Protokolle*, WOLF breaking off *ich breche ab*, and the manual-port answer
  button MANUELLEN PORT NUTZEN, the words WOLF's touch line quotes. Wherever *er* or *sein* could read as
  WOLF, the line names *der Wächter*.
- **Words cut to fit (PR L10)**: MRDEMONWOLF, INC. PRESENTS is VON MRDEMONWOLF, INC. (PRÄSENTIERT ran
  18 px over), BACK TO TITLE is ZUM MENÜ, USE on the touch button is NUTZEN (BENUTZEN widened it),
  TEXT SIZE is TEXT, BREAKER USED is SCHUTZSCHALTER AUS, VALVE USED is VENTIL LEER and EXIT READY is
  AUSGANG FREI (the longer plates ran into their neighbours), and the controller column abbreviates
  *li.* and *re.* Each cut is noted on its line in `de.po`.
