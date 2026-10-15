"""Fix round 2: records round 2 in the game copy's asset register (apps/game/assets/manifest.json), for the
seven assets this round changed: how they were made, the Codex sessions, new size and SHA-256. Run once,
after the final rebuild. usage: manifest_r2.py REPO_ROOT"""
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


R2 = "Codex's built-in image_gen tool in edit mode, fix round 2 (2026-10-13, review r2)"
NOTES = {
    "records-doors-atlas": (f"; fix round 2 (2026-10-13, review r2): both door ends re-designed and painted OPEN with no leaf in the doorway, so the space behind each doorway is built from its own design and never from a painted shut leaf (N1), the blank pipe-penetration plates removed (S2), form-panel joints and grouted tie cones on the cast faces, real 1.2 m LED battens in the passages ({R2}: sessions r2-records-exit 01a13647-baec-7350-92c0-7423ca7a90a8, r2-records-entry 01a13647-c485-7be1-993c-f75c5b7ee5b6, r2-records-parts 01a13647-ce6b-79c2-9fc8-85a101259ba7), cleaned up with detail only where the passage was visible in the paint, graded with fix-r2/tools/grade2.py (linear light, 0.60x the back wall at the corner, closed on render.sh frames) and packed deterministically",
                            "Fix round 2: one lossless {size} atlas (SHA-256 {sha}...), the same regions as round 1; the leaf faces despeckled, their room-face lever lifted; the leaves' level set at runtime by RecordsRoom.EXIT_LEAF_EXPOSURE and ENTRY_LEAF_EXPOSURE. No text anywhere in it."),
    "records-far": (None, "Fix round 2 (2026-10-13): the passage and vestibule behind the two doorways repainted into it from the open-state paints (sessions r2-records-exit, r2-records-entry), graded with grade2.py; now {size} (SHA-256 {sha}...)."),
    "junction-door-atlas": (f"; fix round 2 (2026-10-13, review r2): three full-surface hinges and a dull threshold on the sealed door (S3, S4), the near column after the blast as its own region (torn hinges with sheared pins, the spalled hinge-jamb corner with its bars, the arris angle torn loose, soot) and the latch face plate bent into the opening with sheared keeper lugs, all between 0.3 and 2.0 m (N4), the lane's shade behind the doorway, the batten over the door ({R2}: sessions r2-junction-sealed 01a1364d-2a8e-7910-9bad-505a77d6dee6, r2-junction-blown 01a13652-d4e1-7cf3-a649-307172683fe2), cleaned up, graded with grade2.py and packed deterministically",
                            "Fix round 2: one lossless {size} atlas (SHA-256 {sha}...): round 1's pieces plus the blown column (COLBLOWN: the same DoorColumn sprite once blown, no new draw call); the column's even flecks calmed. No text anywhere in it."),
    "junction-entry-atlas": (f"; fix round 2 (2026-10-13, review r2): re-painted OPEN with no leaf in the doorway (N1), the junction's header and service line carried through the cross-wall in sleeves with escutcheons (N2), a real batten in the passage ({R2}: session r2-junction-entry 01a13646-c4af-7ab3-a67d-4164a78298ea), cleaned up and graded with grade2.py; the pipe lengths over the face are the room's own header pixels from a plain run of it (jeinstall.py)",
                             "Fix round 2: one lossless {size} atlas (SHA-256 {sha}...); the leaf's level set at runtime by JunctionRoom.ENTRY_LEAF_EXPOSURE. No text anywhere in it."),
    "junction-exit-atlas": (f"; fix round 2 (2026-10-13, review r2): design v8: form-panel joints and tie cones, the room's four back-wall pipes through collars at the wall's corner, a forward-throw wall pack with its front glass lit and its pool on the leaf and threshold (S7), a brighter passage fitting ({R2}: session r2-junction-exit 01a136e0-2d99-7b51-8717-f97f71f4e193), cleaned up and graded with grade2.py (the face that sees the junction's corner fitting lit with it, N3)",
                            "Fix round 2: one lossless {size} atlas (SHA-256 {sha}...): the same pieces, the back piece from x 829.5 (it carries the bolt panel's riser at its new x). No text anywhere in it."),
    "junction-mid": (None, "Fix round 2 (2026-10-13, review r2 N2; fix-r2/jentry/tools/jemid.py, deterministic): everything under the entry's cross-wall, its doorway and the floor triangle between the wall's foot and the walk line erased (round 1 cleared only plate x 0-25); deck re-laid in that triangle from the plate's own deck 5 m nearer the camera along the room's vanishing lines (511, 162); the header's elbow above it erased (the header and service line run on into the wall); the guard rail ended on a post (its own right end, mirrored). Now {size} (SHA-256 {sha}...)."),
    "junction-far": (None, "Fix round 2 (2026-10-13): the service passage behind the entry doorway repainted into it from the open-state paint (session r2-junction-entry), graded with grade2.py; now {size} (SHA-256 {sha}...)."),
}
done = []
for a in m["assets"]:
    if a["asset_id"] in NOTES:
        add, mod = NOTES[a["asset_id"]]
        size, sha = info(a["path"])
        if add and "fix round 2" not in a["source_or_tool"]:
            a["source_or_tool"] = a["source_or_tool"].rstrip(".") + add
        a["modifications"] = a["modifications"].split(" Fix round 2")[0].rstrip() + " " + mod.format(size=size, sha=sha)
        if "(fix round 1)" in a.get("rights_review_status", ""):
            a["rights_review_status"] = a["rights_review_status"].replace("(fix round 1)", "(fix round 2)")
        done.append(a["asset_id"])
open(p, "w").write(json.dumps(m, indent=2, ensure_ascii=False) + "\n")
print(done)
