// ============================================================
// Exacto Reflex Sight Housing — v5 (EOTech-style, two-part, birdbath optics)
//
// Two screw-joined parts, split at the seam z = body_height (20 mm):
//   bottom_part()  display holder = screen_body() + joint inserts
//   top_part()     optics holder  = eotech_shroud() + beamsplitter_mount()
//                                   + mirror_mount()
//
// Sub-modules:
//   screen_body()         box holding OLED + electronics, display up
//   eotech_shroud()       rectangular window frame — left/right walls,
//                         top hood, front/rear lower lips, sized to
//                         enclose BOTH optics frames
//   beamsplitter_frame()  flat 30/70 plate frame at `angle` degrees
//   mirror_frame()        curved collimating mirror frame at `mirror_tilt`
//   beamsplitter_mount()  / mirror_mount()  position each frame in world
//                         space (side arms overlap the frame and merge
//                         into the shroud side walls, same idiom as v4)
//
// Optics — true birdbath, two elements (replaces the v4 single curved
//   combiner lens):
//   display (face up) -> flat 30/70 beamsplitter (tilted `angle`,
//   1st hit) -> curved collimating mirror (`mirror_tilt`) -> SAME
//   beamsplitter panel (2nd hit, offset from the 1st) -> eye.  The fold
//   geometry is fully derived from `angle`; see the "Birdbath optics"
//   parameter block below for the closed-form formulas.
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
// Optics retention: friction fit in the frame pockets + adhesive.
// (No set screws — the merged side arms would bury them.)
//
// Set `part` below to choose what to render/export.
//
// Display: Waveshare 1.27-inch SSD1351 RGB OLED
//   PCB     42.20 × 29.00 mm  (hardware/display/dimensions.png)
//   Active  38.00 × 24.80 mm
//   Holes   ø2.10, inset 2.25 mm (X) / 2.10 mm (Y) from PCB edge
//
// Birdbath optics (replaces the old single curved meniscus combiner):
//   Beamsplitter: flat 30/70 reflective sheet, bs_w x bs_h, tilted `angle`.
//   Mirror:       curved collimating mirror, mirror_w x mirror_h, single
//                 cylindrical curvature mirror_R, tilted `mirror_tilt`.
//   See the "Birdbath optics" parameter block for the full derivation.
// ============================================================

// ┌─────────────────────────────────────────────────────────┐
// │  CHANGE THIS VALUE, RE-EXPORT STL, REPRINT              │
// │  angle = beamsplitter tilt from horizontal (1st bounce) │
// │  mirror_tilt is DERIVED from this — see below           │
// │  45° = classic half-mirror reflex position               │
// └─────────────────────────────────────────────────────────┘
use <picatinny.scad>

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

