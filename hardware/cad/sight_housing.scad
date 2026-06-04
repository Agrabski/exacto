// ============================================================
// Exacto Reflex Sight Housing — v3 (EOTech-style)
//
// Layout:
//   screen_body()        box holding OLED + electronics, display up
//   eotech_shroud()      rectangular window frame — left/right walls,
//                        top hood, front/rear lower lips
//   glass_frame_mount()  combiner glass frame at `angle` degrees
//                        (sits inside shroud, no exposed posts)
//
// Display: Waveshare 1.27-inch SSD1351 RGB OLED
//   PCB     42.20 × 29.00 mm  (hardware/display/dimensions.png)
//   Active  38.00 × 24.80 mm
//   Holes   ø2.10, inset 2.25 mm (X) / 2.10 mm (Y) from PCB edge
//
// Lens:   24.00 × 34.00 mm, 2.74 mm thick, arcs R16.97 both ends
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
lens_top_r = 16.97;   // radius of rounded ends (both top and bottom)

// ── Structure ────────────────────────────────────────────────
wall        =  2.50;
shroud_wall =  3.00;   // EOTech shroud wall / hood thickness
clearance   =  0.30;
body_height = 20.00;   // must fit Arduino Nano + wiring
lip_h       = 10.00;   // height of front/rear lower lips on shroud

$fn = 48;

// ── Derived ──────────────────────────────────────────────────
body_w  = disp_pcb_w + 2*wall;   // 47.20
body_d  = disp_pcb_h + 2*wall;   // 34.00
// Lens is landscape: 34 mm (lens_h) horizontal, 24 mm (lens_w) along tilt.
// Arcs (R=16.97) span the 24 mm short edge — the only valid orientation.
arm_w   = lens_h + 2*wall;        // 39.00  horizontal frame width
frame_y = lens_t + 2*wall;        //  7.74  frame depth (glass normal)
frame_z = lens_w + 2*wall;        // 29.00  frame height along tilt axis
x_off   = (body_w - arm_w) / 2;  //  4.10

// Glass centre in world space (along-tilt half-span = lens_w/2)
clearance_body = 5;
glass_cz = body_height + clearance_body + lens_w/2 * sin(angle);
glass_cy = body_d / 2;

// World positions of glass edges
glass_bottom_z = glass_cz - lens_w/2 * sin(angle);
glass_bottom_y = glass_cy + lens_w/2 * cos(angle);
glass_top_z    = glass_cz + lens_w/2 * sin(angle);
glass_top_y    = glass_cy - lens_w/2 * cos(angle);

// Shroud height — auto-sized to enclose the glass frame
frame_tip_z = glass_cz + (frame_z/2)*sin(angle) + (frame_y/2)*cos(angle);
shroud_h    = frame_tip_z - body_height + shroud_wall + 4;

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

// ── EOTech-style shroud ───────────────────────────────────────
// Enclosed rectangular window frame: solid left/right side walls,
// solid top hood bar, short front/rear lower lips.
// The centre opening (front and rear faces) is left open for viewing.
module eotech_shroud() {
    sw = shroud_wall;
    bh = body_height;
    bw = body_w;
    bd = body_d;
    sh = shroud_h;

    // Left side wall (full height, full depth)
    translate([0, 0, bh])
        cube([sw, bd, sh]);

    // Right side wall
    translate([bw - sw, 0, bh])
        cube([sw, bd, sh]);

    // Top hood bar (full width, full depth)
    translate([0, 0, bh + sh - sw])
        cube([bw, bd, sw]);

    // Rear lower lip (Y=0 face, between side walls)
    translate([sw, 0, bh])
        cube([bw - 2*sw, sw, lip_h]);

    // Front lower lip (Y=body_d face, between side walls)
    translate([sw, bd - sw, bh])
        cube([bw - 2*sw, sw, lip_h]);
}

