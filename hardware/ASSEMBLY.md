# Exacto Reflex Sight — Parts List & Assembly

Build guide for the **XM-1E1** housing
defined in [`cad/sight_housing.scad`](cad/sight_housing.scad).

> **Versioning:** `XM-<gen>E<rev>`. The `E<rev>` number is incremented
> **only after a revision has been sent to print** — not on ordinary design
> edits. Current revision: **XM-1E1**.

The sight is a two-part printed housing that holds a small OLED, folds its
image through a birdbath relay (flat beamsplitter → curved partial-mirror
combiner), and clamps to a MIL-STD-1913 Picatinny rail. All electronics
other than the display live in a forward box with a removable lid.

Overall envelope: **58.2 mm wide × 114 mm long × ~50 mm tall** (rail clamp
adds ~11.6 mm below).

---

## 1. Printed parts

Export each by setting `part=` at the top of `sight_housing.scad` (or
`openscad -D 'part="…"'`) and slicing the resulting STL.

| `part` | Component | Qty | Notes |
|--------|-----------|-----|-------|
| `bottom` | Bottom part — display holder + forward electronics box + **fixed** Picatinny jaw | 1 | Hosts the OLED pocket, cable channel, and all brass inserts except the lid/combiner |
| `top` | Top part — optics shroud + beamsplitter mount + combiner mount | 1 | Holds both optical elements |
| `bar` | Picatinny clamp bar (removable left jaw) | 1 | Pulled in by 2 cross-bolts |
| `lid` | Forward-box top lid | 1 | Screws onto the box bosses |

`part="both"` renders the full assembled preview (all four parts in place)
for checking fit; it is not a printable export.

### Print recommendations
- Material: PLA/PETG (PETG or ABS/ASA if the sight will see sun/heat).
- Layer height ≤ 0.2 mm around the optic pockets for a clean friction fit.
- Suggested orientation: print **bottom** and **top** on their flat seam
  face (z = 20 mm split plane) so the lap joint and insert bores come out
  true; print the **lid** flat; print the **bar** on its outer flat face.
- The combiner pocket has a shallow (~1 mm) cylindrical curve — no supports
  needed, but don't over-extrude or the optic won't seat flat.

---

## 2. Optical elements (not printed)

| Item | Size | Qty | Notes |
|------|------|-----|-------|
| Plate beamsplitter, 30/70 (R/T) | 32 × 30 mm, 2.0 mm thick | 1 | Flat sheet. Drops into the angled (45°) frame pocket from the front (+Y) face |
| Curved partial-mirror combiner | 32 × 32 mm, 4.0 mm backing, **cylindrical R ≈ 120 mm**, concave reflective face | 1 | Sits vertical. **Concave/reflective face must point back toward the beamsplitter (−Y)** |

Both are retained by friction fit in their pockets **plus adhesive** (no set
screws — the merged side arms bury any screw access). A ~1.5 mm rim laps each
optic at the rear; the eye looks straight through both windows.

### Recommended / DIY materials

A true cylindrical R≈120 mm partial-mirror combiner is not a common catalog
part, so the optics are the part that drives sourcing. Cheap, hobby-tool
options below; all are knife/scorer/heat-gun workable with no custom optics
order (total optics cost ~$15–30).

**Beamsplitter (flat — the easy one):**
- **Best match:** 70/30 (or 30/70) **teleprompter glass** — dielectric
  partial-mirror film on glass. Score and snap to 32 × 30 mm. ~2 mm thick,
  which matches the pocket. ~$10–20.
- **Cheaper alt:** **two-way ("one-way") mirror acrylic** — saw/laser
  cuttable, won't shatter. Reflectivity is nearer 50/50 and less spectrally
  even, but fine for a prototype. ~$5–15.
- If using thin film-on-PET, laminate it to a 2.0 mm clear carrier so it
  seats flush under the retaining lip. Avoid fragile pellicle beamsplitters
  for a DIY build.
- **Orientation (ghost suppression):** teleprompter glass is partially
  reflective on one face and AR-coated on the other. Mount it with the
  **AR-coated face outward** (toward the real world) so the second surface
  doesn't throw a ghost/double image. This is the standard DIY-AR (Project
  North Star) practice.

