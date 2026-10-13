# Sound as part of play (audio feel) - WOLF//OVERRIDE research notes

Researcher topic: how sound sells actions and space and guides the player. Started 2026-10-12.
Builds on docs/research-2026-10/design-reference-25-games.md section 8 (do not repeat it); fills its
listed gaps: Dead Space ALIVE breathing, procedural-audio technique sources, speaker/phone mix targets.

Current game audio (checked in apps/game/scripts/sfx_bank.gd, 2026-10-12): procedural clips at
22.05 kHz (detailed arc/growl at 44.1 kHz on a worker thread) plus CC0 recordings (steam loops, vent
burst, two growls); every clip normalised to -6 dB peak; 6 shared one-shot voices; 7 loops; every
player on the Effects bus; no footsteps, room tone, breathing, music or ducking yet.

## Working log (raw, as found)

- NOTE: the session's shared WebSearch budget ran out after 1 query; everything below comes from
  direct fetches of URLs (primary sources where known). Some gaps stay UNVERIFIED because of this.
- [AUDIO-FEEL-1] Sony WWS ASWG-R001 v1.10 (Aug 2013), PDF opened and text-extracted. Home platforms:
  average loudness -24 (+/-2) LKFS; portable: -18 (+/-2) LKFS; true peak max -1 dBTP; measure the
  whole mix (not dialogue only) for at least 30 minutes of representative play, BS.1770-3 meter;
  LKFS == LUFS. Reason given (point j): home and portable platforms "are used in different
  environments" with "varying noise floors" [fact-check wording fix]. v1.10 moved the home
  target from -23 to -24 to match ATSC/ARIB.
  -> WOLF: desktop build mix about -24 to -23 LUFS integrated; phone build about -18 LUFS (louder,
  less dynamic range). The current "every clip -6 dB peak" rule is a sample-peak rule, not a loudness
  target; measure integrated LUFS over a 30-min capture and keep true peak <= -1 dBTP.
- [AUDIO-FEEL-2] Dead Space (2023) A.L.I.V.E. system, EA Motive devstream 11 March 2022, Terry
  Calico (Senior VO Designer); reported by MP1st (Alex Co, 11 Mar 2022; the one that names Calico)
  and TheSixthAxis (Stefan L, 14 Mar 2022; does not name the presenter) - secondary; the devstream
  video itself was not opened. Controls Isaac's heart rate, breathing and dialogue. Inputs "jump scares,
  oxygen level, fatigue and more" trigger "varying amounts of adrenaline" (TheSixthAxis, Mar 14 2022).
  Original game: breathing/heartbeat got heavier with damage but "continue to play underneath grunts";
  remake separates breathing from exertion; breathing "will have to recover and transition" after
  vacuum. Scripted lines have multiple recordings per state: normal, fatigued, injured.
  No numbers published (UNVERIFIED: any BPM/thresholds).
  -> WOLF: a tiny engineer breath state machine (calm / exerted / shaken) driven by sprint time, the
  knockdown and sentry alert, decaying back over seconds; it must sit under WOLF's servo bed and never
  over dialogue. Cheap version of ALIVE: 3 states x a few breaths each.
- [AUDIO-FEEL-3] ITU-R BT.1359-1 (1998), "Relative timing of sound and vision for broadcasting", PDF
  opened and text-extracted (the WebFetch summariser misreported it; values below are from the PDF
  text). Detectability thresholds "about +45 ms to -125 ms", acceptability "about +90 ms to -185 ms"
  (positive = sound early). People forgive late sound more than early sound.
  -> WOLF: a sound caused by the player's own press should land within about 45 ms of the frame that
  shows it; never schedule a sound before its visual. This is broadcast data, not game data: for a
  self-caused action the bar is probably stricter (Android cites musicians needing 10 ms).
- [AUDIO-FEEL-4] Android NDK "Audio latency" guide (developer.android.com, opened 2026-10-12):
  android.hardware.audio.low_latency = continuous output latency <= 45 ms; android.hardware.audio.pro
  = round trip <= 20 ms; "musicians generally require 10 ms". Buffer sizes 96-512 frames; pre-roll
  silence to cut warm-up latency.
  -> WOLF: on phones, output latency alone can eat the whole 45 ms budget; play UI confirm sounds on
  the press frame (not on release) and keep a player warm (silent pre-roll) so the first tap has no
  extra start-up delay. Measure on a real Android device; Godot ignores output_latency on Android.
- [AUDIO-FEEL-5] Godot 4.5 ProjectSettings class reference (doc/classes/ProjectSettings.xml, opened):
  audio/driver/output_latency default 15 ms ("ignored on Android"); output_latency.web 50 ms;
  mix_rate 44100 (ignored on iOS/macOS); audio/general/2d_panning_strength 0.5 "tuned for headphones.
  When using speakers, you may find lower values to sound better"; ios/session_category default 0,
  which core/config/project_settings.cpp line 1619 enumerates as "Ambient" (first of
  Ambient, Multi Route, Play and Record, Playback, Record, Solo Ambient); "Use the Playback category
  to get sound output, even if the phone is in silent mode."
  [fact-check] Same defaults confirmed in the 4.7.2-stable tag the game pins (ProjectSettings.xml;
  project_settings.cpp line 1760 there, 1619 in 4.5); 4.7.2 also has audio/general/ios/mix_with_others
  (default false; "Ambient always has this set per default").
  Apple Audio Session Programming Guide (archive): Ambient and SoloAmbient are "silenced by the
  Ring/Silent switch and by screen locking"; Ambient mixes with other apps' audio; Playback is not
  silenced. WOLF's project.godot sets no audio settings, so on iPhone the game is Ambient: muted by the
  silent switch, and it plays over the player's own music.
  -> WOLF: respect the silent switch (Ambient is right for a game) but then the game is SILENT for
  many phone players: every essential sound cue needs a visual or haptic twin, and the first-run
  screen can say "sound recommended; headphones best". Consider pausing music stems if other audio is
  playing (secondaryAudioShouldBeSilencedHint) - UNVERIFIED in Godot, would need a plugin; the
  property name is not on the Apple page opened (UNVERIFIED).
  [fact-check, new source AUDIO-FEEL-29] Apple HIG "Playing audio" backs "respect the switch": in
  silent mode people "also want to silence nonessential sounds, such as keyboard clicks, sound
  effects, game soundtracks"; its category table gives a game as the example for both Solo ambient
  and Ambient ("a game that lets people play music from another app during gameplay").
