// ============================================================
// Exacto Reflex Sight Housing
//
// Display: Waveshare 1.27-inch SSD1351 RGB OLED
//   PCB     42.20 × 29.00 mm  (hardware/display/dimensions.png)
//   Active  38.00 × 24.80 mm
//   Holes   ø2.10 mm, inset 2.25 mm (X) / 2.10 mm (Y) from PCB edge
//
// Printed as one piece.  The lens arm is fused to the body at
// the chosen angle — no hinge, no hardware needed.
// ============================================================

// ┌─────────────────────────────────────────────────────────┐
// │  CHANGE THIS VALUE, RE-EXPORT STL, REPRINT              │
// │  angle = degrees between display plane and lens plane   │
// │  45° = standard half-mirror reflex position             │
// └─────────────────────────────────────────────────────────┘
angle = 45;    // recommended range: 35–65

// ── Display (hardware/display/dimensions.png) ────────────────
disp_pcb_w      = 42.20;
disp_pcb_h      = 29.00;
disp_pcb_t      =  1.60;
disp_active_w   = 38.00;
disp_active_h   = 24.80;
disp_hole_d     =  2.10;
disp_hole_off_x =  2.25;   // hole centre from PCB side edge
disp_hole_off_y =  2.10;   // hole centre from PCB top/bottom edge

// ── Lens / combiner glass (hardware/lens/lense.avif) ────────
// Shape: 24 mm wide, 34 mm tall, rounded top (arc R16.97 mm)
// Side profile: meniscus, R138.34 convex / R136.5 concave, 2.74 mm thick
lens_w = 24.00;
lens_h = 34.00;
lens_t =  2.74;
lens_top_r = 16.97;   // radius of rounded top arc

// ── Structure ────────────────────────────────────────────────
wall         = 2.50;
clearance    = 0.30;
body_height  = 20.00;   // Z depth of electronics cavity (Arduino Nano + wiring)

$fn = 40;

// ── Derived ──────────────────────────────────────────────────
// Display PCB lays flat on the body top face; body footprint = PCB + walls.
body_w  = disp_pcb_w + 2 * wall;   // 47.20 mm  (X)
body_d  = disp_pcb_h + 2 * wall;   // 34.00 mm  (Y, rear to front)

arm_w   = lens_w + 2 * wall;        // lens frame / arm width (X)
frame_z = lens_h + 2 * wall;        // lens frame height (Z)
frame_y = lens_t + 2 * wall;        // lens frame depth along arm (Y)
arm_t   = wall * 2;                  // arm rib thickness in Z

// Arm length: positions lens frame centre above display centre in Y.
arm_len = body_d / (2 * cos(angle)) + frame_y / 2 + 5;

// ============================================================

module rounded_box(w, d, h, r=2) {
    hull()
        for (x=[r, w-r], y=[r, d-r])
            translate([x, y, 0]) cylinder(r=r, h=h);
}

// ── Screen body ──────────────────────────────────────────────
// Display window faces UP (+Z).
// Y=0 = rear face (arm side, connector exits here).
// Y=body_d = front face (target-facing side).
module screen_body() {
    difference() {
        rounded_box(body_w, body_d, body_height);

        // PCB pocket — OLED drops in from top
        translate([wall, wall, body_height - disp_pcb_t - clearance])
            cube([disp_pcb_w, disp_pcb_h, disp_pcb_t + clearance + 0.1]);

        // Active-area window through top face
        translate([
            wall + (disp_pcb_w - disp_active_w) / 2,
            wall + (disp_pcb_h - disp_active_h) / 2,
            body_height - wall
        ])
            cube([disp_active_w, disp_active_h, wall + 0.2]);

        // PCB mount holes, ø2.10 mm (M2 self-tap)
        for (sx=[-1,1], sy=[-1,1])
            translate([
                wall + disp_pcb_w/2 + sx*(disp_pcb_w/2 - disp_hole_off_x),
                wall + disp_pcb_h/2 + sy*(disp_pcb_h/2 - disp_hole_off_y),
                body_height - wall
            ])
                cylinder(d=disp_hole_d, h=wall + 1);

        // Ribbon cable relief through rear wall (Y=0)
        translate([body_w/2 - 6, -0.1, body_height - disp_pcb_t - 5])
            cube([12, wall + 0.2, 5]);

        // USB / power access port in front wall (Y=body_d)
        translate([body_w/2 - 5, body_d - wall, 4])
            cube([10, wall + 0.2, 8]);
    }
}

// ── Lens frame ───────────────────────────────────────────────
// Combiner glass slides into pocket from the –Y face (toward pivot).
// Frame profile matches the lens: rectangular body + rounded top cap.
module lens_frame() {
    // Rectangular bottom portion height (below the rounded cap)
    rect_h = lens_h - lens_top_r;

    difference() {
        union() {
            // Rectangular lower section
            cube([arm_w, frame_y, rect_h + wall]);

            // Rounded top cap: hull between two cylinders
            translate([arm_w/2, frame_y/2, rect_h + wall])
                hull() {
                    translate([-lens_w/2 + lens_top_r, 0, 0])
                        cylinder(r=lens_top_r + wall, h=frame_y, center=true);
                    translate([ lens_w/2 - lens_top_r, 0, 0])
                        cylinder(r=lens_top_r + wall, h=frame_y, center=true);
                }
        }

        // Glass pocket — rectangular lower slot
        translate([wall, -0.1, wall])
            cube([lens_w, lens_t + clearance + 0.1, rect_h]);

        // Glass pocket — rounded top cap slot
        translate([arm_w/2, lens_t/2 + wall/2, rect_h + wall])
            hull() {
                translate([-lens_w/2 + lens_top_r, 0, 0])
                    cylinder(r=lens_top_r + clearance, h=lens_t + clearance + 0.2, center=true);
                translate([ lens_w/2 - lens_top_r, 0, 0])
                    cylinder(r=lens_top_r + clearance, h=lens_t + clearance + 0.2, center=true);
            }
    }
}

// ── Lens arm ─────────────────────────────────────────────────
// Flat rib extending in +Y from origin.
// Lens frame attached at far end, perpendicular to arm axis.
module lens_arm() {
    union() {
        // Backbone rib
        cube([arm_w, arm_len - frame_y, arm_t]);

        // Lens frame at tip, bottom flush with rib
        translate([0, arm_len - frame_y, 0])
            lens_frame();
    }
}

// ── Full housing (one solid piece) ───────────────────────────
// Display faces up.  Arm pivots from rear-top edge (Y=0, Z=body_height),
// centred in X.  rotate([angle,0,0]) tilts arm from horizontal toward
// vertical:  0°=flat (useless),  45°=classic reflex,  90°=straight up.
module sight_housing() {
    screen_body();

    translate([(body_w - arm_w) / 2, 0, body_height])
        rotate([angle, 0, 0])
            lens_arm();
}

sight_housing();
