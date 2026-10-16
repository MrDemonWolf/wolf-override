"""Clean-layer previews (the cleaned Codex paint in the room's plates, as installed). Scratch."""
import json, os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rmodel as M
import compose as C
L = os.path.join(M.TRACK, "layers")
O = os.path.join(M.TRACK, "out", "assets", "rooms")
cont = Image.open(os.path.join(L, "container", "clean-container.png")).convert("RGBA")
cs = json.load(open(os.path.join(M.DESIGN, "container", "spec.json")))
for side in (1, -1):
    for th in (0, 45, 90):
        C.compose(L, "clean", side, th, os.path.join(M.TRACK, "previews", f"clean-{'exit' if side > 0 else 'entry'}-{th:02d}.png"),
                  wall_name="clean-wall.png", front_name="clean-front.png", beyond_name="clean-beyond.png",
                  faces_dir=os.path.join(L, "leaf"), container_img=(cont, cs["canvas"]["x0"], cs["canvas"]["y0"]),
                  far_override=os.path.join(O, "records-far.png"), mid_override=os.path.join(O, "records-mid.png"))
print("ok")
