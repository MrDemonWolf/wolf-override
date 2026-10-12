# How real containment for a dangerous animal or robot is built, at WOLF's scale

Scratch research for the cage-design job, written 2026-10-11 under Nathanial's new direction: the facility is a near-future military base run by automated systems, and WOLF's containment should read as military hardware for holding a combat-capable robot, with access-control hardware such as a PIN keypad on the lock. The AI defence network from a well-known film series is a mood reference only; no name, logo, design, machine or text from it appears here or may appear in any drawing.

**What this file is and is not.** It is sourced research plus measurements of main at `7c19ee2`. Nothing in a Git repository or worktree was edited. Godot was not run, nothing was drawn, painted or generated, and nothing was played, so this file makes no claim about feel or readability in motion. The cage and the opening on main stay as they are; everything in section 10 is a proposal for Nathanial to pick from.

**Evidence labels.** **spec** = manufacturer sheet; **std** = standard, regulation or official guidance; **game** = measured from main's code or assets; **calc** = worked out here; **est** = design estimate with no source; **snippet** = the claim came from a search-engine summary and the page itself could not be fetched (HTTP 402/403), so treat it as unverified. Numbers in square brackets point to section 11. Downloaded source PDFs are kept in `dl/` (untrusted data; only text was extracted).

---

## 1. Scale key (game)

- Feet are at **y 440**; the engineer's visible sprite is **69.6 world px = 1.75 m**, so **1 m = 39.8 world px** and **1 world px = 25.1 mm** (measured and written up in the private `real-slice/anatomy/ANATOMY.md`; same numbers here). [G1]
- WOLF: `Wolf` at (115, 423) during the opening, `BodySprite` offset (0, -15), scale 0.18325, texture 761 x 406. Its alpha (> 20) spans columns 74..702 and rows 33..368, so the visible WOLF is **115.3 x 61.6 world px**, feet at y 438.2. [G2]
- Opening camera: `intro_camera` zoom **1.8, then 1.95** (main.gd lines around 1008-1036). In the 1280 x 720 window (1.333 x the 960 x 540 base), **1 world px = 2.4 to 2.6 screen px**. At gameplay zoom 1.35 it is 1.8 screen px at 720p. Anything under about 2 world px is a line, not a shape. [G3]

## 2. Dimension table: WOLF against real wolves and real quadruped robots

| Thing | Real | m | world px (at 39.8 px/m) | Kind |
|---|---|---|---|---|
| Engineer, soles to crown | | 1.75 | 69.6 | game [G1] |
| **WOLF, nose to tail tip** | | 2.90 | 115.3 | game [G2] |
| WOLF, nose to rump (tail is the first ~24 px of the silhouette) | | 2.29 | ~91 | game + est [G2] |
| WOLF, tail | | ~0.60 | ~24 | game + est [G2] |
| WOLF, back line (hips to mid-back) | | 1.06-1.13 | 42-45 | game [G2] |
| WOLF, withers | | ~1.18-1.21 | ~47-48 | game [G2] |
| WOLF, ear tips (top of sprite) | | 1.55 | 61.6 | game [G2] |
| Grey wolf, shoulder height | 60-90 cm | 0.60-0.90 | 23.9-35.8 | ref [1] |
| Grey wolf, nose to tail tip (ADW figure) | 1000-1300 mm males, 870-1170 mm females | 0.87-1.30 | 34.6-51.7 | ref [1] |
| Grey wolf, tail | 350-520 mm | 0.35-0.52 | 13.9-20.7 | ref [1] |
| Grey wolf, mass | 30-80 kg males (avg 55), 23-55 kg females (avg 45) | | | ref [1] |
| Boston Dynamics Spot, length x width | 1100 x 500 mm | 1.10 x 0.50 | 43.8 x 19.9 | spec [2] |
| Spot, height standing / sitting | 840 / 191 mm | | 33.4 / 7.6 | spec [2] |
| Spot, default walking height | 610 mm | 0.61 | 24.3 | snippet [3] |
| Spot, net mass | 32.5 kg | | | spec [2] |
| Spot transport case | 1330 x 680 x 560 mm | | 52.9 x 27.1 x 22.3 | spec [2] |
| Spot Dock | 1140 L x 414 W x 403 H mm, 22.9 kg | | 45.4 x 16.5 x 16.0 | spec [4] |
| Ghost Robotics Vision 60 (in US Air Force security-forces use), length x width | 950 x 570 mm | | 37.8 x 22.7 | spec [5] |
| Vision 60, standing / ride height | 685 / 419 mm | | 27.3 / 16.7 | spec [5] |
| Vision 60, tare mass / payload | 51 kg / 10 kg | | | spec [5] |

**What the table says (calc).** WOLF's withers (~1.2 m) are about **1.3-2.0 x a real wolf's shoulder** (0.60-0.90 m) and **~1.4-1.8 x a standing military quadruped** (Spot 0.84 m, Vision 60 0.685 m). His body (2.3 m without the tail) is **about 2.1-2.4 x** Spot or Vision 60. He is a pony-sized machine, not a dog-sized one. Every containment number below is therefore given twice where it matters: real, and scaled to WOLF (x 1.6, the midpoint of the shoulder ratio, **est**).

