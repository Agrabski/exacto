// ============================================================
// Exacto Reflex Sight Housing — v4 (EOTech-style, two-part)
//
// Top-level ASSEMBLY.  It owns every base knob, computes every derived value,
// and passes them into the component modules (which live in their own files
// and take parameters — `use <>` imports modules/functions, never globals).
//
// Two screw-joined parts, split at the seam z = body_height (20 mm):
//   bottom_part()  base body = screen_body() + oled_mount() + front_box()
//                  + clamp.  The OLED rides on the body top in a tilted reflex
//                  seat, angled so the combiner reflects it up into the eye.
//   top_part()     optics head = eotech_shroud() + glass_frame_mount() (combiner)
//                  + fresnel_frame() (the collimator sheet, on the chief ray)
//   clamp_bar()    the removable Picatinny left jaw, in assembled position
//   box_lid()      the forward box's screw-on top lid
//
// Component files:
//   screen_body.scad     screen_body / rounded_box / side lap-joint cutters
//   shroud.scad          eotech_shroud
//   lens_frame.scad      lens_frame / lens_negatives / glass_frame_mount
//   oled.scad            display_pocket — Waveshare 0.96" OLED pocket + M2 bores
//   fresnel.scad         fresnel_frame / fresnel_negatives — Fresnel collimator
//   electronics_box.scad front_box / cable_channel / box_lid(+inserts) / engrave
//   picatinny.scad       MIL-STD-1913 two-part clamp
//   screw_mounts.scad    reusable M2/M3 insert + clearance + counterbore cutters
//
// Set `part` below to choose what to render/export.
//
// Display: Waveshare 0.96" OLED, 26×26 mm board (pocket lives in oled.scad),
//          in a tilted reflex seat below the combiner, facing up the reflected
//          chief ray so the combiner throws its image to the eye.
// Lens:    24.00 × 34.00 mm, 2.74 mm thick, arcs R16.97 both ends
// Fresnel: optional flat collimator sheet in the optics head, square to the
//          reflected chief ray, in the space `oled_dist` already reserves
//          between the display and the combiner.  See the `fresnel*` knobs
//          below; nothing else in the sight moves when it is fitted.
// ============================================================
use <picatinny.scad>
use <screw_mounts.scad>
use <screen_body.scad>
use <shroud.scad>
use <lens_frame.scad>
use <electronics_box.scad>
use <oled.scad>
use <fresnel.scad>
use <scad-common/gridfinity_bin_bottom.scad>

// ┌─────────────────────────────────────────────────────────┐
// │  CHANGE angle, RE-EXPORT STL, REPRINT                   │
// │  angle = combiner tilt from horizontal                  │
// │  45° = classic half-mirror reflex position              │
// └─────────────────────────────────────────────────────────┘
angle = 55; // degrees  (combiner tilt from horizontal; reflex reflects OLED→eye)

// Which piece to render/export: "both" (assembled), "top", "bottom",
// "bar" (removable Picatinny clamp jaw), "lid" (box top lid),
// "minimal" (bare display + combiner fixture, for optical alignment)
part = "both";

// ── Base knobs (single source of truth) ──────────────────────
box_len = 80.00; // forward electronics box length, front-to-rear (8 cm)

// lens = [w, h, t, top_r, lip]  (24×34 mm glass, 2.74 thick, R16.97 ends)
lens = [24.00, 34.00, 2.74, 16.97, 2.00];

wall = 2.50;
lens_wall = 1.50; // SLIM combiner-holder wall (independent of body wall)
shroud_wall = 3.00; // EOTech shroud wall / hood thickness
side_edge = 8.00; // THICK left/right edges (host the joint inserts)
clearance = 0.30;
body_height = 20.00; // must fit Arduino Nano + wiring
lip_h = 10.00; // FRONT lower lip height on the shroud
lap_h = 14.00; // vertical skirt overlap below the seam
skirt_t = 3.00; // skirt thickness (sits in a rebate on the bottom)
clearance_body = 3; // gap from body top to the tilted frame's lowest point

engrave = true; // set false to omit the engraved label
engrave_text = "Exacto XM-1E0";

$fn = 48; // special var — propagates into the used modules at call time