- [AUDIO-FEEL-6] Godot class reference: AudioStreamRandomizer (PLAYBACK_RANDOM_NO_REPEATS; random_pitch
  is a multiplier range 1/x..x; random_volume_offset_db); AudioEffectCompressor has a `sidechain`
  property ("Audio bus to use for the volume threshold detection"), defaults threshold 0 dB, ratio 4,
  attack 20 us, release 250 ms. Godot "Audio buses" page: "every 6 dB, sound amplitude doubles or
  halves". -> ready-made engine parts for no-repeat footsteps and for ducking Ambience/Music under
  Voice/WOLF cues without custom DSP.
- [AUDIO-FEEL-7] Xbox Accessibility Guideline 105 (Microsoft Learn, ms.date 2022-05-09): separate
  volume/mute for music, voice-over, "active sound effects (those critical to gameplay like engine
  noise, gunshots, or footsteps)", "background/ambient sound effects (those not critical)", narration,
  voice chat; a stereo-to-mono option; pause audio events (events under 3 seconds exempt). Grounded
  ships 6 sliders. Game Accessibility Guidelines (collaborative, studios + specialists + academics):
  "too many different sources of information can make it difficult to focus on any of them."
  -> WOLF has Master/Music/Effects/Voice buses but every player sits on Effects. Split Effects into
  gameplay cues vs ambience (room tone), add a mono toggle (panning carries WOLF's off-screen
  position, which one-sided-hearing players would lose).
- [AUDIO-FEEL-8] Jakob Schmid, "The Boy from INSIDE: Uncompromising Character Audio Implementation",
  AES 2016 (Playdead publications repo, PDF text-extracted; last slide links
  schmid.dk/talks/2016-02-11-aes/, so February 2016). [fact-check] This deck itself lists the 6
  footstep speed keys: idle < 0.07, sneak < 0.37, walk < 0.70, jog < 0.92, run < 1.30, sprint >= 1.30
  (speed units as in the game), and the matrix example idle -> jog plays 'takeoff_mf'; run -> stop
  'brake'. NEW beyond the 25-game study:
  * Cloth: sound "generated at runtime from character geometry"; "Tracking a single elbow was enough"
    (elbow passing a torso "brush zone" fires a brush sound); "creates coherence between discrete
    foley sounds".
  * "Engagement actions": a separate set of voice sounds for "performing work", in two flavours,
    engaged passive / engaged active.
  * Voice emotion sets (relaxed, frantic, relieved...) with "morphing" to change emotion after a set
    time; intensity clamping per scene; voice direction by trigger boxes and state machines.
  * Breath callback drives an additive breathing animation (sound leads the body, not the reverse).
  -> WOLF: the hold-to-crank valve and MANUAL BYPASS are exactly "engaged active" moments: strain
  breaths/grunts on the engineer while cranking, a relieved exhale on release. One elbow/hip brush
  sound per stride sells the coverall cheaply.
- [AUDIO-FEEL-9] Martin Stig Andersen & Jakob Schmid, "Unbreaking Immersion: Audio Implementation for
  INSIDE", Wwise Tour 2016 (PDF text-extracted). NEW detail:
  * Scene change on death: Wwise updates are PAUSED from fade-out complete to fade-in start; commands
    queue (2 MB queue) and run "all at once when scene change is complete", which "creates the
    illusion of no time passing". So the 25-game study's "respawn never breaks audio / audio keeps
    running" is refined: the ambience is frozen and held, not left running into a new state.
    [fact-check nuance] The same deck says "Audio should retain state and continue during load"
    and "When reload is complete, audio should switch to new state instantly": the sound keeps
    playing (no gap, no mute); only its state changes are held back. Slides dated 2016-06-16
    (schmid.dk/talks/2016-06-16-wwise).
  * "Voice Intensity Interpolation in Space: useful for indicating proximity to danger"; over time:
    "creating reactions to game events, and relaxing over time".
  * Virtual voices: "Inaudible sounds are still updated, but not mixed" (CPU saving).
  * Codecs: "PCM for music, and all other sounds vorbis (quality 10)".
  * QA: glitches were "256 samples of zeros", "No errors in Wwise profiler, only detectable using
    audio recordings"; "Barely audible glitches are easy to spot in spectrogram". Profile the whole
    playthrough ("2D gameplay: predictable, testable performance").
  -> WOLF: on knockdown/death, hold the room-tone players (pause bus or keep playing) and swap state
  in one frame on respawn; as the engineer nears the sentry or the overloaded line, raise breath
  intensity by distance. Test approach that fits "no windows": record the mix inside the render
  container (or AudioEffectRecord) and check a spectrogram for dropouts instead of listening.
- [AUDIO-FEEL-10] Jakob Schmid, "Adaptive Audio in INSIDE and 140", SpilBar 41, 2019 (PDF). 140:
  "Music loop audio sources are placed directly in level geometry"; all loops "exactly same length, or
  integer multiples", "started in the same frame, possibly muted", "Never change pitch"; music at
  140 BPM, a bar is about 1.7 s, the KillBlock rhythm is exactly 2 bars and "Communicates to player
  exactly when certain game areas are either safe or lethal. Must correspond exactly to game logic
  timing". A "death filter" (low-pass + echo) "masks transitions and loops".
  -> WOLF already runs the three hiss loops in step (one length, one wrap point) - that matches 140's
  rule. If the Blowback overload or sentry sweep is periodic, tie its warning sound to the same clock
  as the hazard so the ear can time it; use a low-pass "death filter" on the bus for the Cold Still
  death screen instead of cutting audio.
