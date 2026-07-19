use <screw_mounts.scad>

// Display PCB pocket (negative geometry) with the four M2 screw-insert
// bores beneath its floor.  Pocket floor sits at Z=0; the inserts bore down
// into -Z, so the screws enter from +Z through the PCB.
//
// Sized for the Waveshare 0.96" OLED: 26 x 26 mm board, mounting holes
// inset 2.50 (left) / 1.80 (right) horizontally and 1.90 (bottom) / 2.20
// (top) vertically.
module display_pocket() {
  pcb_w = 26.00;
  pcb_h = 26.00;
  pcb_t = 1.60;
  clearance = 0.30;

  // Mounting-hole centres from the PCB's lower-left corner.
  holes = [
    [2.50, 1.90],
    [pcb_w - 1.80, 1.90],
    [2.50, pcb_h - 2.20],
    [pcb_w - 1.80, pcb_h - 2.20],
  ];

  // PCB pocket — clearance/2 on every side so the PCB drops in freely
  cube([pcb_w + clearance, pcb_h + clearance, pcb_t + clearance + 0.1]);

  // M2 heat-set insert bores below the pocket floor, at the board's holes
  for (h = holes)
    translate([clearance / 2 + h[0], clearance / 2 + h[1], 0]) {
      insert_hole("M2");
    }
}

// Demo: the pocket cut into a solid block, opening at the block's top face.
$fn = 48;
pad = 6;
pocket_w = 26.30; // pcb_w + clearance
pocket_d = 26.30; // pcb_h + clearance
difference() {
  translate([-pad, -pad, -8.5])
    cube([pocket_w + 2 * pad, pocket_d + 2 * pad, 10]);
  display_pocket();
}
