# PIN codes for WOLF//OVERRIDE: research

Status: research only, October 11, 2026. Nothing here is built into the game. Any player-facing words below are **proposed, awaiting Nathanial**. The art job owns the near-future military look. This file covers PIN codes as **gameplay** only. The mood reference is the Terminator films' AI-run defence network, so this file uses no Skynet, Terminator or Cyberdyne names, logos, designs or text.

**Evidence key.** **[F]** means the page or PDF was fetched and the quoted text was read. **[S]** means the claim comes only from a search-engine result for that URL, because the page blocked automated fetching (403, Cloudflare or a JavaScript wall). Treat [S] as weaker.

---

## 1. Real access control in secure and military facilities

### 1.1 PIN length and policy

| Claim | Source |
|---|---|
| The US Intelligence Community's SCIF technical specification says that if a guard cannot watch the door, an automated access control system "shall employ two of the following three technologies": an ID badge or card, a PIN, or a biometric. | [F] ICS 705 Tech Spec v1.5, ch. 8 A.2.a, PDF p. 80 (doc p. 66): https://archive.dni.gov/files/Governance/IC-Tech-Specs-for-Const-and-Mgmt-of-SCIFs-v15.pdf |
| In the same spec, "The PIN shall consist of four or more random digits, with no known or logical association to the individual". A compromised PIN is reported and set to "no access". | [F] same, ch. 8 A.2.a(2) |
| The system's chance of admitting an unauthorized person must be no more than 1 in 10,000, and its chance of rejecting an authorized person no more than 1 in 1,000. | [F] same, ch. 8 A.2.b |
| Mechanical or electromechanical combination devices (UNICAN and Simplex are named) are allowed where few people need access and there is one entrance. "Combinations shall consist of four (4) or more random digits." | [F] same, ch. 8 F.1-F.4, PDF p. 82 |
| Keypads "shall be installed in such a manner to preclude unauthorized observation of the combination". CCTV must not show "external control pads or access control components that would enable them to identify PINs". Readers and keypads outside the SCIF must be tamper-protected. | [F] same, ch. 8 F.5.a, ch. 8 C.1 and PDF p. 94 |
| Administrators must change default maintenance and master PINs. | [F] same, PDF p. 73 |
| Federal PIV smart-card PINs are 6 to 8 digits (FIPS 201-2 minimum 6, SP 800-73 maximum 8). | [S] https://csrc.nist.gov/CSRC/media/Presentations/FIPS-201-2-Workshop-PIV-Card-Specification-Updat/images-media/ferraiolo_piv_card_specification_update_fips201-2_2015.pdf |
| A PIV PIN blocks after too many wrong tries in a row. On YubiKeys the factory retry count is 3, configurable from 1 to 255. A blocked PIN is reset with the PUK. | [F] https://docs.yubico.com/yesdk/users-manual/application-piv/pin-puk-mgmt-key.html |
| NIST SP 800-63B (rev. 3): secrets chosen at random by the system "SHALL be at least 6 characters in length and MAY be entirely numeric". Consecutive failures are capped at 100. | [F] https://raw.githubusercontent.com/usnistgov/800-63-3/nist-pages/sp800-63b/sec5_authenticators.md (sec. 5.1.1.1, 5.2.2) |
| NIST SP 800-63B-4 (current) keeps the cap: the verifier "SHALL limit consecutive failed authentication attempts ... to no more than 100", and lists waiting periods that grow "30 seconds up to an hour" as a throttling method. | [F] https://pages.nist.gov/800-63-4/sp800-63b.html (sec. 3.2.2) |

### 1.2 Lockout, alarms and duress

| Claim | Source |
|---|---|
| Consumer example: a Schlage Encode keypad disables itself for 30 s after 3 wrong codes in a row. After 4, the keypad shuts off and the lock's alarm sounds for 30 s. Each further wrong code disables it for 1 minute. | [S] https://kc.allegion.com/kb/article/do-schlage-encode-series-locks-report-multiple-failed-code-attempts |
| A duress code is a covert distress signal. A duress PIN differs from the real PIN, for example by swapped last digits, and can "trigger a silent alarm". Weakness: an attacker who knows two codes exist can guess between them. | [F] https://en.wikipedia.org/wiki/Duress_code |
| Lenel readers form the duress code by adding one to the PIN's last digit, so 255 becomes 256. | [S] https://kb.lenels2.com/home/what-is-duress-code (now redirects to a Honeywell portal) |
| Alarm panels: a duress code "simulates disarming while discreetly alerting" the monitoring station, and the keypad and sirens stay silent. | [S] https://ajax.systems/products/superior-keypad-fibra/ |
| SCIFs: an "alert system and duress alarm is required" for continuous-operation facilities and recommended for the others. | [F] ICS 705 Tech Spec, ch. 3, PDF pp. 37-39 (URL above) |