**Combiner (curved partial mirror — the hard one):**
- **Recommended DIY:** thermoform **two-way mirror acrylic** over a
  3D-printed **R = 120 mm convex cylindrical (or spherical) form**. Heat to
  ~120–160 °C (heat gun / oven) and slump. Sag over the 32 mm aperture is
  only ~1.07 mm, so the curve is gentle and forgiving. Reflective face goes
  **concave / rear** (−Y) per Step 2 below.
- **Acceptable substitute:** a **spherical** R≈120 mm partial mirror — over a
  32 mm window the difference from cylindrical is minor and spherical forms
  are easier to make/buy.
- **Exact but not cheap:** the serious DIY-AR route. Either a
  cylindrical/spherical concave mirror R = 120 mm (f ≈ 60 mm) with a partial
  coating from an optics supplier (Edmund/Thorlabs), or a **CNC / diamond-
  turned solid PMMA reflector** (the method Leap Motion's Project North Star
  uses, and what vendors like CombineReality / Smart Prototyping sell). Tens
  of dollars plus likely a custom coating, but the surface accuracy is what
  makes the image distortion-free.
  - **How to obtain one (made to spec):** there is no off-the-shelf optic
    for this surface — ready-made AR combiners (e.g. Project North Star
    reflectors) are large freeform/ellipsoidal parts and do **not** match the
    32 × 32 mm, R = 120 mm cylinder, so don't try to adapt one. Instead,
    export the combiner surface from
    [`cad/sight_housing.scad`](cad/sight_housing.scad) as a STEP/STL and send
    it to an online CNC service (PCBWay, Xometry, Protolabs, or a local shop)
    requesting **optical-grade PMMA, machined then vapor-polished** for the
    32 × 32 mm, R = 120 mm concave face. Finish with a partial-mirror
    treatment: a sputter/optics house can apply a real beamsplitter coating,
    or for a budget build apply two-way mirror film / a light spray-on
    "mirror tint" to the convex rear face. Diamond-turning gives the best
    surface but needs a specialist shop (e.g. a custom-optics fabricator) and
    raises cost into the hundreds.
- **Salvage:** curved combiners from dead red-dot sights or cheap car-HUD
  reflectors are already partial mirrors, but their radius won't be 120 mm —
  only viable if you re-derive the optical block.

> **Important:** the model's ~50 mm eye relief and reticle collimation assume
> the **120 mm combiner radius** and the **concave-rear** orientation.
> Substituting a different curve (e.g. a salvaged combiner) invalidates the
> fold; re-check the optical block in
> [`cad/sight_housing.scad`](cad/sight_housing.scad) first.
>
> Combiner reflectivity is a trade-off: too high dims the see-through target,
> too low washes out the reticle. Two-way acrylic (~50/50) is a fine starting
> point — tune by swapping film/coating grades.
>
> **Ghosting:** a thermoformed two-way-acrylic combiner has no AR coating on
> either face, so expect some secondary (ghost) reflection — the known cost
> of the cheap route. DIY-AR builds (Project North Star) AR-coat the outer
> (convex) combiner face to kill it; a CNC/bought reflector can come coated.
> The small 32 mm aperture and gentle R = 120 mm curve keep distortion low,
> which is the one thing working in the thermoform route's favor.

---

## 3. Electronics

| Item | Qty | Notes |
|------|-----|-------|
| Waveshare 1.27" SSD1351 RGB OLED module | 1 | PCB 42.20 × 29.00 mm; active area 38.0 × 24.80 mm faces up |
| Microcontroller (Arduino Nano or equiv.) | 1 | Lives in the forward box; `body_height` is sized for a Nano + wiring |
| Battery + USB / power board | 1 | Forward box; cable exits the box front plug opening (14 × 9 mm) |
| Ribbon/flying lead, OLED → MCU | 1 | Routes **under** the PCB, down the cable channel, into the forward box |

---

## 4. Fasteners

All screws are **countersunk (flat-head)** except the PCB screws (head bears
on the PCB) and the Picatinny cross-bolts (head bears on the bar's outer
face). Insert bores and countersinks are generated by
[`cad/screw_mounts.scad`](cad/screw_mounts.scad) and `cad/picatinny.scad`.

