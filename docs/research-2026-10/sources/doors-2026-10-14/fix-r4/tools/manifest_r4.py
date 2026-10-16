"""Fix round 4: records round 4 in the game copy's asset register for the one asset this round changed (the junction
entry atlas), with size and SHA-256; keeps earlier notes; idempotent. usage: manifest_r4.py REPO_ROOT"""
import hashlib, json, sys
from PIL import Image
ROOT = sys.argv[1]
p = ROOT + "/apps/game/assets/manifest.json"
raw = open(p).read()
m = json.loads(raw)
NOTE = ("Fix round 4 (2026-10-14, review r4 S1; deterministic, no new paint: doors-r1/fix-r4/tools/steamlap.py, NumPy, SciPy and Pillow; no Codex "
        "session): the mid plate's own steam by the header elbow laps onto the cross-wall's face within 7 world px of its back corner (its density "
        "from the dark-channel prior, mirrored about the corner, in the cloud's own colour, fading to nothing), so the cloud no longer ends on a "
        "ruler-straight line at the corner; the leaf's light is set at runtime (JunctionRoom.ENTRY_LEAF_LIGHTS, ENTRY_LEAF_FILL). Now {size} (SHA-256 {sha}...), the same regions.")
for a in m["assets"]:
    if a["asset_id"] == "junction-entry-atlas":
        f = ROOT + "/" + a["path"]
        im = Image.open(f)
        size, sha = f"{im.width}x{im.height} {im.mode}", hashlib.sha256(open(f, "rb").read()).hexdigest()[:16]
        a["modifications"] = a["modifications"].split(" Fix round 4")[0].rstrip() + " " + NOTE.format(size=size, sha=sha)
        a["modifications"] = a["modifications"].replace("JunctionRoom.ENTRY_LEAF_LIGHTS, ENTRY_LEAF_EXPOSURE)", "JunctionRoom.ENTRY_LEAF_LIGHTS; round 4: ENTRY_LEAF_FILL)")
        print("updated", size, sha)
for a in m["assets"]:
    if a["asset_id"] == "records-doors-atlas":
        a["modifications"] = a["modifications"].replace("RecordsRoom.*_LEAF_LIGHTS door light, *_LEAF_EXPOSURE)", "RecordsRoom.*_LEAF_LIGHTS; round 4: *_LEAF_FILL replaces *_LEAF_EXPOSURE)")
open(p, "w").write(json.dumps(m, indent=2, ensure_ascii=False) + "\n")
