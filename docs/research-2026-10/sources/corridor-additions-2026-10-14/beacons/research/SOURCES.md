# Beacons: real-world grounding (item d)

What a real caged red warning light on a hardened site is, and what the design took from each source.
Fetched 2026-10-13 (searches; the Eaton page timed out on a direct fetch, its figures are from the search extract).

1. Eaton Crouse-Hinds EV LED, EVLEDBX2C201R (hazardous-location LED luminaire, red heat- and impact-resistant
   glass globe, guard, wall bracket, 3/4 in hub): 7.25 in W x 16.81 in H x 12.56 in D, 11.1 lb, NEMA 4X / IP66,
   Class I Zone 1. https://www.eaton.com/ca/en-gb/skuPage.EVLEDBX2C201R.html
   -> the whole fixture's proportions (0.44 m tall: bracket plate, finned driver housing, guard collar, red globe,
      cast guard with mid ring and foot ring), the 3/4 in conduit entry into the bracket's top hub. design/spec.json.
2. Federal Signal 27XL explosion-proof LED warning light: steady-burning or flashing (60 flashes/min),
   six lens colours incl. red, 3/4 in NPT pendant, ceiling and wall mounts, optional dome guard, Type 4X / IP66.
   https://www.spartancontrols.com/getattachment/dcbfb451-a993-464c-9e30-25f21f7f231a/FS_27XL_SpecificationSheet.pdf
   -> red lamps in guards are steady OR flashing by configuration, wired through a 3/4 in NPT hub; a lens guard
      is a real, ordinary part (not decoration). Our lamp keeps main's soft 2.6 s pulse (no timing change).
3. Hazardous-location warning lights with guards and 3/4 in pipe/pendant mounts (Edwards 116 series datasheet,
   Crouse-Hinds EXSO steady-on beacon, Federal 151XST):
   https://www.walkerindustrial.com/v/vspfiles/pdf/datasheet/Edwards/ES-116dexsinhgw.pdf
   https://www.electrozad.com/2697991/Product/Crouse-Hinds-EXSO301R/120
   https://gexpro.com/p/36484/federal-signal/hazardous-location-strobe-warning-light-120v-ac-red/782979380740/151xst-120r
   -> guards protect the glass "against accidental collision"; feeds are rigid conduit into a threaded hub.
4. NEC 344.30, rigid metal conduit: secured within 3 ft (0.9 m) of every box or fitting, supports at most 10 ft apart.
   https://industrialmonitordirect.com/blogs/knowledgebase/nec-34430-conduit-stub-up-support-requirements-explained
   -> b0's feed down the column from the ceiling tray carries one-hole straps 0.29 m and 0.89 m above the bracket.
5. Blast-door interlocks and their indicator lamps (DNFSB weekly report on the Pantex blast door interlock: lights
   show each blast door open or closed; door-motion lights flash red while a door moves):
   https://dnfsbstg.dnfsb.gov/sites/default/files/document/3784/wr_20070406_34.pdf
   https://shopactiondirect.com/product/liftmaster-rgl24ly-red-green-light-visual-warning/
   -> red lamps near a sealed door on a defence site are interlock / lockdown status, which is what these do in
      the game (pulse in lockdown, settle when the room's route is cleared).

Not used: rotating mirror beacons (would need a moving beam, i.e. more runtime layers) and strobes (60 fpm flash
is harsher than main's pulse and would change timing). Mood references only; no Terminator/Skynet material.
