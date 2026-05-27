// ============================================================
// Exacto Reflex Sight Housing — v2
//
// Layout:
//   screen_body()        box holding OLED + electronics, display up
//   rear_post()          tall wall at Y=0 supporting high glass edge
//   front_post()         short ledge at Y=body_d for low glass edge
//   side_rails()         left+right walls tying posts together
//   glass_frame_mount()  combiner glass frame at `angle` degrees
//
// Display: Waveshare 1.27-inch SSD1351 RGB OLED
//   PCB     42.20 × 29.00 mm  (hardware/display/dimensions.png)
//   Active  38.00 × 24.80 mm
//   Holes   ø2.10, inset 2.25 mm (X) / 2.10 mm (Y) from PCB edge
//
// Lens:   24.00 × 34.00 mm, 2.74 mm thick, top arc R16.97
//         (hardware/lens/lense.avif)
// ============================================================

// ┌─────────────────────────────────────────────────────────┐
// │  CHANGE THIS VALUE, RE-EXPORT STL, REPRINT              │
// │  angle = combiner tilt from horizontal                  │
// │  45° = classic half-mirror reflex position              │
// └─────────────────────────────────────────────────────────┘
angle = 45;   // degrees  (recommended 35–65)

// ── Display ──────────────────────────────────────────────────
disp_pcb_w      = 42.20;
disp_pcb_h      = 29.00;
disp_pcb_t      =  1.60;
disp_active_w   = 38.00;
disp_active_h   = 24.80;
disp_hole_d     =  2.10;
disp_hole_off_x =  2.25;
disp_hole_off_y =  2.10;

// ── Lens ─────────────────────────────────────────────────────
lens_w     = 24.00;
lens_h     = 34.00;
lens_t     =  2.74;
lens_top_r = 16.97;   // radius of top arc

// ── Structure ────────────────────────────────────────────────
wall       =  2.50;
clearance  =  0.30;
body_height = 20.00;  // must fit Arduino Nano + wiring

$fn = 48;

// ── Derived ──────────────────────────────────────────────────
body_w = disp_pcb_w + 2*wall;   // 47.20
body_d = disp_pcb_h + 2*wall;   // 34.00
arm_w  = lens_w + 2*wall;        // 29.00  — frame/post width in X
frame_y = lens_t + 2*wall;       // 7.74   — frame depth (Y, along glass normal)
frame_z = lens_h + 2*wall;       // 39.00  — frame height
x_off   = (body_w - arm_w) / 2; // 9.10   — X offset to centre glass on body

// Lens profile geometry (see hardware/lens/lense.avif):
//   BOTH ends are rounded with the same radius lens_top_r = 16.97 mm.
//   half_chord = sqrt(lens_top_r² - (lens_w/2)²) = 12.00 mm
//   Top arc centre:    z = lens_h - lens_top_r = 17.03  (in lens local Z)
//   Bottom arc centre: z = lens_top_r          = 16.97  (symmetric)
//   top arc tangent:   z = (lens_h-lens_top_r) + half_chord = 29.03 mm  (= lens_rect_h)
//   bottom arc tangent:z = lens_top_r - half_chord          =  4.97 mm  (= bot_rect_z)
//   Straight section height: lens_rect_h - bot_rect_z ≈ 24.06 mm
lens_arc_cz  = lens_h - lens_top_r;                                    // 17.03
lens_rect_h  = lens_arc_cz + sqrt(lens_top_r*lens_top_r - (lens_w/2)*(lens_w/2)); // 29.03
bot_rect_z   = lens_top_r - sqrt(lens_top_r*lens_top_r - (lens_w/2)*(lens_w/2)); //  4.97

// Glass center in world space.
// The glass is tilted at `angle` from horizontal in the YZ plane.
// "Top" edge (local +Z of frame) maps to world REAR-HIGH direction.
// "Bottom" edge maps to FRONT-LOW direction.
// We set clearance_body = 5 mm above body top at the bottom edge.
clearance_body = 5;
glass_cz = body_height + clearance_body + lens_h/2 * sin(angle);  // 42.02 at 45°
glass_cy = body_d / 2;                                              // 17.00

// World positions of glass edges (for calculating post heights)
// Using rotate([90-angle,0,0]) on the frame:
//   local +Z  → world (0, -cos(angle),  sin(angle)) [rear-up]
//   local +Y  → world (0,  sin(angle),  cos(angle)) [forward-up]
//
// Bottom edge (local Z = -frame_z/2 from centre):
glass_bottom_z = glass_cz - lens_h/2 * sin(angle);  // = body_height + clearance_body
glass_bottom_y = glass_cy + lens_h/2 * cos(angle);
// Top edge (local Z = +frame_z/2 from centre):
glass_top_z    = glass_cz + lens_h/2 * sin(angle);
glass_top_y    = glass_cy - lens_h/2 * cos(angle);

// Post heights above body_height
rear_post_h  = glass_top_z  + frame_y/2*cos(angle) + wall - body_height;
front_post_h = max(wall, glass_bottom_z - frame_y/2*cos(angle) - body_height);

// ============================================================

module rounded_box(w, d, h, r=2) {
    hull()
        for (x=[r,w-r], y=[r,d-r])
            translate([x,y,0]) cylinder(r=r, h=h);
}

