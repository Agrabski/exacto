// ============================================================
// Lens frame — combiner-glass holder + tilted mount
//
//   lens_frame(lens, wall, clearance)      the glass-holder shell: a straight
//                          middle section with an arc cap on each end, minus
//                          the glass pocket + see-through window.
//   lens_negatives(lens, wall, clearance)  the pocket + window as negative
//                          solids in frame-local coords; shared by the frame
//                          and the connecting webs so nothing intrudes on the
//                          lens seat.
//   glass_frame_mount(...)  places the frame tilted at `angle`, bridged to the
//                          shroud side walls by two rear-only connecting webs.
//
// lens = [w, h, t, top_r, lip].  Landscape orientation: lens_h (h) along X,
// lens_w (w) along Z; arc caps on the LEFT/RIGHT ends span lens_w.  Glass
// slides in from the +Y (front) face; the −Y side carries the retaining lip.
// ============================================================

// Frame outer dims derived from the lens block + wall (shared with the
// assembly so the same formulas are never duplicated).
function lens_frame_width(lens, wall) = lens[1] + 2 * wall; // arm_w
function lens_frame_depth(lens, wall) = lens[2] + 2 * wall; // frame_y (glass normal)
function lens_frame_height(lens, wall) = lens[0] + 2 * wall; // frame_z (along tilt)

module lens_frame(lens, wall, clearance) {
  lw = lens[0];
  lh = lens[1];
  ltr = lens[3];
  frame_y = lens_frame_depth(lens, wall);
  frame_z = lens_frame_height(lens, wall);

  // inner pocket arc centres (X, Z) in frame local coords
  inner_hc = sqrt(ltr * ltr - (lw / 2) * (lw / 2)); // half-chord spanning Z = lens_w
  p_lcx = wall + ltr;
  p_rcx = wall + lh - ltr;
  p_cz = wall + lw / 2;

  // inner straight-section X bounds (arc tangent to Z=wall / Z=wall+lens_w)
  inner_lx = p_lcx - inner_hc;
  inner_rx = p_rcx + inner_hc;

  // outer shell (R_outer = lens_top_r + wall)
  R_outer = ltr + wall;
  outer_hc = sqrt(R_outer * R_outer - (frame_z / 2) * (frame_z / 2));
  outer_lx = p_lcx - outer_hc;
  outer_rx = p_rcx + outer_hc;

  difference() {
    // ── outer shell ───────────────────────────────────────────
    union() {
      // straight middle section
      translate([outer_lx, 0, 0])
        cube([outer_rx - outer_lx, frame_y, frame_z]);

      // left arc cap (X < outer_lx)
      intersection() {
        translate([p_lcx, frame_y / 2, p_cz])
          rotate([90, 0, 0])
            cylinder(r=R_outer, h=frame_y + 0.2, center=true, $fn=60);
        translate([-(R_outer + 1), -0.1, -0.1])
          cube([R_outer + 1 + outer_lx, frame_y + 0.2, frame_z + 0.2]);
      }

      // right arc cap (X > outer_rx)
      intersection() {
        translate([p_rcx, frame_y / 2, p_cz])
          rotate([90, 0, 0])
            cylinder(r=R_outer, h=frame_y + 0.2, center=true, $fn=60);
        translate([outer_rx, -0.1, -0.1])
          cube([R_outer + 1, frame_y + 0.2, frame_z + 0.2]);
      }
    }

    // Glass pocket + see-through window cavities (shared with the side webs).
    lens_negatives(lens, wall, clearance);
  }
}

// The glass pocket (opens at +Y) and the see-through window, as a set of
// negative solids in lens_frame local coords.  Cut from the frame AND from
// the connecting webs so nothing intrudes into the lens seat.
module lens_negatives(lens, wall, clearance) {
  lens_pocket(lens, wall, clearance);
  lens_window(lens, wall, clearance);
}

// The glass pocket alone — the stadium prism the lens actually occupies, open
// at the +Y face.  Split out from lens_negatives() so the insertion channel
// can sweep it without dragging the see-through window along.
module lens_pocket(lens, wall, clearance) {
  lw = lens[0];
  lh = lens[1];
  lt = lens[2];
  ltr = lens[3];
  frame_y = lens_frame_depth(lens, wall);

  inner_hc = sqrt(ltr * ltr - (lw / 2) * (lw / 2));
  p_lcx = wall + ltr;
  p_rcx = wall + lh - ltr;
  p_cz = wall + lw / 2;
  p_r = ltr + clearance / 2;
  inner_lx = p_lcx - inner_hc;
  inner_rx = p_rcx + inner_hc;

  // Glass enters from the FRONT (+Y) face; retaining lip on the -Y side.
  pkt = lt + clearance;
  pky = frame_y - pkt;

  // The glass's 24 mm dimension needs slack too.  The thickness and the end
  // arcs already carry `clearance`; without the same on the height the pocket
  // is exactly the glass's size, and a printed one comes out undersize — the
  // optic will not go in.  Costs clearance/2 off the frame's top/bottom rim.
  pz0 = wall - clearance / 2;
  pzh = lw + clearance;

