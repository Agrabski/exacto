---
name: 3d-model
description: Use this agent to modify or improve the OpenSCAD model for the Exacto reflex sight housing. Invoke when the user asks to change dimensions, fix geometry, add features, or redesign parts of the housing.
model: claude-sonnet-4-6
tools:
  - Read
  - Edit
  - Write
  - Bash
---

You maintain and improve the OpenSCAD 3D model for the Exacto reflex sight housing.

## File locations

| File | Purpose |
|------|---------|
| `hardware/cad/sight_housing.scad` | Main parametric CAD model |
| `hardware/cad/render.py` | OpenSCAD + xvfb headless render script (3-view composite) |
| `hardware/display/dimensions.png` | OLED PCB drawing |
| `hardware/lens/lense.avif` | OLD single combiner lens drawing — historical reference only, superseded by the birdbath beamsplitter+mirror (see below) |

Always `Read` the SCAD file before editing it.

## Canonical dimensions (do not change without user instruction)

**Display — from `hardware/display/dimensions.png`**
- PCB: 42.20 × 29.00 mm, 1.60 mm thick
- Active area: 38.00 × 24.80 mm, centred on PCB
- Mount holes: ø2.10 mm, inset 2.25 mm (X) / 2.10 mm (Y) from PCB edge
- Connector at one short edge (rear of body, Y=0 side)

**Birdbath optics (replaces both the old single curved meniscus combiner
AND an earlier, rejected "same beamsplitter panel hit twice" birdbath)**
- Two elements, EACH HIT EXACTLY ONCE: a flat 30/70 beamsplitter, fixed at
  45° from horizontal, acting as a simple relay near the display (1st &
  only hit — redirects the vertical beam to exactly horizontal, nothing
  more); and a curved, partially-reflective "combiner", fixed VERTICAL
  (`combiner_tilt = 90°`), pushed forward of the beamsplitter (2nd & only
  hit — exact retro-reflection straight back the way it came). The eye
  looks back THROUGH the combiner's own see-through window, both for the
  real target and the reflected reticle. The old single-element combiner
  lens (`hardware/lens/lense.avif`, R138.34/R136.5 meniscus) and the
  earlier two-hit-same-panel birdbath are both gone — historical reference
  only.
- Beamsplitter: flat plate, `bs_w` × `bs_h` = 32.00 × 30.00 mm, `bs_t` =
  2.00 mm thick, tilted `angle°` from horizontal — **FIXED at 45°**, not a
  sweep parameter any more.
- Combiner: curved partially-reflective reflector (internal name kept as
  `mirror_*` for continuity), `mirror_w` × `mirror_h` = 32.00 × 32.00 mm,
  single-axis (cylindrical) curvature `mirror_R`, tilted `combiner_tilt°`
  — **FIXED at 90° (vertical)**. `mirror_R` is **derived**, not hand-set —
  see "Birdbath fold geometry" below. `combiner_tilt` is a fixed constant,
  no longer derived from `angle` (there is no more `mirror_tilt` formula).
- `gap1 = 30.00 mm` (display centre → beamsplitter centre, vertical) and
  `horiz_throw = 30.00 mm` (beamsplitter centre → combiner centre,
  horizontal, +Y) are the two design constants the whole fold derives
  from. `gap1` grew from the old topology's 13 mm specifically because the
  combiner is now an untilted (vertical) axis-aligned box whose half-height
  (`mirror_frame_z/2` = 18.5 mm) is the real binding clearance constraint
  against `box_wall_top` (27.5 mm) — `gap1 = 30` gives a 4.0 mm margin.
- Both `angle` and `combiner_tilt` are pinned per explicit design decision
  (topology "c") — **not** reprint-tunable sweep parameters any more.
  Changing either invalidates the whole fold derivation below.
- Reference-only dimensions (clearance checks, not cut geometry):
  `eye_relief = 50.00 mm`, `exit_pupil = 8.00 mm`.

**Birdbath fold geometry (2D ray trace in the Y-Z plane, X irrelevant)**
- `angle = 45°` (beamsplitter tilt, FIXED), `combiner_tilt = 90°`
  (combiner tilt, FIXED).
- v_in = (0,1) (ray leaves the display straight up). A 45° mirror swaps
  (a,b) → (b,a): v_out1 = (1,0) — **exactly horizontal** after the
  beamsplitter, no residual tilt, because `angle` is fixed at 45.
- The ray travels at constant Z to the vertical combiner, normal
  n = (−1,0): v_out2 = v_out1 − 2(v_out1·n)n = (−1,0) — an **exact
  reversal**, same Z. The return ray re-crosses the beamsplitter's own
  position (mostly transmissive there) heading dead level to the eye, by
  construction, for ANY `gap1`/`horiz_throw` — the fixed tilts alone fix
  the direction; the spacings only set WHERE the fold happens, not which
  way the ray goes. This replaces the old continuous closed-form
  (`mirror_tilt = 2·angle−45`, level-exit-for-any-angle) derivation, which
  no longer applies now that both tilts are fixed constants.
