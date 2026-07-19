// ============================================================
// Exacto Reflex Sight Housing — v4 (EOTech-style, two-part)
//
// Top-level ASSEMBLY.  It owns every base knob, computes every derived value,
// and passes them into the component modules (which live in their own files
// and take parameters — `use <>` imports modules/functions, never globals).
//
// Two screw-joined parts, split at the seam z = body_height (20 mm):
//   bottom_part()  display holder = screen_body() + front_box() + clamp body
//   top_part()     lens holder    = eotech_shroud() + glass_frame_mount()
//   clamp_bar()    the removable Picatinny left jaw, in assembled position
//   box_lid()      the forward box's screw-on top lid
//
// Component files:
//   screen_body.scad     screen_body / rounded_box / side lap-joint cutters
//   shroud.scad          eotech_shroud
//   lens_frame.scad      lens_frame / lens_negatives / glass_frame_mount
//   electronics_box.scad front_box / cable_channel / box_lid(+inserts) / engrave
//   picatinny.scad       MIL-STD-1913 two-part clamp
//   screw_mounts.scad    reusable M2/M3 insert + clearance + counterbore cutters
//
// Set `part` below to choose what to render/export.
//
// Display: Waveshare 1.27-inch SSD1351 RGB OLED (specs live in screen_body.scad)
// Lens:    24.00 × 34.00 mm, 2.74 mm thick, arcs R16.97 both ends
// ============================================================
use <picatinny.scad>
use <screw_mounts.scad>
use <screen_body.scad>
use <shroud.scad>
use <lens_frame.scad>
use <electronics_box.scad>

// ┌─────────────────────────────────────────────────────────┐
// │  CHANGE angle, RE-EXPORT STL, REPRINT                   │
// │  angle = combiner tilt from horizontal                  │
// │  45° = classic half-mirror reflex position              │
// └─────────────────────────────────────────────────────────┘
angle = 60; // degrees  (recommended 35–65)

// Which piece to render/export: "both" (assembled), "top", "bottom",
// "bar" (removable Picatinny clamp jaw), "lid" (box top lid),
// "minimal" (bare display + combiner fixture, for optical alignment)
part = "both";

// ── Base knobs (single source of truth) ──────────────────────
box_len = 80.00; // forward electronics box length, front-to-rear (8 cm)

// lens = [w, h, t, top_r, lip]  (24×34 mm glass, 2.74 thick, R16.97 ends)
lens = [24.00, 34.00, 2.74, 16.97, 2.00];

wall = 2.50;
shroud_wall = 3.00; // EOTech shroud wall / hood thickness
side_edge = 8.00;   // THICK left/right edges (host the joint inserts)
clearance = 0.30;
body_height = 20.00; // must fit Arduino Nano + wiring
lip_h = 10.00;       // FRONT lower lip height on the shroud
lap_h = 14.00;       // vertical skirt overlap below the seam
skirt_t = 3.00;      // skirt thickness (sits in a rebate on the bottom)
clearance_body = 3;  // gap from body top to the tilted frame's lowest point

engrave = true; // set false to omit the engraved label
engrave_text = "Exacto XM-1E0";

$fn = 48; // special var — propagates into the used modules at call time

// ── Derived (uses accessor functions exposed by the components) ──
body_w = disp_pcb_w() + 2 * side_edge; // 58.20
body_d = disp_pcb_h() + 2 * wall;      // 34.00
frame_y = lens_frame_depth(lens, wall);  //  7.74  frame depth (glass normal)
frame_z = lens_frame_height(lens, wall); // 29.00  frame height along tilt

// Glass centre in world space.  clearance_body is measured to the LOWEST
// point of the tilted frame so it stays honest as `angle` changes.
glass_cz = body_height + clearance_body + frame_y / 2 * cos(angle) + frame_z / 2 * sin(angle);
// Combiner pushed as far FORWARD as it can go while staying behind the front
// lip.  frame_dy is the frame's half-extent along Y after the tilt.
frame_dy = frame_y / 2 * sin(angle) + frame_z / 2 * cos(angle);
glass_cy = body_d - shroud_wall - frame_dy - 0.5;

