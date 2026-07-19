// ============================================================
// EOTech-style shroud — enclosed rectangular window frame
//
//   eotech_shroud(...)  solid left/right side walls, a top hood bar, short
//                       front/rear lower lips, and the skirts that drop below
//                       the seam to lap the bottom part.  The centre opening
//                       (front and rear faces) is left clear for viewing.
//
// All dimensions are passed in from the assembly except rear_lip_h, which is
// shroud-private (default 4 mm).
// ============================================================

module eotech_shroud(body_w, body_d, body_height, side_edge, shroud_wall,
                     shroud_h, lip_h, lap_h, skirt_t, rear_lip_h = 4.0) {
  se = side_edge;
  sw = shroud_wall;
  bh = body_height;
  bw = body_w;
  bd = body_d;
  sh = shroud_h;

  // Left/right side walls (thick edges, full height, full depth)
  translate([0, 0, bh])
    cube([se, bd, sh]);
  translate([bw - se, 0, bh])
    cube([se, bd, sh]);

  // Left/right skirts — drop below the seam to lap the bottom part's
  // rebated side faces; the horizontal joint screws pass through these.
  translate([0, 0, bh - lap_h])
    cube([skirt_t, bd, lap_h]);
  translate([bw - skirt_t, 0, bh - lap_h])
    cube([skirt_t, bd, lap_h]);

  // Top hood bar (full width, full depth)
  translate([0, 0, bh + sh - sw])
    cube([bw, bd, sw]);

  // Rear lower lip (Y=0 face, between side walls) — lowered for sight picture
  translate([se, 0, bh])
    cube([bw - 2 * se, sw, rear_lip_h]);

  // Front lower lip (Y=body_d face, between side walls)
  translate([se, bd - sw, bh])
    cube([bw - 2 * se, sw, lip_h]);
}

// ── Demo (renders only when this file is opened directly) ────
$fn = 48;
eotech_shroud(body_w = 58.20, body_d = 34.00, body_height = 20.00,
              side_edge = 8.00, shroud_wall = 3.00, shroud_h = 20.00,
              lip_h = 10.00, lap_h = 14.00, skirt_t = 3.00);
