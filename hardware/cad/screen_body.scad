// ============================================================
// Screen body — optics-head display holder + side lap joint
//
// The bottom part's core: a rounded box holding the OLED PCB in a top
// pocket (display faces +Z), the rebates/inserts/clearances for the
// horizontal M3 lap-joint screws, and the generic rounded_box helper.
//
//   screen_body(...)     the display housing block (PCB pocket, active-area
//                        window, M2 heat-set bores below the pocket).
//   side_rebates(...)    cuts the bottom part's outer side faces so the top
//                        part's skirts sit flush (negative geometry).
//   joint_inserts(...)   M3 heat-set bores in the thick side edges (cutter).
//   joint_clearance(...) M3 through-clearance in the top-part skirts (cutter).
//   rounded_box(...)     generic rounded-corner box (union primitive).
//
// Shared/derived dims (body_w, body_d, …) are passed in; display and
// fastener specifics are file-level intrinsics.  Fastener bores come from
// scad-common/screw_mounts.scad — the one fastener library the sight uses.
// (picatinny.scad is the exception: it still carries its own M4 numbers.)
// ============================================================
use <scad-common/screw_mounts.scad>

// ── Display intrinsics — Waveshare 1.27" SSD1351 RGB OLED ────
disp_pcb      = [42.20, 29.00, 1.60]; // PCB w, h, t
disp_active   = [38.00, 24.80];       // lit window w, h
disp_hole_off = [2.25, 2.10];         // mount-hole inset from PCB edge (x, y)
function disp_pcb_w() = disp_pcb[0];
function disp_pcb_h() = disp_pcb[1];
function disp_pcb_t() = disp_pcb[2];

// Generic rounded-corner box: hull of 4 corner cylinders.
module rounded_box(w, d, h, r = 2) {
  hull()for (x = [r, w - r], y = [r, d - r])
    translate([x, y, 0]) cylinder(r=r, h=h);
}

// ── Screen body ──────────────────────────────────────────────
// Optics-only housing: OLED PCB sits in a top pocket; all other
// electronics live in the separate forward box.  Display faces UP (+Z);
// Y=0 = rear, Y=body_d = front.
//
// hold_display : when true (default) the flat top pocket, active-area window
//   and M2 bores are cut for a display lying in the body floor.  Set false to
//   get a solid-topped body — used when the display is mounted elsewhere
//   (e.g. the tilted oled_mount() in the optics head).
module screen_body(body_w, body_d, body_height, side_edge, wall, clearance,
                   hold_display = true) {
  difference() {
    rounded_box(body_w, body_d, body_height);

    if (hold_display) {
    // PCB pocket — clearance/2 on every side so PCB drops in freely
    translate(
      [
        side_edge - clearance / 2,
        wall - clearance / 2,
        body_height - disp_pcb_t() - clearance,
      ]
    )
      cube(
        [
          disp_pcb_w() + clearance,
          disp_pcb_h() + clearance,
          disp_pcb_t() + clearance + 0.1,
        ]
      );

    // Active-area window in top face
    translate(
      [
        side_edge + (disp_pcb_w() - disp_active[0]) / 2,
        wall + (disp_pcb_h() - disp_active[1]) / 2,
        body_height - wall,
      ]
    )
      cube([disp_active[0], disp_active[1], wall + 0.2]);

    // PCB mount: M2 heat-set insert bores below the PCB pocket floor.
    // Screws drop through the PCB corner holes from above and thread into
    // brass inserts pressed up into these bores.
    for (sx = [-1, 1], sy = [-1, 1])
      translate(
        [
          side_edge + disp_pcb_w() / 2 + sx * (disp_pcb_w() / 2 - disp_hole_off[0]),
          wall + disp_pcb_h() / 2 + sy * (disp_pcb_h() / 2 - disp_hole_off[1]),
          body_height - disp_pcb_t() - clearance,
        ]
      )
        insert_hole("M2");
    }

    // Cable exits FORWARD now (see cable_channel()); no rear slot.
  }
}

// ── Side lap joint ───────────────────────────────────────────
// The top-part skirts lap over rebates in the bottom-part side edges; 4
// horizontal M3 screws (2 per side, low — under the PCB) pin and clamp them.

// Rebate the bottom part's outer side faces so the skirts sit flush.
//
// `fit` is the joint clearance: the rebate is cut that much deeper than the
// skirt is thick, and that much lower than the skirt is tall.  Without it the
// rebate is exactly the skirt's size and the printed halves cannot close —
// FDM parts run oversize, and a 3.00 mm skirt will not enter a 3.00 mm slot.
// The skirt's OUTER face still lands flush with the body's side; the slack
// sits on its inner face, and under its bottom edge so the seam faces (not the
// skirt's end) are what set the halves' height.
module side_rebates(body_w, body_d, body_height, skirt_t, lap_h, fit = 0.30) {
  translate([-0.1, -0.1, body_height - lap_h - fit])
    cube([skirt_t + fit + 0.1, body_d + 0.2, lap_h + fit + 0.2]);
  translate([body_w - skirt_t - fit, -0.1, body_height - lap_h - fit])
    cube([skirt_t + fit + 0.1, body_d + 0.2, lap_h + fit + 0.2]);
}

// M3 brass-insert bores in the thick bottom side edges (open at the rebate
// face), low and in solid material below the PCB.
// `fit` must match side_rebates() — the bores start at the rebate's new face,
// so the insert still sits flush in a full-depth pocket.
module joint_inserts(body_w, side_screw_y, skirt_t, joint_screw_z = 9.0, fit = 0.30) {
  for (y = side_screw_y) {
    translate([skirt_t + fit, y, joint_screw_z]) // left edge, bore +X
      rotate([0, -90, 0]) insert_hole("M3");
    translate([body_w - skirt_t - fit, y, joint_screw_z]) // right edge, bore -X
      rotate([0, 90, 0]) insert_hole("M3");
  }
}

// M3 clearance holes through the top-part skirts.
module joint_clearance(body_w, side_screw_y, skirt_t, joint_screw_z = 9.0) {
  for (y = side_screw_y) {
    translate([-0.1, y, joint_screw_z])
      rotate([0, -90, 0]) clearance_hole("M3", skirt_t + 0.2, 0.4);
    translate([body_w + 0.1, y, joint_screw_z])
      rotate([0, 90, 0]) clearance_hole("M3", skirt_t + 0.2, 0.4);
  }
}

// ── Demo (renders only when this file is opened directly) ────
$fn = 48;
_body_w = disp_pcb_w() + 2 * 8.00;   // side_edge = 8
_body_d = disp_pcb_h() + 2 * 2.50;   // wall = 2.5
_ssy = [_body_d * 0.28, _body_d * 0.72];
difference() {
  screen_body(_body_w, _body_d, 20.00, 8.00, 2.50, 0.30);
  side_rebates(_body_w, _body_d, 20.00, 3.00, 14.00);
  joint_inserts(_body_w, _ssy, 3.00);
}