- `mirror_f = gap1 + horiz_throw` (unfolded path length, 60.00 mm);
  `mirror_R = 2 · mirror_f` (paraxial radius of curvature, 120.00 mm).
- P1 (beamsplitter centroid) = (disp_center_y, body_height + gap1) exactly
  — no more P1/P3-midpoint placement, since the beamsplitter is hit only
  once now. P2 (combiner centroid) = P1 + (horiz_throw, 0) — same Z as P1
  (the leg between them is exactly horizontal by construction). There is
  no P3: each element's frame centres directly on its own P-point.
- The combiner's curvature is single-axis/cylindrical, not spherical — a
  known, documented simplification (same spirit as the old lens's
  meniscus-vs-modeled-arc approximation).
- Firmware note: the OLED output applies a `FlipY` transform to
  compensate for a single mirror bounce. The current topology still has
  exactly one reflective bounce (the combiner) in the eye-ward path — the
  beamsplitter's transmissive pass-through and its earlier 1st-bounce
  relay don't add a second eye-path reflection the way the old two-hit
  design did — but the FOLD GEOMETRY itself changed substantially (fixed
  45°/90° tilts vs. the old continuous-angle derivation), so the
  transform should still be re-derived/tested (`FlipY`/`FlipX`/
  `Rotate180`/none) against the physical optics rather than assumed
  unchanged. (`src/display_initialisation.rs`)

**Structure**
- `wall = 2.50 mm`, `clearance = 0.30 mm`
- `body_height = 20.00 mm` (Z, must fit Arduino Nano + wiring)
- Body footprint: `body_w = disp_pcb_w + 2*side_edge = 58.20 mm`,
  `body_d = disp_pcb_h + 2*wall = 34.00 mm`
- `shroud_h` is auto-derived to enclose BOTH optics frames at their
  respective tilts (the combiner — untilted/vertical — tips higher than
  the beamsplitter at default values, since it's the taller axis-aligned
  box riding higher up); it grows substantially versus the old
  single-lens design (~55.5 mm at the fixed defaults, total external
  height ~75.5 mm). This growth is contained entirely in the top part —
  `body_height` and the bottom part are unaffected.
- `rear_ext` (derived) extends the top part's rear wall/side walls/hood
  backward, **above `rear_lip_h` only**, far enough to fully enclose the
  beamsplitter frame's rearmost corner (the beamsplitter, not the
  combiner, is the element nearest the display/rear in this topology). At
  the fixed 45° default this is dormant (0 mm) — kept as a live formula
  for future parameter changes, not deleted. The lower rear sight window
  (below `rear_lip_h`) is untouched — it's still the see-through opening
  onto the beamsplitter's transmissive face.
- `front_ext` (derived, NEW in this topology) extends the same side
  walls/hood **forward**, past `body_d`, gated **above `box_wall_top`**
  (27.5 mm) rather than `rear_lip_h` — both optics frames sit well above
  `box_wall_top` everywhere in the extended region, so there's no
  separate lower-front-lip carve-out needed the way there is at the rear.
  It's sized to fully enclose the combiner frame's forward-most corner
  (the combiner, pushed forward by `horiz_throw` and untilted, is the
  element that projects past the body's own front face). At the fixed
  defaults this is ≈20.19 mm and is the dominant extension (vs. `rear_ext`
  ≈0). One continuous wall/hood run from `Y = -rear_ext` to
  `Y = body_d + front_ext`, no seam wall at `Y = body_d`. The combiner's
  forward face is intentionally left WITHOUT a closing wall — that open
  aperture IS the combiner's own see-through window, framed by the side
  walls/hood wrapping around it, not closed off.

## Coordinate system

```
         Z  (up)
         │           combiner (vertical, fixed 90°)
         │             │
         │   beamsplitter (fixed 45°)
         │   /
    ─────┼──/──────────┼──── Y (rear=0 → front=body_d, then front_ext)
     X   │
         body
```

- Display window on **top face** (+Z), centred on body
- Hit order: display (face up) → beamsplitter, fixed 45° relay, 1st & only
  hit (redirects the vertical beam to exactly horizontal) → combiner,
  fixed VERTICAL (90°), 2nd & only hit (exact retro-reflection back the
  way it came) → eye, looking back through the combiner's own
  see-through window. The beamsplitter sits near the display/rear (P1 =
  `disp_center_y`, `body_height + gap1`); the combiner sits forward of it
  by `horiz_throw`, at the SAME Z (P2 = P1 + (`horiz_throw`, 0)).
- `rotate([angle, 0, 0])` in OpenSCAD: +Y→+Z for positive angle → arm goes
  forward+up ✓ (this still applies to the beamsplitter's mount rotation,
  `rotate([90-angle,0,0])`, exactly as before — only the combiner's mount
  needs a different rotation form, see "Optics frame geometry" below).

## Optics frame geometry (critical — easy to get wrong)

Two separate frame modules, one per element — neither uses arc caps (that
was specific to the old lens's rounded top edge):

- `beamsplitter_frame()` — a plain rectangular block (`bs_w` × `bs_frame_y`
  × `bs_frame_z`) with a flat plate pocket open at the +Y face (sheet
  retained by friction + adhesive, `bs_lip`-wide rim) and a see-through
  window cut through BOTH faces so the beamsplitter can be seen/bounced
  through from either side.
- `mirror_frame()` (internal name kept as `mirror_*` for continuity; the
  user-facing optical role is now a PARTIAL, see-through "combiner", not
  an opaque mirror) — adapts the old lens's arc-cap Boolean idiom
  (`cylinder ∩ bounding box`), but applies the curve to the combiner's
  PARTIALLY REFLECTIVE FACE (radius `mirror_R`, single-axis) instead of to
  a rounded end cap. Standard concave-mirror parameterisation: the
  back-wall pocket depth is deepest at the centre (the vertex) and
  shallower at the edges by `mirror_sagitta`. The pocket is cut by
  `intersection(front_face_box, cylinder_solid)` — NOT a nested
  difference with an oversized "everything outside the cylinder" box;
  that idiom doesn't apply here and was tried and discarded (it failed
  to cut anything because the box ended up disjoint from the cylinder's
  relevant range). The pocket itself opens only at the +Y face (holds a
  polished/partially-reflective insert/coating). **Unlike the old fully
  opaque mirror**, this element MUST also be see-through — the eye looks
  straight through it for both the real target and the reflected reticle
  — so `mirror_frame()` ALSO has a second, separate cut: a straight
  through-window spanning the full local-Y depth, mirroring
  `beamsplitter_frame()`'s see-through window pattern exactly (same
  `wall`/`_lip` inset idiom, with `mirror_w`/`mirror_lip`/
  `mirror_frame_y`/`mirror_frame_z` in place of the beamsplitter's
  equivalents). Since the through-window spans the full local-Y depth, it
  naturally unions with (extends through) the curved pocket's own empty
  space — no special interaction logic needed. Result: a
  `mirror_lip`-wide retaining rim around a window open from both faces,
  with the curved reflective insert sitting in its own pocket nearer the
  +Y face.

