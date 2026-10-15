"""Fix round 3: records round 3 in the game copy's asset register (apps/game/assets/manifest.json) for the seven
assets this round changed: what changed, how (no Codex session this round: deterministic on round 2's cleaned
paint, or drawn from the model), new size and SHA-256. Keeps the round 1 and round 2 notes. Idempotent: an
earlier round-3 note is replaced. Run once, after the final rebuild. usage: manifest_r3.py REPO_ROOT"""
import hashlib
import json
import sys

from PIL import Image

ROOT = sys.argv[1]
p = ROOT + "/apps/game/assets/manifest.json"
m = json.load(open(p))


def info(rel):
    f = ROOT + "/" + rel
    im = Image.open(f)
    return f"{im.width}x{im.height} {im.mode}", hashlib.sha256(open(f, "rb").read()).hexdigest()[:16]


HOW = "deterministic, no new paint (doors-r1/fix-r3, NumPy, SciPy and Pillow; no Codex session this round)"
NOTES = {
    "records-doors-atlas": "Fix round 3 (2026-10-14, review r3 R3-2; " + HOW + "): designed wear on the leaf faces where use and water put it (hand grime round the lever, primer rubbed through on the latch stile, a grime band and heel marks low down, cart scrapes at 0.35-0.95 m, dirt in the edges; tools/leafwear.py) and the paint's own grain lifted, so the faces keep their texture at play size; the leaves' light is set at runtime (RecordsRoom.*_LEAF_LIGHTS door light, *_LEAF_EXPOSURE). Now {size} (SHA-256 {sha}...), the same regions.",
    "records-far": "Fix round 3 (2026-10-14, human r3; " + HOW + "): the passage battens read as fittings: the opal diffuser at a frosted, cool value instead of clipped white, the housing, clips and end caps in their own spill (tools/rgrade2.py batten_r3). Now {size} (SHA-256 {sha}...).",
    "junction-door-atlas": "Fix round 3 (2026-10-14, review r3 S1, S3, S4; " + HOW + "): the threshold plate at the deck's value with a dull 12 mm nose; the blast's fresh fracture faces and torn bare steel lighter than the weathered face, the soot kept dark (jgrade2.py); the thrown leaf dished 0.16 m (resting on its middle and on the chunk, its left end 0.17 m off the deck), 0.4 m further along the lane clear of the wall's stub, its landing corner crushed, scraped along its slide, soot by its latch edge (lying3.py, from jdesign's own leaf geometry); skyline-packed, so the atlas shrinks. Now {size} (SHA-256 {sha}...).",
    "junction-entry-atlas": "Fix round 3 (2026-10-14, review r3 R3-2, R3-3, human r3; " + HOW + "): round 2's header and service-line lengths over the cross-wall's face and their escutcheons removed, the face refilled with its own concrete (the header turns up into its riser at the corner, the room's own elbow, junction-mid); designed wear on the leaf faces (leafwear.py; its grain lifted more than Records', JENTRY_GRAIN 2.2/1.9, as the leaf draws smaller in the junction's camera); the leaf's light set at runtime (JunctionRoom.ENTRY_LEAF_LIGHTS, ENTRY_LEAF_EXPOSURE). Now {size} (SHA-256 {sha}...); regions moved 2 px (JunctionRoom.ENTRY_*_REGION).",
    "junction-exit-atlas": "Fix round 3 (2026-10-14, review r3 R3-1, S2, human r3; " + HOW + "): the violet key fringe on the sliding leaf's left and bottom edges removed (its edge pixels take the leaf's interior colour; tools/fringecheck.py passes every door atlas); the room's four back-wall pipes drawn from the model as pipes running from the corner into 50 mm steel escutcheon rings on the face (narrow upright ellipses), the old knob halo refilled with the face's concrete; the floor between the wall's foot and the walk line is the room's own wet deck, moved in the room's camera, in the wall's contact shadow, out of the wall's gain. Now {size} (SHA-256 {sha}...), the same regions.",
    "junction-mid": "Fix round 3 (2026-10-14, review r3 R3-3, human r3; jemid.py RESTORE_ELBOW, deterministic): the header's elbow and riser and the service line's end between the entry wall's back corner and x 147 are the room's own again (round 2 erased them), so the far plate's ceiling lamp stays hidden behind the elbow as on main. Now {size} (SHA-256 {sha}...).",
    "junction-far": "Fix round 3 (2026-10-14, human r3; " + HOW + "): the entry passage's batten as in records-far. Now {size} (SHA-256 {sha}...).",
}
done = []
for a in m["assets"]:
    if a["asset_id"] in NOTES:
        size, sha = info(a["path"])
        a["modifications"] = a["modifications"].split(" Fix round 3")[0].rstrip() + " " + NOTES[a["asset_id"]].format(size=size, sha=sha)
        if "(fix round 2)" in a.get("rights_review_status", ""):
            a["rights_review_status"] = a["rights_review_status"].replace("(fix round 2)", "(fix round 3)")
        done.append(a["asset_id"])
open(p, "w").write(json.dumps(m, indent=2, ensure_ascii=False) + "\n")
print(done)
