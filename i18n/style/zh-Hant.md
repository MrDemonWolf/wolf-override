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
- **PR L12:** `zh_Hant.po` was made from `zh_Hans.po` with OpenCC 1.4.2 (`s2twp`: Traditional
  characters with Taiwan phrases), then checked line by line. Each change the check made is noted on its
  line ("Taiwan usage after the OpenCC conversion"). The changes, for a reviewer to confirm: mirror 鏡像
  (not 映象), port 連接埠, access 存取 (訪問 reads as interview), timestamp 時間戳記, screen 螢幕, drive
  磁碟, context 脈絡, handle 把手 and controller 控制器 (手柄 means both), full screen 全螢幕, FPS 上限,
  touch 觸控, mobile 行動裝置, research 研究, script 腳本, reference documentation 參考文件, session 工作階段,
  binding 按鍵設定, tap 輕觸, the key names 選單鍵, 說明鍵, 數字鍵盤, 反斜線, 斜線 and 空白鍵, local
  configuration 本機設定, anti-aliasing 反鋸齒, the GENERAL tab 一般, disclosure 聲明, build 建置, drag 拖曳,
  scroll 捲動, surge 突波, gauge 壓力表 (錶 is a watch), a breaker trips 跳脫, current 目前, change 變更,
  via 透過 and there 那裡. The conversion also wrote 復制 for 複製 once.
- Quotes are 「…」; the browser is 瀏覽器 here, since 瀏 is in the Big5 set.