// ── Derived (uses accessor functions exposed by the components) ──
body_w = disp_pcb_w() + 2 * side_edge; // 58.20
body_d = disp_pcb_h() + 2 * wall; // 34.00
frame_y = lens_frame_depth(lens, lens_wall); //  5.74  frame depth (glass normal)
frame_z = lens_frame_height(lens, lens_wall); // 27.00  frame height along tilt

// Combiner (glass) centre in world space.  clearance_body is the gap from the
// body top up to the combiner's LOWEST point, so it stays honest as `angle`
// changes.
glass_cz = body_height + clearance_body + frame_y / 2 * cos(angle) + frame_z / 2 * sin(angle);
// Combiner pushed as far FORWARD (+Y) as it goes: frame_dy is its half-extent
// along Y after the tilt, so the front face ends 0.5 mm behind body_d.
frame_dy = frame_y / 2 * sin(angle) + frame_z / 2 * cos(angle);
glass_cy = body_d - frame_dy - 0.5;

// ── Reflex OLED placement (Waveshare 0.96", from oled.scad) ──
// TRUE reflex: the combiner reflects the display up to the eye.  The shooter's
// horizontal sightline (+Y) reflects off the θ-tilted combiner into the ray
//   r = [0, cos2θ, -sin2θ]        (points down and to the rear)
// so the OLED is placed along r, below the combiner, and pitched (90-2θ) about
// X so its screen faces back up r — square to the reflected chief ray, so its
// reflection lands in the eye.  The seat sits on the body top (bottom part).
oled_fp = 26.30; // PCB footprint + clearance (matches oled.scad)
oled_dist = 18.00; // OLED-centre distance below the combiner, along r
oled_seatwall = 2.00; // wall around the pocket / M2-insert stock
oled_below = 6.50; // seat stock below the screen (M2 inserts sink here)
oled_above = 2.00; // seat rim above the seated PCB
oled_floor_inset = 4.50; // floor rim kept around the cut (holds the M2 bosses)
oled_ray = [0, cos(2 * angle), -sin(2 * angle)];
oled_pitch = 90 - 2 * angle; // OLED tilt from horizontal (faces up the ray)
oled_pos = [body_w / 2, glass_cy, glass_cz] + oled_dist * oled_ray;
oled_screen_z = 1.60; // PCB front (lit) face above the pocket floor (oled.scad pcb_t)

// ── Fresnel collimator sheet (display → combiner, on the chief ray) ──
// A flat Fresnel sheet, cut to size, held in the OPTICS HEAD on a slab tilted
// onto the reflected chief ray — square to the display, so `fresnel_gap` is a
// true on-axis distance from the lit surface.  Nothing else moves: the slab
// grows into the space `oled_dist` already leaves between the two optics.
//
// `fresnel_gap` wants to be the sheet's back focal length to throw the reticle
// to infinity, and at these short focal lengths that is a sharp target — see
// the note in fresnel.scad.  The room here runs out around 9 mm; raise
// `oled_dist` for a longer-focus sheet (it slides the display down the ray
// without disturbing the fold).
fresnel_fitted = true;           // false = optics head exactly as before
fresnel = [26.00, 15.00, 1.00];  // [w (X), d (Y), t] of the sheet, cut to size
fresnel_gap = 7.00;              // lit surface → sheet underside, along the ray
fresnel_lip = 1.50;              // rim lapping the sheet's edge (aperture inset)
fresnel_wall = 2.00;             // slab wall around the sheet slot

// The slab leans forward as it rises, so its top-front edge is what runs out
// of room first — it has to stay behind the shroud's front lip.  Growing the
// gap or the sheet's depth walks it forward; this catches the overrun instead
// of letting the two halves quietly interfere.
fresnel_front_y = oled_pos[1]
  + fresnel_slab_d(fresnel, clearance, fresnel_wall) / 2 * cos(oled_pitch)
  - fresnel_slab_z1(oled_screen_z, fresnel_gap, fresnel, clearance) * sin(oled_pitch);
assert(!fresnel_fitted || fresnel_front_y < body_d - shroud_wall - 0.5,
       "Fresnel slab reaches the shroud's front lip — reduce fresnel_gap or fresnel[1]");

// Shroud height — auto-sized to enclose the tilted glass frame's top tip.
frame_tip_z = glass_cz + (frame_z / 2) * sin(angle) + (frame_y / 2) * cos(angle);
shroud_h = frame_tip_z - body_height + shroud_wall - 0.5;

