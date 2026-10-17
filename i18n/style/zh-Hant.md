# 繁體中文: style guide

File `zh_Hant.po`, glossary key `zh-Hant`. Made by converting the Simplified file and then reviewing it
for Taiwan and Hong Kong usage, not by translating again. Read [the shared guide](README.md) and
[the Simplified guide](zh-Hans.md) first: their rules hold here unless this page says otherwise.

## Address and register

As the Simplified file: 你, short UI words (繼續, 設定).

## The engineer

As the Simplified file: never 他 or 她 for the engineer; no 小姐, 女士 or 先生.

## WOLF

WOLF is **他**, never 它.

## Names

羅溫, 亞歷克斯, 摩根 (samples in `../glossary.json`).

## Quotes and punctuation

- Quotes 「…」.
- Keep 。 and ， in the game's boxes.

## Open questions

- Conversion is not enough where Taiwan uses other words (for example 設定 for 设置, 程式 for 程序); a
  reviewer lists them.
- **Sibling rule:** both Chinese files must translate the same lines and neither may leave one fuzzy;
  the checker fails the pair otherwise, because Godot would show the other file's characters.