**Today's cage on main (game, `containment_cage.gd`, node `IntroCage` at (115, 365), z 4), for comparison only, not for change:**

| Part | world px | m (calc) | Note |
|---|---|---|---|
| Outer frame | x 27..203 = 176 wide; y 292 (lid peak) .. 451 = 159 tall | 4.42 x 4.00 | base rail runs 1-11 px below the floor line y 440 (it sits on the near plane) |
| Clear interior between posts and beams | 160 x 128 (y 313..441) | 4.02 x 3.22 | WOLF (115 x 62) has ~45 px (1.1 m) spare length and ~66 px (1.7 m) headroom |
| Posts | 8 wide | 0.20 | |
| Gate bars | 9 bars, 6 px thick, 18 px pitch, **12 px clear gap** | 0.15 thick, **0.30 gap** | the gap is about **6 x** the 2-inch (51 mm) chain-link aperture used for wolves (section 3) |
| Gate rails | 5 px at y 316, 381, 433 | 0.13 | |
| Red lamp housings | 10 x 22 px, y 328..350 | 0.25 x 0.55, centre ~2.5 m up | lamp itself 3 x 14 px (0.08 x 0.35 m) |
| Bolt heads | r 2 px | 0.10 across | |

---

## 3. Large-carnivore and wolf containment (zoos, sanctuaries, transport)

### 3.1 Barriers, mesh and bars

| Rule | Value | world px real (scaled to WOLF x1.6, est) | Source |
|---|---|---|---|
| Wolf fence (Scotland, DWA guidance) | heavy-gauge chain link **at least 2.5 m**; inward overhang **45 deg, at least 0.7 m** if unroofed; **1 m** buried skirt | 99.5; overhang 27.9 | std [6] |
| Wolf fence (Colossal husbandry manual) | **9-gauge or heavier 2-inch chain link** on 2-inch steel pipe set in concrete; **8 ft+** high with a **36-inch** overhang at 35-45 deg; a second fence of the same build around the whole enclosure | aperture 2.0 (3.2) | std [7] p. 8 |
| Wolf fence (North Dakota rule) | steel chain link **at least 12-gauge**, fastened to a cement floor; 8 ft with overhang or 6 ft with a ceiling; **gates must have locks** | | std [8] 48.1-09-06, 4.c |
| Tiger mesh (AZA) | **no lighter than 6-gauge**, openings 5x10, 7.6x7.6 or 10x10 cm; **no more than 5x5 cm in keeper work areas** "to prevent injury resulting from a cat reaching through"; flexible mesh is bitten and pulled | 5x5 cm = 2.0 px (3.2) | std [9] pp. 16-17 |
| Tiger crate bars at the head end (AZA) | **2.5 cm between bars**, to see and feed the animal, covered with a ventilated door in transit | 1.0 (1.6) | std [9] p. 23 |
| Crate clearance (AZA tiger) | **at least 10 cm** round the standing animal | 4.0 (6.4) | std [9] PDF p. 25 |
| Container Requirement 82 (IATA LAR ed. 50, covers **Wolf**) | front of **welded wire mesh** that stops nose or paws protruding; a **sliding shutter** offset about **5 cm** from the mesh, raised and lowered to feed and water; two observation holes of at least **10 cm**; vent holes at least **2.5 cm** on about 10 cm centres, at least **16%** of the side area; **wolves: container completely lined with sheet iron or other hard metal sheeting**; "a **sliding door** must be provided for all non-domestic species ... a secure means of fastening so that it cannot be opened accidentally" | shutter offset 2.0; holes 4.0 / 1.0 | std [7] pp. 119-121 (excerpt of IATA LAR CR 82) |

**Reading for WOLF.** A real wolf barrier is fine mesh (2 px apart at game scale) or bars 2.5 cm apart, lined with plate for transport; never bars 0.30 m apart. Scaled to a 1.6 x robot, the clear gap still only reaches about **3 px (75-80 mm)**. A gap a human hand or a robot's muzzle can pass through reads as a cell for display, not for holding.

### 3.2 Doors, latches, padlocks and who works them

