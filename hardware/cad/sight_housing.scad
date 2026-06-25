// ============================================================
// Exacto Reflex Sight Housing — v4 (EOTech-style, two-part)
//
// Two screw-joined parts, split at the seam z = body_height (20 mm):
//   bottom_part()  display holder = screen_body() + joint inserts
//   top_part()     lens holder    = eotech_shroud() + glass_frame_mount()
//
// Sub-modules:
//   screen_body()        box holding OLED + electronics, display up
//   eotech_shroud()      rectangular window frame — left/right walls,
//                        top hood, front/rear lower lips
//   glass_frame_mount()  combiner glass frame at `angle` degrees
//                        (sits inside shroud; side arms overlap the
//                        frame and merge into the shroud side walls)
//
// Joint: the top part's side walls drop below the seam as SKIRTS that lap
//   over rebates on the bottom part's thick side edges.  4 horizontal M3
//   screws (2 per side), placed LOW — under the PCB, in the solid lower
//   body — pin and clamp the lap.  Use M3 x ~12 mm into brass inserts.
//   The left/right edges are thickened (side_edge) to host the inserts.
//
// Forward box: a hollow electronics enclosure extends from the optics head
//   toward the muzzle (box_len), full width, up to the lens-opening height,
//   with a screw-on top lid.  Cable routes UNDER the PCB to a plug opening
//   in the box front face.
//
// Mount: a female MIL-STD-1913 Picatinny clamp (picatinny.scad) is fused
//   to the underside and runs the WHOLE length of the sight.
//
// Glass retention: friction fit in the frame pocket + adhesive.
// (No set screws — the merged side arms would bury them.)
//
// Set `part` below to choose what to render/export.
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
use <picatinny.scad>
use <watertight_box.scad>

angle = 60; // degrees  (recommended 35–65)

// Which piece to render/export: "both" (assembled), "top", "bottom",
// "bar" (removable Picatinny clamp jaw), "lid" (box top lid)
part = "both";

// Forward electronics box (extends from the optics head toward the muzzle).
box_len = 80.00; // box length, front-to-rear (8 cm)

// ── Display ──────────────────────────────────────────────────
disp_pcb_w = 42.20;
disp_pcb_h = 29.00;
disp_pcb_t = 1.60;
disp_active_w = 38.00;
disp_active_h = 24.80;
disp_hole_d = 2.10; // PCB clearance-hole dia (datasheet); not used for body bores
disp_hole_off_x = 2.25;
disp_hole_off_y = 2.10;

// ── Fasteners ────────────────────────────────────────────────
// PCB is retained by M2 screws from the top, threading into brass
// heat-set inserts pressed into the body below the PCB pocket.
insert_d = 3.20; // M2 heat-set insert outer diameter (bore)
insert_depth = 4.00; // insert length / bore depth

// Part-joining M3 screws — 4 horizontal, in the left/right edges, low
// (under the PCB) so the inserts land in the solid lower body.
join_clear_d = 3.40; // M3 clearance hole through the top-part skirt
join_insert_d = 4.00; // M3 heat-set insert outer dia (bore in bottom)
join_insert_depth = 5.00; // insert length / bore depth

// ── Lens ─────────────────────────────────────────────────────
lens_w = 24.00;
lens_h = 34.00;
lens_t = 2.74;
lens_top_r = 16.97; // radius of rounded ends (both top and bottom)
lens_lip = 2.00; // retaining lip width around the see-through window

// ── Structure ────────────────────────────────────────────────
wall = 2.50;
shroud_wall = 3.00; // EOTech shroud wall / hood thickness (front/rear, hood)
side_edge = 8.00; // THICK left/right edges (host the joint inserts)
clearance = 0.30;
body_height = 20.00; // must fit Arduino Nano + wiring
lip_h = 10.00; // height of the FRONT lower lip on shroud
rear_lip_h = 4.00; // height of the REAR lip (lowered for a clear sight picture)
arm_overlap = 3.00; // how far side arms reach INTO the lens frame

// Side-wall lap joint
lap_h = 14.00; // vertical overlap: skirt reaches this far below the seam
skirt_t = 3.00; // skirt thickness (sits in a rebate on the bottom)
joint_screw_z = 9.00; // height of the horizontal joint screws (under the PCB)

