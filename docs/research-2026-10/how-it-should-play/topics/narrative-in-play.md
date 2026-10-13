# Story told through play — research notes (WOLF//OVERRIDE)

Researcher: Claude (Opus 5.5) for Nathanial Henniges. Started 2026-10-12. All sources accessed 2026-10-12.
Scope: how narrative games keep the player playing while the story is told: control kept with the player,
walk-and-talk, barks, wordless storytelling, Half-Life without cutscenes, ludonarrative harmony/dissonance,
meaningful choices and how players notice them, dialogue length and on-screen reading speed.
Builds on docs/research-2026-10/design-reference-25-games.md (which covers companions, levels, death, case,
action, presentation, audio, mobile but has NO section on dialogue delivery, reading speed, barks, cutscene
policy or choice signalling).

## Current code (checked 2026-10-12, apps/game/scripts/main.gd)
- One text box (`status_line`) carries narration, WOLF and Director lines, hints and choices.
- READ_SECONDS_PER_WORD 0.15 (= 400 wpm), READ_SECONDS_MIN 2.5, READ_SECONDS_MAX 7.0; used only to decide when
  the stakes line may replace the previous box (`_read_seconds`).
- Opening: INTRO_LINES = 7 press-to-advance beats, controls off (`intro_active`), "SKIP OPENING" in pause.
- Choices: `waiting_for_choice` sets human.controlled false (movement frozen while a choice is up); no timer.
  Two choices so far: relay (DISCLOSE/PRESS) and lane bait (draw it / stay back).
- Callback: WOLF's bait answer names the relay choice openly ("You told me the truth at the relay...").
- END OF SLICE card recaps the run's choices (RELAY / MIRROR / LANE rows).
- Longest lines found: e.g. BAIT_NO_LINE 29 words; TANK_HIT_LINE ~26 words over 2 rows; JUNCTION_ENTRY_LINE ~25 words.

## Findings (in progress)

### F1. On-screen reading speed: broadcast/streaming subtitle norms [NARRATIVE-IN-PLAY-1 BBC], [NARRATIVE-IN-PLAY-2 Netflix English], [NARRATIVE-IN-PLAY-3 Netflix general]
- BBC Subtitle Guidelines (living doc, v1 Sept 2016, current online): "The recommended subtitle speed is 160-180
  words-per-minute (WPM) or 0.33 to 0.375 second per word." Minimum target "around 0.3 seconds per word
  (e.g. 1.2 seconds for a 4-word subtitle)". Max 2 lines for 16:9 (3 for 9:16 vertical). Line length:
  broadcast 37 characters; online 68% of the width of a 16:9 frame (90% for 9:16); "37 characters in a 75%
  width region of a 16:9 video is 25 characters in a 90% width region of a 9:16 video". Gaps between
  subtitles: "a minimum of one second, preferably a second and a half" [FACT-CHECK: this applies only "If there is
  a pause between two pieces of speech, you may leave a gap"; it is not a required gap between every pair of
  subtitles. For continuous dialogue Deryagin [13] says most style guides use ~100-200 ms.] Speakers: colours are
  "the preferred method"; '<'/'>' arrows for off-screen voices (s7.7); labels in white caps only when unclear who
  speaks (s7.8). [FACT-CHECK: page opened via curl 2026-10-12 shows "Subtitle Guidelines Version 1.2.5 March 2026";
  v1 was September 2016.] The doc warns that word count alone is "an unacceptably crude
  approach"; give extra time for unfamiliar words, several speakers, labels, visuals.
- Netflix English (USA) Timed Text Style Guide: 42 characters per line, max 2 lines, up to 20 characters/s
  adult, 17 characters/s children; bottom-heavy pyramid line breaks; break after punctuation, before
  conjunctions/prepositions. Netflix General Requirements: minimum 5/6 s (20 frames at 24 fps), maximum 7 s
  per event.
- Conversion: 20 cps at ~5.5-6 chars/word incl. space ≈ 200-220 wpm; 17 cps ≈ 170-185 wpm. BBC 160-180 wpm.
  So the "film/TV ceiling" is ~0.3-0.375 s/word, with min ~0.83-1.2 s and max ~7 s on screen.
WHAT IT MEANS FOR WOLF: main.gd's READ_SECONDS_PER_WORD = 0.15 s (400 wpm) is more than 2x faster than every
  subtitle standard. It only gates the stakes line today, but if it becomes the auto-advance for walk-and-talk
  lines it would cut text off. Use 0.33 s/word (180 wpm) + ~0.5-1.0 s base, min 1.5 s, max 7 s, and let USE
  advance early. Keep lines to 2 rows of ≤ ~40-42 chars desktop; phone at 960x540 logical needs the box width
  checked (BBC: same text gets ~25 chars in a narrow frame).

### F2. Half-Life: story without taking control away (Valve, primary) [NARRATIVE-IN-PLAY-4 Birdwell 1999], [NARRATIVE-IN-PLAY-5 HL2 commentary 2004/2024], [NARRATIVE-IN-PLAY-6 Episode One commentary 2006], [NARRATIVE-IN-PLAY-7 Episode Two commentary 2007]
(Commentary text read from the Combine OverWiki transcription of Valve's in-game developer commentary; the
 cn_* nodes are the Half-Life 2 20th Anniversary commentary, 2024.)
- Birdwell (Game Developer/Gamasutra, Dec 1999): "experiential density" = "the amount of 'things' that happen
  to and are done by the player per unit of time and area of a map"; "the game world must acknowledge players
  every time they perform an action"; "once active, the player never had to wait too long before the next
  stimulus"; "players should always blame themselves for failure". 200+ playtest sessions; first 20-30 were
  "absolutely critical"; ~100 action items per 2-hour session; telemetry of position, health, deaths, time.
- HL2 cn_146_storytelling (Bill Van Buren): immersion "led us to the self-imposed constraints of never – or
  at least very rarely - taking control away from the player and of keeping the player's avatar silent."
- HL2 cn_128_strider (Doug Wood): "it takes a lot of small tweaks to ensure that as many players as possible
  are looking at the right place at the right time"; street layout and a Metrocop scene frame the reveal.
- HL2 cn_134_the_citadel (Eric Kirchmer): "despite its massive size, playtesters often missed it"; fix: birds
  flying toward it.
- HL2 cn_016_elis_lab (Dhabih Eng): "players wanted to play along with the scene—they just needed enough
  subtle clues"; "if they got distracted, the scene had to gently pause and wait for them to return."
- HL2 cn_017: players would not explore "until they were sure they wouldn't miss any of the character
  performances"; Eli tells them to look around midway to signal it is safe.
- HL2 cn_114_natural_storytelling (Van Buren): NPCs deliver lines when the player approaches; "Giving players
  control over how much story they engage with—without it blocking progress— is a goal we always try to
  maintain".
- HL2 cn_136_the_raid (David Sawyer): "we design Half-Life to let players set their own pace"; forcing pace is
  hard and must be made legible.
- HL2 cn_135_close_captions (Yahn Bernier): full closed captions for all sounds, prioritised so "dialogue
  needed to stand out, and it had to be clear who was speaking".
- Ep1 falling_debris (Matt T. Wood): "Since we never take control away from the player, it can be a real pain
  to get them to notice important environmental events"; a light show "took ten of us two months" and the
  player may be "staring at a tire"; fix: Alyx names it and points: "not foolproof, but it has a high success
  rate."
- Ep1 alyxnag (Matt T. Wood): "after about three minutes of this, the one thing it definitely did was make the
  player hate Alyx"; led to Alyx "almost always following"; players "disliked virtually any hint of bossiness".
- Ep1 powerboxes (Jake Nicholson): waiting for Alyx to operate power boxes: "Playtesters were more annoyed than
  entertained"; "whenever Alyx commits to some action in a dynamic environment, she needs to finish it quickly
  and move on."
- Ep1 Kleiner transmission: train horn -> Alyx line -> lights out so monitors stand out; the jumbotron version
  failed ("never able to reliably make playtesters look at it"); a zombie draped over the exit is "designed to
  slow the player down just long enough for Alyx to finish her lines." (node advisorsighting, Matt Scott)
- [FACT-CHECK ADDITION] Ep1 alyxcitadeltone (Bill Van Buren): urgency acted through Alyx "proved to be
  unsustainable" because if the player did not advance "Alyx eventually ran out of lines or animations"; Valve made
  her "always content to proceed at whatever pace the player chooses", and "lines where Alyx sounded impatient or
  frustrated with the pace of progress quickly stood out and were cut." (Direct support for WOLF never nagging.) Ep1 strollwithbarney: Barney moved so
  his scene plays before exploration; given a plausible long-term idle in case players dawdle.
