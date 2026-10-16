class_name Palette
extends RefCounted
## The named colours more than one script draws with, each written once. Constants only: nothing is
## made at run time. A colour only one script uses stays a constant of that script, and the UI's
## near-identical tints (BypassHandle.LABEL_TEXT and the menus' own) stay separate on purpose.

## Lit or working: the status lights, the hazard glows, the sentry's patrolling eye, sparks.
const AMBER: Color = Color("#f3ae4b")
## Done or safe: a cleared station, a preserved trace, a lit crank readout.
const GREEN: Color = Color("#a4f0c4")
## WOLF's colour: his contact, his name, a powered machine waiting on him, the default spark.
const CYAN: Color = Color("#8be3ff")
## The exit's pale green: its name and the bolt and exit-arc sparks.
const EXIT_GREEN: Color = Color("#c1f4d8")
## A station name at rest, one that has nothing to offer, and one that warns.
const LABEL_TEXT: Color = Color("#b0d1de")
const LABEL_MUTED: Color = Color("#8fa6b2")
const LABEL_ALERT: Color = Color("#ffc7c7")
## A station's name plate behind its text, and the plate's edge (also the bypass plate's leader).
const PLATE_BG: Color = Color(0.035, 0.06, 0.08, 0.8)
const PLATE_EDGE: Color = Color(0.29, 0.4, 0.45, 0.55)
## Unpowered: a dark machine's status light.
const BREAKER_IDLE: Color = Color("#d48954")
## A door's status lamp: red while it is shut, green once it stands open, AMBER while it moves (the
## corridor seal, both Records Access doors and the Service Junction's entry).
const LAMP_SHUT: Color = Color(0.9, 0.2, 0.17)
const LAMP_OPEN: Color = Color("#7dffa8")
## Drawn metal: frames and rails, the darker brackets, rods and housings, and their dim edges.
const STEEL: Color = Color("#4a6572")
const STEEL_DARK: Color = Color("#1b2630")
const DIM: Color = Color("#3e4f5a")