// Forward electronics box (hollow, screw-on top lid) — see watertight_box.scad
box_wall = 2.50; // box wall / floor thickness
lid_t = 2.50; // top-lid thickness
box_boss_r = 4.50; // lid screw-boss radius (inside box corners)
box_boss_inset = 2.00; // pull bosses toward corners so they merge into walls
box_screw_clear = 3.40; // M3 lid-screw clearance (lid)
box_head_d = 6.00; // M3 lid-screw head counterbore dia
box_head_h = 3.00; // counterbore depth
box_insert_d = 4.00; // M3 brass insert dia (box bosses)
box_insert_depth = 5.00;

// Watertight top seal (tongue-and-groove gasket joint between box and lid).
// The box rim carries a groove for an O-ring cord / silicone bead; the lid
// tongue drops in and the 4 corner screws clamp it to seal the electronics.
seal_rim = 5.00; // thickened sealing rim at the box opening (>= box_wall)
seal_rim_h = 4.00; // height of the thick rim band below the lid
seal_w = 2.20; // gasket-groove width (sits within the rim)
seal_depth = 2.00; // groove depth, measured down from the rim top
seal_clear = 0.25; // tongue-to-groove clearance, per side
tongue_h = 1.40; // lid-tongue height (< seal_depth → room for the gasket)

// Cable routing (channel under the PCB, plug opening at the box front)
cable_w = 14.00; // under-PCB cable channel width
cable_h = 7.00; // channel height
cable_z = 9.00; // channel floor height (under the PCB pocket)
plug_w = 14.00; // plug opening width  (box front face)
plug_h = 9.00; // plug opening height
plug_z = 8.00; // plug opening bottom z

// Right-side engraving
engrave = true; // set false to omit the engraved label
engrave_text = "Exacto XM-1E0";
engrave_size = 6.00; // glyph size (mm)
engrave_depth = 0.60; // how deep the text is cut into the face
engrave_font = "Liberation Sans:style=Bold";

$fn = 48;

// ── Derived ──────────────────────────────────────────────────
body_w = disp_pcb_w + 2 * side_edge; // 58.20  (thick left/right edges)
body_d = disp_pcb_h + 2 * wall; // 34.00
// Lens is landscape: 34 mm (lens_h) horizontal, 24 mm (lens_w) along tilt.
// Arcs (R=16.97) span the 24 mm short edge — the only valid orientation.
arm_w = lens_h + 2 * wall; // 39.00  horizontal frame width
frame_y = lens_t + 2 * wall; //  7.74  frame depth (glass normal)
frame_z = lens_w + 2 * wall; // 29.00  frame height along tilt axis

// Glass centre in world space.
// clearance_body = vertical gap from the body top to the LOWEST point of
// the tilted frame (the limiting collision), so it stays honest as `angle`
// changes.  Frame's lowest point sits frame_y/2*cos(a)+frame_z/2*sin(a)
// below the glass centre.
clearance_body = 3;
glass_cz = body_height + clearance_body + frame_y / 2 * cos(angle) + frame_z / 2 * sin(angle);
// Combiner pushed as far FORWARD as it can go while staying behind the front
// lip (so it never collides with the lip or the forward box).  frame_dy is
// the frame's half-extent along Y after the tilt.
frame_dy = frame_y / 2 * sin(angle) + frame_z / 2 * cos(angle);
glass_cy = body_d - shroud_wall - frame_dy - 0.5;

// World positions of glass edges
glass_bottom_z = glass_cz - lens_w / 2 * sin(angle);
glass_bottom_y = glass_cy + lens_w / 2 * cos(angle);
glass_top_z = glass_cz + lens_w / 2 * sin(angle);
glass_top_y = glass_cy - lens_w / 2 * cos(angle);

// Shroud height — auto-sized to enclose the glass frame
frame_tip_z = glass_cz + (frame_z / 2) * sin(angle) + (frame_y / 2) * cos(angle);
shroud_h = frame_tip_z - body_height + shroud_wall + 4;

// Y positions of the 4 side joint screws (2 per side).
side_screw_y = [body_d * 0.28, body_d * 0.72];

// Forward box geometry.  Box spans Y = body_d .. box_y1, sitting in front
// of the optics head; its top reaches the lens-opening bottom (lip top).
box_h = body_height + lip_h; // 30.00, reaches the lens opening
box_wall_top = box_h - lid_t; // 27.50, top of the box walls
box_y0 = body_d; // box back (joins the optics head)
box_y1 = body_d + box_len; // box front (muzzle end)
// (Lid screw-boss positions are derived inside watertight_box.scad from the
// box footprint, box_boss_r and box_boss_inset, so the base and lid agree.)

// Picatinny rail runs the WHOLE length of the sight (optics head + box).
rail_len = body_d + box_len;