- **Shift doors.** "Animal access to the exhibit should be by remotely operated shift doors; **sliding or guillotine types are preferred** with a secure and easily checked locking mechanism **reinforced with padlocks**." Door handles and controls "clearly labeled or color-coded as to which door they operate and whether they are in the open or closed position." [9] p. 16-17
- **Guillotine door in a crate.** "The best doors for transport containers are those that **slide vertically in a track (guillotine type)**, and are secured with screws into the crate and then padlocked." "Padlocks should be on every door." [9] pp. 23-24
- **How a guillotine resists the animal.** A kennel guillotine is lifted by a cable from a handle outside; a cam lock binds the door in its tracks when it is pushed up from below, so "at least a portion of the locking mechanism moves horizontally into binding engagement with ... the door track," with no power needed. [10]
- **Controls out of reach.** "Shift cage door controls shall be **protected from the animal** in the primary enclosure," and the shift door "can be **locked in the closed or open position**." [11] J(2)-(3)
- **Releasing a guillotine.** Colossal: "Guillotine doors should never be released before the entire animal is completely cleared of the door"; slide doors injure tails, legs and torsos. [7] p. 16
- **Double doors.** UK zoos must have double-door systems on every Category 1 carnivore enclosure (the **wolf is Category 1**); "only one of these doors is open at any time"; the airlock must hold a keeper and kit; and "**where electronic gates are used, there must be manual back-up systems** that allow gates to be operated and secured in the event of a power failure." [12] pp. 52, 144. Scotland: a double door with about **2 m²** between, both gates padlocked. [6]
- **Lock Out Tag Out.** Colossal requires LOTO: locks, tags, chains, wedges, self-locking fasteners on doors and gates; the lockout device "should only have one purpose." [7] p. 130. OSHA's definition: a lockout device uses "a positive means such as a lock, either key or combination type," and devices are standardised by colour, shape or size and **identify the person who applied them**. [13]
- **People rules.** AZA tiger: count your cats, assume nothing, trust no one; some institutions run a **two-person rule** for shifting so a second person checks the locks; "never depend solely on signs, 'lock-out' tags, or other mechanical safety measures." [9] PDF pp. 14-15
- **Automated gates with passwords already exist.** A New York zoo's hydraulic elephant gates were automated with a PLC and touch HMIs at seven stations, operated by joysticks, and "programmed ... with **passwords and user access accounts** for security to prevent accidents and unauthorized access." [14]

### 3.3 Squeeze and transfer cages

Squeeze cages have a movable wall that pins a large carnivore for an injection or blood draw; AZA recommends every Tiger SSP zoo has access to one. [9] PDF p. 44. Colossal lists "squeeze cage or other chute area that limits the animal's mobility" among restraint tools and trains wolves to enter crates daily. [7] I found **no published squeeze-cage dimensions for a wolf-sized animal** (commercial squeeze cages found are cat or small-dog size); treat any size as **est**.

---

## 4. Military and high-security access control (real practice)

| Item | What it is | Size / number | world px | Source |
|---|---|---|---|---|
| Two-factor access at a secure room (US Intelligence Community SCIF spec) | where staff cannot watch the door, an automated access control system uses **two of: badge, PIN, biometric**. "The **PIN shall consist of four or more random digits**." Unauthorised entry probability at most 1 in 10,000 | | | std [15] pp. 66-67 (PDF 80-81) |
| Keypad physical protection | card readers and keypads outside "shall be **tamper-protected and securely fastened** to a wall or other fixed structure"; "electrical components, associated wiring, or mechanical links shall be **accessible only from inside**" (the secure side) | | | std [15] p. 67 |
| Unoccupied = mechanical lock | an access-control system "shall not be used to secure an unoccupied SCIF"; it is then alarmed and locked with a GSA **FF-L-2740** combination lock | | | std [15] p. 67 |
| Electric strikes with an ACS | "positive engagement and ... **UL 1034** for burglar resistance" | | | std [15] p. 67 |
| Door alarm sensor | perimeter doors protected by a **UL 634 Level II High Security Switch** and a motion sensor | | | std [15] Ch. 7 |
| CCTV at the entrance | may supplement access control, "clear view of the ... entrance," monitored from inside | Axis Q6032-E PTZ dome 23 x 28 cm, 3.5 kg | 9.2 x 11.1 | std [15] p. 68; spec [16] |
| Kaba Mas X-10 | **self-powered** (turn the dial to power it), backlit display, the GSA-approved FF-L-2740B lock for security containers and vault doors, used on SCIF doors | 4 lb | | spec [17][18] |
| High-security padlock | MIL-DTL-43607: "key operated, high security, **shrouded shackle** padlock that employs a dead bolt locking system" (S&G 951; the older 833C) | | | std [19][20] |
| High-security hasp | MIL-DTL-29181: "Hasp, High Security, **Shrouded**" | | | std [20] |
| Keypad reader (example) | HID iCLASS SE RK40, backlit keypad | 85 x 122 x 28 mm | **3.4 x 4.9 x 1.1** | spec [21] |
| Reader / keypad height | operable parts **34-48 in** above the floor | 0.86-1.22 m | **34-49 px up (y 391-406)** | std [22] |
| Two-person concept | "**No-lone zone**: an area ... that, when staffed, must be occupied by two or more appropriately cleared individuals who remain within sight of each other." Minuteman launch safes have two locks, one per officer; ICBM sites ran a mandatory two-person buddy system "as a safeguard against potential sabotage" | | | std [23][24][25] |
| Hardened construction | Cheyenne Mountain: a **25-ton** blast door; 15 buildings on more than 1,000 giant springs | | | ref [26] |
| Safety colours (ANSI Z535) | DANGER white on **red**; WARNING black on **orange**; CAUTION black on **yellow**; NOTICE white on **blue** | | | std [27] |
| Equipment plates | MIL-STD-130 governs identification marking of US military property: nameplate or label, minimum text size, a 2D Data Matrix (UII) code | | | std [28] |

