# Español (España): style guide

File `es_ES.po`, glossary key `es-ES`. **An adaptation of the Latin-American file, not a second
translation.** Start from `es.po` and change only what the rules below say; every other line stays word
for word. Read [the shared guide](README.md) and [the Latin-American guide](es-419.md) first: their
rules hold here unless this page says otherwise. The glossary gives Spain no forms of its own yet, so
every term uses the Latin-American form (`inherit` in `../glossary.json`).

## Address and register

- tú, as in the Latin-American file. Where the game speaks to more than one person, use **vosotros**
  forms, not ustedes.
- Buttons in the infinitive, as in the base file.

## The engineer

The same rules as the Latin-American guide: no agreeing adjective or participle about the engineer, and
the department instead of a job noun.

## WOLF

As in the base file: él, tú, calm and dry.

## Names

As written, with "de %s" for possessives.

## Quotes and punctuation

«…», as in the base file.

## Open questions

- Which vocabulary differs for Spain in this game (for example ordenador/computadora, móvil/celular) is
  for a reviewer from Spain to list. Until then the adaptation changes only the vosotros forms.
- **Sibling rule:** both Spanish files must translate the same lines and neither may leave one fuzzy;
  the checker fails the pair otherwise, because Godot would show the other file's text.