// Engraving placement: centred along the box, a little above its mid-height.
engrave_y = (box_y0 + box_y1) / 2;
engrave_z = box_wall_top * 0.55;

// ============================================================

module rounded_box(w, d, h, r = 2) {
  hull()for (x = [r, w - r], y = [r, d - r])
    translate([x, y, 0]) cylinder(r=r, h=h);
}

// ── Screen body ──────────────────────────────────────────────
// Optics-only housing: OLED PCB sits in a top pocket; all other
// electronics (MCU, battery, USB) live in a separate external box
// connected through the rear ribbon-cable slot.
// Display window faces UP (+Z).  Y=0 = rear, Y=body_d = front.
module screen_body() {
  difference() {
    rounded_box(body_w, body_d, body_height);

    // PCB pocket — clearance/2 on every side so PCB drops in freely
    translate(
      [
        side_edge - clearance / 2,
        wall - clearance / 2,
        body_height - disp_pcb_t - clearance,
      ]
    )
      cube(
        [
          disp_pcb_w + clearance,
          disp_pcb_h + clearance,
          disp_pcb_t + clearance + 0.1,
        ]
      );

    // Active-area window in top face
    translate(
      [
        side_edge + (disp_pcb_w - disp_active_w) / 2,
        wall + (disp_pcb_h - disp_active_h) / 2,
        body_height - wall,
      ]
    )
      cube([disp_active_w, disp_active_h, wall + 0.2]);

    // PCB mount: heat-set insert bores below the PCB pocket floor.
    // M2 screws drop through the PCB corner holes from above and thread
    // into brass inserts pressed up into these bores.
    for (sx = [-1, 1], sy = [-1, 1])
      translate(
        [
          side_edge + disp_pcb_w / 2 + sx * (disp_pcb_w / 2 - disp_hole_off_x),
          wall + disp_pcb_h / 2 + sy * (disp_pcb_h / 2 - disp_hole_off_y),
          body_height - disp_pcb_t - clearance - insert_depth,
        ]
      )
        cylinder(d=insert_d, h=insert_depth + 0.1);

    // Cable exits FORWARD now (see cable_channel()); no rear slot.
  }
}

// ── EOTech-style shroud ───────────────────────────────────────
// Enclosed rectangular window frame: solid left/right side walls,
// solid top hood bar, short front/rear lower lips.
// The centre opening (front and rear faces) is left open for viewing.
module eotech_shroud() {
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

// ── Lens frame ───────────────────────────────────────────────
// Landscape orientation: lens_h (34 mm) along X, lens_w (24 mm) along Z.
// Arc caps on LEFT (low-X) and RIGHT (high-X) edges, each spanning lens_w.
// Glass slides in from the +Y (FRONT) face; the -Y side has the retaining
// lip.  Held by friction fit plus adhesive.
module lens_frame() {
  // ── geometry --------------------------------------------------
  // inner pocket arc centres (X, Z) in frame local coords
  //   half-chord (spanning Z = lens_w) = sqrt(R² − (lens_w/2)²) = 12.00 mm
  inner_hc = sqrt(lens_top_r * lens_top_r - (lens_w / 2) * (lens_w / 2)); // 12.00
  //   left  arc centre X  =  wall + lens_top_r          = 19.47
  //   right arc centre X  =  wall + lens_h − lens_top_r = 19.53
  p_lcx = wall + lens_top_r; // 19.47
  p_rcx = wall + lens_h - lens_top_r; // 19.53
  p_cz = wall + lens_w / 2; // 14.50
  p_r = lens_top_r + clearance / 2; // 17.12

  // inner straight-section X bounds (where arc is tangent to Z=wall / Z=wall+lens_w)
  inner_lx = p_lcx - inner_hc; //  7.47
  inner_rx = p_rcx + inner_hc; // 31.53

  // outer shell (R_outer = lens_top_r + wall = 19.47)
  R_outer = lens_top_r + wall;
  outer_hc = sqrt(R_outer * R_outer - (frame_z / 2) * (frame_z / 2)); // 12.99
  outer_lx = p_lcx - outer_hc; //  6.48
  outer_rx = p_rcx + outer_hc; // 32.52

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

    // Glass enters from the FRONT (+Y) face: the pocket opens at +Y and the
    // retaining lip is on the -Y side.  pky = pocket start in Y.
    pkt = lens_t + clearance;
    pky = frame_y - pkt;

    // ── glass pocket: straight section ────────────────────────
    translate([inner_lx, pky, wall])
      cube([inner_rx - inner_lx, pkt + 0.1, lens_w]);

