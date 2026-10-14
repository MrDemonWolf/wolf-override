# Wording drafts for Nathanial: where WOLF waits in the Service Junction (P0-4)

> **Status: decided by Nathanial on 2026-10-14** (a clickable choice after reading this file): **Draft A, "holds back"**, the recommended option. It is applied on top of the wording he approved on 2026-10-13 (two-box lines, the SENTRY recap topic; see [drafts-2026-10-13.md](drafts-2026-10-13.md)), changing only the words that placed WOLF "at the rubble". The decision is also recorded in `docs/decisions.md`, "WOLF's junction wording and the safe point (October 14, 2026)", and each changed line has its new text, date and source in `docs/research-2026-10/approved/` (old text kept under `history`). The text below the line is the draft as he read it; its "Line now" column shows the wording before the October 13 restructure.

**The four strings as applied (2026-10-14), each box at most 2 rows of 42 characters with a 12-character name**

| Constant (`apps/game/scripts/main.gd`) | Before | After |
|---|---|---|
| `RUBBLE_LINE` (first box; `RUBBLE_WAKE_LINE` "Past the doorway, something whirs awake." is unchanged) | The door goes. WOLF heads for the rubble / to wait for %s's call. | The door goes. WOLF falls back / to wait for %s's call. |
| `ALONE_LINES[0]` (`ALONE_LINES[1]` "WOLF: The tank takes a moment to fall." is unchanged) | WOLF: I'll hold at the rubble. / It crosses the mark on every pass. | WOLF: I'll hold back. / It crosses the mark on every pass. |
| `BROKE_OFF_RUBBLE_LINE` | WOLF: I'm out. I'll hold at the rubble. | WOLF: I'm out. I'll hold back. |
| `RECAP_LANE_ALONE` (end card row) | SENTRY  WOLF held at the rubble while {name} timed the drop. | SENTRY  WOLF held back while {name} timed the drop. |

No other story, narration or WOLF line changes. The engineer's lines that name the rubble as the sentry's boundary ("get back over the rubble") and the death card "The sentry caught %s short of the rubble." stay.

**"Open. I'm with you." and "We made it." are settled by the safe-point decision of 2026-10-14**, not by a wording change: when WOLF says "We made it." he comes to the doorway, standing in the open doorway near the engineer, fully visible, clear of the door frame, the machines and the engineer, and facing them; and the safe-point room's camera-side wall is shown as a clean architectural cutaway (as in This War of Mine and Fallout Shelter). No line changes. Both are built by a separate corridor door-end job with a redrawn door end; until that lands WOLF still waits on the relay's left there.

WOLF//OVERRIDE, its story and its characters are by **Nathanial Henniges**. These drafts were written for him by AI agents (Claude Code by Anthropic) on 2026-10-13 against the branch `codex/p0-wolf-space` (on `main` at `cec75f6`), from the branch's headless `wolf_space_test` measurements and still images rendered with `tools/render/render.sh`; the four strings were applied on 2026-10-14 on top of `main` at `0c5d1ae`.

---

# Drafts for Nathanial: P0-4 (Keep WOLF out of machines)

Nothing here has shipped. The branch `codex/p0-wolf-space` changes no story, narration or WOLF line.

## Why these drafts

To keep WOLF out of the valve and the blown door frame, his spot during the lane moved. He now waits on the floor between the junction breaker and the valve, about 230 px short of the rubble line. That is the only clear floor on the near side of the rubble that fits his body. Four lines still say he is "at the rubble". A player who reads them closely will see him standing by the valve. Please pick a wording, or keep the current lines. The plan's Q-list may already cover this; if not, it needs a new question.

| Where | Line now (unchanged in the build) | Draft A (short) | Draft B (names the valve) |
|---|---|---|---|
| The door blows (`RUBBLE_LINE`) | The door goes. WOLF heads for the rubble to wait for %s's call. In the lane beyond, something whirs awake. | The door goes. WOLF falls back to wait for %s's call. In the lane beyond, something whirs awake. | The door goes. WOLF waits by the valve for %s's call. In the lane beyond, something whirs awake. |
| Answer 2, "Stay back, I'll time it." | WOLF: I'll hold at the rubble. It crosses the floor mark on every pass; the tank takes a moment to fall. | WOLF: I'll hold back. It crosses the floor mark on every pass; the tank takes a moment to fall. | WOLF: I'll hold back by the valve. It crosses the floor mark on every pass; the tank takes a moment to fall. |
| A missed drop while he is still short of the sentry (`BROKE_OFF_RUBBLE_LINE`) | WOLF: I'm out. I'll hold at the rubble. | WOLF: I'm out. I'll hold back. | WOLF: I'm out. I'll hold back by the valve. |
| End card recap (`RECAP_LANE_ALONE`) | LANE  WOLF held at the rubble while {name} timed the drop. | LANE  WOLF held back while {name} timed the drop. | LANE  WOLF held back by the valve while {name} timed the drop. |

Draft A says what he does (holds back) without naming a place. Draft B names the place the player sees. My recommendation is Draft A: it stays true if the junction's blast door or the room is rebuilt, and that work is already under way.

## Gate on the merge (from the verifier)

The verifier asks that this branch merges only once you pick a wording above, or tell us to ship the mismatch for now. The clash is clearest right after the blast. Most players back away just past the valve, as FUSE LIT tells them. While they stand there, WOLF waits by the entrance, because his spot by the valve is where they stand. Meanwhile the box says "WOLF heads for the rubble to wait for %s's call." The fix round turns him to face the engineer and the rubble while he waits there, so he no longer looks as if he is leaving. The words still do not match. Draft A's "WOLF falls back to wait for %s's call" fits both moments: by the entrance, then by the valve.

## A line to look at, not drafted

Once the corridor's door is open, WOLF now waits on the relay's left, facing the engineer, while they walk on to the safe point. There is no floor for him between the MANUAL BYPASS, the doorway and the safe point. So when the bypass route's "WOLF: Open. I'm with you." and the safe point's "We made it." lines show, he is standing about 320 px back. I read "I'm with you" as loyalty, not position, so I have not drafted a change. Tell us if it reads wrong when you play it.

## Not drafted

- The engineer's lines that say "get back over the rubble" are about the sentry's lane boundary and stay true.
- Debug labels ("hold: at the rubble") are not player-facing.