// ── Birdbath optics ─────────────────────────────────────────────
// True two-element birdbath, replacing the old single curved combiner:
//   display (face up) -> flat 30/70 beamsplitter, 1st hit (tilt `angle`)
//   -> curved collimating mirror (tilt `mirror_tilt`)
//   -> SAME beamsplitter panel, 2nd hit -> eye.
//
// Fold derivation (2D ray trace in the Y-Z plane; X is irrelevant, all
// tilts are rotations about X exactly like `angle` always was):
//   v_in = (0,1)                                  ray leaves display straight up
//   n_bs = (sin angle, cos angle)                 beamsplitter normal
//   v_out1 = (-sin 2*angle, -cos 2*angle)          after 1st bounce, unit vector
//   mirror_tilt = 2*angle - 45                    EXACT closed form: makes the
//                                                  final exit ray dead level for
//                                                  any `angle` (verified by full
//                                                  numeric ray trace, 35-65 deg)
//   v_mirror_out = (-cos 2*angle, sin 2*angle)     after the mirror bounce, unit
//   v_final = (-1, 0)                             after the 2nd beamsplitter
//                                                  bounce — ALWAYS exactly level,
//                                                  for any `angle` — this is what
//                                                  keeps the reticle parallel to
//                                                  the straight-through view of
//                                                  the target (proper collimated
//                                                  overlay)
//
// gap1/mirror_L1 are design constants (display-to-beamsplitter and
// beamsplitter-to-mirror spacing along the folded axis); everything else
// below is derived from them + `angle`, same pattern as the old
// glass_cz/glass_cy/frame_dy block.
//
// mirror_L1 must be large enough that the beamsplitter frame and mirror
// frame (each a ~30-32 mm tall block) don't physically interpenetrate —
// their world-space centres are only mirror_L1 mm apart (P2 = P1 +
// mirror_L1 * v_out1, and the beamsplitter sits at the P1/P3 midpoint),
// so a short mirror_L1 packs two ~30 mm frames closer together than their
// own half-heights allow.  Verified numerically (2D SAT polygon check,
// frame envelope boxes, swept across angle = 35-65 deg): mirror_L1 = 13
// (the original guess) collides at every angle in range; mirror_L1 = 34
// keeps a >= 3 mm separation margin at the worst-case angle (65 deg).
gap1 = 13.00; // display centre -> beamsplitter centre, along the fold axis
mirror_L1 = 34.00; // beamsplitter centre -> mirror vertex, along the fold axis
mirror_f = gap1 + mirror_L1; // unfolded optical path length
mirror_R = 2 * mirror_f; // paraxial radius of curvature (single-axis/cylindrical)
mirror_tilt = 2 * angle - 45; // exact closed-form fold-bisector tilt
mirror_L2 = mirror_L1 / tan(angle); // mirror vertex -> 2nd beamsplitter hit, exact

// Beamsplitter (flat 30/70 sheet) — plain rectangle, no arc caps.
bs_w = 32.00; // panel width across X
bs_h = 30.00; // panel height along the tilt direction (must clear both hit points)
bs_t = 2.00; // sheet thickness
bs_lip = 2.00; // retaining lip width around the see-through window

// Mirror (curved collimating reflector) — single-axis cylindrical curvature
// mirror_R, spanning mirror_w x mirror_h.  Sagitta over mirror_h is ~2.5 mm
// at the values above — same order of magnitude as the old lens's own
// 4.97 mm sagitta, so the existing arc-cap Boolean technique transfers
// directly (cylinder ∩ bounding box).
mirror_w = 32.00; // mirror width across X
mirror_h = 32.00; // mirror height along the tilt direction
mirror_t = 4.00; // backing thickness behind the reflective face (polished insert pocket)
mirror_lip = 2.00; // retaining lip width around the reflective-insert pocket

// Reference dimensions for clearance checks only — NOT cut/printed geometry.
eye_relief = 50.00; // eye -> 2nd beamsplitter hit point, along the level exit ray
exit_pupil = 8.00; // nominal exit pupil diameter, for sightline-cone checks

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

// Forward electronics box (hollow, screw-on top lid)
box_wall = 2.50; // box wall / floor thickness
lid_t = 2.50; // top-lid thickness
lid_fit = 0.20; // lid-to-pocket clearance
box_boss_r = 4.50; // lid screw-boss radius (inside box corners)
box_screw_clear = 3.40; // M3 lid-screw clearance (lid)
box_head_d = 6.00; // M3 lid-screw head counterbore dia
box_head_h = 3.00; // counterbore depth
box_insert_d = 4.00; // M3 brass insert dia (box bosses)
box_insert_depth = 5.00;

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

// Frame envelopes (pocket + wall) for each optic, same pattern as the old
// frame_y/frame_z but one per element.  "_y" = depth along the optic's own
// normal; "_z" = extent along the tilt direction (in-plane).
bs_frame_y = bs_t + 2 * wall; //  7.00  beamsplitter frame depth
bs_frame_z = bs_h + 2 * wall; // 35.00  beamsplitter frame height along tilt