### 1.3 Scrambled keypads

| Claim | Source |
|---|---|
| The Hirsch/Identiv ScramblePad reorders its digits each time START is pressed or a card that needs a PIN is presented. This defeats pattern watching and key wear. Viewing restrictors let only the person directly in front read the digits. It is GSA-approved for FIPS 201 / FICAM use. | [F] https://www.hirschsecure.com/us/en-us/products/access-control-readers/ts-scramblepad-readers ; [S] https://www.identiv.com/products/physical-access-control-video-credentials/physical-access-readers/hirsch-scramblepad-readers |

### 1.4 Two-person integrity

| Claim | Source |
|---|---|
| The two-person rule requires two authorized people for critical actions. US launch crews "insert the keys in slots on the control panel and turn them simultaneously", with the slots far enough apart that one person cannot reach both. COMSEC two-person integrity uses two combination locks. "At no time can one person have in their possession the combinations or keys to gain lone access." | [F] https://en.wikipedia.org/wiki/Two-person_rule |
| A no-lone zone is a space that "must be occupied by two or more appropriately cleared individuals who remain within sight of each other". | [F] https://csrc.nist.gov/glossary/term/no_lone_zone (CNSSI 4009-2022) |

### 1.5 Lockdown modes and what operators see at the door

| Claim | Source |
|---|---|
| Genetec readers can show a separate LED and beeper state for each of: Unlocked, Shunted (reader deactivated), Card only, Card and PIN, Card or PIN, Access denied, Access granted, **Prompt for PIN**, **Prompt for second cardholder**, Door alarm ("Door open too long" or "Door forced open") and Wait. | [F] https://synergis-cloudlink-help.genetec.com/EN/EN/SCLG2/T_SCLG2_ConfiguringReaderLEDAndBeeperSettings.html |
| Genetec "threat levels" are site-wide scenarios. "Set minimum security clearance" raises the level an area requires, and doors that were unlocked by schedule become locked. | [F] https://help.securitycentersaas.genetec.cloud/en/ThreatLevelActions.html |
| Lenel OnGuard reader modes are Locked, Card only, Pin or Card, Pin and Card, Facility Only, Unlock and Default. Locked shuts out every credential. | [F] https://docs.axxonsoft.com/confluence/x/6wC-Eg |
| Typical OSDP reader defaults: standby blue; granted green for 5 s with a continuous beep; denied red for 5 s with three short beeps. | [S] https://knowledge.alloys.com.au/hubfs/Akuvox%20A094%20OSDP%20Reader%20Configuration%20(1).pdf |
| US installations use five Force Protection Conditions: Normal, Alpha, Bravo, Charlie and Delta. Access control runs at every level, and Delta is short-term and local. | [S] https://www.military.com/military-life/fpcon-levels.html |

### 1.6 How people actually choose PINs (useful for believable codes)

| Claim | Source |
|---|---|
| In 3.4 million four-digit codes, 1234 made up 10.713%, 1111 made up 6.016% and 0000 made up 1.881%. The top 20 covered 26.83%. 2580, straight down a phone keypad, ranked #22. Every 19xx code sat in the top fifth. The least used was 8068. | [F] https://www.datagenetics.com/blog/september32012/index.html (fetched over HTTP; the site's certificate has expired) |
| Phone keypads put 1-2-3 on the top row. Bell Labs (Deininger, 1960) found this layout "slightly faster in use than the calculator layout". ITU E.161 standardises it. | [F] https://en.wikipedia.org/wiki/Telephone_keypad |

---

## 2. How games use keypad codes

### 2.1 Game by game

