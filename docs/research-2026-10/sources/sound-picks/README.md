# Picked sounds and how they were made (October 10, 2026)

On October 10, 2026 the game's procedural sound set was measured clip by clip ([sound check page](../../notes/review-pages/2026-10-10-sound-check.md)). The three weakest families, the steam hiss, the electrical arc and WOLF's growl, were then rebuilt two ways, as new synthesis in code and from CC0 recordings, ranked by a measuring critic, refined once, and played to Nathanial ([review batch page](../../notes/review-pages/2026-10-10-review-batch.md), section 3).

## Decision

**October 10, 2026, Nathanial Henniges** picked the eleven sounds in this folder (`*.wav`); the list, licence and recipe of each is in [`LICENCES.md`](LICENCES.md): five recorded hiss loops and bursts, three synthesised arcs, two recorded growls and one synthesised growl. The research summary records it as "recorded CC0 steam set (Joseph Sardin, BigSoundBank, attribution requested), new arc synthesis, recorded CC0 growl through a machine body" ([`../../README.md`](../../README.md)). The full candidate data is in [`../../data/sound-audition.json`](../../data/sound-audition.json) and [`../../data/sound-redo.json`](../../data/sound-redo.json).

## Files

| Path | What it is |
|---|---|
| `*.wav`, `LICENCES.md` | The picked sounds and their licences (tracked earlier). |
| `provenance/hiss-rec-manifest.json`, `hiss-refine-manifest.json` | Every recorded hiss clip: recipe, source recordings, use in the game and measurements (first pass and refined pass). |
| `provenance/arc-rec-sources.json`, `growl-rec-sources.json` | The downloaded CC0 recordings for the arc and growl: title, page, file URL, author, licence text, SHA-256 and what each was used for. |
| `provenance/arc-rec-recipes.json` | How the recorded arc candidates were cut and processed (not picked; kept for the record). |
| `provenance/arc-refine-manifest.json`, `growl-synth-manifest.json` | The synthesised arc and growl clips: recipe, seed and output files. |
| `recipes/arc/synth/arc_synth.gd`, `recipes/arc/refine/arc_synth.gd` | The arc synthesis (recipes A, B and C), first pass and the refined copy that built the picked arcs. GDScript, written in the style of the game's `SfxBank`. |
| `recipes/growl/refine/growl_synth.gd` | The growl synthesis (recipes A, B and C, plus C refined), which built `growl-synth-C-warning.wav`. |
| `recipes/growl/refine/process_r.py`, `dsp.py` | The processing chain that turned the CC0 dog and bear recordings into WOLF's machine-body growls (`growl-rec-seam.wav`, `growl-rec-assertive.wav`). |
| `recipes/hiss/rec/build.mjs`, `dsp.mjs` and `recipes/hiss/refine/build_r.mjs`, `dsp.mjs` | The Node.js build of the recorded hiss set (first pass and refined pass) cited in `LICENCES.md`. |
| `measurements/audition-analysis.json`, `audition-report-clips.json` | The measurement report behind the sound check page: all 69 clips, with verdict, reasons and fixes. |
| `measurements/critic-current-set.json` | The critic's measurements of the game's sound set at the time. |
| `measurements/arc-crit-final.json`, `arc-measure-final.json`, `growl-crit-final.json`, `growl-measure-final.json`, `growl-voice-checks-final.json`, `hiss-measurements-final.json` | Final critic verdicts and measurements of the refined candidates (`hiss-measurements-final.json` was `measurements_r.json`). |

The recipes are kept as written for the record; they expect the downloaded recordings and working folders of the session, which are not in this repository (third-party recordings are cited below, never copied). Paths written as `[session scratch, not kept]/...` pointed into the session scratch folder.

## Credits

- **Game and the decision:** Nathanial Henniges.
- **Synthesis, processing, measurements and critic:** Claude (Claude Code) agents working for Nathanial. Tools: Godot 4.7 (GDScript, headless), Python 3 (standard library), Node.js, and ffmpeg for decoding and resampling.
- **Recordings (all CC0; credit kept as the sources ask):**
  - Joseph Sardin, BigSoundBank / LaSonotheque: "Pressure cooker" #0805 (<https://bigsoundbank.com/pressure-cooker-s0805.html>), "Air leak" #1486 (<https://bigsoundbank.com/air-leak-s1486.html>), "Air" #0138 (<https://bigsoundbank.com/air-s0138.html>). Attribution requested: "Joseph Sardin - BigSoundBank.com / LaSonotheque.org".
  - pauliuw, "Dog sounds", OpenGameArt, 2010 (<https://opengameart.org/content/dog-sounds>).
  - bonebrah, "Dog Growl", OpenGameArt, 2023 (<https://opengameart.org/content/dog-growl>).
  - AntumDeluge, "Bear Growls", OpenGameArt, 2021, from the U.S. Fish & Wildlife Service (<https://opengameart.org/content/bear-growls>, <https://www.fws.gov/video/sound.htm>).
  - Recorded arc candidates (not picked): themightyglider, "Electric Buzz", OpenGameArt (<https://opengameart.org/content/electric-buzz>), from soundtracvkradio's Freesound recording (<https://freesound.org/people/soundtracvkradio/sounds/394679/>); rubberduck, "50 CC0 Sci-Fi SFX", OpenGameArt (<https://opengameart.org/content/50-cc0-sci-fi-sfx>); Kenney, "Sci-fi Sounds" 1.0 (<https://kenney.nl/assets/sci-fi-sounds>); Kenney, "Digital Audio" (<https://kenney.nl/assets/digital-audio>, surveyed only).
  - CC0 1.0 deed: <https://creativecommons.org/publicdomain/zero/1.0/>.
- **Methods cited in the recipes:** Fant, G. (1960), *Acoustic Theory of Speech Production*, Mouton; Klatt, D. H. (1980), "Software for a cascade/parallel formant synthesizer", *Journal of the Acoustical Society of America* 67(3); Rosenberg, A. E. (1971), "Effect of glottal pulse shape on the quality of natural vowels", *JASA* 49(2B); Fitch, W. T., Neubauer, J. and Herzel, H. (2002), "Calls out of chaos: the adaptive significance of nonlinear phenomena in mammalian vocal production", *Animal Behaviour* 63(3); the dog-growl formant work the growl recipe cites as "Fitch 1999" (most likely Riede, T. and Fitch, W. T. (1999), "Vocal tract length and acoustics of vocalization in the domestic dog", *Journal of Experimental Biology* 202); Robert Bristow-Johnson, "Audio EQ Cookbook" biquad formulas (<https://www.w3.org/TR/audio-eq-cookbook/>).