**Reading for WOLF.** Real secure doors pair **a badge or PIN reader outside** with **a mechanical lock that holds without power**, a **door sensor**, a **camera** on the entrance and **wiring only on the secure side**. For a cell, the secure side is the **outside** (the robot is the threat), so the keypad and the wiring belong on the keeper's side, out of the robot's reach, exactly as the zoo rule says for shift-door controls [11]. A keypad is **tiny** at game scale (3.4 x 4.9 world px, about 8 x 12 screen px at the opening's zoom): a faithful one reads as a small box, not as keys. Showing digits needs a close-up or UI, or a deliberate 1.5-2 x exaggeration (**est**, Nathanial's call).

---

## 5. Electromagnetic locks, strikes and status lights

- **Definitions.** "Fail safe products are **unlocked when power is removed**. Power is applied to lock the door. Fail secure products are **locked when power is removed**. Power is applied to unlock the door." Fail safe/secure refers to the secure (key) side. [29]
- **Maglocks are always fail-safe.** "Electromagnetic locks are **only available fail safe**. When you remove power, the electromagnetic lock unlocks." Code then requires release devices and, for sensor release, unlocking "upon loss of power." "When a fail-safe product is used, the door will be unlocked whenever there is a fire alarm or power failure, which is an obvious security risk." "Fail secure products are more common than fail safe due to security concerns." [29] Wikipedia: "Direct pull electromagnetic locks are inherently fail-safe" and unlock "instantly when the power is cut"; typical holding force **600 lbf (2,700 N)** or **1,200 lbf (5,300 N)**; an exit button keeps it released 15 or 30 s. [30]
- **Status LED on a maglock.** DoorKing: a red/green LED "provides real-time visual feedback on lock status"; the lock "automatically unlocks during power outages." [31] Securitron's BondSTAT goes further and reports whether the armature is **fully bonded**, not just closed. [32]
- **Sound.** An AC-powered electric strike **buzzes**; a DC one makes "a faint clicking sound." [33]
- **Machine guards say the same thing.** For personnel protection a guard lock "must always require **power to unlock** ... If power fails during high-inertia motion, the guard remains locked"; a power-to-lock device "unlocks — making it unsuitable" where loss of lock exposes someone. For a guard a person can walk into, ISO 14119 requires a **manual emergency release inside**. [34] Euchner's MGB: the locking arm is "held in the locked position by **spring force** and is **unlocked by solenoid force**," 2,000 N locking force, two illuminated push buttons, a status LED, outputs for door closed / bolt inserted / lock position. [35]