// Y positions of the 4 side joint screws (2 per side).
side_screw_y = [body_d * 0.28, body_d * 0.72];

// Forward box geometry.  Box spans Y = body_d .. box_y1.
box_h = body_height + lip_h; // 30.00, reaches the lens opening
box_y0 = body_d; // box back (joins the optics head)
box_y1 = body_d + box_len; // box front (muzzle end)

// Picatinny rail runs the WHOLE length of the sight (optics head + box).
rail_len = body_d + box_len;

// Engraving placement: centred along the box, a little above its mid-height.
engrave_y = (box_y0 + box_y1) / 2;
engrave_z = box_wall_top(box_h) * 0.55;

// ── Reflex OLED mount ────────────────────────────────────────
// Split into a positive SEAT (unioned into the body) and a negative CAVITY
// (subtracted from the WHOLE bottom part) so that no body/holder material is
// left intruding into the display footprint.  The seat is a low tilted block on
// the body top, centred under the combiner and pitched so the OLED screen faces
// up the reflected chief ray (square to the combiner, so its image reflects
// into the eye).  Local Z is the screen normal: the screen opens toward +Z (up
// toward the combiner), the M2 inserts sink into -Z below the floor.
module oled_seat(pos, pitch, fp, seatwall, below, above) {
  seat = fp + 2 * seatwall;
  translate(pos)
    rotate([pitch, 0, 0])
      translate([-seat / 2, -seat / 2, -below])
        cube([seat, seat, below + above]);
}

// Clearance for the seat in the MATING half.  The top part descends straight
// down onto the bottom, so it must carry no material anywhere below the seat
// within the seat's footprint — that is the seat swept straight down.  The
// shroud's rear lip does exactly that as drawn, and holds the two halves
// ~4 mm apart at the seam; this cuts the lip's inner-lower edge back to a
// chamfer that follows the seat's tilt, leaving it continuous wall to wall.
// `clear` is a non-contact gap, so it is a little looser than a fitted joint.
module oled_seat_clear(pos, pitch, fp, seatwall, below, above, clear = 0.40,
                       drop = 40) {
  seat = fp + 2 * (seatwall + clear);
  module _block() {
    translate(pos)
      rotate([pitch, 0, 0])
        translate([-seat / 2, -seat / 2, -(below + clear)])
          cube([seat, seat, below + above + 2 * clear]);
  }
  hull() {
    _block();
    translate([0, 0, -drop]) _block();
  }
}

// The display cavity, cut from the whole bottom part:
//   • display_pocket() — the PCB recess (Z 0..~2) + four M2 insert bores,
//   • up-clear         — removes any body that rises above the seat top into the
//                        footprint, so the tilted screen sits in an open well,
//   • floor cut        — opens the pocket floor straight down to the holder's
//                        bottom edge (local Z = -below), flush, leaving a rim
//                        (inset) so the four M2 insert bosses survive.
module oled_cavity(pos, pitch, fp, below, above, inset) {
  translate(pos)
    rotate([pitch, 0, 0]) {
      translate([-fp / 2, -fp / 2, 0]) display_pocket();
      translate([-fp / 2, -fp / 2, above]) cube([fp, fp, 40]);
      translate([-fp / 2 + inset, -fp / 2 + inset, -below])
        cube([fp - 2 * inset, fp - 2 * inset, below + 0.1]);
    }
}

// ── Forward baseplate clear ──────────────────────────────────
// Removes the solid body-top plate in the strip between the OLED display
// footprint's world-Y forward edge and the body's front face (body_d).
// The tilted display's screen-normal leans toward +Y, so the plate in this
// strip sits physically "in front of" the display, blocking light and
// wasting material.  A world-axis-aligned box cut is used (no tilt) because
// the removed strip is driven by the Y footprint projection rather than by
// the optical normal.
//
//   fwd_y : world-Y of the display footprint's forward edge, computed as
//           pos[1] + (fp/2) * cos(pitch).  At the fixed parameters this is
//           ≈ 29.6 mm; the cut spans 29.6 → body_d = 34 mm (≈ 4.4 mm strip).
//   X     : pos[0] ± fp/2 — just the display footprint's own width, centred
//           on the OLED, leaving the rest of the plate (including the thick
//           left/right edges) intact.
//   Z     : 0 … body_height + ε — full plate depth cleared in the strip.
//
// Does NOT touch: M2 insert bosses (inside oled_floor_inset, rear of the
// footprint, world Y ≈ 25–27), joint inserts (X < side_edge / X > body_w −
// side_edge), front_box shell (Y ≥ body_d), cable_channel (already void).
module oled_forward_clear(pos, pitch, fp, body_w, body_d, body_h, side_edge) {
  fwd_y = pos[1] + (fp / 2) * cos(pitch);
  cut_y = body_d - fwd_y;
  if (cut_y > 0)
    translate([pos[0] - fp / 2, fwd_y, 0])
      cube([fp, cut_y, body_h + 0.1]);
}