- Ep2 (EP2-Comment072, Ken Birdwell, guardian lair): having the Vortigaunt say the rule "communicating our expectations to the player,
  rather than having them learn by dying."
WHAT IT MEANS FOR WOLF: (a) Keep the engineer moving during almost all story; the 7-beat press-to-advance
  opening is the one exception and should stay short and skippable. (b) To get the player to see a reveal in a
  side view, frame it in the walking direction, add motion (Valve's birds), sound first, then a WOLF line that
  names and points. (c) Story stations (Records terminal, purge display) should wait for the engineer, pause if
  they walk away, and resume. (d) WOLF must never nag ("Hurry"), lead bossily, or make the player wait while
  he works: the relay contact and seam reading should be short (Valve: "finish it quickly and move on"). (e) A
  soft physical slow-down (a narrow gap, a crouch under a pipe) can buy time for a line without stopping the
  player.

### F3. Game subtitle standards and reading-rate science [NARRATIVE-IN-PLAY-8 XAG 104], [NARRATIVE-IN-PLAY-9 Game Accessibility Guidelines], [NARRATIVE-IN-PLAY-10 Brysbaert 2019], [NARRATIVE-IN-PLAY-11 Hamilton GDC 2019 abstract], [NARRATIVE-IN-PLAY-12 CMF/Johnson 2019], [NARRATIVE-IN-PLAY-13 Deryagin 2017]
- Xbox Accessibility Guideline 104 (Microsoft Learn, ms.date 2022-05-09, page updated 2026-06-17): name the speaker
  "each time a new speaker begins talking", again after a pause "greater than 1-2 minutes"; colour only together
  with text; "(on radio)" style tags and "<"/">" arrows for off-screen speakers/sounds; captions for important
  non-speech sounds with direction; separate toggles for conversation, bark and cinematic subtitles (Outer
  Worlds example); "Avoid long lines of text (more than 40 characters)"; "no more than two lines"; manual line
  breaks; mixed case; sans-serif option; background opacity adjustable 0-100%; text scalable to 200%;
  subtitles on by default or set before the first cinematic; developers "encouraged to offer larger minimum
  default sizes" for subtitles because they are on screen briefly.
- Game Accessibility Guidelines (collaborative; studios, specialists, academics; Ian Hamilton is a co-author):
  "no smaller than 46px@1080p"; "no more than 40 characters per line"; "two lines per subtitle (sometimes three,
  in exceptional circumstances)"; name tags + speaker colour; solid/semi-opaque background. The wpm page gives
  no figure itself and defers to BBC/Ofcom.