// ── Lens frame ───────────────────────────────────────────────
// Landscape orientation: lens_h (34 mm) along X, lens_w (24 mm) along Z.
// Arc caps on LEFT (low-X) and RIGHT (high-X) edges, each spanning lens_w.
// Glass slides in from the –Y face (entry opening).
module lens_frame() {
    // ── geometry --------------------------------------------------
    // inner pocket arc centres (X, Z) in frame local coords
    //   half-chord (spanning Z = lens_w) = sqrt(R² − (lens_w/2)²) = 12.00 mm
    inner_hc  = sqrt(lens_top_r*lens_top_r - (lens_w/2)*(lens_w/2)); // 12.00
    //   left  arc centre X  =  wall + lens_top_r          = 19.47
    //   right arc centre X  =  wall + lens_h − lens_top_r = 19.53
    p_lcx = wall + lens_top_r;           // 19.47
    p_rcx = wall + lens_h - lens_top_r;  // 19.53
    p_cz  = wall + lens_w / 2;           // 14.50
    p_r   = lens_top_r + clearance/2;    // 17.12

    // inner straight-section X bounds (where arc is tangent to Z=wall / Z=wall+lens_w)
    inner_lx = p_lcx - inner_hc;         //  7.47
    inner_rx = p_rcx + inner_hc;         // 31.53

    // outer shell (R_outer = lens_top_r + wall = 19.47)
    R_outer  = lens_top_r + wall;
    outer_hc = sqrt(R_outer*R_outer - (frame_z/2)*(frame_z/2)); // 12.99
    outer_lx = p_lcx - outer_hc;         //  6.48
    outer_rx = p_rcx + outer_hc;         // 32.52

    difference() {
        // ── outer shell ───────────────────────────────────────────
        union() {
            // straight middle section
            translate([outer_lx, 0, 0])
                cube([outer_rx - outer_lx, frame_y, frame_z]);

            // left arc cap (X < outer_lx)
            intersection() {
                translate([p_lcx, frame_y/2, p_cz])
                    rotate([90, 0, 0])
                        cylinder(r=R_outer, h=frame_y+0.2, center=true, $fn=60);
                translate([-(R_outer+1), -0.1, -0.1])
                    cube([R_outer+1+outer_lx, frame_y+0.2, frame_z+0.2]);
            }

            // right arc cap (X > outer_rx)
            intersection() {
                translate([p_rcx, frame_y/2, p_cz])
                    rotate([90, 0, 0])
                        cylinder(r=R_outer, h=frame_y+0.2, center=true, $fn=60);
                translate([outer_rx, -0.1, -0.1])
                    cube([R_outer+1, frame_y+0.2, frame_z+0.2]);
            }
        }

        // ── glass pocket: straight section ────────────────────────
        translate([inner_lx, -0.1, wall])
            cube([inner_rx - inner_lx, lens_t + clearance + 0.1, lens_w]);

        // ── glass pocket: left arc cap ────────────────────────────
        intersection() {
            translate([p_lcx, frame_y/2, p_cz])
                rotate([90, 0, 0])
                    cylinder(r=p_r, h=lens_t+clearance+0.2, center=true, $fn=60);
            translate([-(p_r+1), -0.1, wall])
                cube([p_r+1+inner_lx, lens_t+clearance+0.2, lens_w]);
        }

        // ── glass pocket: right arc cap ───────────────────────────
        intersection() {
            translate([p_rcx, frame_y/2, p_cz])
                rotate([90, 0, 0])
                    cylinder(r=p_r, h=lens_t+clearance+0.2, center=true, $fn=60);
            translate([inner_rx, -0.1, wall])
                cube([p_r+1, lens_t+clearance+0.2, lens_w]);
        }
    }
}

// ── Glass frame at angle ─────────────────────────────────────
module glass_frame_mount() {
    translate([body_w/2, glass_cy, glass_cz])
        rotate([90 - angle, 0, 0])
            translate([-arm_w/2, -frame_y/2, -frame_z/2])
                lens_frame();
}

// ── Full housing ─────────────────────────────────────────────
module sight_housing() {
    screen_body();
    eotech_shroud();
    glass_frame_mount();
}

sight_housing();
