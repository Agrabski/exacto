// ============================================================
// Watertight box — parametric enclosure with a sealed top lid
//
//   watertight_box_base(w, d, h, ...)  open-top box: four walls + floor,
//                       a continuous tongue-and-groove SEALING RIM around
//                       the opening, and corner screw bosses with brass-
//                       insert bores.
//   watertight_box_lid(w, d, h, ...)   matching flat lid: a downward
//                       TONGUE that drops into the rim groove, plus
//                       counterbored screw holes over the bosses.
//
// The seal is a tongue-and-groove joint: the box rim carries a continuous
// groove, the lid a matching tongue.  Lay an O-ring cord or silicone bead
// in the groove and the four corner screws clamp the lid down to compress
// it — a labyrinth path that keeps splash and rain off the electronics.
//
// A thin printed wall has no room for a groove, so the wall top is
// thickened INWARD into a sealing rim (`rim` thick over the top `rim_h`).
// The groove then sits in solid material with a lip to either side, and
// the groove is cut THROUGH the corner bosses too so the gasket channel
// stays continuous all the way round.
//
// Coordinate frame (both modules share it, so they stack in place):
//   footprint w (X) x d (Y), z = 0 at the floor underside, walls rise to
//   z = h (the rim top / lid underside).  Translate the pair as a unit.
//
// All dimensions in mm.  `use <watertight_box.scad>` — the demo at the
// bottom is ignored when this file is used as a library.
// ============================================================

$fn = 48;

// Corner screw-boss centres: one in each inside corner, pulled `inset` mm
// toward the corner so the boss merges into the two walls (no thin tangent-
// line contact).  Shared by the base and the lid so their holes line up.
function wb_boss_xy(w, d, wall, boss_r, inset = 2) =
  let (m = wall + boss_r - inset)
  [for (x = [m, w - m], y = [m, d - m]) [x, y]];

// Rectangular groove/tongue ring (a closed loop) of width `ring_w`, inset
// `ring_in` from the outer footprint, `ring_h` tall, sitting at z = z0.
module wb_ring(w, d, ring_in, ring_w, ring_h, z0) {
  translate([0, 0, z0])
    difference() {
      translate([ring_in, ring_in, 0])
        cube([w - 2 * ring_in, d - 2 * ring_in, ring_h]);
      translate([ring_in + ring_w, ring_in + ring_w, -0.1])
        cube([w - 2 * (ring_in + ring_w), d - 2 * (ring_in + ring_w), ring_h + 0.2]);
    }
}

// ── Box base (open top, sealing rim, screw bosses) ───────────
module watertight_box_base(
  w, d, h,
  wall = 2.5, floor = 2.5,
  rim = 5.0, rim_h = 4.0,
  seal_w = 2.2, seal_depth = 2.0,
  boss_r = 4.5, boss_inset = 2.0,
  insert_d = 4.0, insert_depth = 5.0
) {
  groove_in = (rim - seal_w) / 2; // lip width either side of the groove
  bosses = wb_boss_xy(w, d, wall, boss_r, boss_inset);
  difference() {
    union() {
      // hollow shell: main cavity (thin walls) with the top stepped IN to
      // leave the thicker sealing rim around the opening.
      difference() {
        cube([w, d, h]);
        translate([wall, wall, floor])
          cube([w - 2 * wall, d - 2 * wall, h + 1]);
        translate([rim, rim, h - rim_h])
          cube([w - 2 * rim, d - 2 * rim, rim_h + 1]);
      }
      // corner screw bosses (freestanding pillars, floor to rim top)
      for (p = bosses)
        translate([p[0], p[1], 0]) cylinder(r = boss_r, h = h);
    }
    // sealing groove, cut continuously through walls AND bosses
    wb_ring(w, d, groove_in, seal_w, seal_depth + 0.1, h - seal_depth);
    // brass-insert bores down from the boss tops
    for (p = bosses)
      translate([p[0], p[1], h - insert_depth])
        cylinder(d = insert_d, h = insert_depth + 0.1);
  }
}

// ── Matching lid (tongue + counterbored screw holes) ─────────
module watertight_box_lid(
  w, d, h,
  lid_t = 2.5,
  rim = 5.0,
  seal_w = 2.2, seal_depth = 2.0, seal_clear = 0.25, tongue_h = 1.4,
  wall = 2.5, boss_r = 4.5, boss_inset = 2.0,
  screw_clear = 3.4, head_d = 6.0, head_h = 3.0
) {
  groove_in = (rim - seal_w) / 2;
  tongue_in = groove_in + seal_clear; // clearance each side in the groove
  tongue_w = seal_w - 2 * seal_clear;
  bosses = wb_boss_xy(w, d, wall, boss_r, boss_inset);
  difference() {
    union() {
      // flat lid plate (full footprint), underside seated on the rim at z = h
      translate([0, 0, h]) cube([w, d, lid_t]);
      // sealing tongue dropping down from the lid underside into the groove
      wb_ring(w, d, tongue_in, tongue_w, tongue_h + 0.01, h - tongue_h);
    }
    // screw holes: clearance through the lid + head counterbore on top
    for (p = bosses) {
      translate([p[0], p[1], h - tongue_h - 0.1])
        cylinder(d = screw_clear, h = lid_t + tongue_h + 0.2);
      translate([p[0], p[1], h + lid_t - head_h])
        cylinder(d = head_d, h = head_h + 0.1);
    }
  }
}

// ── Demo (ignored when this file is `use`d) ──────────────────
watertight_box_base(60, 80, 28);
translate([0, 0, 12]) color("orange") watertight_box_lid(60, 80, 28);