| Joint | Screw | Qty | Brass heat-set insert | Qty |
|-------|-------|-----|------------------------|-----|
| PCB → body | M2 pan/cheese-head × **8 mm** | 4 | M2 (ø3.2 × 4 mm bore) | 4 |
| Top ↔ bottom side joint | M3 countersunk × **12 mm** (horizontal, 2 per side) | 4 | M3 (ø4.0 × 5 mm bore) | 4 |
| Forward-box lid | M3 countersunk × **12 mm** (vertical) | 2 | M3 (ø4.0 × 5 mm bore) | 2 |
| Picatinny clamp cross-bolts | M4 socket-cap × ~16 mm (horizontal) | 2 | M4 (ø6.0 × 6 mm bore) | 2 |

Screw lengths chosen from the available stock (M2: 8/20 mm; M3: 12/16/20 mm)
as the shortest that fully engages each insert. The M2 × 8 mm engages the
full 4 mm insert; both M3 × 12 mm leave the tip seated in solid material
behind the insert (no breakthrough into a cavity).

**Totals:** 4× M2 + 6× M3 + 2× M4 screws; 4× M2, 6× M3, 2× M4 brass inserts.

> Head geometry the model cuts for: M2 head ø4.0 mm / 1.5 mm thick,
> M3 head ø5.8 mm / 1.75 mm thick (countersink cones). Buy flat-head screws
> matching these so they seat flush.

---

## 5. Assembly

### Step 1 — Press the heat-set inserts
With a soldering iron set for brass inserts, press into the **bottom part**:
- 4× **M2** into the PCB-pocket floor bores (one near each PCB corner).
- 4× **M3** into the side-edge bores (2 per side, low, under the PCB line).
- 2× **M3** into the forward-box lid bosses (front inside corners).
- 2× **M4** into the fixed Picatinny jaw's mating face.

Keep inserts square to the bore; let them cool before loading.

### Step 2 — Bond the optics into the top part
- Seat the **beamsplitter** sheet into its 45° pocket from the front face;
  dab adhesive on the rim. It should sit flush under the retaining lip.
- Seat the **combiner** into its vertical pocket with the **concave
  reflective face toward the rear (−Y, toward the beamsplitter)**; bond.
- Let the adhesive fully cure before further handling.

### Step 3 — Fit and wire the display
- Solder/attach the OLED's flying lead and route it so it will exit the PCB
  underside.
- Drop the OLED into the top pocket of the **bottom part**, active area up
  through the window.
- Fasten with the 4× **M2** screws from the top into the PCB inserts. Snug
  only — don't crack the PCB.
- Route the ribbon down through the cable channel toward the forward box.

### Step 4 — Populate the forward box
- Place the MCU and battery in the forward box.
- Bring the display cable and any external power lead to the front plug
  opening.

### Step 5 — Join the two halves
- Lower the **top part** onto the **bottom part**: the top's side skirts lap
  over the rebates on the bottom's side edges.
- Drive the 4× **M3** countersunk screws horizontally through the skirts into
  the edge inserts (2 per side). Tighten evenly to clamp the lap.

### Step 6 — Close the forward box
- Set the **lid** onto the box bosses.
- Secure with the 2× **M3** countersunk screws.

### Step 7 — Mount to the Picatinny rail
- Hook the fixed (body) jaw onto one rail shoulder.
- Swing the rail up under the clamp ceiling; the recoil lug drops into a
  transverse rail slot.
- Fit the removable **bar** onto the opposite shoulder.
- Run the 2× **M4** cross-bolts through the bar into the body inserts and
  tighten alternately until the clamp grips. Do not overtighten plastic.

### Step 8 — Check
- Confirm the OLED image appears centered in the combiner window and the
  reticle/target are co-aligned (the level exit ray is fixed by the 45°
  beamsplitter + vertical combiner geometry).
- Verify nothing fouls the rail and the clamp holds under hand pressure.

---

## Reference dimensions (from the model)

| Parameter | Value |
|-----------|-------|
| Body (display head) | 58.2 W × 34 D × 20 H mm |
| Forward box length | 80 mm |
| Total rail length | 114 mm |
| Split plane (seam) | z = 20 mm |
| Beamsplitter tilt | 45° (fixed) |
| Combiner tilt | 90° / vertical (fixed) |
| Unfolded optical path | 60 mm (combiner R = 120 mm) |
| Nominal eye relief | ~50 mm |

See the header comment in `cad/sight_housing.scad` for the full optical
derivation.
