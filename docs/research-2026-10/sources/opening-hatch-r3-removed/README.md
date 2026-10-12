# Opening maintenance hatch (round 3), pulled 2026-10-11

Private, git-ignored archive. Nothing here ships.

## What this is

The maintenance crawl hatch that logic round 3 (branch `codex/logic-round-3`, commits fa28229 and
e0933fd/64a67e9) put low on the containment wall behind WOLF's cage in the opening: on the
Director's lockdown order its lamp turned green and its leaf slid up, and WOLF backed away, turned
and slipped into the duct before it shut.

- `art-source/opening-hatch-closed.png`, `art-source/opening-hatch-open.png`: the two full-size
  originals, byte for byte as the tool wrote them, C2PA content credentials (caBX chunk) intact.
  Made with the Codex built-in image generation tool (edit/reference mode), Codex session
  01a12cf0-6478-7731-aa2a-ce12cb405970 (archived afterwards). SHA-256 00ae3ff4591e389d... (closed)
  and 323750bb50512fbe... (open). Prompts, the per-attempt log and review images stay in the
  session scratchpad art notes (r3-art/raw/log.md).
- `game-layers/opening-hatch-{frame,leaf,duct}.png`: the three aligned 640x387 layers the game
  used, cut from the originals by `prepare_opening_hatch.py` (kept here, reproduces them byte for
  byte from `art-source/`).
- `opening_hatch.gd`: the node that drew and animated the three layers.
- `manifest-entries.json`: the five asset-register entries as they stood (source, rights status,
  modifications), so they can be restored as written.

Rights status: provisional AI-generated prop, never reviewed or approved by Nathanial Henniges.

## Why it was pulled

Nathanial, 2026-10-11: "Welllm the cage for the wolf should been the same 100% the same before".
The hatch sat on the wall behind the cage, so its navy panel showed through the cage bars where
main (76d3a50) shows the back wall. Round 3c removed it and restored main's opening exactly
(WOLF walks off to the left on the approved line "WOLF turns from the Director and heads for
maintenance.").

## When it comes back

With the shutter doors (their own PR), at a spot that does not change the cage: not behind it.
Recheck the cage pixel-for-pixel against main's opening when it returns.