// ── Two parts ────────────────────────────────────────────────
module bottom_part() {
  difference() {
    union() {
      // Body top is solid (hold_display = false); the OLED rides on it in the
      // tilted reflex seat below, reflecting up into the combiner.
      screen_body(
        body_w, body_d, body_height, side_edge, wall, clearance,
        hold_display=false
      );
      oled_seat(oled_pos, oled_pitch, oled_fp, oled_seatwall, oled_below, oled_above);
      front_box(body_w, box_y0, box_len, box_h, body_height);
      // Picatinny clamp FIXED body — runs the WHOLE length on the underside.
      translate([body_w / 2, 0, 0]) picatinny_clamp_body(rail_len);
    }
    // Display cavity cut from the whole part (seat + body) so nothing intrudes.
    oled_cavity(oled_pos, oled_pitch, oled_fp, oled_below, oled_above, oled_floor_inset);
    // Clear the solid baseplate forward of the display footprint's world-Y edge.
    oled_forward_clear(oled_pos, oled_pitch, oled_fp, body_w, body_d, body_height, side_edge);
    side_rebates(body_w, body_d, body_height, skirt_t, lap_h, clearance);
    joint_inserts(body_w, side_screw_y, skirt_t, fit = clearance);
    cable_channel(body_w, body_d, body_height, box_y0, box_y1, disp_pcb_t(), clearance);
    box_lid_inserts(body_w, box_y0, box_len, box_h);
    if (engrave) right_side_engrave(body_w, engrave_y, engrave_z, engrave_text);
  }
}

// Removable clamp bar, placed in its assembled position under the sight.
module clamp_bar() {
  translate([body_w / 2, 0, 0]) picatinny_clamp_bar(rail_len);
}

module top_part() {
  difference() {
    union() {
      eotech_shroud(
        body_w, body_d, body_height, side_edge, shroud_wall,
        shroud_h, lip_h, lap_h, skirt_t
      );
      glass_frame_mount(
        lens, lens_wall, clearance, body_w, side_edge,
        glass_cy, glass_cz, angle, base_z=body_height
      );
      // Fresnel collimator slab, on the chief ray between OLED and combiner.
      if (fresnel_fitted)
        fresnel_frame(fresnel, clearance, fresnel_wall, body_w, side_edge,
                      oled_pos, oled_pitch, oled_screen_z, fresnel_gap);
    }
    joint_clearance(body_w, side_screw_y, skirt_t);
    // Lens seat + its front insertion channel, cut from the WHOLE part: the
    // shroud's front lip otherwise stands in the seat's mouth.
    glass_seat_clear(lens, lens_wall, clearance, body_w, glass_cy, glass_cz, angle);
    // Keep the descent path onto the OLED seat clear (see oled_seat_clear).
    oled_seat_clear(oled_pos, oled_pitch, oled_fp, oled_seatwall, oled_below,
                    oled_above);
    if (fresnel_fitted)
      fresnel_negatives(fresnel, clearance, fresnel_wall, fresnel_lip,
                        oled_pos, oled_pitch, oled_screen_z, fresnel_gap);
  }
}