| Game | Where the code comes from | Length | Fail and retry, alternatives | Source |
|---|---|---|---|---|
| System Shock (1994) | Its first keypad door is 451, the start of the "0451" tradition (a Fahrenheit 451 nod that became the Looking Glass office door code). | 3 | n/a | [F] https://www.shamusyoung.com/twentysidedtale/?p=1605 |
| System Shock (2023 remake) | Audio logs and USB drives. "All codes ... are randomly generated." | 3 | Brute force is possible but described as "too much effort". | [F] https://www.gfinityesports.com/article/system-shock-remake-secrets |
| Deus Ex series | The first keypad code is 451 or 0451 (Deus Ex, Invisible War). In Mankind Divided, typing a code instead of hacking gives no XP. | 4 | Hacking is the parallel route. | [F] Shamus Young (above); [F] https://segmentnext.com/2016/08/23/deus-ex-mankind-divided-keypad-codes-and-hacking-passwords |
| Prey (2017) | Notes, emails, audio logs and characters. "A majority of keycodes ... are random, changing with each new playthrough", though "a few codes never change". A found code "will be displayed next to the control panel", but you still type it. You can type a code you never found. | 4 | Hacking skill opens the same panels. | [F] https://segmentnext.com/2017/05/03/prey-2017-safe-codes-keycodes-locations-terminals-passwords-guide/ ; [F] https://www.dtgre.com/2017/05/all-keycard-locations-keycodes-and.html ; [F] https://www.shacknews.com/article/99864/all-of-preys-safe-locations-and-keycodes |
| Doom 3 | Picking up a PDA downloads it automatically. Its emails and audio logs carry "storage or door key codes". | 3-4 [S] | n/a | [F] https://en.wikipedia.org/wiki/Doom_3 ; [S] https://www.doomwiki.org/wiki/Doom_3_locker_codes |
| BioShock | Audio diaries and notes. The first door code is 0451 (Medical Pavilion). | 4 | Optional loot rooms. | [F] https://www.ggrecon.com/guides/bioshock-1-door-codes/ |
| Dead Space (2023) | No typed codes. Story-granted Security Clearance levels 1-3 open doors and lockers. | n/a | Optional Master Override side quest. | [F] https://www.gamesradar.com/dead-space-security-clearance/ |
| Alien: Isolation | Sevastolink terminal files. Example: the "Hospital Quarantine" file holds 1702, used later under pressure from the Alien. | 4 | Access Tuner bypass on some doors. | [F] https://www.gosunoob.com/alien-isolation/the-quarantine-mission-5/ ; [S] https://alienisolation.fandom.com/wiki/Security_Access_Tuner |
| Resident Evil 2 (2019) | Most locker and safe codes are fixed. The portable safe's button-to-light mapping "change[s] with every playthrough". A mistake turns all the lights off, but the mapping stays, so it can be solved by trial. | 8 buttons | Unlimited retries. | [F] https://vandal.elespanol.com/en/resident-evil-2-remake/resident-evil-2-remake-how-to-open-the-portable-safe.html |
| Half-Life: Alyx | No digit keypad. A 4x4 button grid is solved from an environmental clue: floating cardboard forms an eye that "is looking at" the answer. | 2 of 16 | Unlimited. | [F] https://www.pcgamer.com/half-life-alyx-button-puzzle-gate-mural/ |
| Inside | No keypad. The secret-ending door uses one switch pulled Up, Left or Right in a 14-step sequence, learned from the tones on a tape recorder. Input uses the game's existing moves. | 14 | Unlimited. Sound-only clue. | [F] https://www.shacknews.com/article/95640/inside-how-to-get-the-secret-ending |
| Dishonored 2 (Jindosh lock) | A logic riddle randomized per player and per run, "so you can't just google the solution". A quest route gives the code instead. Players complained about the riddle's wording. | 5 | Alternative quest route. | [F] https://kotaku.com/have-you-got-what-it-takes-to-solve-dishonored-2-s-wick-1790056270 ; [S] https://steamcommunity.com/app/403640/discussions/0/217691032443432137/?ctp=2 |
| The Last of Us Part II | Notes give safe combinations, but the dial gives "a distinct and louder click" on each correct number, so any safe opens in under a minute. TheWrap: this "likely will not work" for hearing-impaired players. | 3 | Brute force by sound. | [F] https://www.thewrap.com/the-last-of-us-part-2-how-to-easily-open-any-safe-without-the-combination/ |

### 2.2 What players love

- **The code is a small story moment.** Codes arrive inside someone's personal log or email, as in System Shock, BioShock, Prey, Doom 3 and Alien: Isolation (sources above). Reading a stranger's note to get in is the payoff, more than the typing. 0451 survives across studios as a shared nod (Shamus Young).
- **Knowledge is a key.** Prey lets you type a code you already know, even one you never found in this run (dtgre). It rewards attention and repeat play.
- **Codes sit alongside other routes.** Deus Ex and Prey offer hacking, Alien: Isolation the Access Tuner, Dishonored 2 a quest. The code is one route, not the only one.
- **Delivery under pressure.** Alien: Isolation's 1702 is read in a quiet office and typed later with the Alien patrolling (GosuNoob).

### 2.3 What players hate, and what to avoid

