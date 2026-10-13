# WOLF's containment designs (October 11, 2026)

Nathanial asked on October 11: "Make sure the wolf cagte design makes sense" and "Can we add some pin codes and make it feel more like a furttgrue milialry base like iin skynet". Claude agents researched how real containment for a dangerous animal or robot is built (`research/RESEARCH.md`), audited today's cage in the opening (`audit/AUDIT.md`), and drew three options at game scale: A, B and C (`option-a/`, `option-b/`, `option-c/`). A separate judge compared them from the same opening beats (`OPTIONS.md`, `judge/`, `sheet.png`), the options were fixed (revision 2), and Nathanial picked.

**Decision (October 11, night), by Nathanial:** design C, a standby dock in a guarded bay: a floor-anchored robot stand with a charging umbilical, a dock lamp that goes amber, blue, off, telescoping mesh panels, and a guard lock on a lock pilaster that WOLF visibly tears off by pushing it. The opened, empty bay stays in the room after the opening. Until it is built, today's cage stays exactly as it is ("the cage for the wolf should been the same 100% the same before"). See "WOLF's containment" in [`../../README.md`](../../README.md). The Terminator films were named as a mood reference only; nothing is borrowed from them.

## Files

Tracked since October 11: `OPTIONS.md` (the judged comparison and revision-2 results; start here), `sheet.png` (the pick sheet), `research/RESEARCH.md`, `audit/AUDIT.md` and `audit/crops/`, `judge/` (comparison images and the contrast scripts), and each option's `DESIGN.md`, strip, construction drawing and renders, with option A's drawing tools in `option-a/tools/`.

Added on 2026-10-12 from the session scratch:

- `_v1-before-fixes/OPTIONS.md` and `_v1-before-fixes/option-{a,b,c}/DESIGN.md`: revision 1, exactly as the judge saw it before the fixes (the tracked `OPTIONS.md` says revision 1 is kept here). It records what the judge's "must fix" list changed. Its relative links (such as `../research/RESEARCH.md`) were written for the folder one level up, so from here they mean `../../research/RESEARCH.md` and `../../audit/AUDIT.md`.
- `_v1-before-fixes/sheet.webp`: the revision-1 pick sheet (WebP quality 80). The revision-1 renders, layers and scripts were not kept; revision 2 supersedes them.
- `option-b/driver/`: option B's code-drawn design: `design.py` (the single geometry source), `cell_spec_r1.json`, `cell_spec_r2.json` and `cell_spec_r2_plain.json` (the generated specs), `drawing.py` (construction drawing), `render_lib.py` (rasteriser), `compose.py` (sheets), `bake.py` with `cell_baked.gd` (baked-texture cost test), `cell_proto.gd` (the Godot prototype) and `driver.gd` (capture driver).
- `option-b/vector-vs-baked.webp`: the vector-drawn against baked-texture comparison behind B's draw-cost numbers.
- `option-c/driver/`: the approved design C's exact functional shapes: `containment_unit_codedrawn.gd` (the code-drawn version), `containment_unit_design.gd` (revision 2, flat-shaded layers plus live parts), `design_art.py` (the layer art generator), `design_opening.gd` (capture driver for main's opening with the proposed beat-3 timing) and `sheets.py` (drawing, beat renders and strip).
- `measurements/`: `audit-measure.txt` (lamp colour and position across the opening's beats), `option-a-r2-sparks-check.txt` and `option-c-r2-sparks-check.txt` (spark positions against the Director in beat 3), and `option-c-r2-shimmer.txt` (mesh shimmer measured as frame-to-frame flicker at 1280x720 and phone size, against main).

The driver scripts are design drawings and capture tools. They were never part of the game; the Godot scripts expect a scratch copy of the game and will not run from here. The capture runs, repository copies, logs and per-frame contact sheets (about 2 GB) were left out.

The design files here are kept as written on October 11. Where they call the engineer "he", read "they": since October 12 the engineer is non-binary and uses they/them. WOLF is he/his.

## Credits

- Game, story, WOLF and the decisions here: Nathanial Henniges.
- Research, audit, designs, drawings, measurements and judging: Claude (Claude Code) agents working for Nathanial, with Godot 4.7.2 for the captures and Python (Pillow, NumPy) for drawings and measurements. Design C's layers are flat-shaded drawings made by `design_art.py`, not generated images. No image-generation tool was used for these designs.
- Outside sources: `research/RESEARCH.md`, section 11, lists every source with its evidence label (manufacturer sheets, standards and official guidance, game references), 57 web sources in all, among them Boston Dynamics' Spot and Spot Dock specifications and Spot User Guide, Colossal Biosciences' Dire Wolf Husbandry Manual (with its IATA Live Animals Regulations container requirement 82 excerpt), the AZA *Tiger Care Manual* (2016), North Dakota Administrative Code 48.1-09-06, Defra's *Standards of Modern Zoo Practice*, OSHA 29 CFR 1910.147, ODNI's technical specifications for SCIFs (v1.5), Allegion's "Decoded: Fail Safe vs. Fail Secure", Troax's ISO 13857 safety guide, and the game references *Inside*, *Little Nightmares*, *Alien: Isolation*, *Detroit: Become Human* and *Stray* (described only). The downloaded PDFs themselves were not kept (third-party). Option B's `DESIGN.md` also cites:
  - "Meanings of tower light colors", OpTraffic blog: <https://optraffic.com/blog/meanings-of-tower-light-colors/>
  - ABB pilot devices catalogue, page 148 (via IPD): <https://resources.ipd.com.au/Flipbook/ABB_Pilot_Devices%20_Catalogues/files/basic-html/page148.html>