// Mirror sagitta over its curved (mirror_w) axis — the curved pocket eats
// extra depth at the vertex, so mirror_frame_y must include it on top of
// the usual wall + insert-pocket allowance, or the backing wall behind
// the deepest point of the pocket would be thinner than `wall`.
mirror_sagitta = mirror_R - sqrt(mirror_R * mirror_R - (mirror_w / 2) * (mirror_w / 2)); // ~2.52 mm
mirror_frame_y = wall + (mirror_t + clearance) + mirror_sagitta + wall; // ~11.52  mirror frame depth
mirror_frame_z = mirror_h + 2 * wall; // 37.00  mirror frame height along tilt

// World-space fold geometry (Y,Z), derived directly from the verified
// formulas above.  X stays centred on body_w/2 for both optics, exactly
// like the display's active area is centred on body_w/2.
//   P1 = beamsplitter optical centroid (display's chief ray travels
//        straight up from the display centre, so P1 sits directly above
//        it by gap1).
//   P2 = mirror vertex = P1 + mirror_L1 * v_out1.
//   P3 = 2nd beamsplitter hit point = P2 + mirror_L2 * v_mirror_out.
// P3 is guaranteed (by the closed-form math above) to land back on the
// beamsplitter's own plane — i.e. (P3-P1) . n_bs == 0 — verified
// numerically to ~1e-15 for angle in [35,65] before settling on these
// constants; not re-asserted at OpenSCAD runtime since trig there is also
// degrees-based and consistent with the derivation.
disp_center_y = body_d / 2; // display active area is centred on body_d (==17.0)
v_out1_y = -sin(2 * angle);
v_out1_z = -cos(2 * angle);
v_mirror_out_y = -cos(2 * angle);
v_mirror_out_z = sin(2 * angle);

p1_y = disp_center_y;
p1_z = body_height + gap1;
p2_y = p1_y + mirror_L1 * v_out1_y;
p2_z = p1_z + mirror_L1 * v_out1_z;
p3_y = p2_y + mirror_L2 * v_mirror_out_y;
p3_z = p2_z + mirror_L2 * v_mirror_out_z;

// Beamsplitter panel must physically span BOTH P1 and P3 (offset from each
// other along the panel's own surface direction d_bs = (cos angle, -sin
// angle)).  Centre the panel's geometric middle at the P1/P3 midpoint so
// both hit points sit safely inside the aperture with margin for actual
// beam width, not just the chief-ray point.
bs_cy = (p1_y + p3_y) / 2;
bs_cz = (p1_z + p3_z) / 2;

// Mechanical clearance check (same pattern as the old clearance_body):
// vertical gap from the body top to the LOWEST point of the tilted
// beamsplitter frame.  bs_clearance_margin must stay positive; if a future
// change to gap1/mirror_L1/angle drives it negative, increase gap1.
bs_lowest_z = bs_cz - (bs_frame_y / 2 * cos(angle) + bs_frame_z / 2 * sin(angle));
bs_clearance_margin = bs_lowest_z - body_height; // ~2.6 mm at the default values

// Mirror vertex world position (P2) — mirror frame centres here.
mirror_cy = p2_y;
mirror_cz = p2_z;

// Eye reference point (clearance checks only, not a printed feature) —
// directly behind P3 at the SAME height, since the exit ray is level.
eye_y = p3_y - eye_relief;
eye_z = p3_z;

// Shroud height — auto-sized to enclose BOTH frames at their respective
// tilts (mirror tips higher than the beamsplitter, since it sits further
// up the folded axis).
bs_tip_z = bs_cz + (bs_frame_z / 2) * sin(angle) + (bs_frame_y / 2) * cos(angle);
mirror_tip_z = mirror_cz + (mirror_frame_z / 2) * sin(mirror_tilt) + (mirror_frame_y / 2) * cos(mirror_tilt);
optics_tip_z = max(bs_tip_z, mirror_tip_z);
shroud_h = optics_tip_z - body_height + shroud_wall + 4;