- **Forced note-taking and backtracking.** Most of these games make the player remember or re-open the source. Prey does show a found code next to the panel (dtgre), and Doom 3 keeps every log in the PDA (Wikipedia). There is no stronger source here than guide sites. Note that guides list every code (Prey, BioShock, Deus Ex), which suggests players often look codes up rather than track them.
- **Riddles that fail on wording, not logic.** See the Jindosh lock complaints ([S] Steam thread).
- **Sound-only solutions.** Inside's tones and The Last of Us Part II's clicks fail deaf and hard-of-hearing players (TheWrap). This breaks the guideline "Ensure no essential information is conveyed by sounds alone" (GAG, below).
- **Brute force as the real answer.** Short codes invite guessing. In the System Shock remake, 3-digit codes are guessable but tedious (Gfinity).
- **Pixel hunting.** Half-Life: Alyx avoids it by making the clue a large, framed event (the cardboard eye) rather than a tiny texture (PC Gamer).

### 2.4 Accessibility evidence

| Claim | Source |
|---|---|
| Game Accessibility Guidelines that apply to a keypad, by level. **Basic:** "Ensure no essential information is conveyed by a fixed colour alone"; "Ensure no essential information is conveyed by sounds alone"; "Use an easily readable default font size"; "Ensure interactive elements / virtual controls are large and well spaced, particularly on small or touch screens"; "Include toggle/slider for any haptics"; "Allow controls to be remapped / reconfigured". **Intermediate:** "Indicate / allow reminder of current objectives during gameplay"; "Avoid repeated inputs (button-mashing/quick time events)". **Advanced:** "Do not make precise timing essential to gameplay". | [F] https://gameaccessibilityguidelines.com/full-list/ |
| WCAG 1.4.1: colour cannot be the only means of conveying information. A red-for-error border with no text or icon is the textbook failure. | [S] https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html |
| "About 1 in 12 men have color vision deficiency", most often between red and green. | [F] https://www.nei.nih.gov/learn-about-eye-health/eye-conditions-and-diseases/color-blindness |
| Dyslexia-friendly text: sans serif, 16-19 px or larger, wider letter spacing, no italics or underline, no all-caps for continuous text. | [S] https://ako.ac.nz/assets/Knowledge-centre/ALNACC-Resources/Dyslexia-resources/230907-Dyslexia-Friendly-Style-Guide.pdf (based on the British Dyslexia Association guide) |
| Dyslexic children show difficulty sequencing and transcoding numbers, which shows up as transposed digits. | [S] https://www.bib.irb.hr/513613 |

---

## 3. A keypad that works with touch, controller and keyboard

| Topic | Evidence | Source |
|---|---|---|
| Layout | Use the phone layout (1-2-3 on top, 0 centred below). Bell Labs found it slightly faster than the calculator layout, and wall keypads and phones use it. Desktop numeric keypads use the calculator layout, so typed digits must not depend on screen position. | [F] Wikipedia Telephone keypad (above) |
| Touch size | Apple: default control size 44x44 pt and minimum 28x28 pt on iOS and iPadOS. "Consider spacing between controls as important as size." | [F] https://developer.apple.com/tutorials/data/design/human-interface-guidelines/accessibility.json (JSON behind the HIG Accessibility page) |
| Touch size | Android: "at least 48x48dp, separated by 8dp of space or more". About 9 mm; 7-10 mm is recommended. | [F] https://support.google.com/accessibility/android/answer/7101858?hl=en |
| Controller focus | Godot: focus neighbours give 4-way D-pad navigation through the built-in `ui_up`, `ui_down`, `ui_left`, `ui_right` and `ui_accept` actions. `grab_focus()` sets the starting key. | [F] https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html |
| Focus visibility | XAG 113: the focused element must always be clearly marked, using border, size or weight rather than a faint glow. When a dialog opens, focus moves into it and stays there. | [F] https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/113 |
| Typing digits | Godot: `unicode` is "meant for text input", while `physical_keycode` is for position-based game input. On French AZERTY keyboards, the top-row digits "must be typed" with Shift held. So read typed digits through `unicode` and accept the numeric keypad too. | [F] https://docs.godotengine.org/en/stable/classes/class_inputeventkey.html ; [F] https://en.wikipedia.org/wiki/AZERTY |
| Native number pad | Godot `LineEdit` offers `KEYBOARD_TYPE_NUMBER`, a "Virtual number keypad, useful for PIN entry". A custom in-world pad is still better here because it looks the same on every device and needs no OS keyboard. | [F] https://docs.godotengine.org/en/stable/classes/class_lineedit.html |
| Haptics | Apple: use haptics consistently, so each pattern maps to one cause; "complement" visual and audio feedback; "Avoid overusing haptics"; "Make haptics optional". | [F] https://developer.apple.com/tutorials/data/design/human-interface-guidelines/playing-haptics.json |
| Haptics in Godot | `Input.vibrate_handheld(duration_ms, amplitude)` runs on Android, iOS and Web. Android needs the `VIBRATE` export permission, and iOS supports a duration only from iOS 13. `Input.start_joy_vibration()` drives controller rumble; macOS supports it from macOS 11 with USB limits. | [F] https://docs.godotengine.org/en/stable/classes/class_input.html |
| Real-keypad feedback | Real readers give a coloured LED plus a beep pattern and a named state (Prompt for PIN, Denied, Door alarm). Text, light, sound and an optional buzz together read as "real". | [F] Genetec states (1.5) |

