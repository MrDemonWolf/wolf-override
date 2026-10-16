# First-time player review, doors r1

I looked at the frames in route order as a player would see them: full 1280x720 frames from `integrate/captures/after-1280/` first, then the `-phone` 2400x1080 frames, then the 3x crops in `shots/crops/`. These are stills only, not play.

**Verdict: fix-needed.** The doors now work: they block the path, they open physically, nothing vanishes, and the ending reads in the right order. But the new walls look pasted in from another game. A first-time player would notice that before anything else.

## Records entry (r01 to r03)

- **fine:** I come in through a plain steel door. It stands open behind me (r01), its closer swings it shut (r02, r03), and the lamp goes amber, then red. It reads as "the door I came through, now shut behind me". Nothing vanishes.
- **should-fix (look):** the strip to the left of the engineer looks like a different game: a smooth pale wall, clean drywall-like surfaces, and a cut floor slab with a bright white edge line (crop `r01-arrival-records-entry-3x`, bottom left). The rest of the room is gritty painted metal. Before, that edge was pipes and a tank that matched the room.

## Records copy point and exit (r04 to r08)

- **must-fix (look):** the whole right third of the Records screen is now a big, blank, pale concrete wall (r04, r05, r07; crop `r04-copy-point-records-exit-3x`). It is smooth and lit like a clean render, with no grime, no signage and no pipes, set against the painted room. It reads as a pasted-in image, which is exactly the "AI slop / not real" look Nathanial named. The floating "EXIT" text over this blank wall makes it worse.
- **should-fix:** the "security container" is a plain flat grey filing cabinet (r04 to r07). It looks like clip art, much cleaner and flatter than the mirror port next to it, and it has no label. "E: secure the first copy." at a filing cabinet does not say *why* this is where the copy goes.
- **fine:** the pressed-twice problem is gone. Securing the copy swings the exit leaf open into the room (r05, r06 handle visible, r07 open, green lamp). A second USE walks me through the doorway into a lit passage (r08-walk-out-1, -2). I see where it goes and I walk through it. The old navy "failed to load" rectangle is gone.
- **should-fix:** WOLF does not follow me through. In r08-walk-out-2 he is still back by the cabinet when the scene cuts to the junction, where he is already standing. It is a small version of the old "WOLF teleports" problem.
- **should-fix:** the exit door is small and tucked into the far corner, partly behind the column. The open leaf (r07, crop `r07-exit-open-records-exit-3x`) is a dark slab with almost no detail. It reads as "door" only at 3x. On a phone (`after-phone/r07-exit-open`) it is fine because it is larger.

## Junction arrival (r09)

- **inherited:** I just walked out of Records through a side door, but the junction opens with me standing beside a round, camera-facing vault hatch (left edge). Players will wonder whether that is the door I came through. It is the old camera-facing style.

## Junction blast door (j01 to j07)

- **should-fix:** before the blast (j01, j02, phone `j01-sealed`), the "SEALED DOOR" is a pale concrete pillar with a dark recessed door behind the valve. It reads as a door *beside* the walkway, not a wall *across* it. I would not guess it blocks my path. At full size it is about the width of a finger. The old one was ugly, but I could see it.
- **fine:** the blast (j03) is now a grey-blue cloud with a few embers instead of the flat beige blob. It no longer looks like a placeholder.
- **should-fix:** after the blast (j04, j06; crop `j06-lane-sentry-junction-blast-3x`), the doorway reads as a pale panel with two dark square holes. I cannot tell it is a blown-open doorway. I see nothing torn, burnt or bent. "DOOR DOWN" is the only thing telling me it opened.
- **should-fix (hover/odd):** the thrown door leaf lying on the deck in front of TANK RELEASE (j04, j06, j13; phone `j13-closing-shot`, the big grey slab at the bottom middle) reads as a clean floor plate or a step, not a blasted steel door. It has no scorch marks, dents or hinges. The "rubble" is still a handful of small grey chips by the valve.
- **must-fix (overlap):** when WOLF waits at the rubble, his head and front half disappear behind the concrete column, and his back half overlaps the valve (j04, j05, phone `j05-walking-through`). This is the "WOLF overlaps door frames" look the first players named, and it is still there.
- **should-fix:** in j05 ("walking through") the engineer is hidden behind the column. Only a red sliver shows (phone `j05-walking-through`, x ~985). For that moment the player loses their own character exactly at the door they are meant to be walking through.

## Junction exit door (j08 to j13)

- **should-fix:** j08 and j09 say "pop the exit bolt by the hatch", but no hatch is on screen. There is only a blank pale wall at the right edge, with WOLF standing in front of it. I would not know where the exit is until it opens. The word "hatch" for a sliding door also does not match what I see (j10 to j13).
- **should-fix (fake effect):** the bolt sparks in j10 are a cluster of soft mint discs floating over the panel and WOLF. They look like bubbles, not sparks. They pull the eye more than anything else in the frame.
- **fine:** the door opens properly. The leaf slides into the wall and its striped edge stays visible in the pocket (j10, j11). The doorway becomes a lit opening, and WOLF steps into it and waits looking back (j11, j12). The leaf never vanishes. "The hatch is open. Leave through it." now points at something I can see.
- **should-fix (look):** the exit's cross-wall is the same blank pale concrete slab as in Records (j08 to j14; crop `j12-at-the-door-junction-exit-3x`). It is clean and smooth, with no wear, set against the rusty painted room.
- **fine:** WOLF's tail at the bait spot reaching into the door reveal (crop `j10-hatch-opening-junction-exit-3x`) is not noticeable at normal size.

## Ending (j13 to j15)

- **fine:** this now reads. In the closing shot (j13) WOLF stands in the doorway and I stand just outside. After CONTINUE, WOLF walks through first (j14-walk-out-00, -01), then I follow (j14-walk-out-01, -02). The doorway sits empty for a beat (j14-walk-out-02, -03), and then the END OF SLICE card comes (j15). Nobody fades and nobody pops. I leave through the door I opened.
- **should-fix:** the closing camera keeps the exit pressed against the right edge of the screen, and the doorway is small (about 90 px on the laptop frame). The most important exit of the slice gets the least screen space. On a phone (`after-phone/j13-closing-shot`) it is readable.

## Inherited, outside these doors

- **inherited:** a mint (earlier yellow) beam line runs straight through the fallen tank and the crushed sentry from j08 to the end (j10 to j14). After the sentry is down it looks like a rendering glitch.
- **inherited:** the dialogue box covers the bottom quarter during both walk-outs, so the feet and floor of the exit moments are hidden.
- **inherited:** the floating label tags (SEALED DOOR, TANK RELEASE, EXIT OPEN) are fine as UI, but "EXIT" in Records floats on a bare wall with no sign or frame.

## Summary for a first-time player

They would understand the route: each door opens, the route is unblocked, and we walk out together in the right order. But they would notice three things straight away. Two clean grey walls look like they come from a different, more photographic game (Records right side, junction exit), and the blast door is a pillar. A slab lies on the floor and does not look like a door, and WOLF's head goes into the column while he waits. The mint spark bubbles at the bolt also pull the eye. Before this can pass, the cross-walls and the container need to match the painted room's grime and lighting, WOLF needs a clean waiting spot, the blown doorway and thrown leaf need to read as blast damage, and the spark effect needs replacing.
