import sys
from PIL import ImageFont
F = sys.argv[1]
def font(n, s, w="Regular"):
    f = ImageFont.truetype(F + "/" + n, s); f.set_variation_by_name(w); return f
story = font("Roboto-Variable.ttf", 17); hint = font("Roboto-Variable.ttf", 14)
def rows(text, f, width):
    total = 0; widest = 0
    for para in text.split("\n"):
        line = ""; n = 1
        for w in para.split(" "):
            t = (line + " " + w).strip()
            if f.getlength(t) > width and line:
                widest = max(widest, f.getlength(line)); line = w; n += 1
            else:
                line = t
        widest = max(widest, f.getlength(line)); total += n
    return total, int(widest)
D = [
 ("PIN_K1_GRANTED", "The locker runs on its own controller; the lockdown never reached it.\nA grey cartridge sits in its reader. The reader shows OVERWRITE COMPLETE; the casing is still warm.", 855),
 ("PIN_K2_REFUSED", "LANE TERMINAL / ACCESS: SECURITY\nMAINTENANCE CODE REFUSED. CODE HELD BY PAIRED UNIT: LANE SENTRY.", 855),
 ("PIN_K2_OFFER_DISCLOSE", "The sentry still holds the code. I'll read it, or you take its port.", 715),
 ("PIN_K2_OFFER_PRESS", "The sentry holds the code. My readout or its port.", 715),
 ("PIN_K2_WOLF_READ", "WOLF reads the pairing code off the downed sentry. It shows on his readout.", 855),
 ("PIN_K2_PORT_READ", "Morgan reads the pairing code off the sentry's service port. WOLF keeps watch.", 855),
 ("PIN_K2_PORT_READ_ALONE", "Morgan reads the pairing code off the sentry's service port.", 855),
 ("PIN_K2_LOCKOUT", "The lane beacons flash amber while the terminal locks itself.", 855),
 ("PIN_K1_LOCKOUT", "The keypad locks itself for a few seconds.", 855),
 ("PIN_K2_WOLF_AWAY", "WOLF crosses to the downed sentry.", 855),
]
H = [
 ("PIN_K1_HINT", "E: open the media locker."),
 ("PIN_K1_HINT_OPEN", "The media locker is open."),
 ("PIN_K2_HINT", "E: use the lane terminal."),
 ("PIN_K2_HINT_PORT", "HOLD E: read the sentry's service port."),
 ("PIN_K2_HINT_PORT_PROGRESS", "HOLD E: read the sentry's service port, 2 of 3."),
 ("PIN_K2_HINT_KNOWN", "E: enter the lane code."),
 ("PIN_K2_HINT_DONE", "The lane terminal's log is copied."),
 ("USE_FORM", "HOLD USE: read the sentry's service port, 2 of 3."),
]
for i, t, w in D:
    print(i, rows(t, story, w), "limit", w, "x 3 rows")
for i, t in H:
    print(i, int(hint.getlength(t)), "of 526")