// Shroud height — auto-sized to enclose the tilted glass frame.
frame_tip_z = glass_cz + (frame_z / 2) * sin(angle) + (frame_y / 2) * cos(angle);
shroud_h = frame_tip_z - body_height + shroud_wall - 0.5;

// Y positions of the 4 side joint screws (2 per side).
side_screw_y = [body_d * 0.28, body_d * 0.72];

// Forward box geometry.  Box spans Y = body_d .. box_y1.
box_h = body_height + lip_h; // 30.00, reaches the lens opening
box_y0 = body_d;             // box back (joins the optics head)
box_y1 = body_d + box_len;   // box front (muzzle end)

// Picatinny rail runs the WHOLE length of the sight (optics head + box).
rail_len = body_d + box_len;

// Engraving placement: centred along the box, a little above its mid-height.
engrave_y = (box_y0 + box_y1) / 2;
engrave_z = box_wall_top(box_h) * 0.55;

// ── Two parts ────────────────────────────────────────────────
module bottom_part() {
  difference() {
    union() {
      screen_body(body_w, body_d, body_height, side_edge, wall, clearance);
      front_box(body_w, box_y0, box_len, box_h, body_height);
      // Picatinny clamp FIXED body — runs the WHOLE length on the underside.
      translate([body_w / 2, 0, 0]) picatinny_clamp_body(rail_len);
    }
    side_rebates(body_w, body_d, body_height, skirt_t, lap_h);
    joint_inserts(body_w, side_screw_y, skirt_t);
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
      eotech_shroud(body_w, body_d, body_height, side_edge, shroud_wall,
                    shroud_h, lip_h, lap_h, skirt_t);
      glass_frame_mount(lens, wall, clearance, body_w, side_edge,
                        glass_cy, glass_cz, angle);
    }
    joint_clearance(body_w, side_screw_y, skirt_t);
  }
}

// ── Minimal holder ───────────────────────────────────────────
// Bare fixture that holds ONLY the display and the combiner lens in the exact
// same relative orientation as the full sight — the display pocket, two thin
// side supports, and the tilted lens frame.  No shroud hood/lips, no forward
// box, no Picatinny.  Intended as a single-piece proof/optical-alignment print
// to check that the display image reflects off the combiner correctly.
// base_h defaults to the SHORTEST base that still seats the display: the PCB
// pocket depth + the M2 insert length + a thin floor.  No room is reserved for
// electronics (that's what the full body_height is for).
module minimal_holder(base_h = disp_pcb_t() + clearance + insert_bore_depth("M2") + 1.5) {
  // Combiner geometry recomputed off the shortened base so the glass keeps the
  // SAME offset above the display surface as in the full sight.  glass_cy does
  // not depend on base height, so it is reused unchanged.
  gcz = base_h + clearance_body + frame_y / 2 * cos(angle) + frame_z / 2 * sin(angle);
  ftz = gcz + frame_z / 2 * sin(angle) + frame_y / 2 * cos(angle);
  sh = ftz - base_h + shroud_wall - 0.5;

  // display holder (base just tall enough for the pocket + M2 inserts)
  screen_body(body_w, body_d, base_h, side_edge, wall, clearance);
  // two minimal side supports rising from the body top to the frame; the
  // glass_frame_mount webs fuse into these (same faces the shroud walls use)
  translate([0, 0, base_h])
    cube([side_edge, body_d, sh]);
  translate([body_w - side_edge, 0, base_h])
    cube([side_edge, body_d, sh]);
  // combiner lens frame, tilted into the target orientation
  glass_frame_mount(lens, wall, clearance, body_w, side_edge,
                    glass_cy, gcz, angle);
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
  minimal_holder();
else {
  // "both" — full assembled preview
  bottom_part();
  top_part();
  clamp_bar();
  box_lid(body_w, box_y0, box_len, box_h);
}