// ── Minimal holder ───────────────────────────────────────────
// Bare fixture that holds ONLY the display and the combiner lens in the exact
// same reflex relationship as the full sight — the tilted OLED seat below and
// the tilted combiner frame above, on two thin side supports.  No shroud
// hood/lips, no forward box, no Picatinny.  Intended as a single-piece
// proof/optical-alignment print to check the display image reflects off the
// combiner into the eye correctly.
module minimal_holder(base_h = 4.0) {
  // Combiner + reflex-OLED recomputed off the shortened base so the combiner
  // keeps the SAME height above the base (and the OLED below it) as the full
  // sight.  glass_cy does not depend on base height, so it is reused.
  gcz = base_h + clearance_body + frame_y / 2 * cos(angle) + frame_z / 2 * sin(angle);
  opos = [body_w / 2, glass_cy, gcz] + oled_dist * oled_ray;
  ftz = gcz + frame_z / 2 * sin(angle) + frame_y / 2 * cos(angle);
  sh = ftz - base_h + shroud_wall - 0.5;

  difference() {
    union() {
      // thin solid base plate
      screen_body(
        body_w, body_d, base_h, side_edge, wall, clearance,
        hold_display=false
      );
      // two minimal side supports rising from the base to the frame
      translate([0, 0, base_h])
        cube([side_edge, body_d, sh]);
      translate([body_w - side_edge, 0, base_h])
        cube([side_edge, body_d, sh]);
      // combiner lens frame, tilted into the target orientation
      glass_frame_mount(
        lens, lens_wall, clearance, body_w, side_edge,
        glass_cy, gcz, angle, base_z=base_h
      );
      // reflex OLED seat below the combiner, facing up the reflected ray
      oled_seat(opos, oled_pitch, oled_fp, oled_seatwall, oled_below, oled_above);
      // Fresnel collimator slab, at the same on-axis gap above the screen
      if (fresnel_fitted)
        fresnel_frame(fresnel, clearance, fresnel_wall, body_w, side_edge,
                      opos, oled_pitch, oled_screen_z, fresnel_gap);
    }
    // display cavity cut from the whole fixture
    oled_cavity(opos, oled_pitch, oled_fp, oled_below, oled_above, oled_floor_inset);
    // Same lens seat + front insertion channel as the full optics head.
    glass_seat_clear(lens, lens_wall, clearance, body_w, glass_cy, gcz, angle);
    if (fresnel_fitted)
      fresnel_negatives(fresnel, clearance, fresnel_wall, fresnel_lip,
                        opos, oled_pitch, oled_screen_z, fresnel_gap);
    // Clear the solid baseplate forward of the display footprint's world-Y edge.
    oled_forward_clear(opos, oled_pitch, oled_fp, body_w, body_d, base_h, side_edge);
  }
}

// ── Gridfinity mount (minimal fixture only) ──────────────────
// Puts the minimal alignment fixture on a Gridfinity bin bottom
// (with magnet slots), so it clips onto a Gridfinity baseplate on the bench.
// The bin bottom (from scad-common) is only stacking feet + an X-brace lattice
// per cell — no solid floor — so a thin platform slab caps the feet and carries
// the fixture.  A 2×1 footprint (84×42) comfortably covers the 58.2×34 fixture
// (which is itself too shallow to sit inside a single 42 mm cell), centred.
gf_cols = 2; // Gridfinity cells across (X)
gf_rows = 1; // Gridfinity cells deep (Y)
gf_plat_t = 1.00; // platform slab: caps the feet, seats the fixture

module minimal_holder_gridfinity() {
  gf_w = gf_cols * 42;
  gf_d = gf_rows * 42;
  dx = body_w / 2 - gf_w / 2; // centre the grid footprint under the fixture
  dy = body_d / 2 - gf_d / 2;
  // bin bottom + capping platform, centred beneath the fixture
  translate([dx, dy, 0]) {
    gridfinity_bin_bottom(
      cols=gf_cols,
      rows=gf_rows,
      magnets=true,
      skeletonize=false
    );
    linear_extrude(gf_plat_t)
      offset(r=4) offset(delta=-4) square([gf_w, gf_d]);
  }
  // the minimal fixture, lifted onto the platform top
  translate([0, 0, gf_plat_t]) minimal_holder(10);
}

// ── Render selector ──────────────────────────────────────────
if (part == "bottom")
  bottom_part();
else if (part == "top")
  top_part();
else if (part == "bar")
  clamp_bar();
else if (part == "lid")
  box_lid(body_w, box_y0, box_len, box_h);
else if (part == "minimal")
  minimal_holder_gridfinity();
else {
  // "both" — full assembled preview
  bottom_part();
  top_part();
  clamp_bar();
  box_lid(body_w, box_y0, box_len, box_h);
}
