// ============================================================
// Exacto Reflex Sight Housing
// Adjustable screen-to-lens angle
//
// Display: Waveshare 1.27" SSD1351 RGB OLED
//   PCB:    42.20 x 29.00 mm
//   Active: 38.00 x 24.80 mm
//   Holes:  2.10mm dia, 2.25mm from side edge, 2.10mm from top/bottom
// ============================================================

// ── Display (from hardware/display/dimensions.png) ──────────
disp_pcb_w      = 42.20;
disp_pcb_h      = 29.00;
disp_pcb_t      =  1.60;
disp_active_w   = 38.00;
disp_active_h   = 24.80;
disp_hole_d     =  2.10;
disp_hole_off_x =  2.25;  // hole centre from left/right PCB edge
disp_hole_off_y =  2.10;  // hole centre from top/bottom PCB edge

// ── Lens (measure your actual combiner glass) ───────────────
lens_w          = 30.00;  // glass width
lens_h          = 25.00;  // glass height
lens_t          =  2.00;  // glass thickness

// ── Angle adjustment ─────────────────────────────────────────
// Angle is measured between the display face normal and the lens plane.
// 45° is the classic half-mirror reflex position.
angle_default   = 45;
angle_min       = 30;
angle_max       = 60;
angle_step      =  5;   // detent spacing (degrees)

// ── Structure ────────────────────────────────────────────────
wall            =  2.50;
clearance       =  0.30;  // fit tolerance
hinge_r         =  4.00;  // knuckle outer radius
hinge_pin_d     =  3.20;  // M3 hinge pin bore
lock_bolt_d     =  3.20;  // M3 lock bolt bore in arc slot
arc_radius      = 28.00;  // radius of adjustment arc from hinge axis

$fn = 40;

// ── Derived ──────────────────────────────────────────────────
body_w  = disp_pcb_w + 2 * wall;      // 47.20
body_h  = disp_pcb_h + 2 * wall;      // 34.00
body_d  = 22.00;                        // front-to-back depth (room for nano + wiring)

lf_w    = lens_w + 2 * wall;           // lens frame outer width
lf_h    = lens_h + 2 * wall;           // lens frame outer height

// ============================================================
// SCREEN BODY
// Holds OLED PCB.  Display faces forward (+Y).
// Hinge axis sits on top edge (+Z face), centred in X.
// ============================================================
module screen_body() {
    difference() {
        // Outer shell
        rounded_box(body_w, body_d, body_h, r=2);

        // PCB pocket — display PCB slides in from front face
        translate([wall, -0.1, wall])
            cube([disp_pcb_w, disp_pcb_t + clearance + 0.1, disp_pcb_h]);

        // Display window — open front face over active area
        translate([
            wall + (disp_pcb_w - disp_active_w) / 2,
            -0.1,
            wall + (disp_pcb_h - disp_active_h) / 2
        ])
            cube([disp_active_w, wall + 0.2, disp_active_h]);

        // PCB mount holes (M2 self-tap)
        for (sx = [-1, 1], sy = [-1, 1])
            translate([
                wall + disp_pcb_w/2 + sx * (disp_pcb_w/2 - disp_hole_off_x),
                -0.1,
                wall + disp_pcb_h/2 + sy * (disp_pcb_h/2 - disp_hole_off_y)
            ])
                rotate([-90, 0, 0])
                    cylinder(d=disp_hole_d, h=wall + 0.5);

        // Ribbon cable relief — bottom centre slot
        translate([body_w/2 - 6, wall, -0.1])
            cube([12, body_d - wall, wall + 0.2]);

        // Arc slot for lens-arm lock bolt (in top face)
        translate([body_w/2, body_d/2, body_h - wall])
            arc_slot();
    }

    // Two outer hinge knuckles on top face
    for (x = [body_w * 0.25, body_w * 0.75])
        translate([x, body_d/2, body_h])
            hinge_knuckle(outer=true);

    // Detent bumps on top face alongside arc slot
    translate([body_w/2, body_d/2, body_h])
        detent_array(above=true);
}

// ============================================================
// LENS ARM
// Pivots on the hinge knuckles.  Holds lens frame at far end.
// Print separately, assemble with M3 × 30 bolt as hinge pin.
// Use M3 × 8 bolt + nut through arc slot to lock angle.
// ============================================================
module lens_arm() {
    arm_len = arc_radius + lf_h/2 + 8;  // just long enough to clear the body

    difference() {
        union() {
            // Arm backbone rib
            translate([0, -wall/2, 0])
                rounded_box(lf_w, arm_len, wall, r=2);

            // Lens frame box at far end
            translate([0, arm_len - lf_h, -wall])
                lens_frame_box();

            // Centre hinge knuckle at base of arm
            translate([lf_w/2, 0, 0])
                hinge_knuckle(outer=false);
        }

        // Arc slot for lock bolt (matches body slot, centred on arm width)
        translate([lf_w/2, 0, -0.1])
            arc_slot();
    }

    // Detent receiver dimples on underside of arm
    translate([lf_w/2, 0, 0])
        detent_array(above=false);
}

// ── Lens frame ───────────────────────────────────────────────
module lens_frame_box() {
    // Open-front channel; lens slides in from front, retained by snap lips
    difference() {
        cube([lf_w, lf_h, lens_t + 2 * wall]);

        // Lens slot (open front face, full depth)
        translate([wall, -0.1, wall])
            cube([lens_w, lf_h + 0.2, lens_t]);

        // Retention lip cutout — leaves 1mm lips top and bottom
        translate([wall + 1.5, -0.1, wall + lens_t])
            cube([lens_w - 3, lf_h + 0.2, wall - 0.5]);
    }
}

// ── Hinge knuckle ────────────────────────────────────────────
// outer=true  → body knuckle  (full width, one gap clearance)
// outer=false → arm knuckle   (slightly narrower for slip fit)
module hinge_knuckle(outer=true) {
    len  = outer ? hinge_r * 1.5       : hinge_r * 1.5 - 2 * clearance;
    rad  = outer ? hinge_r             : hinge_r - clearance;

    rotate([90, 0, 0])
        difference() {
            cylinder(r=rad, h=len, center=true);
            cylinder(d=hinge_pin_d, h=len + 0.2, center=true);
        }
}

// ── Angle arc slot ───────────────────────────────────────────
// Swept circular slot centred on hinge axis (origin).
// Bolt travels through this slot to lock the arm angle.
module arc_slot() {
    for (a = [angle_min : 1 : angle_max])
        rotate([0, 0, a])
            translate([arc_radius, 0, -0.1])
                cylinder(d=lock_bolt_d, h=wall + 0.2);
}

// ── Detent bumps / dimples ───────────────────────────────────
// Bumps on body top face snap into dimples on arm underside.
bump_r = 0.8;

module detent_array(above=true) {
    z = above ? wall - bump_r * 0.5 : bump_r * 0.5;
    for (a = [angle_min : angle_step : angle_max])
        rotate([0, 0, a])
            translate([arc_radius, 0, z])
                sphere(r=bump_r);
}

// ── Rounded box helper ───────────────────────────────────────
module rounded_box(w, d, h, r=2) {
    hull()
        for (x = [r, w - r], y = [r, d - r])
            translate([x, y, 0])
                cylinder(r=r, h=h);
}

// ============================================================
// RENDER
// ============================================================
// Lay both parts flat for slicing, or comment out one part.

// Screen body — print in place orientation
screen_body();

// Lens arm — offset to the side for a combined slice plate,
// or print separately and rotate as needed.
translate([body_w + 5, 0, 0])
    lens_arm();