- [AUDIO-FEEL-11] Martin Stig Andersen, "The Environment is the Orchestra: Soundscape Composition in
  LIMBO" (Playdead publications repo, PDF; year not on slides; [fact-check] the PDF metadata says it
  was made in Keynote on 2011-03-21 from a GDC-branded template, so c.2011; the event is still
  UNVERIFIED). Reviewers split on
  whether Limbo even has music ("Limbo is devoid of a soundtrack" vs "The music in Limbo is just
  phenomenal"). Technique: environmental recordings become music by degrees - a foundry recording
  interpolated (morphed) with an orchestral recording, then with a bowed cymbal [fact-check: the
  foundry is interpolated, not filtered; the filtering examples are the engine and the saw];
  "activating the fundamental note by filtering it through
  the pulsing engine"; a drone activated "by filtering it through the swooshing sound of a circular
  saw"; a "stinger-like sound, triggered when the boy survives".
  -> WOLF: the base's machines are the orchestra: tune the coolant hum, relay buzz and servo loops to
  one key per room so that a "music" swell can come out of the machines (filter sweep) instead of a
  separate score track; keep the survival stinger for passing the sentry/tank beat.
- [AUDIO-FEEL-12] Mikkel Svendsen (Playdead; author in the deck metadata), "Turn It Down 90% - INSIDE
  VFX", Control Conference 2016 (pptx, Playdead publications repo). This is a VISUAL-effects talk, not
  an audio talk (the 25-game study only saw the title). Audio-relevant line: dimmed rain that "you
  wouldn't notice most of the time unless you looked in the shade, or under a lamp. Or because the
  audio hints that it's raining, making you check subconsciously." Water displacement "Seen for about
  5-10 frames per dive". Closing lesson: "most of the time you're not first violinist. Know when you
  are and when you aren't."
  -> Sound can carry the ambient fact (steam, rain, leak, power hum) so the art can stay restrained;
  this supports Nathanial's "look real, no slop": fewer floating VFX, more sound.
- [AUDIO-FEEL-13] Celeste Player.cs (Maddy Makes Games, class file released as a learning resource
  under MIT in github.com/NoelFB/Celeste; opened 2026-10-12). Footsteps fire from the sprite's
  OnFrameChange on the contact frames: frames 0 and 6 of Walk/RunSlow/RunFast/RunCarry (2 steps per
  cycle), frame 6 of RunStumble, frame 4 of Flip. Each step looks up the platform under the feet
  (SurfaceIndex.GetPlatformByPriority) and passes its step-sound index as an FMOD parameter; hand
  holds use the wall's sound index; landing plays a land sound by surface, but within 0.5 s of a
  climb hop (playFootstepOnLand = 0.5f) it plays a footstep instead (a small hop should not sound like
  a fall); landing also fires Input.Rumble(Light, Short). Idle animations carry their own small
  sounds (scratch, sneeze, knuckle crack) that stop if the animation is interrupted.
  -> WOLF: the painted frame-by-frame walk/jog cycles should fire a footstep on each foot-contact frame
  (not on a timer), with the surface read from the floor under the engineer (grating vs plate vs
  wet floor near coolant) and WOLF's four paws on his own contact frames (lighter metal taps plus a
  servo whir per stride). Small idle sounds (WOLF's servo settle, the engineer's sleeve rub) stop
  when interrupted.
- [AUDIO-FEEL-14] Rob Bridgett, "The Future of Game Audio - Is Interactive Mixing the Key?", Game
  Developer (Gamasutra), 14 May 2009. Without mix decisions games become "a single wall of noise that
  occupies the entire spectrum of perceivable sound and that ultimately fatigues the player". Film
  (he describes film mixing practice here, not a game rule):
  "The ambience never disappears, but it is pushed to the back of our perception". Mixing is "a series
  of choices about what to hear at any particular moment". Snapshots: default, multiplier/ducking,
  override, with priority so stacked ducks do not over-attenuate. No dB/ms values given.
  -> WOLF: write 4-5 mix snapshots (explore, WOLF speaking, Blowback action, sentry alert, death) as
  bus-volume presets that crossfade; the room tone ducks but never drops out.
- [AUDIO-FEEL-15] Jason Graves (composer, Dead Space) interviewed by Joey Thurmond, Push Square, 16 May
  2015: wanted "a musical Necromorph", "musical sound design"; "there is music...playing all the time,
  even at the lowest level it's so textural that it sounds like room tone"; aleatoric notation where
  "the 40 string players could play any note they wanted". [fact-check] The full clause is "unless
  you're in zero gravity - playing all the time": Dead Space drops the music in zero-G, so even this
  always-on score has a deliberate silence. Wikipedia (Dead Space 2008 article, secondary)
  credits Don Veca's team with "Fear Emitters" and a "Creepy Ambi Patch".
  [fact-check: NOW VERIFIED IN PRIMARY SOURCES, AUDIO-FEEL-27/28] Don Veca (audio director) to
  Jayson Napolitano, Original Sound Version, 7 Oct 2008: the fear emitter "is simply a first-class
  game object that designers can place in the world or attach to other objects, most notably, the
  enemy alien creatures"; "the music is played back as four layered stereo streams" mixed by "how
  much 'fear' is being emitted"; with this one tool they affect "music, streamed ambience, adaptive
  ambience, reverb control, general mixing parameters". Veca to Ben Reeves, Game Informer, 11 Dec
  2009: "the fear effects change as your proximity to it changes"; up to four layers of music per
  emitter; "A lot of ambient tracks run as long as two or three minutes."
  -> WOLF: a music layer that sounds like room tone is the right floor for a machine base; a
  distance-to-threat parameter (sentry, overload) can raise it, which is what Fear Emitters did.
- [AUDIO-FEEL-16] Nicolas Fournel (Sony Computer Entertainment Europe), "Procedural Audio for Video
  Games: Are we there yet?", GDC 2010, GDC Vault page: motivates procedural audio by "Explosion of
  content, non-repetitive sound effects, need for interactive music"; covers design choices, sound
  models, tools, engines and QA across production.
- [AUDIO-FEEL-17] Andy Farnell, "Designing Sound", MIT Press 2010, 688 pp. (Open Library record;
  Google Books description and table of contents): "understand and create sound effects starting from
  nothing" in Pure Data; treats "sound as a process, rather than as data". Practicals directly useful
  here: Electricity, Switches, Motors, Fans, Creaking, Bouncing, Footsteps, Explosions, R2D2 (a
  synthesized robot voice). Companion site aspress.co.uk/ds (Applied Scientific Press). The 2007 paper
  "An introduction to procedural audio and its application in computer games" was NOT reachable (404).
  -> WOLF's procedural SfxBank (clank, thud, servo, winch, whine, arc) is exactly Farnell's territory:
  model the mechanism (motor = rotor buzz + load-dependent pitch; switch = click transient + body
  resonance; creak = stick-slip friction) with parameters the game drives (gauge, crank speed), rather
  than static one-shots. The R2D2 practical is the reference for a non-verbal robot companion voice.
- [AUDIO-FEEL-18] Paul Weir (Earcom), "The Sound of 'No Man's Sky'", GDC 2017, GDC Vault page: "Along
  with conventional sound design, 'No Man's Sky' features an innovative vocal modeling synthesizer
  plugin and a custom built generative music system to provide a varied and reactive in-game
  soundtrack" (VocAlien, a physically modelled vocal synth for creatures; 65daysofstatic wrote both
  linear and generative material). Numbers not on the page (UNVERIFIED).
  -> Synthesized creature voice precedent: WOLF's growls could be a recorded growl driven through a
  synthesized "machine body" (already the case for growl_seam/refusal) plus parameters for mood.