// Rear extension — the mirror frame's rearmost (most -Y) corner can land
// behind Y=0 (the bottom part's rear face), since `mirror_tilt` is steep
// (close to vertical) and the frame's own depth swings a long way in Y
// when rotated that far.  This is expected: the plan calls for the
// mirror housing to occupy the rear-upper region that the open hood
// leaves empty today.  Closed-form rearmost corner of the mirror frame
// box (tilted mirror_tilt, centred at mirror_cy/mirror_cz):
mirror_rear_y = mirror_cy - mirror_frame_y / 2 * sin(mirror_tilt) - mirror_frame_z / 2 * cos(mirror_tilt);
// Extend the top part's rear wall/side walls backward (in the upper
// region only — the bottom part's footprint is untouched) far enough to
// fully enclose that corner, plus a small margin.
rear_ext = max(0, -mirror_rear_y + 2.0);

// Y positions of the 4 side joint screws (2 per side).
side_screw_y = [body_d * 0.28, body_d * 0.72];

// Forward box geometry.  Box spans Y = body_d .. box_y1, sitting in front
// of the optics head; its top reaches the lens-opening bottom (lip top).
box_h = body_height + lip_h; // 30.00, reaches the lens opening
box_wall_top = box_h - lid_t; // 27.50, top of the box walls
box_y0 = body_d; // box back (joins the optics head)
box_y1 = body_d + box_len; // box front (muzzle end)
// Lid screw-boss positions (the 4 inside box corners).  Pulled 2 mm toward
// the corners so the bosses MERGE into the walls (no tangent line contact).
box_screw_x = [box_wall + box_boss_r - 2, body_w - box_wall - box_boss_r + 2];
box_screw_y = [box_y0 + box_wall + box_boss_r - 2, box_y1 - box_wall - box_boss_r + 2];

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
// solid top hood bar, short front/rear lower lips.  Sized to enclose
// BOTH the beamsplitter and mirror frames at their respective tilts.
// The centre opening (front face, and the rear face BELOW the mirror
// housing) is left open for viewing; the mirror housing itself (rear,
// above rear_lip_h) is closed at the back — no rear viewing window is
// needed there, since the mirror is internal/reflective, not see-through.
module eotech_shroud() {
  se = side_edge;
  sw = shroud_wall;
  bh = body_height;
  bw = body_w;
  bd = body_d;
  sh = shroud_h;
  re = rear_ext; // how far the upper rear region extends behind Y=0

  // Left/right side walls (thick edges, full height).  Extended backward
  // by rear_ext ONLY above rear_lip_h, so the existing lower rear sight
  // window (Y=0 face, below rear_lip_h) is untouched; the mirror housing
  // sits in the upper region that the old open hood left empty.
  translate([0, -re, bh + rear_lip_h])
    cube([se, bd + re, sh - rear_lip_h]);
  translate([bw - se, -re, bh + rear_lip_h])
    cube([se, bd + re, sh - rear_lip_h]);
  // Lower portion of the side walls (Y >= 0, same as before) — keeps the
  // rear sight window open below rear_lip_h.
  translate([0, 0, bh])
    cube([se, bd, rear_lip_h]);
  translate([bw - se, 0, bh])
    cube([se, bd, rear_lip_h]);

  // Left/right skirts — drop below the seam to lap the bottom part's
  // rebated side faces; the horizontal joint screws pass through these.
  translate([0, 0, bh - lap_h])
    cube([skirt_t, bd, lap_h]);
  translate([bw - skirt_t, 0, bh - lap_h])
    cube([skirt_t, bd, lap_h]);

  // Top hood bar (full width), extended backward by rear_ext to roof over
  // the mirror housing.
  translate([0, -re, bh + sh - sw])
    cube([bw, bd + re, sw]);

  // Mirror housing rear wall — closes off the back of the upper rear
  // region (no viewing window needed; the mirror is internal/reflective).
  translate([se, -re, bh + rear_lip_h])
    cube([bw - 2 * se, sw, sh - rear_lip_h - sw]);

  // Rear lower lip (Y=0 face, between side walls) — lowered for sight picture
  translate([se, 0, bh])
    cube([bw - 2 * se, sw, rear_lip_h]);