  // ── glass pocket: straight section ────────────────────────
  translate([inner_lx, pky, pz0])
    cube([inner_rx - inner_lx, pkt + 0.1, pzh]);

  // ── glass pocket: left arc cap ────────────────────────────
  intersection() {
    translate([p_lcx, frame_y - pkt / 2, p_cz])
      rotate([90, 0, 0])
        cylinder(r=p_r, h=pkt + 0.2, center=true, $fn=60);
    translate([-(p_r + 1), -0.1, pz0])
      cube([p_r + 1 + inner_lx, frame_y + 0.2, pzh]);
  }

  // ── glass pocket: right arc cap ───────────────────────────
  intersection() {
    translate([p_rcx, frame_y - pkt / 2, p_cz])
      rotate([90, 0, 0])
        cylinder(r=p_r, h=pkt + 0.2, center=true, $fn=60);
    translate([inner_rx, -0.1, pz0])
      cube([p_r + 1, frame_y + 0.2, pzh]);
  }

}

// The see-through window alone — open through BOTH faces, inset by the lens's
// `lip` so a rim laps the glass on each side.
module lens_window(lens, wall, clearance) {
  lw = lens[0];
  lh = lens[1];
  lt = lens[2];
  ltr = lens[3];
  llip = lens[4];
  frame_y = lens_frame_depth(lens, wall);

  inner_hc = sqrt(ltr * ltr - (lw / 2) * (lw / 2));
  p_lcx = wall + ltr;
  p_rcx = wall + lh - ltr;
  p_cz = wall + lw / 2;
  p_r = ltr + clearance / 2;
  inner_lx = p_lcx - inner_hc;
  inner_rx = p_rcx + inner_hc;

  // ── see-through window — open through BOTH faces ──────────
  wr = p_r - llip; // inset arc radius for the window
  translate([inner_lx, -0.1, wall + llip])
    cube([inner_rx - inner_lx, frame_y + 0.2, lw - 2 * llip]);
  intersection() {
    translate([p_lcx, frame_y / 2, p_cz])
      rotate([90, 0, 0]) cylinder(r=wr, h=frame_y + 0.2, center=true, $fn=60);
    translate([-(wr + 1), -0.1, wall + llip])
      cube([wr + 1 + inner_lx, frame_y + 0.2, lw - 2 * llip]);
  }
  intersection() {
    translate([p_rcx, frame_y / 2, p_cz])
      rotate([90, 0, 0]) cylinder(r=wr, h=frame_y + 0.2, center=true, $fn=60);
    translate([inner_rx, -0.1, wall + llip])
      cube([wr + 1, frame_y + 0.2, lw - 2 * llip]);
  }
}

// ── Glass seat clearance + front insertion channel ───────────
// In ASSEMBLY coordinates (not frame-local): the lens seat, plus the pocket
// swept straight out the FRONT (+Y), so the glass can be pushed in
// horizontally through the front aperture instead of having to be threaded in
// along its own tilted normal.
//
// Subtract this from the WHOLE top part, not just the frame.  The frame is
// deliberately parked 0.5 mm behind body_d, which puts the seat's mouth inside
// the shroud's front lip — cutting only the frame and its webs leaves the lip
// standing in the pocket, and the glass cannot seat at all, let alone slide in.
// The channel notches the lip's upper half across the lens width; the lip's
// lower half runs wall to wall untouched.
//
// The sweep is horizontal, so gravity acts square across the channel and
// cannot walk the glass back out of it; adhesive on the rim does the rest.
//   travel : how far forward to sweep.  Needs to carry the pocket's REARMOST
//            corner past the front face; the default clears body_d for the
//            stock geometry.
module glass_seat_clear(lens, wall, clearance, body_w, glass_cy, glass_cz,
                        angle, travel = 25) {
  arm_w = lens_frame_width(lens, wall);
  frame_y = lens_frame_depth(lens, wall);
  frame_z = lens_frame_height(lens, wall);

  module _seat_local() {
    translate([body_w / 2, glass_cy, glass_cz])
      rotate([90 - angle, 0, 0])
        translate([-arm_w / 2, -frame_y / 2, -frame_z / 2])
          children();
  }

  // The seat itself (pocket + window), so nothing outside the frame intrudes.
  _seat_local() lens_negatives(lens, wall, clearance);

  // Insertion channel: the pocket swept forward.  The pocket is a convex
  // stadium prism, so hull() of the two ends is exactly the swept volume.
  hull() {
    _seat_local() lens_pocket(lens, wall, clearance);
    translate([0, travel, 0])
      _seat_local() lens_pocket(lens, wall, clearance);
  }
}

