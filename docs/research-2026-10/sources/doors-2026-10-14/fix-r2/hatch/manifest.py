"""Updates the scratch game copy's asset manifest for the junction exit door (scratch only):
registers junction-exit-atlas.png, retires corridor-bulkhead-open.png and its art-source original
(deleted with this change), and says the junction hatch art is now the entry hatch only.
Usage: python manifest.py GAME_APP_DIR"""
import hashlib
import json
import sys

G = sys.argv[1]
p = f"{G}/assets/manifest.json"
import os
m = json.load(open(os.path.abspath(G).replace("/hatch/game/", "/main-hatch/") + "/assets/manifest.json"))  # always from main
sha = hashlib.sha256(open(f"{G}/assets/props/junction-exit-atlas.png", "rb").read()).hexdigest()
REC = "docs/research-2026-10/sources/junction-exit-door-2026-10-13/"
entry = {
    "asset_id": "junction-exit-atlas",
    "path": "apps/game/assets/props/junction-exit-atlas.png",
    "source_or_tool": "Design-first build, 2026-10-13, following the corridor door end's method: the cross-wall, its doorway, the sliding leaf, the exit bolt's housing, conduit, wall pack, status lamp and the service passage beyond were ray-cast by Python from measured parts with the room's camera and its visible light sources (" + REC + "tools/geom.py, design.py, compose.py, leaf.py, noleaf.py; NumPy and Pillow), painted inside those shapes with Codex's built-in image_gen tool in edit mode (sessions hatch-wall, 01a13425-e4a3-79f3-b16d-bde40869d3cf, and hatch-leaf, 01a13425-e4a3-7aa0-ae2f-c035b413d7c7, 2026-10-13), then cleaned up and packed deterministically by Python (" + REC + "tools/cleanup.py and install.py; NumPy, SciPy and Pillow). No text anywhere in it.",
    "source_reference": "Design and paint record in " + REC + " (NOTES.md, design/v6/spec.json, placement.json and every tool); the Codex sessions (ids, outputs, SHA-256 and use) in its provenance.txt, with the raw outputs kept byte for byte with their C2PA content credentials (caBX chunk) in its codex/<job>/out/. Design language from docs/research-2026-10/sources/corridor-door-end-2026-10-12/ and docs/research-2026-10/art-direction/REAL-LOOK.md section 8.",
    "terms_reference": "https://openai.com/policies/terms-of-use/",
    "rights_review_status": "Provisional AI-assisted gameplay prop: deterministic construction drawings painted with an AI image tool, then cleaned up deterministically. Awaiting Nathanial Henniges's review; final commercial asset-rights review remains open; not covered by the code/docs GPL license.",
    "modifications": "One lossless RGBA atlas (SHA-256 " + sha[:16] + "...) at 2 source px per world px holding the Service Junction exit door's pieces: the service passage beyond with the pocket and the rear of the sill; the sliding steel leaf (shut, lit in place); the cast-concrete cross-wall behind the walk line with the far jamb, its steel-lined reveal and pocket mouth, the steel threshold, the status lamp's back box, guard and conduit, the floor between the walk line and the wall's foot, and the exit bolt panel's riser down to a floor flange; the status lamp's glass; and the cross-wall in front of the walk line with the near jamb, the lintel, the exit bolt's housing, its conduit and the wall pack. Paint is kept only inside each part's designed mask; the design's exact alpha is re-imposed, values are held to the design's light plan, the concrete is calmed and graded to the corridor door end's values in the junction's cold light.",
    "implementation_status": "In use since 2026-10-13 as the Service Junction's exit (junction_room.gd EXIT_* regions and world positions): the passage, the leaf and the wall behind the walk line draw under the actors, the wall in front of it over them; the leaf slides back along the wall into the pocket as the exit bolt releases it (exit_leaf_anchor), and the lamp's glass is tinted live in the bolt's colour. Imported lossless with mipmaps, drawn with linear-with-mipmaps filtering. It replaces the exit use of junction-hatch.png and the passage cut from corridor-bulkhead-open.png (deleted 2026-10-13 with its art-source original; both in the Git history).",
}
out = []
for a in m["assets"]:
    if a["asset_id"] in ("corridor-bulkhead-open", "door-a-corridor-open-master"):
        continue
    if a["asset_id"] == "junction-hatch":
        a["implementation_status"] = "In use since 2026-10-09 for the Service Junction's entry hatch at x 80, 0.206x (144 px tall), with its lamp drawn green. From 2026-10-09 to 2026-10-13 it was also the exit hatch at x 880 (its lamp in the bolt's colour, lifting and fading over a passage cut from corridor-bulkhead-open.png when the bolt arced); since 2026-10-13 the exit is the sliding steel door in junction-exit-atlas.png."
    out.append(a)
    if a["asset_id"] == "corridor-seal-atlas":
        out.append(entry)
m["assets"] = out
st = m["status"]
old = "the pressure bulkheads in door design A (the junction's sealed, breaking, blown and front-lip images, and the corridor's open image, whose doorway fills the junction's exit hatch, with their full-size approved originals under apps/game/art-source/doors/)"
new = "the Service Junction exit door's atlas (2026-10-13: the cross-wall, sliding steel leaf, exit bolt housing, status lamp glass and the service passage beyond in one image), the pressure bulkheads in door design A (the junction's sealed, breaking, blown and front-lip images, with their full-size approved originals under apps/game/art-source/doors/)"
assert old in st
m["status"] = st.replace(old, new)
open(p, "w").write(json.dumps(m, indent=2, ensure_ascii=False) + "\n")
print("manifest updated", sha)
