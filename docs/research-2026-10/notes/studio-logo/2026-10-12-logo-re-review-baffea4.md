# Studio logo re-review (baffea4)

I re-reviewed baffea4, which is on main and is also origin/main. I made no changes to the game. My work files were in the session scratch (not kept); the contact sheet and the loading-bar crops are kept next to this file as `sheet720.webp` and `bar-crops.webp`.

**Verdict: pass.** All four earlier defects are fixed, and I found no new defect.

## Earlier defects

1. **A second press could start a New Game: fixed.** The new `HandoverCover._input` swallows key, mouse, controller and touch presses, and its mouse filter is now STOP. It stays until 0.6 s of wall time after the title's first frame.
   - I ran a headless probe (`proj/review_hs/mash3.gd`) that pressed every 100 ms from the start of the logo.
   - **Key and controller:** the title stayed open whenever the presses ended at +500 or +600 ms. When they went on longer, the first press to act landed at +607 to +703 ms.
   - **Mouse and touch:** the title stayed open in every window I tried.
   - **All four kinds at once:** the same result as keys.
   - Main's `_input` sees the event before the cover, but on the title it only tracks the input device, so a press can't activate anything.
2. **Saved window applied late: fixed.**
   - In render.sh with a saved `resolution:2`, the first logo frame is already 1920x1080. That frame matches the boot splash with 0 differing pixels.
   - With a saved `fullscreen:true`, the window mode is FULLSCREEN (3) on the first logo frame.
   - The title calls the same `GameSettings.apply_saved_window`, and it does nothing the second time.
3. **Loading bar stuck at about 98%: fixed.** The bar now shows a sweeping segment, 48 px of a 160 px track.
   - In the render.sh key-skip run, the segment moved from 0 to 72 px over frames f004 to f022. Crops: [`bar-crops.webp`](bar-crops.webp).
   - With no input, the title loaded by t = 0.57 s and the bar never appeared.
4. **Quitting during the load: fixed.** I sent a close or Back notification at 30, 200, 400 and 1500 ms.
   - At 30, 200 and 400 ms, the game quit at 96 to 444 ms, with no errors or leaks.
   - At 1500 ms the load had finished and quitting was handed back to the engine (`auto_accept_quit` true), so it quits at once.

## Re-verified

- **`bun run game:check`:** 15/15 suites passed. `studio_logo_test` took 8 s.
- **CI on baffea4:** Game checks, Test builds and Deploy Docs are all green.
- **Boot splash against the first frame (render.sh):**
  - 0 differing pixels at 1920x1080, at the 2340x1080 phone shape (the picture area) and with the saved 1920x1080 size.
  - At 1280x720 the simulated downscale differs by at most 25/255, only inside the mascot's box.
- **Smirk to grin:** only the mouth box changes (base x 440-496, y 176-210) at 720p, 1080p and on the phone shape.
- **Look:** the name reads clearly on the phone shape, and the dark fur reads against the navy glow with no bright flash. Contact sheet: [`sheet720.webp`](sheet720.webp).
- **Skips and automation:**
  - With `-- --skip-logo`, the first scene is main.tscn.
  - A headless run skips the logo.
  - A key press skips to the full logo.
  - The existing capture paths load main.tscn directly, so they are unaffected.
- **Files the fix didn't change:** the brand PNGs and the logo scene are the same as in b98bc94 (90,175 B, 7,554 B and 195,104 B).
- **Provenance and docs:**
  - The manifest provenance and rights notes and the README sentence are still in place.
  - The changelog bullet is spoiler-free, and `export_changelog.py` regenerates the same `changelog.txt`.
  - The diff contains no Drive path or email.
  - No commit carries a Co-Authored-By line.

## Notes (not defects)

- Each frame advances the logo by at most 1/30 s, so on a device below 30 fps the logo plays for longer than 2 s. That was already the case in b98bc94.
- One of 25 headless probe runs logged `Parameter "t" is null`. Five reruns of the same case didn't show it again. It most likely comes from my probe freeing the title, not from the game.
- No one has watched or played the logo in a game window or on a device. Feel, timing and the 0.6 s press guard are checked only by headless probes and render.sh still images.