// ── Glass frame at angle ─────────────────────────────────────
// The lens_frame is centred in X; connecting webs bridge from each shroud
// side wall to the frame's rounded ends, running the FULL height of the
// frame (web_hz = frame_z/2) so the wing reaches from the frame's top edge
// down to its bottom edge — previously web_hz was a thin central band,
// leaving the frame's lower half floating unsupported inside the shroud
// opening.  (The side walls themselves are already solid full-height blocks
// — see eotech_shroud — so what was missing was the visible wing/mullion
// inside the window opening, not extra material buried in the wall.)  Webs
// only occupy the solid depth BEHIND the glass pocket (the −Y half), so they
// never enter the clear window.
//
// Because the web follows the frame's own tilt (its local Z axis), its
// bottom edge sits a few mm above the true world floor even at full height —
// a pair of small, genuinely-vertical (world-Z) columns close that last gap,
// planted in the open span between the wall and the frame's edge (NOT inside
// the wall itself, which is already solid — a column there would be buried
// in existing material and invisible/structurally moot).
module glass_frame_mount(
  lens,
  wall,
  clearance,
  body_w,
  side_edge,
  glass_cy,
  glass_cz,
  angle,
  base_z,
  arm_overlap = 3.0
) {
  lt = lens[2];
  arm_w = lens_frame_width(lens, wall);
  frame_y = lens_frame_depth(lens, wall);
  frame_z = lens_frame_height(lens, wall);

  web_hz = frame_z / 2; // half-height of the connecting web (Z band) — full frame height
  web_dy = frame_y - (lt + clearance); // depth behind the pocket
  web_y0 = -frame_y / 2; // rear (-Y) face of the frame
  theta = 90 - angle; // frame tilt from vertical (matches the rotate below)

  // World Y/Z of two points just inside the web's solid near its bottom edge
  // (local Z nudged up from -web_hz) and inset from each Y end (local Y
  // nudged in from web_y0 / web_y0+web_dy) — both axes nudged so hull()'s
  // tapered apex lands strictly inside real solid rather than merely
  // touching a boundary face (a zero-volume "kiss" that CGAL keeps as a
  // separate shell instead of fusing into the union).
  ly_in1 = web_y0 + 0.5;
  ly_in2 = web_y0 + web_dy - 0.5;
  lz_anchor = -web_hz + 0.5;
  col_y1 = glass_cy + ly_in1 * cos(theta) - lz_anchor * sin(theta);
  col_z1 = glass_cz + ly_in1 * sin(theta) + lz_anchor * cos(theta);
  col_y2 = glass_cy + ly_in2 * cos(theta) - lz_anchor * sin(theta);
  col_z2 = glass_cz + ly_in2 * sin(theta) + lz_anchor * cos(theta);
  col_pad = 2; // floor footprint padding beyond the anchor points, each side
  col_w = 8; // column width — small, just enough to print solid

  translate([body_w / 2, glass_cy, glass_cz])
    rotate([90 - angle, 0, 0]) {
      translate([-arm_w / 2, -frame_y / 2, -frame_z / 2])
        lens_frame(lens, wall, clearance);

      // Connecting webs — pocket/window cavities re-cut as a safeguard.
      difference() {
        union() {
          // Left web: frame end (overlapping arm_overlap into the arc) → wall
          hull() {
            translate([-arm_w / 2 - 0.1, web_y0, -web_hz])
              cube([arm_overlap + 0.1, web_dy, 2 * web_hz]);
            translate([-body_w / 2, web_y0, -web_hz])
              cube([side_edge, web_dy, 2 * web_hz]);
          }
          // Right web: frame end → wall
          hull() {
            translate([arm_w / 2 - arm_overlap, web_y0, -web_hz])
              cube([arm_overlap + 0.1, web_dy, 2 * web_hz]);
            translate([body_w / 2 - side_edge, web_y0, -web_hz])
              cube([side_edge, web_dy, 2 * web_hz]);
          }
        }
        translate([-arm_w / 2, -frame_y / 2, -frame_z / 2])
          lens_negatives(lens, wall, clearance);
      }
    }

  // Small plumb columns, left and right, closing the last gap between the
  // web's (tilted) underside and the true world floor — hulled from the
  // web's two true anchor corners down to a padded footprint on the floor.
  if (col_z1 > base_z || col_z2 > base_z) {
    // The columns reach under the frame's ends, where the glass pocket also
    // lives, so they get the same cavities cut from them as the webs do —
    // otherwise they clip the glass's lower corners and it cannot seat.
    difference() {
      for (x0 = [side_edge, body_w - side_edge - col_w]) {
        hull() {
          translate([x0, col_y1, col_z1]) cube([col_w, 0.1, 3]);
          translate([x0, col_y2, col_z2]) cube([col_w, 0.1, 3]);
          translate([x0, min(col_y1, col_y2) - col_pad, base_z])
            cube([col_w, abs(col_y2 - col_y1) + 2 * col_pad, 0.1]);
        }
      }
      translate([body_w / 2, glass_cy, glass_cz])
        rotate([90 - angle, 0, 0])
          translate([-arm_w / 2, -frame_y / 2, -frame_z / 2])
            lens_negatives(lens, wall, clearance);
    }
  }
}

// ── Demo (renders only when this file is opened directly) ────
$fn = 48;
_lens = [24.00, 34.00, 2.74, 16.97, 2.00];
lens_frame(_lens, 2.50, 0.30);