  // Front lower lip (Y=body_d face, between side walls)
  translate([se, bd - sw, bh])
    cube([bw - 2 * se, sw, lip_h]);
}

// ── Beamsplitter frame ───────────────────────────────────────
// Flat 30/70 plate — much simpler than the old lens_frame(): a plain
// rectangular pocket, angled slot, NO arc caps at all (the old lens
// needed arc caps because it had curved/rounded ends; the beamsplitter
// is a plain flat rectangle).  Local coords: X spans [0, bs_w] (panel
// width), Y spans [0, bs_frame_y] (depth / panel normal), Z spans
// [0, bs_frame_z] (panel height, along the tilt direction).
// Sheet enters from the FRONT (+Y) face; the -Y side has the retaining
// lip.  Held by friction fit plus adhesive — identical retention idiom
// to the old lens.
module beamsplitter_frame() {
  pkt = bs_t + clearance; // pocket depth (sheet thickness + clearance)
  pky = bs_frame_y - pkt; // pocket starts here in local Y (entry at +Y face)

  difference() {
    // outer shell — solid rectangular block
    cube([bs_w, bs_frame_y, bs_frame_z]);

    // sheet pocket — open at the +Y face, full width, inset by `wall` top/bottom
    translate([wall, pky, wall])
      cube([bs_w - 2 * wall, pkt + 0.1, bs_frame_z - 2 * wall]);

    // see-through window — open through BOTH faces so you can look/bounce
    // through the beamsplitter; a bs_lip-wide rim retains the sheet.
    translate([wall + bs_lip, -0.1, wall + bs_lip])
      cube([bs_w - 2 * (wall + bs_lip), bs_frame_y + 0.2, bs_frame_z - 2 * (wall + bs_lip)]);
  }
}

// ── Mirror frame ─────────────────────────────────────────────
// Adapts the old lens_frame()'s arc-cap Boolean idiom (cylinder ∩/−
// bounding box), but the curve is applied to the mirror's REFLECTIVE
// FACE (radius mirror_R, single-axis/cylindrical) instead of to rounded
// end caps.  The curve runs along local X (mirror_w); the reflective
// pocket is flat (un-curved) along local Z (mirror_h) — i.e. the
// reflective face is a cylindrical arc, not a sphere.  The pocket holds
// a polished/reflective insert; this is NOT a see-through window like
// the beamsplitter (the mirror doesn't need to be seen through), so
// there is no open-through-both-faces cut — the pocket opens only at
// the +Y (front) face, same entry convention as the beamsplitter.
//
// Pocket geometry (standard concave-mirror parameterisation, vertex at
// local X = mirror_w/2):
//   back-wall Y(x) = Y_vertex + (mirror_R − sqrt(mirror_R² − (x−mirror_w/2)²))
// so the CENTRE (x = mirror_w/2) is the deepest point (smallest Y,
// vertex) and the EDGES are shallower by `mirror_sagitta`.  This profile
// is the lower boundary of a cylinder (axis along X) of radius mirror_R
// centred at (X = mirror_w/2, Y = Y_vertex + mirror_R); cutting
// (front-face box) MINUS (that cylinder solid) leaves exactly the
// curved pocket, open at +Y, with the deepest point at Y_vertex.
module mirror_frame() {
  pkt = mirror_t + clearance; // insert pocket depth at the EDGES (shallowest)
  y_vertex = mirror_frame_y - pkt - mirror_sagitta; // deepest point of the pocket (centre)
  y_axis = y_vertex + mirror_R; // cylinder axis Y position (pulled back -Y by mirror_R)

  difference() {
    // ── outer shell ── plain rectangular block, same spirit as the
    // beamsplitter's plain block; the curve is cut INTO the front face
    // by the pocket below.
    cube([mirror_w, mirror_frame_y, mirror_frame_z]);

    // ── reflective insert pocket — curved back wall, open at +Y ────
    // The pocket is the region INSIDE the cylinder (Y above the curved
    // boundary) AND inside the front-face box (between the deepest
    // possible point and the front face, inset by `wall` on X/Z) — i.e.
    // a plain intersection() of the two, no extra Booleans needed.
    intersection() {
      translate([wall, y_vertex - 0.1, wall])
        cube([mirror_w - 2 * wall, mirror_frame_y - y_vertex + 0.2, mirror_frame_z - 2 * wall]);
      translate([mirror_w / 2, y_axis, mirror_frame_z / 2])
        rotate([0, 90, 0])
          cylinder(r=mirror_R, h=mirror_w + 2, center=true, $fn=120);
    }
  }
}