// ── Screen body ──────────────────────────────────────────────
// Display window faces UP (+Z).  Y=0 = rear, Y=body_d = front.
module screen_body() {
    difference() {
        rounded_box(body_w, body_d, body_height);

        // PCB pocket
        translate([wall, wall, body_height - disp_pcb_t - clearance])
            cube([disp_pcb_w, disp_pcb_h, disp_pcb_t + clearance + 0.1]);

        // Active-area window in top face
        translate([
            wall + (disp_pcb_w - disp_active_w)/2,
            wall + (disp_pcb_h - disp_active_h)/2,
            body_height - wall
        ])
            cube([disp_active_w, disp_active_h, wall + 0.2]);

        // PCB mount holes ø2.10
        for (sx=[-1,1], sy=[-1,1])
            translate([
                wall + disp_pcb_w/2 + sx*(disp_pcb_w/2 - disp_hole_off_x),
                wall + disp_pcb_h/2 + sy*(disp_pcb_h/2 - disp_hole_off_y),
                body_height - wall
            ])
                cylinder(d=disp_hole_d, h=wall+1);

        // Ribbon cable slot in rear wall (Y=0)
        translate([body_w/2-6, -0.1, body_height - disp_pcb_t - 5])
            cube([12, wall+0.2, 5]);

        // USB/power port in front wall
        translate([body_w/2-5, body_d-wall, 4])
            cube([10, wall+0.2, 8]);
    }
}

// ── Rear post ────────────────────────────────────────────────
// Tall wall across the full arm width at the rear (Y=0).
// Supports the high edge of the glass.
module rear_post() {
    translate([x_off, 0, body_height])
        cube([arm_w, wall, rear_post_h]);
}

// ── Front post ───────────────────────────────────────────────
// Short ledge at the front (Y=body_d) supporting the low glass edge.
module front_post() {
    translate([x_off, body_d - wall, body_height])
        cube([arm_w, wall, front_post_h]);
}

// ── Side rails ───────────────────────────────────────────────
// Left and right walls connecting rear and front posts.
// Their top edge follows the glass tilt so the frame sits flush.
module side_rails() {
    for (x = [x_off, x_off + arm_w - wall])
        translate([x, 0, body_height])
            hull() {
                cube([wall, wall,         rear_post_h]);
                translate([0, body_d-wall, 0])
                    cube([wall, wall, front_post_h]);
            }
}

// ── Lens frame ───────────────────────────────────────────────
// A pocket that grips the combiner glass (24 × 34 mm, top arc R16.97).
// Glass slides in from the –Y face.
//
// Frame outer profile = lens profile offset by wall.
// Outer arc: same centre as lens arc (in frame Z), radius = lens_top_r + wall.
// Outer rectangular height = (outer arc centre Z) + sqrt(R_outer² - (arm_w/2)²)
module lens_frame() {
    R_outer     = lens_top_r + wall;
    outer_arc_cz = wall + lens_arc_cz;            // 2.5 + 17.03 = 19.53
    outer_rect_h = outer_arc_cz
                 + sqrt(R_outer*R_outer - (arm_w/2)*(arm_w/2));  // 19.53+12.99=32.52

    difference() {
        // Outer shell: rectangular body + only the arc sliver above outer_rect_h
        union() {
            cube([arm_w, frame_y, outer_rect_h]);

            // Arc cap clipped to the region above outer_rect_h (sagitta ≈ 6.5 mm)
            intersection() {
                translate([arm_w/2, frame_y/2, outer_arc_cz])
                    rotate([90, 0, 0])
                        cylinder(r=R_outer, h=frame_y + 0.2, center=true, $fn=60);
                translate([-1, -0.1, outer_rect_h])
                    cube([arm_w + 2, frame_y + 0.2, R_outer]);
            }
        }

        // Glass pocket: straight section only (between the two arc tangent lines)
        translate([wall, -0.1, wall + bot_rect_z])
            cube([lens_w, lens_t + clearance + 0.1, lens_rect_h - bot_rect_z]);

        // Glass pocket: top arc cap clipped above lens_rect_h (sagitta ≈ 4.97 mm)
        intersection() {
            translate([arm_w/2, frame_y/2, wall + lens_arc_cz])
                rotate([90, 0, 0])
                    cylinder(r=lens_top_r + clearance/2,
                             h=lens_t + clearance + 0.2, center=true, $fn=60);
            translate([-1, -0.1, wall + lens_rect_h])
                cube([arm_w + 2, frame_y + 0.2, lens_top_r + 1]);
        }

        // Glass pocket: bottom arc cap clipped below bot_rect_z (sagitta ≈ 4.97 mm)
        intersection() {
            translate([arm_w/2, frame_y/2, wall + lens_top_r])
                rotate([90, 0, 0])
                    cylinder(r=lens_top_r + clearance/2,
                             h=lens_t + clearance + 0.2, center=true, $fn=60);
            translate([-1, -0.1, wall - 0.1])
                cube([arm_w + 2, frame_y + 0.2, bot_rect_z + 0.2]);
        }
    }
}

// ── Glass frame at angle ─────────────────────────────────────
// Positions lens_frame() at glass_cz with the correct tilt.
//
// rotate([90-angle, 0, 0]) maps:
//   local +Y (frame depth/normal) → world (0,  sin(a), cos(a))  [forward-up]
//   local +Z (frame height)       → world (0, -cos(a), sin(a))  [rear-up]
// This gives: bottom of glass at front-low, top at rear-high.
module glass_frame_mount() {
    translate([body_w/2, glass_cy, glass_cz])
        rotate([90 - angle, 0, 0])
            translate([-arm_w/2, -frame_y/2, -frame_z/2])
                lens_frame();
}

// ── Full housing ─────────────────────────────────────────────
module sight_housing() {
    screen_body();
    rear_post();
    front_post();
    side_rails();
    glass_frame_mount();
}

sight_housing();
