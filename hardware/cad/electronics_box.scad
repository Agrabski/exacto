// ============================================================
// Forward electronics box — hollow enclosure + screw-on lid
//
//   front_box(...)         hollow box (walls + floor, open top) in front of
//                          the optics head, with 4 inside-corner lid bosses.
//   cable_channel(...)     under-PCB cable run + plug opening (negative geo).
//   box_lid_inserts(...)   M3 heat-set bores down into the lid bosses (cutter).
//   box_lid(...)           the removable top lid, counterbored for its screws.
//   right_side_engrave(...) label cut into the box's +X face (cutter).
//
// The box envelope (body_w, box_y0, box_len, box_h) is passed in; wall/boss/
// fastener/cable specifics are file-level intrinsics.  The lid-boss grid and
// wall-top height are file-level FUNCTIONS so front_box, box_lid_inserts and
// box_lid stay consistent by construction.  Fastener bores come from
// screw_mounts.scad.
// ============================================================
use <screw_mounts.scad>

// ── Box intrinsics ───────────────────────────────────────────
box_wall = 2.50;        // wall / floor thickness
lid_t = 2.50;           // top-lid thickness
box_boss_r = 4.50;      // lid screw-boss radius (inside corners)
box_screw_clear = 3.40; // M3 lid-screw clearance (in the lid)
box_head_d = 6.00;      // M3 lid-screw head counterbore dia
box_head_h = 3.00;      // counterbore depth
cable_w = 14.00;        // under-PCB cable channel width
cable_z = 9.00;         // channel floor height (under the PCB pocket)
plug_w = 14.00;         // plug opening width (box front face)
plug_z = 8.00;          // plug opening bottom z
plug_h = 9.00;          // plug opening height

function box_wall_top(box_h) = box_h - lid_t; // top of the box walls
function box_screw_x(body_w)         = [box_wall + box_boss_r - 2, body_w - box_wall - box_boss_r + 2];
function box_screw_y(box_y0, box_y1) = [box_y0 + box_wall + box_boss_r - 2, box_y1 - box_wall - box_boss_r + 2];

// ── Forward box ──────────────────────────────────────────────
// Back joins the optics-head front wall; cable enters via cable_channel().
module front_box(body_w, box_y0, box_len, box_h, body_height) {
  bwt = box_wall_top(box_h);
  box_y1 = box_y0 + box_len;
  sx = box_screw_x(body_w);
  sy = box_screw_y(box_y0, box_y1);
  difference() {
    union() {
      // outer shell (walls + floor), open top
      translate([0, box_y0, 0])
        cube([body_w, box_len, bwt]);
      // fuse block tying the box into the lower body (z <= body_height,
      // so it never clashes with the shroud lip above)
      translate([0, box_y0 - 2, 0])
        cube([body_w, 2 + box_wall, body_height]);
    }
    // interior cavity (open top)
    translate([box_wall, box_y0 + box_wall, box_wall])
      cube([body_w - 2 * box_wall, box_len - 2 * box_wall, box_h + 1]);
  }
  // lid screw bosses in the 4 inside corners (rise from the floor)
  for (bx = sx, by = sy)
    translate([bx, by, 0]) cylinder(r=box_boss_r, h=bwt + 0.01);
}

// Cable channel: opens through the PCB pocket floor, runs forward UNDER the
// PCB and through the optics-head front wall into the box, plus a plug
// opening in the box front face.
module cable_channel(body_w, body_d, body_height, box_y0, box_y1, disp_pcb_t, clearance) {
  pocket_floor = body_height - disp_pcb_t - clearance;
  translate([body_w / 2 - cable_w / 2, body_d * 0.45, cable_z])
    cube([cable_w,
          (box_y0 + box_wall + 1) - body_d * 0.45,
          pocket_floor + 0.2 - cable_z]);
  // plug opening in the box front wall
  translate([body_w / 2 - plug_w / 2, box_y1 - box_wall - 0.1, plug_z])
    cube([plug_w, box_wall + 0.2, plug_h]);
}

// Vertical M3 insert bores in the lid bosses (from the boss tops down).
module box_lid_inserts(body_w, box_y0, box_len, box_h) {
  bwt = box_wall_top(box_h);
  box_y1 = box_y0 + box_len;
  for (bx = box_screw_x(body_w), by = box_screw_y(box_y0, box_y1))
    translate([bx, by, bwt]) insert_hole("M3");
}

// Removable top lid (separate printed part), screwed to the bosses.
module box_lid(body_w, box_y0, box_len, box_h) {
  bwt = box_wall_top(box_h);
  box_y1 = box_y0 + box_len;
  difference() {
    translate([0, box_y0, bwt])
      cube([body_w, box_len, lid_t]);
    for (bx = box_screw_x(body_w), by = box_screw_y(box_y0, box_y1))
      translate([bx, by, box_h])
        counterbore_hole("M3", lid_t, 0.4, box_head_d, box_head_h);
  }
}

// Engraved label cut into the RIGHT (+X) face of the box.  The readable side
// faces +X (outward) so it reads correctly from the right.
module right_side_engrave(body_w, engrave_y, engrave_z, text = "Exacto XM-1E0",
                          size = 6.0, depth = 0.6, font = "Liberation Sans:style=Bold") {
  translate([body_w - depth, engrave_y, engrave_z])
    rotate([90, 0, 90])
      linear_extrude(height = depth + 0.2)
        text(text, size = size, font = font,
             halign = "center", valign = "center");
}

// ── Demo (renders only when this file is opened directly) ────
$fn = 48;
_body_w = 58.20; _box_y0 = 34.00; _box_len = 80.00; _box_h = 30.00;
front_box(_body_w, _box_y0, _box_len, _box_h, 20.00);
color("orange") box_lid(_body_w, _box_y0, _box_len, _box_h);