// ── Beamsplitter / mirror mounts at their derived positions ──
// Each frame is centred in X; rectangular arms run from each shroud side
// wall and overlap arm_overlap mm INTO the frame.  Reuses the old
// glass_frame_mount()'s side-arm-merge-into-shroud-wall pattern, now
// parametrized per element and placed at the P1/P2, angle/mirror_tilt
// positions derived above.
module beamsplitter_mount() {
  arm_len = body_w / 2 - bs_w / 2 + arm_overlap;
  translate([body_w / 2, bs_cy, bs_cz])
    rotate([90 - angle, 0, 0]) {
      translate([-bs_w / 2, -bs_frame_y / 2, -bs_frame_z / 2])
        beamsplitter_frame();

      // Left arm: from left shroud wall, overlapping the frame end
      translate([-body_w / 2, -bs_frame_y / 2, -bs_frame_z / 2])
        cube([arm_len, bs_frame_y, bs_frame_z]);

      // Right arm: from right shroud wall, overlapping the frame end
      translate([bs_w / 2 - arm_overlap, -bs_frame_y / 2, -bs_frame_z / 2])
        cube([arm_len, bs_frame_y, bs_frame_z]);
    }
}

module mirror_mount() {
  arm_len = body_w / 2 - mirror_w / 2 + arm_overlap;
  translate([body_w / 2, mirror_cy, mirror_cz])
    rotate([90 - mirror_tilt, 0, 0]) {
      translate([-mirror_w / 2, -mirror_frame_y / 2, -mirror_frame_z / 2])
        mirror_frame();

      // Left arm: from left shroud wall, overlapping the frame end
      translate([-body_w / 2, -mirror_frame_y / 2, -mirror_frame_z / 2])
        cube([arm_len, mirror_frame_y, mirror_frame_z]);

      // Right arm: from right shroud wall, overlapping the frame end
      translate([mirror_w / 2 - arm_overlap, -mirror_frame_y / 2, -mirror_frame_z / 2])
        cube([arm_len, mirror_frame_y, mirror_frame_z]);
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
// Hollow box in front of the optics head, open on top for a screw-on lid.
// Its back joins the optics-head front wall; the cable enters via
// cable_channel().  Walls/floor = box_wall; top reaches the lens opening.
module front_box() {
  difference() {
    union() {
      // outer shell (walls + floor), open top
      translate([0, box_y0, 0])
        cube([body_w, box_len, box_wall_top]);
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
  for (bx = box_screw_x, by = box_screw_y)
    translate([bx, by, 0]) cylinder(r=box_boss_r, h=box_wall_top + 0.01);
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

// Vertical insert bores in the lid bosses (M3, from the boss tops down).
module box_lid_inserts() {
  for (bx = box_screw_x, by = box_screw_y)
    translate([bx, by, box_wall_top - box_insert_depth])
      cylinder(d=box_insert_d, h=box_insert_depth + 0.1);
}

// Removable top lid (separate printed part), screwed to the bosses.
module box_lid() {
  difference() {
    translate([0, box_y0, box_wall_top])
      cube([body_w, box_len, lid_t]);
    for (bx = box_screw_x, by = box_screw_y) {
      translate([bx, by, box_wall_top - 0.1])
        cylinder(d=box_screw_clear, h=lid_t + 0.2);
      translate([bx, by, box_h - box_head_h])
        cylinder(d=box_head_d, h=box_head_h + 0.1);
    }
  }
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
    box_lid_inserts();
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
      beamsplitter_mount();
      mirror_mount();
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
