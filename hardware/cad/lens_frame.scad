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
function lens_frame_width(lens, wall)  = lens[1] + 2 * wall; // arm_w
function lens_frame_depth(lens, wall)  = lens[2] + 2 * wall; // frame_y (glass normal)
function lens_frame_height(lens, wall) = lens[0] + 2 * wall; // frame_z (along tilt)

module lens_frame(lens, wall, clearance) {
  lw = lens[0]; lh = lens[1]; ltr = lens[3];
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
  lw = lens[0]; lh = lens[1]; lt = lens[2]; ltr = lens[3]; llip = lens[4];
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

  // ── glass pocket: straight section ────────────────────────
  translate([inner_lx, pky, wall])
    cube([inner_rx - inner_lx, pkt + 0.1, lw]);

  // ── glass pocket: left arc cap ────────────────────────────
  intersection() {
    translate([p_lcx, frame_y - pkt / 2, p_cz])
      rotate([90, 0, 0])
        cylinder(r=p_r, h=pkt + 0.2, center=true, $fn=60);
    translate([-(p_r + 1), -0.1, wall])
      cube([p_r + 1 + inner_lx, frame_y + 0.2, lw]);
  }

  // ── glass pocket: right arc cap ───────────────────────────
  intersection() {
    translate([p_rcx, frame_y - pkt / 2, p_cz])
      rotate([90, 0, 0])
        cylinder(r=p_r, h=pkt + 0.2, center=true, $fn=60);
    translate([inner_rx, -0.1, wall])
      cube([p_r + 1, frame_y + 0.2, lw]);
  }

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

// ── Glass frame at angle ─────────────────────────────────────
// The lens_frame is centred in X; short connecting webs bridge from each
// shroud side wall to the frame's rounded ends.  Webs live in a central Z
// band (web_hz above/below the glass centreline) and only in the solid depth
// BEHIND the glass pocket (the −Y half), so they never enter the clear window.
module glass_frame_mount(lens, wall, clearance, body_w, side_edge,
                         glass_cy, glass_cz, angle, arm_overlap = 3.0) {
  lt = lens[2];
  arm_w   = lens_frame_width(lens, wall);
  frame_y = lens_frame_depth(lens, wall);
  frame_z = lens_frame_height(lens, wall);

  web_hz = frame_z * 0.28; // half-height of the connecting web (Z band)
  web_dy = frame_y - (lt + clearance); // depth behind the pocket
  web_y0 = -frame_y / 2; // rear (-Y) face of the frame
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
}

// ── Demo (renders only when this file is opened directly) ────
$fn = 48;
_lens = [24.00, 34.00, 2.74, 16.97, 2.00];
lens_frame(_lens, 2.50, 0.30);