- [AUDIO-FEEL-19] Scott Lawlor & Tomas Neumann (Blizzard), "Overwatch - The Elusive Goal: Play by
  Sound", GDC 2016, GDC Vault page: a "Play by Sound" production objective in a 12-player shooter;
  systems across music, effects and dialogue so audio carries split-second decisions. Details not in
  the description (UNVERIFIED beyond it).
  -> The goal statement fits WOLF: a player should be able to tell the sentry's state, the gauge and
  WOLF's position with eyes closed.
- [AUDIO-FEEL-20] Android Developers, "Haptics design principles" (opened 2026-10-12): "We strongly
  recommend co-design of visual, audio, and haptic effects"; "Given the choice of buzzy haptics or no
  haptics for touch feedback, choose no haptics"; a keyclick haptic "should last between 10 to 20
  milliseconds" and the actuator "may continue to ring for another 20 to 50 milliseconds"; use haptics
  "To confirm a state change ... following a user action".
  -> WOLF on phones: a crisp 10-20 ms tick on USE accepted, on each crank ratchet click and on the
  safe-point secure; a heavier pattern only for the blast and tank drop; no long buzzes. This is the
  silent-switch fallback too.
- [AUDIO-FEEL-21] Apple Podcasts "Audio requirements" (podcasters.apple.com/support/893): "around -16 dB
  LKFS, with a +/- 1 dB tolerance", true peak not over -1 dB FS (BS.1770-5). Not a games rule, but it is
  Apple's own target for content heard mostly on phones and earbuds; it sits 2 dB louder than ASWG's
  portable -18. AES TD1004 (often quoted as -16 to -20 LUFS for portable) was behind a bot wall and is
  UNVERIFIED here.

## Measured: the current WOLF//OVERRIDE sound set (headless, 2026-10-12)

Method: `godot --headless` (isolated HOME, Godot 4.7.2) ran a scratch script that instantiates
SfxBank, waits for the detailed clips and saves every stream with AudioStreamWAV.save_to_wav; the
repo stayed clean. Measured with pyloudnorm (ITU-R BS.1770 integrated LUFS), 4x-oversampled true
peak, FFT energy share. Clips shorter than 0.4 s (clank 0.04 s, thud 0.08 s, small_boom 0.3 s,
relay_spark 0.34 s) are below one BS.1770 gating block, so their LUFS is indicative only.
This is clip data, not a measurement of the played mix; nothing was listened to.

[fact-check, 2026-10-13] Re-dumped independently (godot 4.7.2 --headless, isolated HOME, repo at
da5c14e, git status clean afterwards): 20 streams, none named `hiss`; 9 at 22.05 kHz, 11 at 44.1 kHz.
Re-measured with a separate BS.1770 K-weighting implementation (numpy/scipy, not pyloudnorm): every
LUFS value below agrees within 0.1 LU, and the <150 Hz shares and centroids match exactly. True peak
(4x oversampled) runs up to 0.7 dB above sample peak (klaxon -5.3 dBTP, relay_spark -5.3, hum -5.0),
still far under -1 dBTP. generation_ms was 31.0 in this run against about 112 in the researcher's:
the startup render time varies run to run, so quote it as a range.

| clip | sec | peak dBFS | ~LUFS | crest dB | energy <150 Hz | <300 Hz | centroid Hz |
|---|---|---|---|---|---|---|---|
| klaxon | 0.50 | -6.0 | -9.1 | 3.2 | 0.2% | 0.2% | 1038 |
| servo (loop) | 1.00 | -6.0 | -10.4 | 4.6 | 0% | 0% | 1107 |
| whine | 0.60 | -6.0 | -14.4 | 8.4 | 0% | 1.6% | 1073 |
| winch (loop) | 1.00 | -6.0 | -14.9 | 7.2 | 68.3% | 91.1% | 161 |
| hum (loop) | 1.00 | -6.0 | -15.5 | 8.1 | 72.7% | 88.4% | 175 |
| hiss_high (loop) | 6.00 | -6.0 | -18.1 | 14.5 | 0.9% | 3.4% | 2606 |
| hiss_mid (loop) | 6.00 | -6.0 | -18.2 | 14.3 | 1.3% | 4.8% | 2198 |
| boom | 0.50 | -6.0 | -18.9 | 8.3 | 90.6% | 92.0% | 239 |
| hiss_low (loop) | 6.00 | -6.0 | -18.9 | 13.9 | 2.7% | 10.5% | 1279 |
| bolt_arc | 0.80 | -6.0 | -19.2 | 15.7 | 1.2% | 6.8% | 1922 |
| coolant_cloud (loop) | 8.00 | -6.0 | -19.3 | 14.8 | 2.9% | 10.7% | 1574 |
| growl_seam | 0.90 | -6.0 | -19.4 | 13.2 | 10.8% | 25.7% | 609 |
| vent_burst | 2.40 | -6.0 | -19.7 | 17.7 | 0% | 1.8% | 2071 |
| records_arc | 0.65 | -6.0 | -20.1 | 14.8 | 2.9% | 11.4% | 2032 |
| growl_warning | 1.20 | -6.0 | -20.4 | 15.6 | 15.7% | 32.7% | 973 |
| growl_refusal | 0.92 | -6.0 | -21.5 | 15.6 | 0.7% | 4.8% | 903 |
| (short) thud | 0.08 | -6.0 | ~-19.9 | 10.2 | 99.3% | 99.8% | 64 |
| (short) small_boom | 0.30 | -6.0 | ~-18.8 | 11.8 | 67.0% | 73.1% | 623 |
| (short) clank | 0.04 | -6.0 | ~-18.1 | 12.8 | 0.5% | 1.4% | 1692 |
| (short) relay_spark | 0.34 | -6.0 | ~-19.7 | 15.4 | 0.6% | 5.7% | 2300 |

What it shows:
1. Same -6 dB peak, 12.4 LU spread in loudness (klaxon -9.1 vs growl_refusal -21.5). Peak
   normalisation does not equalise loudness - exactly ASWG-R001's point (g) [AUDIO-FEEL-1].