- Brysbaert, "How many words do we read per minute? A review and meta-analysis of reading rate" (J. Memory and
  Language 109, 2019; preprint PsyArXiv 2019-04-12): 190 studies, 18,573 participants; adult silent reading
  238 wpm non-fiction, 260 wpm fiction; most adults 175-300 wpm (non-fiction), 200-320 (fiction); oral reading
  183 wpm; slower for children, older adults and second-language readers.
  => 400 wpm (WOLF's 0.15 s/word) is faster than nearly every adult's silent reading; 180 wpm (0.33 s/word)
  covers the slow end (175 wpm) and matches BBC.
- Ian Hamilton, "Subtitles Are Changing, Don't Be Left Behind" (GDC 2019, Advocacy; abstract only, video
  members-only): "most players choose to play with subtitles turned on". Relayed statistic (CMF, Maxime Johnson,
  2019-04-12, citing Hamilton's GDC talk): "More than 60% of the players activated the subtitles in Assassin's
  Creed Origins" (Ubisoft data; primary not opened: relayed only). Johnson relays 46 px subtitle / 32 px static
  UI text at 1080p. [FACT-CHECK: CMF attributes the 46 px figure and "38 characters per line" to the BBC; the BBC
  guide itself says 37 characters and the 46 px@1080p figure is GAG's [9]. Use GAG/BBC directly, not CMF.]
- [FACT-CHECK ADDITION, primary] David Tisserand (Ubisoft accessibility), tweet thread 2019-06-25 [37], opening
  tweet (read via Twitter oEmbed): "~60% of @assassinscreed Origins players turned ON the subtitles" (the 2018
  figure; "subtitles off by default" is NOT in the tweet: UNVERIFIED). The rest of the thread was not opened; relayed by Shazoo (2019-06-27) [38]:
  Far Cry New Dawn 97% and Assassin's Creed Odyssey 95% of players kept subtitles on; The Division 2 (off by default)
  75% turned them on at least once. 95/97/75%: relayed (secondary), thread tweets 2-4 UNVERIFIED.
- Max Deryagin (md-subs.com, 2017): "an epidemic of microscopic subtitles" across indie and AAA; recommends
  45-50 characters per line for games (vs 42 film) and a 100-200 ms gap between continuous subtitles; says he
  surveyed "several hundred" games (count not given: UNVERIFIED).
WHAT IT MEANS FOR WOLF: the game is text-first (humans are written-only; WOLF optional TTS). Treat the dialogue
  box as subtitles: name tag every speaker change (already "WOLF:"/"DIRECTOR:"), give WOLF a fixed colour plus
  the name, ≤ 40-42 chars/line, ≤ 2 lines per box (3 only at choices), mixed case (stencil-style ALL CAPS only for
  props), ≥ 46 px at 1080p equivalents (scale to 960x540 logical: ≥ 23 px), a solid/opaque backing option,
  size option to 200%. On phone at 960x540 logical the box must be checked in a render capture. When WOLF is
  off-screen his line needs a direction cue ("WOLF (left):" or an arrow) because XAG and BBC both ask for it and
  the design reference already plans an off-screen edge cue.

### F4. Choices players notice [NARRATIVE-IN-PLAY-14 Meier GDC 2012 via Alexander], [NARRATIVE-IN-PLAY-15 Fendt et al. ICIDS 2012], [NARRATIVE-IN-PLAY-16 Wikipedia TWD]
- Sid Meier, GDC 2012 "Interesting decisions" (reported by Leigh Alexander, Game Developer, 2012-03-07): bad
  choices are ones where players always pick the same option or pick randomly; good ones have tradeoffs, are
  "situational", allow personal expression; err toward "providing the player with too much information"; "The
  worst thing you can do is just move on. There's nothing more paranoia-inducing than having made a decision
  and the game just kind of goes on."
- Fendt, Harrison, Ware, Cardona-Rivera, Roberts, "Achieving the Illusion of Agency" (ICIDS 2012, Springer LNCS
  7648; NC State). Text story with 6 forced choices. Three versions: branching (79 readers; 52 on the compared
  path), non-branching WITH immediate textual feedback acknowledging the choice (54), non-branching with minimal
  feedback (44). Result: no significant difference between branching and acknowledged-non-branching in most
  agency questions; branching beat minimal feedback on every story-level question (p ≤ 0.05). Branching still
  beat acknowledged on "I felt that the story would have been different if I had selected different choices"
  (p = 0.05). Higher-agency choices were those with severe consequences or "two seemingly distinct story paths"
  (free the orc, how to attack); lower were "two different means to the same end" (which weapon). Caveat: text
  only, online snowball sample, CYOA priming.
  [FACT-CHECK CORRECTION, from the PDF, Table 2 and s5]: (1) the branching story had BOTH immediate feedback AND later
  callbacks to the choice; the acknowledged non-branching story had immediate feedback only, never referenced again.
  (2) Branching vs acknowledged: no significant difference on Q1-3 and Q5 (Q5 marginal, p = 0.084), but branching
  higher on Q4 "story would have been different", p = 0.030. (3) Branching vs minimal: significant on all six
  story-level items (p 0.003-0.032; Q6 is "would play again", not agency). (4) CRUCIAL: acknowledged vs minimal
  (both non-branching) differed significantly on only ONE item (Q2 "important to the progression", p = 0.039); the
  authors write "We failed to prove the second hypothesis". So the paper does NOT show that immediate
  acknowledgement by itself carries most felt agency; it shows acknowledgement can approach branching on most items,
  while branching + later callbacks beat no feedback everywhere. (5) The "severe consequences / distinct paths vs
  means to the same end" split is the authors' hypothesis ("We do not have sufficient data to make decisive
  claims"). (6) Groups were unbalanced (Story 1 downselected: 20 men/32 women; Story 2: 47/7; Story 3: 33/11).
  Design implication still holds, more modestly: acknowledge at once (Meier [14]) AND call the choice back later
  (what the branching condition had).
- Telltale's The Walking Dead (2012; via Wikipedia, secondary): a "choice notification" signals changes in
  characters' attitudes and can be disabled; timed responses where, if no selection, "Lee will remain quiet,
  which can affect how other characters respond"; writers aimed for neutral wording "to create an even split
  among player decisions"; "Although choices were designed to seem significant, they often had little effect on
  the larger narrative." (Exact on-screen wording "X will remember that" not verified from a primary here.)
WHAT IT MEANS FOR WOLF: (a) Acknowledge every choice IMMEDIATELY in the world (WOLF's posture, a line, an action)
  — this is where most of the felt agency comes from (Fendt), and silence after a choice is the worst case
  (Meier). (b) Then pay off a FEW choices visibly later; WOLF's bait answer naming the relay choice already does
  this, and the END OF SLICE recap does it again. (c) Make choices about distinct paths/values (honesty vs
  rushing WOLF; risking WOLF vs doing it yourself), not "two means to the same end". (d) Do not show a "WOLF
  will remember that" banner: the project forbids a visible morality meter, and Fendt shows diegetic feedback
  text works; show it through WOLF instead. (e) Do not freeze movement for a long time at a choice; consider
  letting the engineer keep walking while the two answers stay up (Oxenfree), with silence as a valid outcome
  only if it is authored (Telltale/Firewatch) — never a hidden fail.

### F5. Portal / Portal 2: a talking machine while you play (Valve commentary, primary) [NARRATIVE-IN-PLAY-17 Portal 2007], [NARRATIVE-IN-PLAY-18 Portal 2 2011]
(Read from the Combine OverWiki transcription of the in-game developer commentary.)
- Portal 2 com-accents (Erik Robson): a breakout scene with Wheatley and GLaDOS talking was cut because "every
  player made a beeline for the opening. So we either had to ditch all the dialogue or figure out a reason for the
  player to stand around for five minutes even though they could escape at any time. We ditched the dialogue."
- Portal 2 com-slowburn (Elan Ruskin): GLaDOS was more cutting early; "Playtests revealed, though, that it was a
  bit grueling getting brow-beaten by GLaDOS this early in the game", so her arc became a slow burn.
- Portal 2 com-cowrite (Chet Faliszek): in single player "you can count on players paying attention"; for co-op
  they "broke up the story beats into smaller sections so players don't become impatient", repeated points, and
  after a death "there is a two second beat for you to laugh or yell before GLaDOS speaks."
  [FACT-CHECK 2: the stated purpose is co-op: "give players room to talk" to each other. Using it for a single-player
  death screen is an analogy, not what Valve measured.]
- Portal 2 com-eyehasit (Karen Prell): Wheatley talks with no mouth: "body language, head attitudes and rhythm of
  movement and eye focus"; slow head moves/steady gaze = calm; "Short, sharp head turns, rapid blinks" =
  nervousness or deceit; constricted aperture + shiver = fear; when hacking, his parts "become perfectly centered
  and spin mechanically" to remind you he is a machine.
- Portal 2 com-fatigue (Marcus Egan): after many hard chambers, a funnel ride gives "a short break while reminding
  them of the facility's state of disrepair" (story beat used as rest).
- Portal com-095 (Erik Wolpaw): GLaDOS is monotone before the fire-pit escape, then "progressively more
  expressive" (character arc carried by delivery). Portal com-077: lots of backstory "crammed ... into the
  environments" (Ratman dens) rather than said.
WHAT IT MEANS FOR WOLF: (a) A line placed where the player can leave will be walked away from: don't hang story on
  a room the player is trying to exit (the junction exit hatch, the Records door). Either let the line continue as
  the pair walk (walk-and-talk) or put it on the walk itself. (b) WOLF's early tone should be a slow burn: angry at
  the Director, not lecturing the engineer. (c) After a death, give a ~2 s quiet beat before WOLF's capped line
  (matches the approved Cold Still death screen). (d) WOLF's optic and head carry subtext: calm = slow head and
  steady optic; unease = quick turns and flicker; working = centred, mechanical motion. This is how a wolf robot
  "talks" without a mouth (also supports the design reference's "expression over cognition").

### F6. Oxenfree: walk-and-talk with no cutscenes (Night School Studio) [NARRATIVE-IN-PLAY-19 Francis/Game Developer 2015], [NARRATIVE-IN-PLAY-20 Road to the IGF 2016], [NARRATIVE-IN-PLAY-21 Wikipedia Oxenfree]
- Sean Krankel (to Bryant Francis, Game Developer, 2015-12-17): "We decided to have no cutscenes. We used dialogue
  bubbles that grow from characters and are tethered to them visually, instead of having subtitles sitting off to
  the side." "each line can only last so long as the player goes from point A to point B, and how many
  interactable objects you introduce between those points expands the amount of dialogue that can occur." In a
  4-5 character beach argument "the conversation system gets to do 90% of the work", but alone with one
  character open space "was almost too open-ended". Story thresholds fire on in-game hours so Hines knows what
  characters know.
- Road to the IGF (Game Developer, 2016-02-04), Krankel: "why not let you move freely while communicating,
  interacting, and exploring a branching narrative?"
- Wikipedia (secondary) on the system: 2-3 options appear in bubbles over Alex; the player can wait, interrupt or
  stay silent; "At its core, we wanted to never have a cut scene in the game, where you could walk and move freely"
  [FACT-CHECK 2: Wikipedia gives this quote with no speaker (it follows a Krankel quote; ref [8]); "Hines" is
  UNVERIFIED, attribute it to Night School Studio].
  (Exact bubble timeout not found in a primary: UNVERIFIED.) Wikipedia also says certain options pop a thought
  bubble over a character "suggesting that the player's choice had an effect on the characters' relationship"
  (an in-world choice acknowledgement).
- [FACT-CHECK CORRECTION] The 2016 Road to the IGF interview is by Bryant Francis (Senior Editor), not "staff".
  Krankel's "almost too open-ended" quote is about free Z-space (depth) movement when the player is alone with one
  character; the fix was "moving through 2-D snakey environments, which lets chunks of conversation easily push you
  from point A to point B." The researcher's reading "give WOLF something to do or look at" is NOT what Krankel said;
  the sourced lesson is that a constrained 2D path (which WOLF//OVERRIDE's side view already is) carries a two-person
  conversation well.
WHAT IT MEANS FOR WOLF: (a) Tether text to the speaker in the world (a small box or line above WOLF/the engineer)
  for barks; keep the bottom box for long or important lines. (b) Size conversations to the walk: a 1.5-2 view
  room is ~5.6-7.5 s of jogging (design reference), i.e. ~2-3 short lines at 0.33 s/word + base; more lines need
  more interactables or a slower walk segment. (c) Two characters alone (engineer + WOLF) is exactly the case
  Krankel found "too open-ended" in free depth movement; Night School's fix was a constrained 2D path, which the
  side view already gives. [FACT-CHECK: original "give WOLF something to do or look at" was not in the source.]

### F7. Wordless storytelling in side-view cinematic games [NARRATIVE-IN-PLAY-22 Nutt/Jensen 2012], [NARRATIVE-IN-PLAY-23 Wikipedia Journey], [NARRATIVE-IN-PLAY-24 GDC Vault Designing Journey 2013], [NARRATIVE-IN-PLAY-25 Wikipedia Brothers], [NARRATIVE-IN-PLAY-26 Wikipedia Another World], [NARRATIVE-IN-PLAY-27 GDC Vault Chahi 2011], [NARRATIVE-IN-PLAY-28 Wikipedia Inside]
- Limbo (Arnt Jensen to Christian Nutt, Game Developer "Hanging in Limbo", 2012-02-24): "I think it's great when
  you're done playing it, you're still thinking about it. It's not supposed to be, 'It's like that, and that's how
  it is.' I hate that." "I think it's pretty important to have the right feelings throughout the game. I don't know
  if it's that important if it's specific storytelling."
- Inside (Wikipedia, secondary): "mostly silent, with the exception of occasional musical cues, the boy's vocals,
  dogs barking, equipment and sound effects"; continuous play without traditional cutscenes; meaning left open.
- Journey (GDC Vault abstract, Jenova Chen 2013): "It took thatgamecompany three years to develop a two-hour long
  video game." Wikipedia (secondary, citing Gamasutra GDC 2012 and Chen's D.I.C.E. 2013 talk via Destructoid):
  only a wordless shout whose length/volume follows the button press; no usernames until the credits because text,
  voice or names would let "players' biases and preconceptions" come between them; murals and between-level
  visions carry backstory; Chen said "3 of their 25 testers had cried" (relayed; primary talk not opened).
- Brothers: A Tale of Two Sons (Wikipedia, secondary): one stick per brother; dialogue in an invented language, so the
  story is "conveyed through actions, gestures and expressions"; at the end the younger brother must use the older
  brother's button to swim: control scheme as story (ludonarrative harmony).
  [FACT-CHECK: the Wikipedia page opened does NOT say the player uses the older brother's input to swim; it only says
  Naiee swims "with Naia's spiritual guidance". Primary added: Josef Fares to Kyle Hilliard, Game Informer
  "Afterwords" 2013-09-27 [39]: "you connect with your left hand to the bigger brother and right hand to the little
  brother"; losing the left stick gives "that feeling that you're missing something"; the ending, where "you get the
  strength from the big brother to go on with your life", is "the essence of the whole game itself". The exact
  input used for the swim is still not stated word for word in an opened source: treat "the older brother's
  button" as UNVERIFIED wording; the control-scheme-as-story point is verified.]
  [FACT-CHECK 2 (2026-10-13): now VERIFIED in [39]. Hilliard asks about "the final puzzle of the game, where you have
  to swim by yourself"; Fares answers "pushing the button for the other brother was actually something that came up
  later" and "by pushing the button and getting the strength from him ... it is the essence of the whole game itself".]
- Another World (Wikipedia, secondary; Chahi's GDC 2011 Classic Postmortem exists, free video, not transcribed
  here): ~2 years solo development; little to no language or UI; in-engine cutscenes that flow into play; the alien
  companion "Buddy" rescues the hero at key moments. [FACT-CHECK: Wikipedia says "cinematic effects in both
  real-time and cutscenes"; "cutscenes that flow into play" is not stated there: UNVERIFIED. Likewise the Inside
  page says "mostly silent" but does not say "continuous play without traditional cutscenes": UNVERIFIED. Journey
  per the GDC abstract is a "two-hour long" game (not 2-3 h). The Journey murals: Wikipedia says "Art adorns the
  walls of many areas, describing the rise and fall of the civilization" plus visions at shrines.] (Fills the design reference's missing Another World card only
  at summary level.)
WHAT IT MEANS FOR WOLF: the genre WOLF//OVERRIDE sits in (Limbo, Inside, Another World, Little Nightmares, Planet of
  Lana) tells almost everything without words. WOLF//OVERRIDE is deliberately more verbal (an investigation, a
  talking companion, choices). So: (a) say with the world first (the purge display, the Director's monitors, the
  empty dock), and use words only for what pictures cannot carry (who ordered what, what WOLF feels about it).
  (b) Short cutscenes should flow straight into control from the same frame (Another World, Inside): the opening
  should end with the engineer already standing where play starts, no fade-to-black if avoidable. (c) Leave room
  for interpretation in optional records (Jensen), but not in the core stakes (the design reference already made
  the stakes line required).

### F8. Ludonarrative harmony and dissonance [NARRATIVE-IN-PLAY-29 Hocking 2007], [NARRATIVE-IN-PLAY-30 Wikipedia Ludonarrative dissonance], [NARRATIVE-IN-PLAY-31 Wikipedia God of War 2018]
- Clint Hocking, "Ludonarrative Dissonance in Bioshock", Click Nothing blog, 2007-10-07: "Bioshock seems to suffer
  from a powerful dissonance between what it is about as a game, and what it is about as a story." The mechanics
  (the ludic contract) reward self-interest (harvesting Little Sisters for ADAM); the narrative contract obliges the
  player to help Atlas: "I am constrained by the design of the game to help Atlas, even if I am opposed to the
  principle". Freedom is offered in mechanics and withheld in story.
- Wikipedia (secondary): later uses: the Uncharted series' likeable hero who kills hundreds; Uncharted 4 has a
  trophy literally named "Ludonarrative Dissonance" for 1,000 kills; Neil Druckmann said the studio did not buy the
  criticism. Harmony examples given: Papers, Please, Journey.
- God of War (2018) (Wikipedia, secondary): one continuous camera shot, no cuts or loading screens, for "a more
  intimate and player-controlled experience" [FACT-CHECK: Wikipedia's paraphrase ("Barlog said they wanted a more
  intimate and player-controlled experience"), not a direct Barlog quote]; Barlog said "about forty percent of the team did not originally agree"
  because of the extra work.
WHAT IT MEANS FOR WOLF: the theme is "belonging WITH, not TO"; WOLF is not property. Dissonance risks: (1) a verb
  that commands WOLF (the project already forbids it; keep requests as asks he may refuse). (2) Rewarding the player
  for using WOLF as bait with an easier route while the story says the bond matters (the design reference already
  says the engineer-only route should cost time, not progress — consistent). (3) A trust number on screen turning
  care into farming (forbidden already). (4) The Blowback action beat: smashing a sentry is fine (machines); keep any
  human harm out of the engineer's verbs so the investigation story ("expose, not punish") matches what the hands
  do. Harmony to aim for: the engineer's verbs are maintenance verbs (crank, reroute, copy, secure) — the story is
  an engineer's story, told with an engineer's hands.

### F9. Player-paced text, replay and the current dialogue box [NARRATIVE-IN-PLAY-32 GAG full list], [NARRATIVE-IN-PLAY-33 Apple HIG Typography]
- Game Accessibility Guidelines full list: "Allow players to progress through text prompts at their own pace"
  (Basic, cognitive); "Allow all narrative and instructions to be replayed" (Advanced); "Do not make precise timing
  essential to gameplay – offer alternatives, actions that can be carried out while paused, or a skip mechanism";
  "Offer a means to bypass gameplay elements that aren't part of the core mechanic"; "Provide a visual indication of
  who is currently speaking"; "Use simple clear language".
- Apple HIG Typography (developer.apple.com, current): iOS/iPadOS default 17 pt, minimum 11 pt; macOS 13/10 pt;
  "you need to test game text for legibility on each platform on which your game runs"; avoid light weights.
  (Phone pt-per-viewport-px conversion is already in topics/mobile-performance.md: 17 pt ≈ 23-25 viewport px.)
- Current box (scenes/main.tscn, checked 2026-10-12): BottomBar 892x82 px at 960x540; Speaker label 15 px; Story label
  17 px, 715 px wide with a speaker tag (855 px without), autowrap, ~3 rows fit.
  MEASURED (godot --headless, isolated HOME, Font.get_string_size on Roboto-Regular.tres with two real WOLF lines,
  script in scratch narr-measure/measure.gd): 17 px = 7.26-7.41 px per character -> ~97-99 characters per row with a
  speaker tag, ~115-118 without. 19 px: ~86-88 / ~103-105. 22 px: ~75-76 / ~89-91. 24 px: ~68-70 / ~82-84.
  So today's rows are ~2.3-2.8x the 37-42 characters of BBC/Netflix/XAG. At 24 px a ~430 px text column gives ~42
  characters. 17 px is also below 23 px (46 px@1080p scaled to 540) and about 12.4 pt on an iPhone 15 landscape:
  above Apple's 11 pt minimum, below its 17 pt default. (Rendered look not checked: headless measurement only.)
WHAT IT MEANS FOR WOLF: long rows are hard to read quickly (XAG: "longer lines of text are harder to read"). Options:
  (a) raise the Story font to ~22-24 px so rows naturally hold ~55-65 chars; (b) or keep 17-19 px but cap the text
  column to ~420-480 px (≈ 42-50 chars) and break lines by hand; (c) add a TEXT SIZE setting to 200%; (d) a pause-menu
  LOG of the last ~10-20 lines (GAG "replayed"); (e) auto-advanced walk-and-talk lines must also respond to USE, and
  essential lines never auto-dismiss before 0.33 s/word + base. All need a rendered capture at desktop and phone
  sizes before any claim.

### F10. Barks: short reactive lines (Valve, Microsoft) [NARRATIVE-IN-PLAY-34 Ruskin GDC 2012], [NARRATIVE-IN-PLAY-5], [NARRATIVE-IN-PLAY-6], [NARRATIVE-IN-PLAY-8]
- Elan Ruskin (Valve), "AI-driven Dynamic Dialog through Fuzzy Pattern Matching. Empower Your Writers!", GDC 2012
  (free video; abstract read; slides site elanruskin.com no longer resolves): Left 4 Dead's characters pick lines by
  "fuzzy pattern matching against a database of thousands of possible lines", tracking "hundreds" of world facts so
  characters can reference history, with writers editing rules rather than programmers editing scripts.
- HL2 cn_114: NPCs speak when the player comes close, keeping it "low-key"; Ep1 alyxnag: repeated urgency barks made
  players hate Alyx in ~3 minutes; Ep1 falling_debris: a companion line plus pointing directs attention with "a high
  success rate".
- XAG 104: bark subtitles should be toggled separately from conversation and cinematic subtitles; name the speaker.
- Cross-reference: Ellie's callouts in The Last of Us must always point at something the player can see, or they make
  her look stupid (Dyckhoff, Game AI Pro 2, 2015 — see topics/companion-play.md [COMPANION-PLAY-1]).
WHAT IT MEANS FOR WOLF: a tiny rule table, not a dialogue tree: (speaker, trigger, conditions on memory flags,
  cooldown, once/repeat, priority). Examples: WOLF notices the purge display (once), a death (capped, approved
  lines), the engineer idling > N s near the goal (one hint, long cooldown, never "hurry"), the relay choice
  callback (once). Rules: every bark refers to something visible or audible right now; never repeat the same line
  within a room; at most one WOLF bark per ~10-20 s of free movement (DERIVED from alyxnag's 3-minute burn-out, not a
  sourced value — tune by play); urgent lines only when there is real danger.

### F11. Current script measured against the norms (code reading, 2026-10-12)
Python over apps/game/scripts/main.gd string constants (lines of 6+ words: 41):
- Longest: BAIT_NO_LINE 29 words/142 chars; JUNCTION_ENTRY_LINE 29/152; TANK_HIT_OFF_CENTRE_LINE 27/130; BAIT_YES_LINE
  26/119; TANK_HIT_LINE 24/121; RUBBLE_LINE 20/106. 6 of 41 lines are ≥ 20 words.
- At 0.33 s/word these need 6.6-9.6 s; at the code's 0.15 s/word they get 3.0-4.3 s. A 142-152 char line is 3.4-3.6
  subtitle rows of 42 chars, i.e. two subtitle "events" by BBC/Netflix/XAG rules.
- Opening: 7 beats, word counts [12, 8, 17, 27, 13, 10, 9] = 96 words, 549 chars; ~32 s at 180 wpm, ~24 s at 238 wpm
  (press-to-advance, controls off). Beat 4 (27 words, 2 sentences + Director reaction) is the only one above ~20
  words. (topics/onboarding.md also counts ~99 words / ~30-45 s.)
WHAT IT MEANS FOR WOLF: split every ≥ 20-word line into two boxes at the sentence break (e.g. TANK_HIT: narration
  box, then WOLF box), which also fixes "narration and a WOLF line sharing one box"; keep WOLF's spoken lines to
  ≤ ~15 words (≤ ~2 rows of 42 chars, ≤ ~5 s at 180 wpm). JUNCTION_ENTRY_LINE (29 words spelling the whole puzzle)
  is also flagged by topics/puzzles.md as over-explaining.

### F12. Firewatch: a relationship told over a radio while walking [NARRATIVE-IN-PLAY-36 Wikipedia Firewatch]
- Wikipedia (secondary; Polygon interviews blocked to this tool, Emily Short's Game Developer essay "Reading the end of
  Firewatch" (2016-02-18) was opened but discusses themes, not mechanics): Henry's "only means of communication is a
  walkie-talkie" to Delilah; the player picks dialogue "upon the discovery of new interactive objects or
  environments, or can choose not to answer at all"; choices "influence the tone of Henry's relationship". Actors
  Cissy Jones and Rich Sommer recorded in separate studios on a live call "to achieve a more natural rapport".
- UNVERIFIED (from memory, no primary opened): the choice timer length and exactly what silence does.
WHAT IT MEANS FOR WOLF: Firewatch's pattern (find a thing -> optional remark to the companion -> companion responds)
  maps onto WOLF exactly: the engineer USEs an object, and WOLF (present in the room) reacts, sometimes with a short
  two-option exchange. Silence/declining to comment should be a real, authored option, never a fail.

## Where this agrees or disagrees with design-reference-25-games.md
AGREE / now verified:
- §2.6 "Valve's commentary documents changing Alyx from leading to following ... nagging made players resent her
  quickly (dossier summary; the exact node wording did not reach this step)". Verified from the Episode One
  commentary (alyxnag, Matt T. Wood): "after about three minutes of this, the one thing it definitely did was make the
  player hate Alyx" -> she switched to "almost always following" [NARRATIVE-IN-PLAY-6]. Gap closed.
- §2.2 "reliability earns praise; latency read as disobedience". Extended by Ep1 powerboxes: watching the companion
  work while you wait made playtesters "more annoyed than entertained"; "she needs to finish it quickly and move on"
  [6]. Applies to WOLF taking the relay contact and reading the junction gauge (WOLF_GAUGE_READ_SECONDS = 1.0 is fine;
  keep any WOLF task the engineer waits on short).
- §3.1/§3.6 "the play camera scrolls; framing is authored; seamless transitions". Agrees with Half-Life's "never – or at
  least very rarely - taking control away" [5], Oxenfree's "no cutscenes" [19] and God of War's one shot [31].
- §5.6 "Examine text should under-explain". Agrees with Jensen [22] for OPTIONAL records. Qualify for essentials:
  Valve found that stating the rule ("communicating our expectations ... rather than having them learn by dying",
  Ep2 [7]) and naming-and-pointing (Ep1 [6]) work; the reference's own decision to make the stakes line required is
  consistent with this.
- §7.4 "UI appears only when actionable". Agrees for prompts; Oxenfree tethered bubbles [19] and XAG [8] support
  world-anchored speech for barks.
DISAGREE / gap the reference does not cover:
- The reference has no dialogue-delivery section at all: no reading speed, line length, speaker naming, text size or
  log. The current code's READ_SECONDS_PER_WORD = 0.15 (400 wpm) is above Brysbaert's adult silent-reading range
  (175-300 wpm non-fiction) [10] and >2x BBC's 160-180 wpm [1]. Measured rows of ~97-118 characters are ~2.3-2.8x
  the 37-42 character norm [1][2][8][9].
- §7 target "Persistent HUD: 0" should not be read as "minimise the dialogue box". Subtitle standards want an
  opaque/adjustable backing and large text [8][9]; the box should be absent when there is no text, and fully
  readable when there is.
- §2 "Input to WOLF acknowledgement: no source gives seconds". Still no source gives a companion-response latency;
  the nearest number found is Portal 2's deliberate "two second beat" of quiet after a co-op death before GLaDOS
  speaks [18] — a speech-spacing value, not an acknowledgement value.
- §2.7 "attachment from idle business plus two-way voice". Adds a channel the reference lacks for a robot: Wheatley's
  head/eye grammar (calm/nervous/fear/working) [18] gives WOLF a non-verbal way to "talk".
- Choice signalling is not covered by the reference beyond "track treatment silently and show it as behaviour"
  (Brothers/Plague Tale card). Fendt et al. [15] show silent tracking alone loses agency: the choice must be
  acknowledged immediately. "Show it as behaviour" must therefore be IMMEDIATE and VISIBLE behaviour, not only a
  later payoff.

## Needs (summary)
MUST
1. Story keeps control with the player; cutscenes rare, short, skippable, flowing straight into play [5][19][31]; the
   opening (96 words, ~24-32 s, controls off) is the one long exception — keep it player-paced and skippable.
2. Readable timing: auto-timed lines ≥ 0.33 s/word (180 wpm) + base, min ~1.2-1.5 s, max 7 s per box, USE advances;
   replace READ_SECONDS_PER_WORD 0.15 [1][2][3][10].
3. Text geometry: ≤ 40-42 chars/line, ≤ 2 lines/box (3 at choices), ≥ 23 px at 540p (46 px@1080p), size option to
   200%, opaque backing option [1][2][8][9][33]. Measured today ~97-118 chars/row at 17 px.
4. Name every speaker change; WOLF a fixed colour + name; off-screen direction cue [1][8][9][5].
5. Acknowledge every choice immediately and visibly through WOLF; pay off a few later; never "just move on" [14][15].
   (Fact-check: Fendt [15] supports acknowledgement + later callback together, not acknowledgement alone; see F4.)
6. Companion speech never nags or bosses; companion tasks the player waits on are short [6].
7. Player-paced text and replay: a dialogue log; no hidden choice timer [32][16].
8. Never hang dialogue on a room the player can leave; run it on the walk [18].
9. Direct gaze without taking control: motion + sound + WOLF names and points; frame reveals in the walking direction [5][6].
10. Ludonarrative harmony: engineer verbs are maintenance verbs; no WOLF command verb; no visible trust meter [29][30].
SHOULD
11. Walk-and-talk sized to the walk (1.5-2 views ≈ 5.6-7.5 s ≈ 2-3 short lines); barks tethered to the speaker [19][20].
12. Bark rule table: trigger, memory conditions, cooldown, once/repeat, priority; visible referent; separate bark
    subtitle toggle [34][8][5].
13. Split ≥ 20-word lines (6 today); WOLF lines ≤ ~15 words [1][10] + F11.
14. WOLF's head/optic grammar carries subtext [18].
15. Story stations wait, pause if the player wanders and resume; signal when it is safe to explore [5].
16. Soft physical slowdowns to buy a line's time [6].
17. ~2 s quiet after a death before WOLF speaks [18].
18. Show before tell: environment carries backstory, words only for what pictures cannot [22][17][23].
COULD
19. Choices that stay up while the engineer walks; authored silence [19][21][16][36].
20. Optional extra story on approach, never blocking progress [5].
21. A control-scheme story beat for the Fracture separation (Brothers) [25].
22. Captions for important non-speech sounds with direction [8][5].

## Sources (all accessed 2026-10-12)
[NARRATIVE-IN-PLAY-1] BBC (Accessibility for Products). "BBC Subtitle Guidelines" (living document, version 1 Sept 2016, current revision online). Official broadcaster guidelines. https://www.bbc.co.uk/accessibility/forproducts/guides/subtitles/
[NARRATIVE-IN-PLAY-2] Netflix. "English (USA) Timed Text Style Guide". Netflix Partner Help Center, current. https://partnerhelp.netflixstudios.com/hc/en-us/articles/217350977-English-USA-Timed-Text-Style-Guide
[NARRATIVE-IN-PLAY-3] Netflix. "Timed Text Style Guide: General Requirements". Netflix Partner Help Center, current. https://partnerhelp.netflixstudios.com/hc/en-us/articles/215758617-Timed-Text-Style-Guide-General-Requirements
[NARRATIVE-IN-PLAY-4] Ken Birdwell (Valve). "The Cabal: Valve's Design Process For Creating Half-Life". Gamasutra / Game Developer, 1999-12-10. https://www.gamedeveloper.com/design/the-cabal-valve-s-design-process-for-creating-i-half-life-i-
[NARRATIVE-IN-PLAY-5] Valve (Bill Van Buren, Doug Wood, Dhabih Eng, Eric Kirchmer, David Sawyer, Yahn Bernier et al.). Half-Life 2 developer commentary (20th Anniversary, 2024), transcribed by Combine OverWiki. https://combineoverwiki.net/wiki/Developer_commentary/Half-Life_2
[NARRATIVE-IN-PLAY-6] Valve (Matt T. Wood, Jake Nicholson, Wade Schin et al.). Half-Life 2: Episode One developer commentary (2006), transcribed by Combine OverWiki. https://combineoverwiki.net/wiki/Developer_commentary/Half-Life_2:_Episode_One
[NARRATIVE-IN-PLAY-7] Valve. Half-Life 2: Episode Two developer commentary (2007), transcribed by Combine OverWiki. https://combineoverwiki.net/wiki/Developer_commentary/Half-Life_2:_Episode_Two
[NARRATIVE-IN-PLAY-8] Microsoft. "Xbox Accessibility Guideline 104" (subtitles and captions). Microsoft Learn, ms.date 2022-05-09, updated 2026-06-17. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/104
[NARRATIVE-IN-PLAY-9] Game Accessibility Guidelines (collaborative group of studios, specialists and academics). "If any subtitles / captions are used, present them in a clear, easy to read way". gameaccessibilityguidelines.com, current. https://gameaccessibilityguidelines.com/if-any-subtitles-captions-are-used-present-them-in-a-clear-easy-to-read-way/
[NARRATIVE-IN-PLAY-10] Marc Brysbaert. "How many words do we read per minute? A review and meta-analysis of reading rate". Journal of Memory and Language 109, 2019 (preprint PsyArXiv 2019-04-12; abstract read via the OSF API). https://doi.org/10.1016/j.jml.2019.104047 ; https://osf.io/preprints/psyarxiv/xynwg
[NARRATIVE-IN-PLAY-11] Ian Hamilton. "Subtitles Are Changing, Don't Be Left Behind". GDC 2019, GDC Vault (abstract; video members-only). https://gdcvault.com/play/1025738/contactUs
[NARRATIVE-IN-PLAY-12] Maxime Johnson. "Subtitles in Video Games: The Best Practices". Canada Media Fund (CMF) Now & Next, 2019-04-12 (relays Hamilton's GDC 2019 Assassin's Creed Origins figure). https://cmf-fmc.ca/now-next/articles/subtitles-in-video-games-the-best-practices/
[NARRATIVE-IN-PLAY-13] Max Deryagin. "What game subs got wrong in 2017". md-subs.com, 2017. https://www.md-subs.com/what-game-subs-got-wrong-in-2017
[NARRATIVE-IN-PLAY-14] Leigh Alexander (reporting Sid Meier's GDC 2012 talk). "GDC 2012: Sid Meier on how to see games as sets of interesting decisions". Game Developer, 2012-03-07. https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions
[NARRATIVE-IN-PLAY-15] Matthew William Fendt, Brent Harrison, Stephen G. Ware, Rogelio E. Cardona-Rivera, David L. Roberts. "Achieving the Illusion of Agency". ICIDS 2012 (Springer LNCS 7648), NC State. https://cs.uky.edu/~sgware/reading/papers/fendt2012achieving.pdf
[NARRATIVE-IN-PLAY-16] Wikipedia contributors. "The Walking Dead (video game)" (Telltale Games, 2012). Wikipedia, secondary. https://en.wikipedia.org/wiki/The_Walking_Dead_(video_game)
[NARRATIVE-IN-PLAY-17] Valve (Erik Wolpaw, Kim Swift et al.). Portal developer commentary (2007), transcribed by Combine OverWiki. https://combineoverwiki.net/wiki/Developer_commentary/Portal
[NARRATIVE-IN-PLAY-18] Valve (Erik Robson, Elan Ruskin, Chet Faliszek, Karen Prell, Marcus Egan et al.). Portal 2 developer commentary (2011), transcribed by Combine OverWiki. https://combineoverwiki.net/wiki/Developer_commentary/Portal_2
[NARRATIVE-IN-PLAY-19] Bryant Francis (interviewing Adam Hines and Sean Krankel, Night School Studio). "How Oxenfree's narrative unfolds like a free-flowing conversation". Game Developer, 2015-12-17. https://www.gamedeveloper.com/design/how-i-oxenfree-i-s-narrative-unfolds-like-a-free-flowing-conversation
[NARRATIVE-IN-PLAY-20] Bryant Francis (interviewing Sean Krankel). "Road to the IGF: Night School Studio's Oxenfree". Game Developer, 2016-02-04. https://www.gamedeveloper.com/design/road-to-the-igf-night-school-studio-s-i-oxenfree-i-
[NARRATIVE-IN-PLAY-21] Wikipedia contributors. "Oxenfree". Wikipedia, secondary. https://en.wikipedia.org/wiki/Oxenfree
[NARRATIVE-IN-PLAY-22] Christian Nutt (interviewing Arnt Jensen and Dino Patti, Playdead). "Hanging in Limbo". Game Developer, 2012-02-24. https://www.gamedeveloper.com/business/hanging-in-limbo
[NARRATIVE-IN-PLAY-23] Wikipedia contributors. "Journey (2012 video game)". Wikipedia, secondary (relays Gamasutra GDC 2012 and Chen's D.I.C.E. 2013 talk). https://en.wikipedia.org/wiki/Journey_(2012_video_game)
[NARRATIVE-IN-PLAY-24] Jenova Chen (thatgamecompany). "Designing Journey". GDC 2013, GDC Vault (abstract; members-only video). https://www.gdcvault.com/play/1017700/Designing
[NARRATIVE-IN-PLAY-25] Wikipedia contributors. "Brothers: A Tale of Two Sons" (Starbreeze, Josef Fares, 2013). Wikipedia, secondary. https://en.wikipedia.org/wiki/Brothers:_A_Tale_of_Two_Sons
[NARRATIVE-IN-PLAY-26] Wikipedia contributors. "Another World (video game)" (Éric Chahi, 1991). Wikipedia, secondary. https://en.wikipedia.org/wiki/Another_World_(video_game)
[NARRATIVE-IN-PLAY-27] Éric Chahi. "Classic Game Postmortem - OUT OF THIS WORLD/ANOTHER WORLD". GDC 2011, GDC Vault (free video; only the page was read). https://www.gdcvault.com/play/1014630/Classic-Game-Postmortem-OUT-OF
[NARRATIVE-IN-PLAY-28] Wikipedia contributors. "Inside (video game)" (Playdead, 2016). Wikipedia, secondary. https://en.wikipedia.org/wiki/Inside_(video_game)
[NARRATIVE-IN-PLAY-29] Clint Hocking. "Ludonarrative Dissonance in Bioshock". Click Nothing (blog), 2007-10-07. https://clicknothing.com/2007/10/07/ludonarrative-d/
[NARRATIVE-IN-PLAY-30] Wikipedia contributors. "Ludonarrative dissonance". Wikipedia, secondary. https://en.wikipedia.org/wiki/Ludonarrative_dissonance
[NARRATIVE-IN-PLAY-31] Wikipedia contributors. "God of War (2018 video game)" (Santa Monica Studio, Cory Barlog). Wikipedia, secondary. https://en.wikipedia.org/wiki/God_of_War_(2018_video_game)
[NARRATIVE-IN-PLAY-32] Game Accessibility Guidelines. "Full list". gameaccessibilityguidelines.com, current. https://gameaccessibilityguidelines.com/full-list/
[NARRATIVE-IN-PLAY-33] Apple. "Typography". Human Interface Guidelines, Apple Developer, current (read via the HIG JSON data endpoint). https://developer.apple.com/design/human-interface-guidelines/typography
[NARRATIVE-IN-PLAY-34] Elan Ruskin (Valve). "AI-driven Dynamic Dialog through Fuzzy Pattern Matching. Empower Your Writers!". GDC 2012, GDC Vault (free video; abstract read). https://www.gdcvault.com/play/1015528/AI-driven-Dynamic-Dialog-through
[NARRATIVE-IN-PLAY-35] Game Accessibility Guidelines. "Ensure that subtitles/captions are cut down to and presented at an appropriate words-per-minute for the target age-group" (gives no number; defers to BBC/Ofcom). http://gameaccessibilityguidelines.com/ensure-that-subtitlescaptions-are-cut-down-to-and-presented-at-an-appropriate-words-per-minute-for-the-target-age-group
[NARRATIVE-IN-PLAY-36] Wikipedia contributors. "Firewatch" (Campo Santo, 2016). Wikipedia, secondary. https://en.wikipedia.org/wiki/Firewatch
Opened but not useful for mechanics: Emily Short, "Reading the end of Firewatch", Game Developer, 2016-02-18, https://www.gamedeveloper.com/design/reading-the-end-of-firewatch

Method notes: the shared WebSearch budget (200 calls) ran out after two searches in this pass, so remaining sources were
reached by known URLs. Blocked to this tool: polygon.com, rockpapershotgun.com, web.archive.org, sciencedirect.com;
elanruskin.com no longer resolves. Not opened (so not used): the Hades GDC 2021 dialogue talk, Telltale primary
interviews, Firewatch dialogue talks, the Journey GDC 2012 Gamasutra report. Commentary text was downloaded to the
scratch folder dl-narrative/ for searching only; nothing copied into the repo beyond short quotes.
[NARRATIVE-IN-PLAY-37] David Tisserand (Ubisoft). Tweet thread on subtitle usage data in Ubisoft games, 2019-06-25 (opening tweet read via publish.twitter.com oEmbed). https://twitter.com/TisserandDavid/status/1143570437173104643
[NARRATIVE-IN-PLAY-38] Shazoo (Russian games news, relaying Tisserand's thread). "Ubisoft: Большинство геймеров играют с субтитрами", 2019-06-27. Secondary. https://shazoo.ru/2019/06/27/81229/ubisoft-bolshinstvo-gejmerov-igrayut-s-subtitrami
[NARRATIVE-IN-PLAY-39] Kyle Hilliard (interviewing Josef Fares). "Afterwords: Brothers: A Tale of Two Sons". Game Informer, 2013-09-27. https://gameinformer.com/b/features/archive/2013/09/27/afterwords-brothers-a-tale-of-two-sons

## Fact-check (independent pass, 2026-10-12)
Every source URL [1]-[36] was opened again (BBC via curl because the fetch tool is blocked there; Valve commentary
pages downloaded fresh from Combine OverWiki; Fendt PDF read in full via PDFKit; Brysbaert abstract via the OSF API;
Apple HIG via its JSON data endpoint). The headless Godot font measurement was re-run (isolated HOME, same script):
17 px = 7.26-7.41 px/char, ~97-99 chars in 715 px, ~115-118 in 855 px; 24 px = 10.23-10.44 px/char. Reproduced.
main.gd constants (READ_SECONDS_PER_WORD 0.15, MIN 2.5, MAX 7.0, WOLF_GAUGE_READ_SECONDS 1.0), the BottomBar
(892x82) and Story label (715 px, 17 px), and the opening's 7 beats [12, 8, 17, 27, 13, 10, 9] = 96 words were
confirmed. Long-line counts match within one word (formatting placeholders such as %s).
VERIFIED exactly (quotes match): BBC 160-180 wpm / 0.33-0.375 s, 0.3 s/word (1.2 s for 4 words), 2 lines, 37 chars,
68%/90%, "unacceptably crude approach"; Netflix 42 chars, 2 lines, 20/17 cps, 5/6 s min, 7 s max; Birdwell 1999 (all
quotes, 200+ playtests, first 20-30, ~100 items per 2-hour session); every HL2, Ep1, Ep2, Portal and Portal 2
commentary quote and its node/author; XAG 104 (speaker naming, 1-2 min, (on radio), < >, Outer Worlds toggles, 40
chars, 2 lines, 200%, 0-100% opacity, "longer lines of text are harder to read"); GAG 46 px@1080p, 40 chars, 2 (3)
lines; Brysbaert 190 studies / 18,573 participants / 238 and 260 wpm / 175-300 and 200-320 / 183 wpm aloud (77
studies, 5,965 participants); Meier quotes; Oxenfree 2015 quotes; Limbo quotes; Hocking quotes; Wikipedia LD
(Uncharted 4 trophy, 1,000 kills, Druckmann); GoW 40%; TWD, Oxenfree, Firewatch, Journey (3 of 25 testers, D.I.C.E.)
Wikipedia lines; GAG full-list items; Apple HIG 17/11 pt and "test game text for legibility on each platform";
Ruskin, Chen, Hamilton, Chahi GDC Vault abstracts; Deryagin "epidemic of microscopic subtitles", 45-50 chars,
100-200 ms, "several hundred video games" (so that count is stated, not UNVERIFIED).
CHANGED:
1. Fendt et al. [15]: the claim that immediate acknowledgement alone preserves most agency is overstated. The
   acknowledged non-branching story beat minimal feedback on only 1 of 6 items (p = 0.039); hypothesis 2 failed.
   The branching condition also had later callbacks. Exact p for Q4 is 0.030. See F4.
2. Oxenfree [19]: "too open-ended" referred to free depth movement; the fix was 2D snaking paths. Dropped the
   unsourced "give WOLF something to do" reading.
3. [20] author is Bryant Francis, not "Game Developer staff".
4. BBC gap of 1-1.5 s applies only when a gap is left at a pause in speech; not a minimum between all boxes.
   BBC current version is 1.2.5 (March 2026).
5. Brothers: the "older brother's button" detail is not in the opened Wikipedia page; added Fares interview [39]
   for control-as-story; exact swim input wording UNVERIFIED.
6. Another World "cutscenes flow into play" and Inside "continuous play without traditional cutscenes": not in the
   opened pages, now UNVERIFIED. Journey is a "two-hour" game (abstract), not 2-3 h.
7. GoW "intimate and player-controlled" is Wikipedia's paraphrase of Barlog, not a quote.
8. CMF [12] misattributes 46 px and "38 characters" to the BBC; use GAG [9] and BBC [1] directly.
9. Added Ep1 alyxcitadeltone (Bill Van Buren) supporting "never nag"; named Ep1 advisorsighting (Matt Scott) and
   Ep2 EP2-Comment072 (Ken Birdwell) as the node/authors.
10. Added Tisserand [37] as the Ubisoft primary for the ~60% AC Origins subtitle figure; 95%/97%/75% only relayed [38].
COULD NOT VERIFY: Tisserand thread tweets 2-4 (95/97/75%); Oxenfree bubble timeout; Firewatch timer; the exact
Telltale banner wording; whether GDC Vault videos for [11]/[24] are free or members-only (the pages tag them "free
content", which conflicts with the researcher's "members-only").
MISSED SOURCES CHECKED BUT NOT ADDED (abstract only, no usable numbers): Jason Gregory (Naughty Dog), "A
Context-Aware Character Dialog System", GDC 2014, https://www.gdcvault.com/play/1020386/A-Context-Aware-Character-Dialog
(TLOU dialogue using individual/collective knowledge and world state; a sibling of Ruskin's system); Greg Kasavin and
Darren Korb, "Breathing Life into Greek Myth: The Dialogue of 'Hades'", GDC 2021,
https://gdcvault.com/play/1026975/Breathing-Life-into-Greek-Myth ("fewer than 20 employees", "more than 22,000 lines").

## Fact-check 2 (second independent pass, 2026-10-13)
Method: re-downloaded every must-level source and every source behind a number today (fresh copies in scratch
fc2-narr/, search helper fc2-g.py), plus the Fendt PDF (byte-identical to the first pass's copy), the Apple HIG JSON,
the Tisserand oEmbed and the Game Informer interview. Re-checked main.gd at commit da5c14e.
CONFIRMED again (exact wording): BBC 160-180 wpm / 0.33-0.375 s, 0.3 s per word (1.2 s / 4 words), 2 lines (3 for
9:16), 37 chars broadcast, "unacceptably crude approach", colour "the preferred method"; Netflix 42 chars, "Maximum two
lines", 20/17 cps, 5/6 s min, 7 s max; Birdwell (December 10, 1999): >200 sessions ("about half of them with repeat
players"), "100 or so 'action items'" per two-hour session, first 20 or 30 sessions; every HL2 cn_* quote and author
(Van Buren, Doug Wood, Kirchmer, Dhabih Eng, Sawyer, Bernier); Ep1 alyxnag / powerboxes / falling_debris /
advisorsighting (Matt Scott) / alyxcitadeltone (Van Buren); Ep2 EP2-Comment072 (Ken Birdwell); Portal 2 com-accents
(Robson), com-slowburn (Ruskin), com-cowrite (Faliszek), com-eyehasit (Prell), com-fatigue (Egan); Portal Comment095
and 077 (Wolpaw); XAG 104 (ms.date 2022-05-09, updated_at 2026-06-17; visible footer says 2026-03-04); GAG 46px@1080p,
40 chars, 2 (3) lines; GAG full-list items; Brysbaert abstract (OSF API, 2019-04-12) incl. 77 studies / 5,965 for
183 wpm; Apple 17/11 pt and "test game text for legibility on each platform"; Meier (Leigh Alexander, March 7, 2012);
Fendt numbers 79/52/54/44 and Table 2; ICIDS 2012 pp. 114-125, best paper of 48 submissions (NC State news via search);
Oxenfree quotes (Francis, Dec 17, 2015; Road to the IGF by Bryant Francis, Feb 4, 2016); Limbo quotes (AJ = Arnt
Jensen; Nutt, Feb 24, 2012); Hocking (Oct 7, 2007); Wikipedia LD / GoW / TWD / Journey / Firewatch / Inside lines;
Ruskin, Hamilton, Chen abstracts (all three GDC Vault pages are tagged "free content"); Deryagin quotes incl. 100-200
ms and "several hundred video games"; CMF misattribution of 46 px / 38 chars to the BBC; Tisserand opening tweet
("~60% of @assassinscreed Origins players turned ON the subtitles", 2018 edition).
Code: READ_SECONDS_PER_WORD 0.15 / MIN 2.5 / MAX 7.0 (line 39-41), used ONLY in _read_seconds to gate the stakes line
(line 959); WOLF_GAUGE_READ_SECONDS 1.0; human.controlled is false while waiting_for_choice (line 3013). Long lines
re-counted: BAIT_NO 29/142, JUNCTION_ENTRY 28/153, TANK_HIT_OFF_CENTRE 26/131, BAIT_YES 26/119, TANK_HIT 23/122,
RUBBLE 20/106 (within 1 word / 1 char of the researcher). Opening beats split on spaces: [12, 8, 16, 26, 12, 10, 9] = 93
words (researcher 96; the difference is tokenising dashes). Use "about 93-96 words, about 24-32 s".
CHANGED in this pass:
1. Brothers swim via the older brother's button: upgraded from UNVERIFIED to VERIFIED via Fares [39].
2. Tisserand [37]: "subtitles off by default" is not in the tweet; it is relayed by Shazoo [38] (opened 2026-10-13: Origins and The Division 2 had subtitles off by default; FC New Dawn 97%, AC Odyssey 95% kept them on; Division 2 75% turned them on at least once). Relayed, secondary.
3. Oxenfree "never have a cut scene": Wikipedia gives no speaker; "Hines" UNVERIFIED.
4. Portal 2 two-second beat: purpose is co-op talk room; applying it to WOLF's death screen is an analogy.
5. Corrections to the researcher's STRUCTURED RESULT that the first pass made only in these notes and that I carried
   into the returned result: Fendt Q4 p = 0.030 (not 0.05) and acknowledgement-alone claim softened (hypothesis 2
   failed); Road to the IGF author Bryant Francis; Journey "two-hour" (not 2-3 h); BBC 1-1.5 s gap only at pauses in
   speech (continuous dialogue: ~100-200 ms, Deryagin); "BBC 37 characters (68% of a 16:9 frame)" conflates two rows of
   the BBC table: 37 chars is broadcast (equivalent to a 75% width region), 68% width is the ONLINE limit; GoW
   "intimate and player-controlled" is Wikipedia's paraphrase; Another World "cutscenes flow into play" UNVERIFIED (the
   page says "no HUD or dialog" and "cinematic effects in both real-time and cutscenes"); the 0.15 s/word constant only
   gates the stakes line today, so "lines would vanish" is the risk IF it becomes the walk-and-talk timer.
ADDED SOURCE (missed by the researcher, opened and verified):
[NARRATIVE-IN-PLAY-40] Emily Short. "Beyond Branching: Quality-Based, Salience-Based, and Waypoint Narrative
Structures". Emily Short's Interactive Storytelling (emshort.blog, practitioner blog), 2016-04-12.
https://emshort.blog/2016/04/12/beyond-branching-quality-based-and-salience-based-narrative-structures/
Defines salience-based narrative as picking "a bit of content out of a large pool depending on which content element
is judged to be most applicable at the moment"; cites Ruskin's Left 4 Dead system and says it "was picked up by
Firewatch"; advantage: "build a rudimentary set of content with sensible, broad defaults, and then gradually add new,
more salient content for individual situations"; ties are broken at random among equally salient lines. Supports the
bark rule table (most-specific matching line wins; WOLF needs a broad default line per trigger before special cases).
LEADS NOT OPENED (do not cite until opened): Patrick Ewing (Campo Santo) and William Armstrong (Unity), "Do You Copy?
Dialog Systems and Tools in 'Firewatch'", GDC 2017 (described by search snippets as going from "an interrupt heavy bark
system, to the long, restarting, conversations they shipped"); the GDC Vault page URL was not found.
STILL UNVERIFIED: Oxenfree bubble timeout; Firewatch reply timer; Telltale banner wording; Tisserand tweets 2-4
(95/97/75%); Journey "3 of 25 testers cried" primary (D.I.C.E. 2013 talk not opened); Inside "no cutscenes".
Also re-opened [35] (GAG wpm page, 2026-10-13): no wpm number; it defers to "established guidelines from the TV/Movie
industry" (links BBC and OFCOM) and notes "the 17% of the UK/US population that has some difficulty reading" (GAG gives
no source for the 17%: treat as relayed). It says to cut text by "compacting phrases, and not through removing any
information".