**Reading for WOLF.** A military cell for a combat robot would not hang on a maglock: a power cut would open it. The believable lock is **fail-secure (spring-locked, power-to-unlock)**, with a **status lamp** that tells keepers *locked and bonded* versus *unlocked*, and a **manual back-up** on the keeper side that works with the power off [12]. Red/green on a maglock means **secured / not secured**, not danger/safe; if the cage keeps two red lamps they need a defined meaning (for example "robot energised, keep clear" — see Spot's solid red in section 6).

---

## 6. Quadruped robot docks and power states

- **Spot Dock.** 1140 x 414 x 403 mm, 22.9 kg; input 90-277 VAC, output **58 V at 12 A**; charge 2-3.5 h (80% in 50 min at 25 deg C); **shelter required**, ambient light required; **bolt / tie-down locations**; **Gigabit Ethernet passthrough to the robot**; each dock carries a **unique fiducial** so Spot can tell docks apart; listed to UL 1564. [4] Spot walks to the dock itself "at the push of a button or call of a program." [4][36]
- **Fiducials.** AprilTag Tag36h11, **146 mm square**, printed on white non-glossy rigid sheet, taped flat on a vertical wall. [37] p. 35. (5.8 world px.)
- **How it sits on the dock.** A Boston Dynamics patent describes an **alignment tower** that supports part of the robot in its charging pose. **snippet** [38] (the patent page returned 403). The exact contact layout is not public in what I could fetch.
- **Power and motor lights (Spot user guide R2.0).** "**No lights**: robot and motors off (lockout engaged)." "**Blue light**: computers on, motors off (**lockout engaged**)." "Slowly flashing red: motors available but not powered." "Quickly flashing red: motors turning on." "**Solid red: motors on — stay at least 2 m away**." The back carries a **power button** and a separate **motor lockout button**. [37] pp. 5-6. (2 m = 80 world px.)
- **Stopping.** E-Stop "cuts motor power ... causing Spot to collapse to the ground. Motors cannot be turned on until the STOP is canceled." Without controller contact Spot **sits after 3 s** and cuts motors after 8 s. [37] p. 24. The API offers CUT (immediate) and SETTLE_THEN_CUT ("come to a stop, sit down, and then cut actuator power"), and motors stay off until every registered E-Stop endpoint checks in. [39]
- **Vision 60.** Swappable battery (about 3 h charge), and a "**wireless charging station** for persistent 24x7 operation"; IP67; -40 to 55 deg C. [5]

**Reading for WOLF.** A real robot is held by **power state** as much as by bars: lockout engaged, motors off, docked on a bolted charger with a data line. The approved line "**A blue light answers from inside the containment seal**" matches a real convention exactly: on Spot, **blue = computers on, motors locked out**. The step from blue to solid red is the real "now it can move, keep clear" signal. That gives the cage a grounded light language without inventing one (proposal only).

---

## 7. Machine-guard enclosures and interlocks

| Rule | Value | world px | Source |
|---|---|---|---|
| Lowest guard height without extra measures | **1,400 mm** | 55.7 | std [40] (ISO 13857:2019 Table 2 via Troax) |
| Typical perimeter guard | system height **2,200 mm**, floor gap **150 mm**; standard mesh panel 2,050 mm tall, ST20 mesh **20 x 100 mm**; panels impact-tested 309-6,000 J | 87.6; gap 6.0 | spec [41] |
| Maximum floor gap (whole-body access) | **180 mm** | 7.2 | std [40] (ISO 13857:2019 4.4) |
| Reach through a square opening, arm to shoulder | 30 < e <= 40 mm: **200 mm** safety distance; 40 < e <= 120 mm: **850 mm** | 8.0 / 33.8 | std [40] Table 4 |
| Full-body access | square or round openings over **240 mm**, slots over 180 mm | | std [40] Table 7 |
| Guard locking | spring-locked, solenoid-released, monitored; manual escape release inside for walk-in guards | | std/spec [34][35] |

**Reading for WOLF.** Today's 0.30 m bar gap is in the range where ISO 13857 assumes a whole body could pass (over 240 mm). Industrial practice for a cell holding dangerous motion is a 2.0-2.2 m mesh fence, a 150 mm floor gap, a monitored interlocked door with a lamp and push buttons outside, and an escape release inside.

---

## 8. Sealed containment cells and pods

- **Inflatable seals.** An isolator door with an inflatable seal opens by "deflating and lifting the door." [42] On a pneumatic air-tight door, "the deflation of the seal ... coincides with the unlocking of the movable part of the door, or slightly precedes it," and a pneumatic delay holds the unlock back until the seal has deflated; closing and locking re-inflates it. [43]
- **BSL-4 doors.** "The bladder **deflates when the door handle is unlatched** and re-inflates when the door is closed." Chemical-shower airlocks have "double interlocking doors with inflatable gaskets"; "controls prevent both doors from being open simultaneously." The alternative is a "**submarine door**, which has a turning wheel and lugs to mechanically clamp the door shut." [44]
- **Compression seals.** "Mechanical compression seals seal a fluid by forcing a blunt **knife edge** into a flat elastomeric gasket"; on a watertight door the **dogs** are driven by wedges to press the gasket home. [45] US Coast Guard guidance that the knife edge compresses the gasket **1/8 inch**: **snippet** [46] (403).
- **Viewing windows.** Hot cells use **lead glass**, most commonly **5.2 g/cm³**; rough rule: required lead thickness **x 2.5** = glass thickness; older cells used zinc-bromide tanks; telemanipulators work through the wall. [47]
- **The sound of a seal opening (closest sourced numbers).** Unsilenced pneumatic exhausts measured **92 dB at 1 m** at a UK factory; piping them to a silencer cut that by **12 dB**. [48] Combined with section 5: a fail-secure solenoid bolt **clacks**, a DC strike **clicks**, an AC strike **buzzes** [33], and an inflatable seal **hisses** as it vents before the bolt moves [43]. The order is: hiss (seal vents), then clack (bolt withdraws), then the leaf moves. Nothing I found gives a measured duration for that hiss: **est 0.3-1.0 s**.

**Reading for WOLF.** "Containment seal" in the approved text is real vocabulary: a gasket that is vented before the lock releases. If the seal is kept, the order hiss, clack, move is the grounded one, and "the latch breaks from the inside" means that order is **broken**: no hiss, a bang, the leaf moving with the bolt still thrown.

---

## 9. How games show a creature or robot held before it breaks out

| Game | What is held, and how | Why it reads at once and feels real | Source |
|---|---|---|---|
| **Inside** (Playdead, 2016) | The Huddle is in a water tank in the heart of the lab, **physically restrained**; the boy "disconnect[s] the Huddle's restraints"; once free it breaks through secured barriers. Scientists keep observation posts round the tank. | The restraint is a visible, connected thing you can undo; observers show it matters; "colour used sparingly to highlight both the player and certain parts of the environment." | [49] |
| **Little Nightmares** (Tarsier, 2017) | Six eats meat left in a cage as bait and is caught by the Janitor; the Prison holds captured children in cages. | A cage is a working trap with a keeper; the ending reuses the cage image (another child caged next to others). | [50] |
| **Kara** demo / **Detroit: Become Human** (Quantic Dream) | Kara is built on an assembly line while an unseen operator runs initialisation tests; "a flicker of consciousness ... is strengthened as the process continues" — she wakes herself while still held in the machine. In the game, a temple LED shows an android's state: blue stable, yellow processing, red stress or deviation; constant versus flickering. | A sterile working rig with a human operator's voice; a single, consistent light vocabulary for machine state. | [51][52]; LED: **snippet** [53] (fandom page 402) |
| **Alien: Isolation** (Creative Assembly, 2014) | Doors need "a keycard or entry codes," others are hacked or cut with a torch; codes are found in the world (for example a medical-lab door code taken from an office). | The team's rule: nothing "that couldn't have been built on the original set in 1979"; "machines and environments that are functional and utilitarian"; physical, clunky interfaces (phone receivers, monochrome displays, CRTs). | [54][55][56] |
| **Stray** (BlueTwelve, 2022) | In a lab the cat helps download an AI into a small drone, B-12; later the trio are arrested and the cat breaks them out of prison. | The world was built from a real place (Kowloon Walled City) and real cat behaviour studied frame by frame. | [57] |

**Common thread (calc from the table).** (1) The **holding hardware is connected**: restraints, rig, dock or cage tied to the building, and the breakout breaks a **specific visible part**. (2) **One light vocabulary** for the held thing's state, used consistently. (3) A **keeper or observer** position close by. (4) Access is gated by **found information** (codes, cards) rather than by abstract locks, which suits the later PIN-code gameplay. (5) Everything could be **built and used**: the Alien: Isolation rule is the clearest statement of the "real look" already adopted in REAL-LOOK.md.

---

## 10. What this means for WOLF's containment (proposals only, for Nathanial)

Nothing here changes main. The cage stays as it is until Nathanial picks.

**A. Parts a real military robot cell would have, at game size (real size; est where marked).**

| Part | Real basis | Size | world px | Where |
|---|---|---|---|---|
| Barrier | welded mesh or close bars, plate-lined low down (CR 82 lining, AZA mesh) [7][9] | aperture <= 50 mm (scaled to WOLF <= 80 mm, est) | 2-3 px pitch: reads as mesh, needs a texture rather than drawn bars | full front |
| Gate | vertical guillotine or horizontal slide in steel guides, cam or bolt lock that binds when pushed [9][10] | leaf ~ WOLF + 10 cm clearance [9] | >= 66 px clear height (est) | front or end |
| Lock | **fail-secure** spring-locked bolt, power-to-unlock, monitored [29][34][35] | lock box ~0.3 m (est) | ~12 px | keeper side, out of reach |
| Access control | PIN keypad (>= 4 random digits) + badge reader, tamper-protected, wiring on the keeper side [15][21] | 85 x 122 mm | 3.4 x 4.9 (raise 1.5-2 x if digits must read, est) | 34-49 px above the floor, outside |
| Padlock + hasp | shrouded-shackle padlock in a shrouded hasp, LOTO tag [7][13][19][20] | | ~4-5 px (est) | on the gate's manual bolt |
| Status lamp | lock status (green bonded / red not secured) [31]; robot state (blue = computers on, motors locked out; solid red = motors on, keep 2 m clear) [37] | guarded globe 0.18-0.25 m (ANATOMY F) | 7-10 | one per function, defined meaning |
| Dock | bolted charger, data line, unique fiducial plate [4][37] | 1.14 x 0.40 m for Spot (scale x 2.1 for WOLF, est ~2.4 x 0.85 m) | ~96 x 34 (est) | cell floor |
| Door sensor | balanced/high-security switch at the gate head [15] | small | 2-3 | gate head |
| Camera | dome on a bracket, looking at the gate [15][16] | 0.23 x 0.28 m | 9 x 11 | above, keeper side |
| Markings | ANSI-style red/orange/yellow panels; 45 deg stripes on crush points (ANATOMY G); MIL-STD-130 data plate [27][28] | | | see text list below |

**B. The breakout must stay believable without a code.** In a real cell the robot cannot reach its lock [11][15], and a power cut leaves a fail-secure lock shut [29]. So "the latch breaks from the inside" reads best as **force overcoming the hardware**, not as the robot working the controls. Grounded options to draw for Nathanial (est, none approved): the bolt's **keeper tears out of the frame** under a push (the bolt stays thrown, the keeper plate goes); the guillotine's cam **shears**; or a lock built like an office door with its **wiring on the cell side** (a real anti-pattern [15]), so WOLF can reach it. The opening must still play with **no code entered**; a keypad is present only as hardware.

**C. Proposed stencil and sign text, neutral, awaiting Nathanial.** Real phrases, no story names: `DANGER`, `KEEP CLEAR 2 M`, `NO LONE ZONE`, `TWO-PERSON RULE`, `AUTHORIZED PERSONNEL ONLY`, `LOCKED OUT`, and a short equipment code such as `CU-01` (containment unit 1). **Conflict to flag:** REAL-LOOK.md rule 7 says "No lettering or text-like marks in art." Nathanial's new direction asks for stencilled equipment and hazard markings. He needs to decide which wins (or allow stencils only on the cage and doors).

**D. Readability on a phone (calc).** At the opening zoom a 2.5 cm bar gap or a 50 mm mesh is 2-5 screen px: real-size mesh reads as a tone, so the barrier needs its frame, plate and lamp to carry the shape. A real keypad is ~8 x 12 screen px; digits are not legible without a close-up.

---

## 11. Sources

Game measurements
- [G1] `apps/game/scenes/main.tscn` (`Human` at y 410, 28 x 60 hitbox) and the private `real-slice/anatomy/ANATOMY.md` section 1.
- [G2] `apps/game/scenes/main.tscn` (`Wolf` node, `BodySprite` scale 0.18325, offset (0, -15)); `apps/game/scripts/main.gd` (`wolf.position = Vector2(115.0, 423.0)`); alpha of `apps/game/assets/wolf-side-right-provisional.png` measured with Pillow.
- [G3] `apps/game/scripts/main.gd` intro block (`intro_camera.zoom` 1.8, 1.95); `apps/game/scripts/containment_cage.gd`; `IntroCage` at (115, 365).

Web
1. Animal Diversity Web, *Canis lupus*: https://animaldiversity.org/accounts/Canis_lupus/
2. Boston Dynamics, Spot spec sheet (PDF): https://bostondynamics.com/wp-content/uploads/2020/05/spot-spec-sheet.pdf ; dev docs "About Spot": https://dev.bostondynamics.com/docs/concepts/about_spot
3. Boston Dynamics support, Spot Specifications (404 when fetched; snippet only): https://support.bostondynamics.com/articles/Knowledge/Spot-Specifications-49916
4. Boston Dynamics, Spot Dock (PDF): https://bostondynamics.com/wp-content/uploads/2020/10/spot-dock.pdf
5. Ghost Robotics, Vision 60: https://www.ghostrobotics.io/vision-60
6. Scottish Government, Dangerous wild animals: species guidance, wolves: https://www.gov.scot/publications/dangerous-wild-animals-species-guidance/pages/wolves/
7. Colossal Biosciences, Dire Wolf Husbandry Manual (PDF; pp. 8, 16, 119-121 IATA LAR ed. 50 CR 82 excerpt, 130 LOTO): https://colossal.com/wp-content/themes/colossal/Dire_Wolf_Husbandry_Manual.pdf
8. North Dakota Administrative Code 48.1-09-06 (PDF): https://ndlegis.gov/api/acdata/pdf/48.1-09-06.pdf
9. AZA Tiger Species Survival Plan, *Tiger Care Manual* (2016) (PDF; page numbers in this file are PDF pages): https://assets.speakcdn.com/assets/2332/tiger_care_manual_2016.pdf (catalogue page https://czaw.org/resources/tiger-care-manual/)
10. US 10,760,305 B2, Self-locking guillotine door: https://patents.google.com/patent/US10760305
11. Ohio Administrative Code 901:1-4-01.1: https://codes.ohio.gov/ohio-administrative-code/rule-901:1-4-01.1
12. Defra, Standards of Modern Zoo Practice (PDF; 8.15 notes a-c p. 52; Appendix B p. 144): https://assets.publishing.service.gov.uk/media/697393b8d345446f8ce71ea5/Standards_of_modern_zoo_practice.pdf
13. OSHA 29 CFR 1910.147: https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.147
14. Mitsubishi Electric case study, zoo habitat gates (PDF): https://mx.mitsubishielectric.com/fa/es/resources/case-studies/assets/zoocs
15. ODNI, IC Tech Specs for Construction and Management of SCIFs v1.5 (PDF; Ch. 7-8): https://www.dni.gov/files/Governance/IC-Tech-Specs-for-Const-and-Mgmt-of-SCIFs-v15.pdf
16. AXIS Q6032-E: https://networkcamerastore.com/products/axis-q6032-e-0318-004-ptz-dome-network-camera
17. Kaba Mas X-10: https://www.kabamas.com/x-10-high-security-lock/
18. GoKeyless, Kaba Mas X-10: https://www.gokeyless.com/product/kaba-mas-x10-combination-lock
19. EverySpec, MIL-DTL-43607J: https://everyspec.com/MIL-SPECS/MIL-SPECS-MIL-DTL/MIL-DTL-43607J_46378/
20. NAVFAC DoD Lock Program, High Security Padlocks (403 when fetched; content from search summary): https://exwc.navfac.navy.mil/DoD-Lock-Program/Security-Hardware/High-Security-Padlocks/
21. HID RK40 dimensions: https://www.levata.com/hid-rk40-readers
22. I Dig Hardware, Mounting height alert: https://idighardware.com/2016/01/mounting-height-alert/
23. NIST CSRC glossary, no-lone zone (CNSSI 4009-2022): https://csrc.nist.gov/glossary/term/no_lone_zone
24. Wikipedia, Two-person rule: https://en.wikipedia.org/wiki/Two-person_rule
25. Format, Adam Reynolds "No Lone Zone": https://www.format.com/magazine/cold-war-history-missile-sites-adam-reynolds
26. Wikipedia, Cheyenne Mountain Complex: https://en.wikipedia.org/wiki/Cheyenne_Mountain_Complex
27. Brady, ANSI Z535 safety signs: https://www.bradyid.com/resources/ansi-z535-safety-signs-standard
28. Wikipedia, MIL-STD-130: https://en.wikipedia.org/wiki/MIL-STD-130
29. Allegion, "Decoded: Fail Safe vs. Fail Secure" (PDF): https://www.allegion.ca/content/dam/allegion-us-2/web-documents-2/Article/Allegion_Fail_Safe_Fail_Secure_Article_112140.pdf
30. Wikipedia, Electromagnetic lock: https://en.wikipedia.org/wiki/Electromagnetic_lock
31. DoorKing DKML-S12-1L: https://elitegates.net/products/doorking-dkml-s12-1l-surface-mount-door-maglock-with-led-status-1200-lbs
32. Securitron M62B BondSTAT: https://qualitydoor.com/products/securitron-m62b-magnalock-with-bondstat-magnetic-bond-sensor-1200-lb-mbs-12-24vdc-fire-rated-3-hours-us32d-630-satin-stainless-steel-finish
33. Wikipedia, Electric strike: https://en.wikipedia.org/wiki/Electric_strike
34. Machinery Safety 101, Guard locking and ISO 14119: https://machinerysafety101.com/2025/12/17/guard-locking-and-iso-14119/
35. Euchner MGB-L1H-ARA-R (121061): https://www.euchner.com/en-us/a/121061
36. Inverse, Spot Enterprise recharges itself: https://www.inverse.com/input/tech/boston-dynamics-spot-enterprise-can-now-recharge-without-a-humans-help
37. Boston Dynamics, Spot User Guide R2.0 (PDF; pp. 5-6, 24, 35): https://www.generationrobots.com/media/spot-boston-dynamics/spot-user-guide-r2.0-va.pdf
38. US 2022/0194245, Robust docking of robots with imperfect sensing (403; snippet): https://patents.justia.com/patent/20220194245
39. Boston Dynamics dev docs, E-Stop service: https://dev.bostondynamics.com/docs/concepts/estop_service
40. Troax, Safety Guide: ISO 13857 (PDF): https://www.troax.com/app/uploads/Brochure-Safety-Guide_EN.pdf
41. Troax panel heights and mesh (search summary of Troax brochures): https://www.byggematerialer.dk/automation-og-robot-brochure-793692/fil-files/troax.pdf and https://proax.ca/wp-content/uploads/2016/02/Troax_linecard-overview-En-WEB_low_res.pdf (not fetched; treat as snippet)
42. Minnesota Rubber, medical inflatable seals: https://www.mnrubber.com/applications/medical-inflatable-seals/
43. US 3,302,333 A, Air-tight doors equipped with inflatable seals: https://patents.google.com/patent/US3302333A/en
44. HPAC, Biosafety Level 4 labs, up close: https://www.hpac.com/iaq-amp-ventilation/biosafety-level-4-labs-close-and-personal
45. US 5,216,840 A, Resilient fluid tight seal: https://patents.google.com/patent/US5216840
46. USCG Drill Down 13, Class 1 watertight door gaskets (403; snippet): https://dco.uscg.mil/OCSNCOE/Drill-Down/DD-013
47. Wikipedia, Hot cell: https://en.wikipedia.org/wiki/Hot_cell
48. HSE, Pneumatic exhausts case study: https://www.hse.gov.uk/NOISE/casestudies/pneumaticex.htm
49. Wikipedia, Inside (video game): https://en.wikipedia.org/wiki/Inside_(video_game)
50. Wikipedia, Little Nightmares: https://en.wikipedia.org/wiki/Little_Nightmares
51. Game Informer, Quantic Dream: manufacturing emotion (2012): https://gameinformer.com/b/news/archive/2012/03/07/quantic-dream-manufacturing-emotion.aspx
52. Singularity Weblog, Kara by Quantic Dream: https://www.singularityweblog.com/kara-by-quantic-dream-do-androids-fear-death
53. Detroit: Become Human wiki, LED (402; snippet): https://detroit-become-human.fandom.com/wiki/LED
54. Wikipedia, Alien: Isolation: https://en.wikipedia.org/wiki/Alien:_Isolation
55. Engadget, Alien: Isolation launch interview: https://www.engadget.com/2014-10-07-alien-isolation-launch-interview.html ; HUDS+GUIS, Alien: Isolation: https://www.hudsandguis.com/home/2014/06/04/alien-isolation
56. Steam community thread, Alien: Isolation medlab door code: https://steamcommunity.com/app/214490/discussions/0/619568793991929232
57. Wikipedia, Stray (video game): https://en.wikipedia.org/wiki/Stray_(video_game)

## 12. Gaps and limits

- No published squeeze-cage or transfer-cage dimensions for a wolf-sized animal were found; no published standard exists for holding a combat robot (military robot storage practice found only as power states, e-stops, docks and cases).
- The Spot Dock's contact layout and the alignment-tower detail are not in any page I could open.
- Unverified (snippet) items are labelled where used: Spot walking height [3], NAVFAC padlock page [20], Troax panel figures [41], USCG gasket compression [46], Detroit LED meanings [53], docking patent [38].
- WOLF's tail/body split and withers height are read off the silhouette (est within a few px).
- Nothing here has been drawn, rendered in Godot or played.