2. With the call-site gains in main.gd, WOLF's choice growls land near -25 LUFS (growl_warning -5 dB,
   growl_refusal -3.5 dB) while the sentry lock-on klaxon lands near -17 (klaxon -8 dB, pitch 1.6)
   and the fuse-lit klaxon near -13 (klaxon -4 dB): WOLF's answer to the bait choice is about 8-12 LU
   quieter than the alarms around it. For a companion story his voice is the dialogue line; it should
   sit on top (Voice bus, duck the rest), not under the machines. (Derived: clip LUFS + call gain;
   pitch_scale changes are ignored; not measured in the running mix.)
3. Low-frequency dependence: thud (tank landing, door blast layer) has 99.3% of its energy below
   150 Hz (centroid 64 Hz); boom 90.6%; hum 72.7%; winch 68.3%. On phone and laptop speakers that
   reproduce little bass (cut-off figure UNVERIFIED here; no primary source opened) these will mostly
   vanish. The impacts already stack a clank with the thud/boom in several places; every big impact
   needs a mid/high layer (debris, metal ring, 1-4 kHz) so it reads on a phone.
4. Klaxon and servo are near-square tones (crest 3.2 and 4.6 dB): loud and fatiguing per peak, good
   for alarms, poor for a constant companion bed. Keep WOLF's servo low (main.gd plays it at -16 to
   -24 dB, i.e. about -26 to -34 LUFS) and varied.
5. BUG (code reading + dump): main.gd line 970 plays `&"hiss"` for the corridor MANUAL BYPASS crank and
   line 1767 stops it, but SfxBank has no `hiss` stream (only hiss_low/mid/high), and `play()` returns
   null for unknown clips, so the bypass crank is silent apart from the klaxon. It is also called
   every frame; if it were a one-shot it would restart every frame and cycle through all 6 voices.
   Per-frame sounds must go to a loop player (as the junction's play_blend does).

## More findings (continued log)

- [AUDIO-FEEL-22] Steve Swink, "Game Feel: A Game Designer's Guide to Virtual Sensation", Morgan
  Kaufmann/Elsevier 2009, ISBN 978-0-12-374328-2, chapter 1 (PDF copy on a course site, mycours.es,
  opened; an unofficial course copy, so cite the book, not the PDF). [fact-check] The "clues" are given
  by all polish (animations, sounds, particles, camera shake), not by sound alone. "Polish refers to
  any effect that artificially enhances interaction without changing the underlying simulation",
  e.g. "a crashing sound when two cars collide"; polish gives "clues about whether they're heavy,
  light, soft, sticky, metallic, rubber"; "for players-simulation and polish are indistinguishable".
  -> The crank, valve, relay, door and tank are judged by their sound as much as by their logic: a
  silent bypass crank (see the bug above) feels broken even though it works.
- [AUDIO-FEEL-23] Michael Taylor, "Room Tone, Emotional Tone: The Importance of Hearing Ambience",
  Designing Sound, 15 Nov 2012: "Silence is an incredibly unnatural phenomenon it is psychologically
  jarring, even if only on a subconscious level"; two layers - room tones (cut into segments in
  randomised playlists to avoid loop fatigue) and one-shots randomised in time, position, pitch and
  volume. No numbers.
- [AUDIO-FEEL-24] Mark Hollier, "Video game audio under the hood: Eon Altar ambience system", Game
  Developer, 1 Feb 2016: 3 zone beds; the trigger's "On Enter" event "prime[s]" the next bed (the
  article's words: "(playing at 0db)"), and "On Exit" crossfades the current and primed beds
  [fact-check: "primed silent" was an interpretation; whether the primed bed is audible before the
  crossfade is UNVERIFIED]; one-shot
  "sweeteners" every 5-10 s (random), picked from 5-10 sound groups of 5 variations each, at random
  offsets around the listener, never overlapping (wait for the current one to end).
  -> WOLF room tone recipe with numbers: one bed per room (corridor HVAC + fluorescent buzz; Records
  server fans; Junction pump + pressure), primed and crossfaded at doorways; 1 machine "sweetener"
  every 5-10 s (relay tick, pipe knock, distant PA, sentry servo far off) from about 5 groups x 5
  variations, positioned left/right of the engineer. Never full silence, even in the death screen.
- [AUDIO-FEEL-25] Sony/Naughty Dog, The Last of Us Part II accessibility options (playstation.com):
  Traversal audio cues for "Jumpable gaps, climbable ledges, and squeeze-throughs", "Interacts and
  pick-ups", "Gaining or losing movement control"; Combat cues incl. "Aiming at an enemy", "Landing a
  shot"; Enhanced Listen Mode where a scan pings at the target and "The pitch of the sound changes
  based on the target's height relative to you"; subtitles with a direction arrow for off-screen
  speakers.
  -> WOLF: an optional "audio cues" toggle: a soft ping on every USE-able object as it enters reach,
  a cue on losing/regaining control (knockdown), and WOLF's subtitle lines get a direction arrow when
  he is off-screen (pairs with the off-screen edge marker decision).
