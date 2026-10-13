# Sound check: the procedural sound set (review page, October 10, 2026)

Markdown copy of the page "WOLF//OVERRIDE Sound Check" shown to Nathanial on October 10, 2026. Scripts, styles and the audio players are dropped; the rendered clips were not kept (they are rebuilt by the game's own code, `apps/game/scripts/sfx_bank.gd` at the time). Notes were cut short on the page itself (the "…" marks); the full measurement report for every clip is in [`../../sources/sound-picks/measurements/audition-analysis.json`](../../sources/sound-picks/measurements/audition-analysis.json) and [`audition-report-clips.json`](../../sources/sound-picks/measurements/audition-report-clips.json), and the critic's numbers for the in-game set in [`critic-current-set.json`](../../sources/sound-picks/measurements/critic-current-set.json).

**Outcome.** The steam hiss, the electrical arc and WOLF's growl were redone the same day, both as new synthesis and from CC0 recordings ([`2026-10-10-review-batch.md`](2026-10-10-review-batch.md), section 3), and Nathanial picked eleven sounds on October 10 ([`../../sources/sound-picks/LICENCES.md`](../../sources/sound-picks/LICENCES.md)). The other TWEAK and REDO notes fed the sound work recorded in [`../../data/sound-audition.json`](../../data/sound-audition.json).

---

*Sound check · October 10, 2026*

Every sound here is generated in code. Nobody has listened to them yet, so this is the first chance. Try them on headphones and on a phone or laptop speaker: many of the problems below only show up on small speakers.

Each clip has a verdict from a measurement pass (loudness, clicks at the edges, loop seams, how much of the sound sits in bass that small speakers cannot play). It is not a listening judgement; yours is the one that counts.

**Verdicts: 29 KEEP, 39 TWEAK, 1 REDO.**

## Sounds in the game today

Every effect the game generates in code at startup, rendered exactly as the game builds it. The 10-second files tile a loop so you can hear its seam.

- **boom** · TWEAK · 0.50 s · audio not kept  
  Tank shell hit (0 dB), door blast (0 dB), containment gate shutter boom (-2 dB).  
  *Why:* Truncated tail. The last sample is 0.050 and the sub is still ringing at 500 ms, so the spectrogram shows a broadband click at the end. The energy is 83% at 40-100 Hz and 7.4% below 40 Hz. Above roughly 300 Hz the clip is about 10 dB below its total RMS, so on…  
  *Fix:* Add a 30-50 ms fade to zero, or extend the clip to about 0.9 s so the 0.18 s tau decays fully. High-pass at 35 Hz. Drive the sub harder through tanh so 2x and 3x harmonics (90-180 Hz) imply the low end. Add a 200-600 Hz band-passed noise cr…
- **small boom** · TWEAK · 0.30 s · audio not kept  
  Relief vent letting go when the junction gauge peaks and the breaker trips (-2 dB).  
  *Why:* Ends at -0.0154, a small end click. 55% of the energy is at 40-100 Hz. For a relief vent letting go, the recipe is only a pop; it has no gas-release component, and the junction already has a hiss loop it could match.  
  *Fix:* Fade the last 20 ms. After the pop, add a 0.3-0.5 s decaying band-passed hiss (1-4 kHz, falling) so it reads as a vent venting rather than a small explosion. High-pass at 40 Hz.
- **clank** · TWEAK · 0.04 s · audio not kept  
  Breaker, junction autosave, clamp release, bolt arc, tank hit/miss/rehung, valve turn and relay spark contact, at pitches 0.55-2.2.  
  *Why:* At 40 ms the 12 ms-tau ring has fallen only to about -29 dB, and the clip ends at -0.011, a truncation click. The square ring puts 79% of the energy at 300-1000 Hz with harmonic partials, so pitched to 0.55-2.2 across about eight call sites it sounds like a bu…  
  *Fix:* Extend to 90-120 ms with a 5 ms fade. Replace the square with 3-4 inharmonic sine modes (for example 420, 1130, 2210 and 3480 Hz with decreasing tau) plus the noise tick. Consider 2-3 seeded variants with a no-repeat pick, as the footsteps …
- **thud** · REDO · 0.08 s · audio not kept  
  Tank miss landing (-3 dB, 0.8), fail-beat knockdown (0 dB, 0.9), seal door landing (-2 dB, 1.1).  
  *Why:* 99.2% of the energy is at 40-100 Hz (centroid 61 Hz), which is effectively inaudible on phone speakers and weak on laptops. The tail is truncated at 80 ms: it ends at -0.036 and the spectrogram shows a vertical click line. DC offset is 0.010 (-40 dBFS) on an 8…  
  *Fix:* Rebuild it as a 180->110 Hz pitch-dropping body (tau 40 ms) plus a 400-900 Hz band-passed knock (tau 15 ms) and a short 2 kHz contact tick. Make it 150 ms with a 10 ms fade. Add a one-pole DC blocker or a 40 Hz high-pass.
- **hiss** · TWEAK · 0.50 s · audio not kept  
  Junction pressure-line loop, -28 to -8 dB with the gauge; stopped by the door blast.  
  *Why:* No seam click (wrap step 0.099 against a 0.111 median step), but the 0.5 s noise buffer repeats twice a second, and the 2 Hz wobble is locked to the same period, so it pulses audibly. About 50% of the energy is above 2 kHz despite the '3 kHz low-pass' (a one-p…  
  *Fix:* Build a 4-6 s buffer from 3-5 noise chunks joined with equal-power crossfades (the corridor-bed method), or stream noise from an AudioStreamGenerator. Make the wobble period non-integer against the loop. Use a 2-pole low-pass at 3 kHz to ta…
- **hiss (10 s loop test)** · TWEAK · 10.00 s · audio not kept  
  Seam audition for the junction pressure-line hiss loop.  
  *Why:* Audition tiling confirms what the base loop shows: there is no click, but the same 0.5 s grain recurs 20 times in 10 s. The spectrogram texture repeats at the yellow seams.  
  *Fix:* Same fix as hiss: a longer chunked buffer, with the wobble decoupled from the loop length.
- **hum** · TWEAK · 1.00 s · audio not kept  
  Junction pump loop, -16 to -9 dB, pitch 0.5-0.8 with the gauge.  
  *Why:* The seam clicks once per loop: a 0.567 jump against a 0.0055 median step. The last sample is 0.4995 and the first is -0.068 because the one-pole low-pass state starts at 0. The spectrogram shows a broadband vertical line every second. Otherwise it is good: 110…  
  *Fix:* Pre-roll the filter: run the oscillator and filter over one full loop, discard it, then record the second pass, so the state at the end matches the start. Alternatively, generate the saws band-limited (additive harmonics up to 500 Hz) with …
- **hum (10 s loop test)** · TWEAK · 10.00 s · audio not kept  
  Seam audition for the junction pump hum loop.  
  *Why:* A click every 1 s seam, visible as ten vertical broadband lines. This would be audible throughout the junction pump scene.  
  *Fix:* Same filter pre-roll fix as hum.
- **arc** · TWEAK · 0.50 s · audio not kept  
  Records exit arc (-3 dB), exit bolt arc (0 dB), relay spark crackle (-8 dB, 1.2).  
  *Why:* Very bright: 54% of the energy is above 5 kHz and the centroid is 5.4 kHz. There is almost nothing below 1 kHz (2.4%), so the arc lacks body. Crest is 20.8 dB (RMS -26.8 dBFS), so at the same peak it will play about 12-17 dB quieter in perceived loudness than …  
  *Fix:* Add a 100/120 Hz-gated buzz band-passed at 300-1500 Hz under the crackle for the first 150 ms (the 'zzt' body), and roll off the crackle above 6 kHz by a few dB. Raise the call-site gains, or normalise the bank by RMS rather than peak.
- **klaxon** · TWEAK · 0.50 s · audio not kept  
  Seal-charged warning on a junction valve turn (-4 dB).  
  *Why:* The 2.5 kHz low-pass leaves 93% of the energy at the 880 Hz fundamental, so it reads as a clean microwave-timer beep rather than an industrial warning. Crest is 3.2 dB (RMS -9.2 dBFS), making it by far the loudest clip by RMS, about 17 dB above arc at the same…  
  *Fix:* Make it a two-tone or slightly detuned pair (for example 880 Hz plus 1046 or 660 Hz, or a 5-cent detuned second square), keep some third harmonic (raise the low-pass to about 3.5 kHz), and drop the call-site gain to about -10 dB.
- **growl** · TWEAK · 0.60 s · audio not kept  
  WOLF's growl at the lane choice (-9 dB at pitch 1.5, or -8 dB) and when he reads the seam (-6 dB).  
  *Why:* 65% of the energy is at 40-100 Hz (the 70->58 Hz saw fundamental) behind a 900 Hz low-pass, with only 7.8% at 300-1000 Hz. On phone speakers WOLF's growl will be thin and quiet, yet it is a character beat. The envelope (80 ms swell, 0.2 s die-away, ends at 0) …  
  *Fix:* Raise the low-pass to about 1.8 kHz and add a formant band-pass around 450-700 Hz (Q 2-3) on the saw, about +6 dB, so the growl's identity lives where small speakers play. Add light tanh grit for a metallic edge. Keep the sub, but high-pass…
- **servo** · TWEAK · 1.00 s · audio not kept  
  Sentry motor loop at -22/-19/-16 dB and pitch 1.0/1.15/1.4 by sentry state; faded out after the tank hit.  
  *Why:* The loop is seamless (whole cycles; the seam step equals a normal step). But 84.5% of the energy is in a single 1.2 kHz sine with vibrato, so it reads as a test-tone whistle or theremin rather than a sentry motor. A pure tone at 1.2 kHz also cuts through every…  
  *Fix:* Keep the seamless whole-cycle design, but add gear texture: a 2.4 kHz harmonic at about 0.2, a 3-5% amplitude ripple at an integer gear-tooth rate (for example 40 Hz), and a faint band-passed noise (1-3 kHz) whose envelope also loops in who…
- **servo (10 s loop test)** · TWEAK · 10.00 s · audio not kept  
  Seam audition for the sentry servo loop.  
  *Why:* Tiled 10 s confirms it is seamless. The only issue is timbre: the pure whistle.  
  *Fix:* Same harmonic and gear-ripple additions as servo, keeping whole cycles per loop.
- **winch** · TWEAK · 1.00 s · audio not kept  
  Arm winch loop while the tank is hauled back up (-14 dB).  
  *Why:* Clicks once per loop: a 0.440 jump against a 0.0032 median step (last 0.375, first -0.066), from the same one-pole filter state restart as hum. Timbre is OK: a 90 Hz saw with a 7 Hz wobble, 50% at 40-100 Hz and 41% at 100-300 Hz.  
  *Fix:* Pre-roll the filter one loop as for hum. Add a faint integer-rate (for example 14 Hz) ratchet or tick layer at 1-2 kHz so it reads as a winch on phones.
- **winch (10 s loop test)** · TWEAK · 10.00 s · audio not kept  
  Seam audition for the arm winch loop.  
  *Why:* A click at every 1 s seam in the tiled audition.  
  *Fix:* Same filter pre-roll fix as winch.
- **whine** · KEEP · 0.60 s · audio not kept  
  Exit bolt charging before it arcs (-4 dB).

## Draft footsteps

Not in the game yet. Four variants per surface for the engineer and for WOLF, plus a six-step walk that plays them the way the game would (no repeats, small pitch and volume changes).

- **engineer plate 1** · TWEAK · 0.25 s · audio not kept  
  Engineer footstep on plate decking (corridor).  
  *Why:* 94% of the energy is below 300 Hz (36% at 40-100 Hz, 58% at 100-300 Hz) and only 4% at 300-1000 Hz. The 611 and 1270 Hz plate modes are visible but faint, so on phones a heavy boot on steel plate will be a soft dull pat or vanish. DC is 0.003. Heel and toe tim…  
  *Fix:* Raise the 611 and 1270 Hz plate modes by 8-10 dB with tau of about 40-60 ms, raise the 232 Hz mode a little, shorten the 95 Hz thump tau, and high-pass at 50 Hz with a DC blocker.
- **engineer plate 2** · TWEAK · 0.25 s · audio not kept  
  Engineer footstep on plate decking (corridor).  
  *Why:* Same balance as variant 1: 93% below 300 Hz, 5% at 300-1000 Hz, RMS -22.2 dBFS. It differs from the others enough in thump weighting.  
  *Fix:* Same as engineer_plate_1: lift the plate modes 8-10 dB and high-pass at 50 Hz.
- **engineer plate 3** · TWEAK · 0.25 s · audio not kept  
  Engineer footstep on plate decking (corridor).  
  *Why:* 92% below 300 Hz (67.5% at 100-300 Hz); the plate ring is too weak for small speakers.  
  *Fix:* Same as engineer_plate_1.
- **engineer plate 4** · TWEAK · 0.25 s · audio not kept  
  Engineer footstep on plate decking (corridor).  
  *Why:* 93% below 300 Hz; 300-1000 Hz is 5.3%. Same issue as the other plate variants.  
  *Fix:* Same as engineer_plate_1.
- **engineer plate walk (6 steps)** · TWEAK · 1.70 s · audio not kept  
  Walking audition: engineer on plate with the planned jitter.  
  *Why:* Per-step peaks are -7.1, -7.4, -8.1, -6.6, -6.0 and -8.9 dB. The jitter and no-repeat pick work and there is no machine-gun effect in level. But the walk centroid is 198 Hz, so on a phone the corridor walk will be nearly silent.  
  *Fix:* Re-render after lifting the plate modes. Keep the jitter scheme.
- **engineer grating 1** · KEEP · 0.32 s · audio not kept  
  Engineer footstep on grating and the hollow vent grate.
- **engineer grating 2** · KEEP · 0.32 s · audio not kept  
  Engineer footstep on grating.
- **engineer grating 3** · KEEP · 0.32 s · audio not kept  
  Engineer footstep on grating.
- **engineer grating 4** · KEEP · 0.32 s · audio not kept  
  Engineer footstep on grating.
- **engineer grating walk (6 steps)** · KEEP · 1.77 s · audio not kept  
  Walking audition: engineer on grating.
- **engineer wet 1** · TWEAK · 0.28 s · audio not kept  
  Engineer footstep on the Junction wet-deck span.  
  *Why:* 81% of the energy is below 300 Hz and only 1.4% at 300-1000 Hz, so the '100-900 Hz squelch' layer is effectively missing. The splash and droplets (13% at 2-5 kHz) are there, so on phones it will sound like a thin hiss-tick rather than a boot in water.  
  *Fix:* Raise the squelch layer about 10 dB and centre it at 250-700 Hz with a short (20-40 ms) wobbling band-pass. Cut the 90 Hz thump about 4 dB and high-pass at 50 Hz.
- **engineer wet 2** · TWEAK · 0.28 s · audio not kept  
  Engineer footstep on wet deck.  
  *Why:* Even heavier low end (53% at 40-100 Hz) with 1.4% at 300-1000 Hz; the splash is quieter (10% at 2-5 kHz).  
  *Fix:* Same as engineer_wet_1.
- **engineer wet 3** · TWEAK · 0.28 s · audio not kept  
  Engineer footstep on wet deck.  
  *Why:* Same balance problem: 82% below 300 Hz, 1.4% at 300-1000 Hz.  
  *Fix:* Same as engineer_wet_1.
- **engineer wet 4** · TWEAK · 0.28 s · audio not kept  
  Engineer footstep on wet deck.  
  *Why:* Same balance problem: 83% below 300 Hz, 1.4% at 300-1000 Hz.  
  *Fix:* Same as engineer_wet_1.
- **engineer wet walk (6 steps)** · TWEAK · 1.73 s · audio not kept  
  Walking audition: engineer on wet deck.  
  *Why:* Step peaks are -7.1, -6.0, -7.0, -7.2, -7.6 and -8.2 dB, so the jitter is fine. The walk centroid is 452 Hz with a hole in the mids, so wet deck will not read as distinct from plate on small speakers.  
  *Fix:* Re-render after the squelch lift.
- **engineer rubble 1** · TWEAK · 0.26 s · audio not kept  
  Engineer footstep on rubble spans.  
  *Why:* The 75 Hz knock dominates (68% at 40-100 Hz), with a hollow middle (300-1000 Hz only 0.8%) and grit at 1-5 kHz. The spectrogram shows grains as narrow tonal pings (for example an isolated 3.5 kHz ping at 165 ms) rather than broadband crunch, which can sound li…  
  *Fix:* Add a 200-800 Hz crunch layer (noise bursts, 5-15 ms) about 8 dB up. Make the grit grains band-passed noise (Q 2-4) rather than sines, or shorten them to under 2 ms. High-pass the knock at 50 Hz.
- **engineer rubble 2** · TWEAK · 0.26 s · audio not kept  
  Engineer footstep on rubble.  
  *Why:* Same mid hole: 65% at 40-100 Hz, 1.2% at 300-1000 Hz.  
  *Fix:* Same as engineer_rubble_1.
- **engineer rubble 3** · TWEAK · 0.26 s · audio not kept  
  Engineer footstep on rubble.  
  *Why:* Same mid hole: 61% at 40-100 Hz, 1.4% at 300-1000 Hz; the grit is a bit brighter (17.5% at 2-5 kHz).  
  *Fix:* Same as engineer_rubble_1.
- **engineer rubble 4** · TWEAK · 0.26 s · audio not kept  
  Engineer footstep on rubble.  
  *Why:* Same mid hole: 60% at 40-100 Hz, 1.5% at 300-1000 Hz.  
  *Fix:* Same as engineer_rubble_1.
- **engineer rubble walk (6 steps)** · TWEAK · 1.71 s · audio not kept  
  Walking audition: engineer on rubble.  
  *Why:* Step peaks are -6.0, -7.1, -8.6, -8.5, -6.6 and -8.5 dB, a fine spread. Spectrally it is boom plus grit with no crunch body.  
  *Fix:* Re-render after adding the 200-800 Hz crunch.
- **wolf plate 1** · TWEAK · 0.16 s · audio not kept  
  WOLF footstep on plate decking.  
  *Why:* Good small-speaker balance (44% at 100-300 Hz, 24% at 300-1000 Hz, 30% above 1 kHz), light and short (t-40 dB about 100 ms), clean edges, and about 2 dB quieter than the engineer, as designed. But the claw lines (3.15/4.72 kHz) and pad modes (523/1347 Hz) sit …  
  *Fix:* Per variant, randomise the claw frequencies by +/-10%, the number of claw ticks (1-3) and the front/hind level ratio (0.6-1.0), and detune the pad modes by +/-4% on top of the pitch jitter.
- **wolf plate 2** · TWEAK · 0.16 s · audio not kept  
  WOLF footstep on plate decking.  
  *Why:* Similar balance (36% at 300-1000 Hz, RMS -22.7 dBFS) with the same fixed claw and pad partials as the other variants.  
  *Fix:* Same variant diversification as wolf_plate_1.
- **wolf plate 3** · TWEAK · 0.16 s · audio not kept  
  WOLF footstep on plate decking.  
  *Why:* Nearly identical to variant 1 (same band split to within 2%).  
  *Fix:* Same as wolf_plate_1.
- **wolf plate 4** · TWEAK · 0.16 s · audio not kept  
  WOLF footstep on plate decking.  
  *Why:* Its peak is at 517 Hz instead of 172 Hz, so it is a bit different, but it has the same fixed claw lines.  
  *Fix:* Same as wolf_plate_1.
- **wolf plate walk (6 steps)** · TWEAK · 1.18 s · audio not kept  
  Walking audition: WOLF on plate.  
  *Why:* Step peaks are -8.0, -6.0, -9.5, -7.3, -7.3 and -8.4 dB. The level jitter works, but the spectrogram shows six identical horizontal-line stacks; only the pitch jitter separates them.  
  *Fix:* Re-render after diversifying the variants.
- **wolf grating 1** · KEEP · 0.22 s · audio not kept  
  WOLF footstep on grating.
- **wolf grating 2** · KEEP · 0.22 s · audio not kept  
  WOLF footstep on grating.
- **wolf grating 3** · KEEP · 0.22 s · audio not kept  
  WOLF footstep on grating.
- **wolf grating 4** · KEEP · 0.22 s · audio not kept  
  WOLF footstep on grating.
- **wolf grating walk (6 steps)** · KEEP · 1.24 s · audio not kept  
  Walking audition: WOLF on grating.
- **wolf wet 1** · KEEP · 0.20 s · audio not kept  
  WOLF footstep on wet deck.
- **wolf wet 2** · KEEP · 0.20 s · audio not kept  
  WOLF footstep on wet deck.
- **wolf wet 3** · KEEP · 0.20 s · audio not kept  
  WOLF footstep on wet deck.
- **wolf wet 4** · KEEP · 0.20 s · audio not kept  
  WOLF footstep on wet deck.
- **wolf wet walk (6 steps)** · KEEP · 1.22 s · audio not kept  
  Walking audition: WOLF on wet deck.
- **wolf rubble 1** · KEEP · 0.18 s · audio not kept  
  WOLF footstep on rubble.
- **wolf rubble 2** · TWEAK · 0.18 s · audio not kept  
  WOLF footstep on rubble.  
  *Why:* Fine spectrally, but RMS is -26.1 dBFS against -22.9 for variant 4. A 3.2 dB variant spread plus the +/-2 dB jitter gives about 7 dB step-to-step swings.  
  *Fix:* Gain-match the four variants to within 1 dB RMS before jitter, by raising this one about 2 dB.
- **wolf rubble 3** · KEEP · 0.18 s · audio not kept  
  WOLF footstep on rubble.
- **wolf rubble 4** · KEEP · 0.18 s · audio not kept  
  WOLF footstep on rubble.
- **wolf rubble walk (6 steps)** · KEEP · 1.20 s · audio not kept  
  Walking audition: WOLF on rubble.

## Draft room tone

Ten seconds of each room's background bed, built from crossfaded chunks so the loop is hard to spot.

- **corridor room tone (10 s)** · KEEP · 10.00 s · audio not kept  
  Corridor room tone bed.
- **records room tone (10 s)** · TWEAK · 10.00 s · audio not kept  
  Records Access room tone bed.  
  *Why:* It is not a 'soft hush'. 76% of the energy is above 2 kHz (36% at 2-5 kHz, 40% above 5 kHz), the hiss is flat to 10 kHz and the centroid is about 4.5 kHz. At peak normalisation it is the loudest bed (RMS -16 dBFS), and this fizz is fatiguing on phone speakers.…  
  *Fix:* Low-pass the hiss with a 2-pole filter at about 3.5 kHz plus a pink tilt, and drop it 10-12 dB against the transformer buzz so the buzz carries the room. Keep the micro-crackle sparse. Target about -32 dBFS RMS in game.
- **junction room tone (10 s)** · TWEAK · 10.00 s · audio not kept  
  Service Junction room tone bed.  
  *Why:* 35% of the energy is below 40 Hz and 77% below 100 Hz (centroid 118 Hz). Above about 300 Hz it is about 10 dB below the total, so on phones and laptops the 'big metal drone' collapses to faint partials. The brown rumble also makes the level jump around (100 ms…  
  *Fix:* High-pass at 40 Hz and cut the brown rumble about 10 dB. Soft-saturate the 41 Hz drone so its 82/123/164 Hz harmonics imply the fundamental. Lift the metal partials (137/211/389/523 Hz) and the 660 Hz Q8 band 6-8 dB. Add a slow-beating pair…

## Draft ambient one-shots

Occasional distant sounds the rooms would play at random times.

- **distant bang** · TWEAK · 1.80 s · audio not kept  
  Distant hull bang for the ambient scheduler (corridor hull knocks).  
  *Why:* Good distance cues (hull modes, reflections at 140 and 310 ms, clean decay to 0, t-40 dB about 1.75 s). But 80% of the energy is below 100 Hz (6.5% below 40 Hz) and the centroid is 69 Hz with a 600 Hz low-pass, so on phones it will be nearly silent. That is a …  
  *Fix:* Add a 150-400 Hz metallic hull-ring layer about 10 dB up, plus a faint 1-2 kHz rattle of loose fittings at about -20 dB in the first 200 ms. High-pass at 35 Hz. Keep the 600 Hz low-pass on the main knock for distance.
- **drip** · KEEP · 0.50 s · audio not kept  
  Junction drips near the wet deck.
- **pipe creak** · KEEP · 1.20 s · audio not kept  
  Junction pipe and pressure creaks (designed to thin out after door_blown).
- **cooling tick** · KEEP · 0.60 s · audio not kept  
  Metal cooling ticks, for example after the blast or near warm machinery.
- **vent flutter** · KEEP · 1.00 s · audio not kept  
  Vent flutter in the corridor or Junction.
- **relay click** · TWEAK · 0.35 s · audio not kept  
  Records relay ticks (designed to stop once the corridor relay is set).  
  *Why:* The armature click and bounces are good, but 67% of the energy is the 160 ms, 120 Hz coil buzz at 100-300 Hz, which is a pure low tone that phones will mostly drop, leaving only the click.  
  *Fix:* Make the buzz a clipped or square 120 Hz (harmonics at 240/360/480 Hz) at about -6 dB, so the 'energised relay' character survives on small speakers.

## Draft evidence-case handling

The sounds for picking up and stowing evidence.

- **rustle** · KEEP · 0.60 s · audio not kept  
  A paper or evidence sheet taken from or put into the case.
- **clack** · KEEP · 0.14 s · audio not kept  
  A data cartridge seated in the case slot.
- **clink** · KEEP · 0.70 s · audio not kept  
  A metal tag or tool set down in the case.
- **ratchet** · KEEP · 0.50 s · audio not kept  
  Ratchet clicks, one per hold tick, when a tool is used at a station or the case latch is worked.

---

## Credits

- Game and decisions: Nathanial Henniges.
- Sounds: original procedural synthesis in the game's code; no third-party audio on this page.
- Measurement pass, verdicts and page: Claude (Claude Code) agents working for Nathanial.