---

## 4. What this means for WOLF//OVERRIDE

All proposals below are for Nathanial to pick from. Displayed words are **proposed, awaiting Nathanial**.

1. **A code is a fact in the evidence case, not something to write down.** When the engineer reads a record that holds a code, the code goes into the case automatically. This fits the decision that records are facts with no slots. At the keypad, one Interact press enters the known code, and typing it by hand stays optional. This removes forced note-taking (2.3) and matches Prey's code shown beside the panel and Doom 3's PDA.
2. **Four digits, and believable.** Four random digits is the real SCIF minimum (1.1) and the genre norm (2.1). Avoid 1234, 0000 and date-like 19xx codes, since real users pick those (1.6) and they would read as a joke at a military site. A 0451 cameo would be a homage Nathanial may or may not want.
3. **A gentle lockout instead of a punishment.** Real keypads lock briefly after about 3 wrong tries (Schlage 30 s, PIV 3 tries; 1.1-1.2). In the game, use 3 wrong tries, then a visible LOCKOUT countdown of a few seconds plus beacon light and sound. Never a death, and the cost stays inside the current beat. Guessing is never required, because the code always exists in a record nearby.
4. **An engineer-only route for every essential code.** Its source is a record or terminal the engineer can reach in the same room or the one before, with no backtracking (2.3). WOLF never fetches a code. Under memory gating he may recognise one, or rarely refuse to share it, but the engineer's record route always stands.
5. **Real systems give the military-base feel.** Each idea below is sourced in Part 1:
   - **Card and PIN.** A door asks for a credential and a code (ICS 705's two of three). The credential can be something the engineer already has, so no inventory slot is added.
   - **Lockdown reader mode.** A sealed area shows its readers as LOCKED, and restoring power or a breaker drops them back to CARD AND PIN (Lenel modes, Genetec threat levels). This ties into the breaker and the lockdown beacons already in the slice.
   - **Prompt for second cardholder.** This is two-person integrity, with two readers too far apart for one person. It is a strong moment for WOLF's independent choice to stand at the second panel. It **must** have an engineer-only fallback, such as a manual override elsewhere or a timed relay, and no penalty if WOLF declines.
   - **Door alarm states.** "DOOR HELD" and "DOOR FORCED" text and lights make blowing or bypassing a door read as a real breach.
   - **Scramble pad.** Use it only as optional set dressing on a non-essential panel. Reshuffled digits break controller focus memory and slow readers who transpose digits (2.4).
   - **Duress code.** Strong for story, but a code that is accepted yet secretly sounds an alarm can feel unfair. Keep it for an authored, clearly signalled later beat.
6. **Input with no new actions.** While the pad is open: digits 0-9 from `unicode` or the numeric keypad on keyboard; D-pad or stick focus over a 3x4 phone-layout grid with Interact to press on controller; on touch, large buttons (at least 44 pt, roughly 9 mm, with gaps) while the move and USE buttons hide. Delete and Back reuse `ui_cancel` and the existing pause action. Focus starts on the "enter known code" key when the code is known, otherwise on 5.
7. **Feedback that never relies on one sense.** Each state is a text label plus a shape or icon plus colour plus sound, with an optional short buzz (GAG, WCAG 1.4.1, Apple HIG). Example labels, proposed: ENTER CODE, ACCESS GRANTED, DENIED 1/3, LOCKED OUT 0:05, READER LOCKED. Show the typed digits clearly in a large sans-serif font for readability, with masking off by default since this is a game. No essential clue is sound-only, colour-only or timing-only.
8. **Keep it light.** Draw the pad from the existing theme and fonts as Godot Controls. No new textures are needed for a first pass, and the logic is a small state machine (idle, entering, granted, denied, lockout, locked) the rooms can share.