- [AUDIO-FEEL-26] Godot 4.5 class reference (doc XML on GitHub): AudioStreamPlayer/2D `max_polyphony`
  default 1 ("Calling play after this value is reached will cut off the oldest sounds");
  AudioStreamPlayer2D `attenuation` exponent default 1.0, `max_distance` default 2000 px,
  `panning_strength` multiplier; AudioStreamInteractive ("combining clips and a transition table",
  from_time/to_time/fade modes) and AudioStreamSynchronized ("sub-streams, which will be played
  in-sync"); AudioEffectRecord records a bus.
  -> Engine-native routes: footsteps on one AudioStreamPlayer2D per actor with max_polyphony 2-3 and
  an AudioStreamRandomizer (no repeats, pitch 1.05, volume offset 2 dB - tuning values are mine,
  UNVERIFIED); stems with AudioStreamSynchronized (INSIDE/140-style locked loops); state music with
  AudioStreamInteractive; AudioEffectRecord on Master for the spectrogram QA in the render container.

## Synthesis: what a game like WOLF//OVERRIDE must, should and could do with sound

MUST
1. Confirm every state-changing press with sound on the same frame as its visual (USE accepted, each
   crank ratchet tick, valve turn, relay throw, safe-point secure, door lamp change). Budget: sound no
   later than ~45 ms after the visual and never before it; phones also get a 10-20 ms haptic tick.
   [AUDIO-FEEL-3, 4, 20, 22, 13]
2. Fix the silent MANUAL BYPASS crank (`&"hiss"` does not exist) and route any per-frame sound to a
   loop player. [measured section, AUDIO-FEEL-22]
3. Footsteps fired from the painted walk/jog cycles' foot-contact frames, surface read from the floor
   under the feet, no immediate repeats, with start/stop (takeoff/brake) variants; WOLF's paws and
   servo on his own frames. [AUDIO-FEEL-13, 8, 26; 25-game study INSIDE bands]
4. Room tone in every room, never digital silence: a bed per room crossfaded at doorways plus a
   sweetener every 5-10 s from ~5 groups x 5 variations; hold it through death and respawn. [23, 24,
   9, 14]
5. Mix by loudness, not peaks: integrated LUFS over a 30-min capture; desktop about -24 (+/-2) LUFS,
   phone about -18 (+/-2) LUFS, true peak <= -1 dBTP. Today's clips span 12.4 LU at an equal -6 dB
   peak. [1, 21, measured]
6. Big impacts must carry mid/high layers so they read on phone and laptop speakers (thud: 99.3% of
   energy below 150 Hz). [measured, 22]
7. Every essential cue has a visual twin, and on phones a haptic twin: under the default iOS Ambient
   category the silent switch mutes the whole game. [5, 7, 20, 25]
8. Separate volumes: Master, Music, gameplay Effects, Ambience, Voice (WOLF and engineer), plus a mono
   toggle. [7]

SHOULD
9. WOLF's voice on top: Voice bus with a sidechain compressor ducking Ambience/Music/Effects; raise his
   choice growls about 8-12 LU relative to the alarms they now sit under. [6, 14, measured]
10. A small breath/effort system for the engineer (cheap ALIVE/INSIDE): calm, exerted, shaken,
    engaged-active (cranking); intensity = low-pass filtered exertion, raised by distance to danger,
    relaxing over seconds; 1 breath per 2 steps when jogging. [2, 8, 9]
11. Mix snapshots: explore, WOLF speaks, Blowback action, sentry alert, death (low-pass "death filter",
    not a cut). [14, 10, 9]
12. Let the machines be the score: tune hums/servos per room, a music layer that "sounds like room
    tone", a distance-to-threat parameter (Fear Emitter idea: up to 4 music layers mixed by
    proximity, per Veca), a survival stinger. [11, 15, 10, 27, 28]
13. Periodic hazards: the warning sound runs on the same clock as the hazard logic. [10]
14. Procedural sounds as parameterised mechanisms (crank speed drives ratchet rate; gauge drives hiss
    blend; motor load drives pitch). [17, 16, 18]
15. Audio QA without listening on Nathanial's Mac: record a bus (AudioEffectRecord) inside the render
    container, check a spectrogram for dropouts, measure LUFS. [9, 26]

COULD
16. Optional audio-cue assist: ping interactables in reach, cue control lost/regained, direction arrow
    on off-screen WOLF subtitles. [25]
17. One cloth brush per stride and small idle sounds that stop when interrupted. [8, 13]
18. Recommend headphones on first run; lower 2D panning strength when on speakers. [5]
19. Duck or skip music stems when the player's own music is playing on iOS (UNVERIFIED in Godot). [5]

## Agreement / disagreement with design-reference-25-games.md (section 8)