    // ── glass pocket: left arc cap ────────────────────────────
    // Cylinder centred at frame_y - pkt/2 so it spans the +Y pocket depth
    // and reaches the front entry face.
    intersection() {
      translate([p_lcx, frame_y - pkt / 2, p_cz])
        rotate([90, 0, 0])
          cylinder(r=p_r, h=pkt + 0.2, center=true, $fn=60);
      translate([-(p_r + 1), -0.1, wall])
        cube([p_r + 1 + inner_lx, frame_y + 0.2, lens_w]);
    }

    // ── glass pocket: right arc cap ───────────────────────────
    intersection() {
      translate([p_rcx, frame_y - pkt / 2, p_cz])
        rotate([90, 0, 0])
          cylinder(r=p_r, h=pkt + 0.2, center=true, $fn=60);
      translate([inner_rx, -0.1, wall])
        cube([p_r + 1, frame_y + 0.2, lens_w]);
    }

    // ── see-through window — open through BOTH faces so you can look
    //    through the combiner; a lens_lip-wide rim retains the glass. ──
    wr = p_r - lens_lip; // inset arc radius for the window
    // straight middle (full X, Z inset by the lip)
    translate([inner_lx, -0.1, wall + lens_lip])
      cube([inner_rx - inner_lx, frame_y + 0.2, lens_w - 2 * lens_lip]);
    // left arc end (inset)
    intersection() {
      translate([p_lcx, frame_y / 2, p_cz])
        rotate([90, 0, 0]) cylinder(r=wr, h=frame_y + 0.2, center=true, $fn=60);
      translate([-(wr + 1), -0.1, wall + lens_lip])
        cube([wr + 1 + inner_lx, frame_y + 0.2, lens_w - 2 * lens_lip]);
    }
    // right arc end (inset)
    intersection() {
      translate([p_rcx, frame_y / 2, p_cz])
        rotate([90, 0, 0]) cylinder(r=wr, h=frame_y + 0.2, center=true, $fn=60);
      translate([inner_rx, -0.1, wall + lens_lip])
        cube([wr + 1, frame_y + 0.2, lens_w - 2 * lens_lip]);
    }
  }
}

// ── Glass frame at angle ─────────────────────────────────────
// The lens_frame is centred in X; rectangular arms run from each shroud
// side wall and overlap arm_overlap mm INTO the frame's curved end.  The
// frame ends taper to a point at the apex, so the arms must overlap the
// solid arc region (not just butt the apex) to merge into one solid.
module glass_frame_mount() {
  arm_len = body_w / 2 - arm_w / 2 + arm_overlap;
  translate([body_w / 2, glass_cy, glass_cz])
    rotate([90 - angle, 0, 0]) {
      translate([-arm_w / 2, -frame_y / 2, -frame_z / 2])
        lens_frame();

      // Left arm: from left shroud wall, overlapping the frame end
      translate([-body_w / 2, -frame_y / 2, -frame_z / 2])
        cube([arm_len, frame_y, frame_z]);

      // Right arm: from right shroud wall, overlapping the frame end
      translate([arm_w / 2 - arm_overlap, -frame_y / 2, -frame_z / 2])
        cube([arm_len, frame_y, frame_z]);
    }
}

// ── Side lap joint ───────────────────────────────────────────
// The top-part skirts lap over rebates in the bottom-part side edges;
// 4 horizontal M3 screws (2 per side, low — under the PCB) pin and clamp
// them.  The screw shanks also pin the halves against vertical separation.

// Rebate the bottom part's outer side faces so the skirts sit flush.
module side_rebates() {
  translate([-0.1, -0.1, body_height - lap_h])
    cube([skirt_t + 0.1, body_d + 0.2, lap_h + 0.2]);
  translate([body_w - skirt_t, -0.1, body_height - lap_h])
    cube([skirt_t + 0.1, body_d + 0.2, lap_h + 0.2]);
}

// Brass-insert bores in the thick bottom side edges (open at the rebate
// face), low and in solid material below the PCB.
module joint_inserts() {
  for (y = side_screw_y) {
    translate([skirt_t - 0.3, y, joint_screw_z]) // left edge, bore +X
      rotate([0, 90, 0]) cylinder(d=join_insert_d, h=join_insert_depth + 0.3);
    translate([body_w - skirt_t + 0.3, y, joint_screw_z]) // right edge, bore -X
      rotate([0, -90, 0]) cylinder(d=join_insert_d, h=join_insert_depth + 0.3);
  }
}