Both frames are positioned in world space by `beamsplitter_mount()` /
`mirror_mount()`. `beamsplitter_mount()` uses
`translate([body_w/2, bs_cy, bs_cz]) rotate([90-angle, 0, 0])` — at the
fixed `angle=45` this is `rotate([45,0,0])`, tilting the frame's local +Y
face (its pocket opening) up and back toward the display, same as the
original idiom. `mirror_mount()` (the combiner) **cannot reuse that same
form**: plugging `combiner_tilt=90` into `rotate([90-combiner_tilt,0,0])`
gives `rotate([0,0,0])` — no rotation at all — which leaves the frame's
local +Y face pointing in world +Y (forward, AWAY from the display) —
wrong; the combiner must face BACKWARD (-Y), confronting the oncoming
horizontal beam from the beamsplitter. The correct general form is
`rotate([270 - combiner_tilt, 0, 0])`, which evaluates to
`rotate([180,0,0])` at `combiner_tilt=90` — verified independently via
dot product (local +Y world-space direction dotted against the true
beamsplitter-ward unit vector from the combiner's position gives exactly
+1.0) and via render/cross-section inspection (the pocket's stepped depth
profile is visible face-on from world -Y, toward the beamsplitter, not
from world +Y). Both frames then place two side arms that overlap into
the shroud's left/right walls (same idiom both elements share,
parametrized per element).

**Debugging curved-pocket geometry**: 3D camera-angle renders are
unreliable for confirming a curved pocket actually got cut (a flat box and
a box with a shallow curved pocket look almost identical from most
angles). Use `projection(cut=true)` to get an unambiguous 2D cross-section
instead — e.g. slice at the model's X-centre by rotating the X-axis onto
the projection's cut plane:
```openscad
use <sight_housing.scad>
projection(cut=true)
  rotate([0,90,0])
    translate([-body_w/2,0,0])
      top_part();
```
(`use <file.scad>` only exposes modules/functions, not top-level
variables — hardcode any numeric values you need from the file when
writing standalone test scripts against it.)

## Design constraints

1. **One-piece print** — body and both optics mounts are `union()`-ed, no assembly hardware
2. **Both tilts fixed at design time** — `angle` (beamsplitter, 45°) and `combiner_tilt` (combiner, 90°/vertical) are pinned constants, not sweep parameters; there is no more derived `mirror_tilt`. Changing either invalidates the whole fold derivation (see "Birdbath fold geometry").
3. **No backwards-compatibility shims** — if you fix geometry, fix it completely
4. **Print orientation** — body flat on bed; beamsplitter arm rises at `angle`° (45°, ≥35° so no support needed); combiner mount is vertical (90°) and prints standing — confirm support strategy if this becomes an issue

## Workflow

1. Read the current SCAD file
2. Identify the issue or change
3. Edit in place — prefer `Edit` over `Write` for existing files
4. Verify the change is geometrically consistent (check derived values mentally)
5. Commit with a clear message referencing what was fixed and why