- AGREE: room tone as default soundtrack; speed-keyed footsteps (Celeste's contact-frame triggers
  [13] are a simpler 2D form of INSIDE's matrix); breathing as a sequencer; listening duck; clarity
  over density (Bridgett's "wall of noise" [14]); -6 dB peak normalisation works against dynamics
  (now measured: 12.4 LU spread).
- REFINE: "Respawn never breaks audio / 0 ms gap" - INSIDE actually PAUSED Wwise updates through the
  reload and applied queued commands at once, creating "the illusion of no time passing" [9]. Hold,
  don't keep evolving. (The sound itself keeps playing through the load - "retain state and continue
  during load" - so the study's 0 ms gap stands; only state changes are frozen.)
- CORRECT: "Turn it Down 90%" is a Playdead VFX talk (Mikkel Svendsen, Control Conference 2016), not
  an audio talk; its sound-relevant point is that audio can carry ambient facts so visuals can be
  dimmed [12].
- CORRECT (stale fact): the bank now has 6 shared one-shot voices and 7 loops, not 4 and 4; detailed
  clips render at 44.1 kHz.
- NUANCE: "Music only at authored beats; <=1 cue per room, often none" - right for melodic cues, but
  Dead Space ran music "all the time" at a level that "sounds like room tone" [15] and Limbo made
  music out of filtered machine sound [11]; a continuous tonal machine bed is compatible with "few
  cues".
- GAPS FILLED: Dead Space ALIVE (secondary reports; no numbers) [2]; procedural-audio technique
  (Farnell, Fournel, Weir) [16-18]; speaker/phone mix targets (ASWG -24/-18, Apple -16, Godot panning
  note) [1, 5, 21]. STILL OPEN: listening-duck dB/timing from a shipped game; phone speaker low cut-off;
  Bluetooth output latency. (Don Veca primary source: found in fact-check, AUDIO-FEEL-27/28.)

## Pitfalls
- Peak-normalising every clip and calling the mix done (12.4 LU spread at equal peak).
- Calling a sound every frame on a one-shot voice (steals all voices) or on a clip that does not exist
  (silent; play() returns null without a warning).
- Bass-only impacts that vanish on phone speakers.
- Sound-only essentials on iPhone, where the silent switch mutes the Ambient category.
- Sound scheduled before its visual (early sound is detected at ~45 ms, late only at ~125 ms).
- Hard audio cut on death or room change; full digital silence anywhere.
- Companion voice buried under alarms.
- Loops of unequal length or pitch-shifted stems drifting out of sync.
- Claiming audio feel from headless tests: no one has listened to the mix yet.

## Source list (all accessed 2026-10-12)
AUDIO-FEEL-1  Sony Worldwide Studios Audio Standards Working Group. "Average Loudness and Peak Levels of Audio Content on Sony Computer Entertainment Platforms", Recommendation ASWG-R001 v1.10. Sony WWS (hosted by Game Audio Podcast). 2013. https://www.gameaudiopodcast.com/ASWG-R001.pdf
AUDIO-FEEL-2  EA Motive devstream (11 Mar 2022; Terry Calico, Senior VO Designer, per MP1st) as reported by Stefan L (TheSixthAxis, 14 Mar 2022) and Alex Co (MP1st, 11 Mar 2022). "Dead Space remake slated for early 2023 release date". TheSixthAxis. 2022. https://www.thesixthaxis.com/2022/03/14/dead-space-remake-slated-for-early-2023-release-date/ ; MP1st 2022 https://mp1st.com/news/dead-space-remake-release-set-for-early-next-year-new-gameplay-audio-comparison-crawl-out
AUDIO-FEEL-3  ITU-R. "BT.1359-1 Relative timing of sound and vision for broadcasting". ITU Recommendation. 1998. https://www.itu.int/rec/R-REC-BT.1359 (PDF https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.1359-1-199811-I!!PDF-E.pdf)
AUDIO-FEEL-4  Google / Android Developers. "Audio latency" (NDK guide). Official docs. accessed 2026. https://developer.android.com/ndk/guides/audio/audio-latency
AUDIO-FEEL-5  Godot Engine contributors. ProjectSettings class reference (doc/classes/ProjectSettings.xml, branch 4.5) and core/config/project_settings.cpp; Apple, "Audio Session Programming Guide: Audio Session Categories and Modes" (archive). Official docs. 2025 / Apple archive. https://raw.githubusercontent.com/godotengine/godot/4.5/doc/classes/ProjectSettings.xml ; https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionCategoriesandModes/AudioSessionCategoriesandModes.html
AUDIO-FEEL-6  Godot Engine contributors. AudioStreamRandomizer, AudioEffectCompressor, Audio buses. Godot docs (stable). accessed 2026. https://docs.godotengine.org/en/stable/classes/class_audiostreamrandomizer.html ; https://docs.godotengine.org/en/stable/classes/class_audioeffectcompressor.html ; https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html ; https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html
AUDIO-FEEL-7  Microsoft. "Xbox Accessibility Guideline 105" (audio). Microsoft Learn. 2022 (updated 2026). https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/105 ; Game Accessibility Guidelines (collaborative). "Provide separate volume controls or mutes for effects, speech and background/music". https://gameaccessibilityguidelines.com/provide-separate-volume-controls-or-mutes-for-effects-speech-and-background-music/
AUDIO-FEEL-8  Jakob Schmid (Playdead). "The Boy from INSIDE: Uncompromising Character Audio Implementation". AES 2016 talk slides, Playdead publications repo. 2016. https://github.com/playdeadgames/publications/blob/master/INSIDE/schmid-AES_2016-The_Boy_from_INSIDE.pdf
AUDIO-FEEL-9  Martin Stig Andersen & Jakob Schmid (Playdead). "Unbreaking Immersion: Audio Implementation for INSIDE". Wwise Tour 2016 slides. 2016. https://github.com/playdeadgames/publications/blob/master/INSIDE/schmid-Wwise_2016-INSIDE_Audio.pdf
AUDIO-FEEL-10 Jakob Schmid. "Adaptive Audio in INSIDE and 140". SpilBar 41 slides. 2019. https://github.com/playdeadgames/publications/blob/master/INSIDE/spilbar2019-schmid-adaptive_audio.pdf
AUDIO-FEEL-11 Martin Stig Andersen (Playdead). "The Environment is the Orchestra: Soundscape Composition in LIMBO". Talk slides, Playdead publications repo. c.2011 (year UNVERIFIED). https://github.com/playdeadgames/publications/blob/master/LIMBO/Martin_Stig_andersen_audio_SoundscapeCompositionInLimbo.pdf
AUDIO-FEEL-12 Mikkel Svendsen (Playdead; author per file metadata). "Turn It Down 90% - INSIDE VFX". Control Conference 2016 deck. 2016. https://github.com/playdeadgames/publications/blob/master/INSIDE/turn_it_down_90pct.pptx (video https://www.youtube.com/watch?v=vA3uFC2p8eo, not watched)
AUDIO-FEEL-13 Maddy Makes Games (Noel Berry, Maddy Thorson et al.). Celeste Player.cs (released class file, MIT for code only). GitHub. 2018. https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs
AUDIO-FEEL-14 Rob Bridgett. "The Future of Game Audio - Is Interactive Mixing the Key?". Game Developer (Gamasutra). 2009. https://www.gamedeveloper.com/audio/the-future-of-game-audio---is-interactive-mixing-the-key-
AUDIO-FEEL-15 Jason Graves, interviewed by Joey Thurmond. "Interview: The Man Behind the Music - Jason Graves". Push Square. 2015. http://www.pushsquare.com/news/2015/05/interview_the_man_behind_the_music_-_jason_graves ; plus Wikipedia, "Dead Space (2008 video game)" (secondary, Fear Emitters) https://en.wikipedia.org/wiki/Dead_Space_(2008_video_game)
AUDIO-FEEL-16 Nicolas Fournel (SCEE). "Procedural Audio for Video Games: Are we there yet?". GDC Vault. 2010. https://www.gdcvault.com/play/1012645/Procedural-Audio-for-Video-Games
AUDIO-FEEL-17 Andy Farnell. "Designing Sound". MIT Press (book, 688 pp.). 2010. Google Books https://books.google.com/books?vid=ISBN9780262014410 ; Open Library https://openlibrary.org/isbn/9780262014410 ; companion site http://aspress.co.uk/ds/
AUDIO-FEEL-18 Paul Weir (Earcom). "The Sound of 'No Man's Sky'". GDC Vault. 2017. https://www.gdcvault.com/play/1024067/The-Sound-of-No-Man
AUDIO-FEEL-19 Scott Lawlor & Tomas Neumann (Blizzard). "Overwatch - The Elusive Goal: Play by Sound". GDC Vault. 2016. https://www.gdcvault.com/play/1023317/Overwatch-The-Elusive-Goal-Play
AUDIO-FEEL-20 Google / Android Developers. "Haptics design principles". Official docs. accessed 2026. https://developer.android.com/develop/ui/views/haptics/haptics-principles
AUDIO-FEEL-21 Apple. "Audio requirements" (Apple Podcasts for Creators). Official docs. accessed 2026. https://podcasters.apple.com/support/893-audio-requirements
AUDIO-FEEL-22 Steve Swink. "Game Feel: A Game Designer's Guide to Virtual Sensation", ch. 1. Morgan Kaufmann/Elsevier (book). 2009, ISBN 978-0-12-374328-2. Chapter PDF opened at http://mycours.es/gamedesign2014/files/2014/10/Game-Feel-Steve-Swink-chapter-1.pdf
AUDIO-FEEL-23 Michael Taylor. "Room Tone, Emotional Tone: The Importance of Hearing Ambience". Designing Sound. 2012. https://designingsound.org/2012/11/15/room-tone-emotional-tone-the-importance-of-hearing-ambience
AUDIO-FEEL-24 Mark Hollier. "Video game audio under the hood: Eon Altar ambience system". Game Developer. 2016. https://www.gamedeveloper.com/audio/video-game-audio-under-the-hood-eon-altar-ambience-system
AUDIO-FEEL-25 Sony Interactive Entertainment / Naughty Dog. "The Last of Us Part II accessibility". PlayStation.com. 2020. https://www.playstation.com/en-us/games/the-last-of-us-part-ii/accessibility/
AUDIO-FEEL-26 Godot Engine contributors. AudioStreamPlayer, AudioStreamPlayer2D, AudioStreamInteractive, AudioStreamSynchronized, AudioEffectRecord class references (4.5 doc XML). GitHub. 2025. https://github.com/godotengine/godot/tree/4.5/doc/classes ; https://github.com/godotengine/godot/tree/4.5/modules/interactive_music/doc_classes
AUDIO-FEEL-27 Don Veca, interviewed by Jayson Napolitano. Dead Space sound design interview (title as given by the URL slug: "Dead Space Sound Design: In Space No One Can Hear Interns Scream ... Interview"). Original Sound Version. 7 Oct 2008. http://www.originalsoundversion.com/dead-space-sound-design-in-space-no-one-can-hear-interns-scream-they-are-dead-interview/ (added by fact-check)
AUDIO-FEEL-28 Ben Reeves (quoting Don Veca). "Noises In The Dark: Exploring The Sounds Of Dead Space". Game Informer. 11 Dec 2009. https://www.gameinformer.com/b/features/archive/2009/12/11/feature-noises-in-the-dark-exploring-the-sounds-of-dead-space.aspx (added by fact-check)
AUDIO-FEEL-29 Apple. "Playing audio", Human Interface Guidelines. Official design guidelines. accessed 2026-10-13. https://developer.apple.com/design/human-interface-guidelines/playing-audio (read via its JSON data endpoint; added by fact-check)
AUDIO-FEEL-30 Martin Stig Andersen. "A Game That Listens - The Audio of INSIDE". GDC Vault (GDC 2016). https://www.gdcvault.com/play/1023731/A-Game-That-Listens-The (description only: sound "often plays a key role in articulating temporal qualities such as pace, suspense and release"; audio-driven gameplay and the death-respawn sequence; talk not watched; added by fact-check)
Local measurement: WOLF//OVERRIDE SfxBank clips dumped headless (Godot 4.7.2) and measured with pyloudnorm; scripts in scratchpad tools/dump_sfx.gd and tools/measure.py; clips in play-research/dl-audio-feel/clips/ (not for the repo).

## Fact-check (independent, 2026-10-13)

Method: re-downloaded every primary PDF/deck/source file myself (Playdead decks via GitHub LFS media
URLs, ASWG, ITU BT.1359-1, Swink ch. 1, Celeste Player.cs, Godot 4.5 and 4.7.2-stable XML/C++),
extracted text with PDFKit, and fetched every web source again. Re-dumped the SfxBank clips headless
and re-measured them with my own BS.1770 code. Working files: play-research/fc-audio/.

Confirmed exactly (quotes and numbers match the source): AUDIO-FEEL-1 (all targets, 30 min, LKFS=LUFS,
point g), 3 (+45/-125, +90/-185 ms), 4 (45 ms, 20 ms, 10 ms, 96-512 frames, silent warm-up), 5 (15/50
ms, ignored on Android, 0.5 panning, session_category 0 = Ambient; Apple table), 6, 7 (6 categories,
mono, <3 s exemption, Grounded six, "noisy room or ... device sound off"), 8, 9 (pause, 2 MB, 1024
samples, 256-sample zeros, spectrogram, PCM/vorbis q10, lowpass-filtered exhaustion, soft exhale /
hard grunt, proximity to danger), 10 (all 140 rules and numbers), 12, 13 (frames 0/6, 0.5 s,
Rumble Light/Short, idle sounds cancelled), 14 (three quotes; no dB/ms given), 16, 17, 18, 19, 20 (all
four quotes), 21, 23, 25 (incl. "Aiming at an enemy", "Landing a shot on an enemy"), 26; the
main.gd:970/1767 `hiss` bug; the call gains behind the 8-12 LU derivation.

Changed:
- AUDIO-FEEL-1: "noisier places" reworded to the source's "different environments" / "varying noise floors".
- AUDIO-FEEL-2: creators fixed (Stefan L, TheSixthAxis; Alex Co, MP1st); only MP1st names Calico.
- AUDIO-FEEL-5: confirmed for 4.7.2-stable (the pinned engine); line 1760 there.
- AUDIO-FEEL-8: the AES deck itself carries the 6 footstep speed bands (values added); date Feb 2016.
- AUDIO-FEEL-9: nuance added: the sound keeps playing through the load; only state is held.
- AUDIO-FEEL-11: the foundry was interpolated with an orchestra, not filtered (the engine and saw are
  the filter examples); PDF made 2011-03-21 on a GDC template, event still UNVERIFIED.
- AUDIO-FEEL-14: the "ambience never disappears" line describes film practice.
- AUDIO-FEEL-15: zero-gravity caveat added; Fear Emitters upgraded from Wikipedia-only to primary
  Veca quotes (new AUDIO-FEEL-27, 28), with numbers: 4 layered stereo music streams, up to 4 layers
  per emitter, ambient tracks of 2-3 minutes.
- AUDIO-FEEL-22: "sound gives the clues" broadened to all polish; book ISBN added; PDF is a course copy.
- AUDIO-FEEL-24: "primed silent" was an interpretation; the article says "(playing at 0db)". UNVERIFIED.
- Measurement: independent re-dump and re-measure agree (within 0.1 LU); true peak up to 0.7 dB over
  sample peak; startup render 31-112 ms across two runs (was given as 112 ms).
- Added AUDIO-FEEL-29 (Apple HIG: silent mode silences "game soundtracks"; games are the example for
  Ambient/Solo ambient) and AUDIO-FEEL-30 (Andersen, GDC 2016, description only).

Could not verify (left UNVERIFIED): Limbo deck's event/year; Eon Altar primed-bed level;
secondaryAudioShouldBeSilencedHint (not on the Apple page opened); any shipped game's duck depth or
time; phone-speaker bass cut-off; Bluetooth latency; A.L.I.V.E. numbers; the devstream video itself.
The researcher's footstep randomizer values (pitch 1.05, 2 dB) are their own suggestions, not sourced.