// M3 clearance holes through the top-part skirts.
module joint_clearance() {
  for (y = side_screw_y) {
    translate([-0.1, y, joint_screw_z])
      rotate([0, 90, 0]) cylinder(d=join_clear_d, h=skirt_t + 0.3);
    translate([body_w + 0.1, y, joint_screw_z])
      rotate([0, -90, 0]) cylinder(d=join_clear_d, h=skirt_t + 0.3);
  }
}

// ── Forward electronics box ──────────────────────────────────
// Hollow box in front of the optics head, with a WATERTIGHT screw-on top
// lid (see watertight_box.scad).  Its back joins the optics-head front
// wall; the cable enters via cable_channel().  Walls/floor = box_wall; top
// reaches the lens opening.
module front_box() {
  // Watertight enclosure: shell + sealing rim + lid screw bosses/inserts.
  translate([0, box_y0, 0])
    watertight_box_base(
      w = body_w, d = box_len, h = box_wall_top,
      wall = box_wall, floor = box_wall,
      rim = seal_rim, rim_h = seal_rim_h,
      seal_w = seal_w, seal_depth = seal_depth,
      boss_r = box_boss_r, boss_inset = box_boss_inset,
      insert_d = box_insert_d, insert_depth = box_insert_depth
    );
  // fuse block tying the box into the lower body (z <= body_height, so it
  // never clashes with the shroud lip above)
  translate([0, box_y0 - 2, 0])
    cube([body_w, 2 + box_wall, body_height]);
}

// Cable channel: opens through the PCB pocket floor, runs forward UNDER the
// PCB and through the optics-head front wall into the box, plus a plug
// opening in the box front face.  Top reaches the pocket floor so the
// display cable can drop straight down into it.
module cable_channel() {
  pocket_floor = body_height - disp_pcb_t - clearance; // 18.10
  translate([body_w / 2 - cable_w / 2, body_d * 0.45, cable_z])
    cube([cable_w,
          (box_y0 + box_wall + 1) - body_d * 0.45,
          pocket_floor + 0.2 - cable_z]);
  // plug opening in the box front wall
  translate([body_w / 2 - plug_w / 2, box_y1 - box_wall - 0.1, plug_z])
    cube([plug_w, box_wall + 0.2, plug_h]);
}

// Removable top lid (separate printed part): a sealing tongue drops into
// the box-rim groove and 4 counterbored screws clamp it down — watertight.
module box_lid() {
  translate([0, box_y0, 0])
    watertight_box_lid(
      w = body_w, d = box_len, h = box_wall_top,
      lid_t = lid_t,
      rim = seal_rim,
      seal_w = seal_w, seal_depth = seal_depth,
      seal_clear = seal_clear, tongue_h = tongue_h,
      wall = box_wall, boss_r = box_boss_r, boss_inset = box_boss_inset,
      screw_clear = box_screw_clear, head_d = box_head_d, head_h = box_head_h
    );
}

// Engraved label cut into the RIGHT (+X) face of the box.  The text's
// readable side faces +X (outward) so it reads correctly from the right.
module right_side_engrave() {
  translate([body_w - engrave_depth, engrave_y, engrave_z])
    rotate([90, 0, 90])
      linear_extrude(height = engrave_depth + 0.2)
        text(engrave_text, size = engrave_size, font = engrave_font,
             halign = "center", valign = "center");
}

// ── Two parts ────────────────────────────────────────────────
module bottom_part() {
  difference() {
    union() {
      screen_body();
      front_box();
      // Picatinny clamp FIXED body — runs the WHOLE length on the underside.
      translate([body_w / 2, 0, 0]) picatinny_clamp_body(rail_len);
    }
    side_rebates();
    joint_inserts();
    cable_channel();
    if (engrave) right_side_engrave();
  }
}

// Removable clamp bar, placed in its assembled position under the sight.
module clamp_bar() {
  translate([body_w / 2, 0, 0]) picatinny_clamp_bar(rail_len);
}

module top_part() {
  difference() {
    union() {
      eotech_shroud();
      glass_frame_mount();
    }
    joint_clearance();
  }
}

// ── Render selector ──────────────────────────────────────────
if (part == "bottom")
  bottom_part();
else if (part == "top")
  top_part();
else if (part == "bar") // the removable clamp bar, on its own
clamp_bar(); else if (part == "lid") // the box top lid, on its own
box_lid(); else {
  // "both" — full assembled preview
  bottom_part();
  top_part();
  clamp_bar();
  box_lid();
}
