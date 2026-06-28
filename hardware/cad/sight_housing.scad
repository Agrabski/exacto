// ============================================================
// Exacto Reflex Sight Housing — v5 (EOTech-style, two-part, birdbath optics)
//
// Two screw-joined parts, split at the seam z = body_height (20 mm), PLUS a
// detachable front-lens cartridge:
//   bottom_part()        display holder = screen_body() + joint inserts
//   top_part()           optics holder  = eotech_shroud() + beamsplitter_mount()
//                                         + combiner_index_stops()
//   combiner_cartridge() removable front lens = combiner_frame() + side ears,
//                        bolted into the top part's front channel by 4 side M3
//                        screws and depth-located by 3 rear indexing stops.
//
// Sub-modules:
//   screen_body()         box holding OLED + electronics, display up
//   eotech_shroud()       rectangular window frame — left/right walls,
//                         top hood, front/rear lower lips, sized to
//                         enclose BOTH optics frames
//   beamsplitter_frame()  flat 30/70 plate frame at `beamsplitter_tilt` deg
//   combiner_frame()      curved partial-mirror ("combiner") frame, fixed
//                         vertical (`combiner_tilt` = 90°)
//   beamsplitter_mount()  / combiner_mount()  position each frame in world
//                         space (side arms overlap the frame and merge
//                         into the shroud side walls, same idiom as v4)
//
// Optics — true birdbath, two elements, each hit EXACTLY ONCE (replaces
//   both the v4 single curved combiner lens AND the earlier "same panel
//   hit twice" birdbath topology):
//   display (face up) -> flat 30/70 beamsplitter, fixed 45° relay (1st &
//   only hit) -> curved partial-mirror combiner, fixed VERTICAL 90°
//   (2nd & only hit, exact retro-reflection back the way it came) -> eye,
//   looking back THROUGH the combiner's see-through window.  Both tilts
//   are fixed constants now — no derivation, no sweep.  See the
//   "Birdbath optics" parameter block below for the exact ray-trace.
//
// Joint: the top part's side walls drop below the seam as SKIRTS that lap
//   over rebates on the bottom part's thick side edges.  4 horizontal M3
//   screws (2 per side), placed LOW — under the PCB, in the solid lower
//   body — pin and clamp the lap.  Use M3 x ~12 mm into brass inserts.
//   The left/right edges are thickened (side_edge) to host the inserts.
//
// Forward box: a hollow electronics enclosure extends from the optics head
//   toward the muzzle (box_length), full width, up to the lens-opening
//   height, with a screw-on top lid.  Cable routes UNDER the PCB to a plug
//   opening in the box front face.
//
// Mount: a female MIL-STD-1913 Picatinny clamp (picatinny.scad) is fused
//   to the underside and runs the WHOLE length of the sight.
//
// Optics retention: friction fit in the frame pockets + adhesive.  The
// beamsplitter frame is fused into the top part; the COMBINER frame is a
// detachable cartridge (combiner_cartridge()) bolted in from the sides, so the
// front lens can be serviced/swapped without reprinting the optics head.
//
// Set `render_part` below to choose what to render/export.
//
// Display: Waveshare 1.27-inch SSD1351 RGB OLED
//   PCB     42.20 × 29.00 mm  (hardware/display/dimensions.png)
//   Active  38.00 × 24.80 mm
//   Holes   ø2.10, inset 2.25 mm (X) / 2.10 mm (Y) from PCB edge
//
// Birdbath optics (replaces both the old single curved meniscus combiner
// AND the earlier two-hit-same-panel birdbath):
//   Beamsplitter: flat 30/70 reflective sheet, beamsplitter_optic_width x
//                 beamsplitter_optic_height, FIXED 45° relay near the
//                 display — redirects the vertical beam to exactly
//                 horizontal, nothing more.
//   Combiner:     curved partial mirror, combiner_optic_width x
//                 combiner_optic_height, single cylindrical curvature
//                 combiner_radius, FIXED VERTICAL (combiner_tilt = 90°) —
//                 the element the eye actually looks through, both for the
//                 real target and the reflected reticle.
//   See the "Birdbath optics" parameter block for the full derivation.
// ============================================================

// ┌─────────────────────────────────────────────────────────────┐
// │  beamsplitter_tilt = beamsplitter tilt from horizontal —      │
// │  FIXED at 45°.  combiner_tilt = combiner tilt — FIXED at 90°  │
// │  (vertical).  Both are pinned per explicit design decision    │
// │  (topology "c") — NOT reprint-tunable sweep parameters any    │
// │  more.  Changing either invalidates the whole fold derivation │
// │  below.                                                       │
// └─────────────────────────────────────────────────────────────┘
use <picatinny.scad>
use <screw_mounts.scad>

beamsplitter_tilt = 45; // beamsplitter tilt from horizontal, deg — FIXED, do not sweep (was 35–65 in the rejected topology)

// Which piece to render/export: "both" (assembled), "top", "bottom",
// "combiner" (detachable front-lens cartridge), "bar" (removable Picatinny
// clamp jaw), "lid" (box top lid)
render_part = "both";

// Forward electronics box (extends from the optics head toward the muzzle).
box_length = 80.00; // box length, front-to-rear (8 cm)

// ── Display (Waveshare 1.27" SSD1351 OLED) ───────────────────
display_pcb_width = 42.20; // OLED carrier PCB width  (X)
display_pcb_height = 29.00; // OLED carrier PCB height (Y)
display_pcb_thickness = 1.80; // OLED carrier PCB thickness (Z)
display_active_width = 38.00; // visible/active screen width  (X)
display_active_height = 24.80; // visible/active screen height (Y)
display_hole_dia = 2.10; // PCB clearance-hole dia (datasheet); not used for body bores
display_hole_inset_x = 2.25; // mounting-hole inset from the PCB edge, X
display_hole_inset_y = 2.10; // mounting-hole inset from the PCB edge, Y
display_fit_clearance = 0.10; // gap on EVERY side of the OLED PCB in its pocket (X/Y edges + Z floor)

// ── Fasteners ────────────────────────────────────────────────
// All screw/insert geometry now comes from screw_mounts.scad — its
// insert_hole()/screw_hole() cutters plus the shared M2/M3 fastener table
// are the single source of truth (no local diameter/depth constants).
//   PCB        : M2, screw from the top into inserts below the pocket.
//   Part joint : M3, 4 horizontal screws through the skirts into edge inserts.
//   Box lid    : M3, 4 vertical screws through the lid into boss inserts.
m3_clearance_fit = 0.40; // added to the M3 body dia for a free-fit through-hole (skirts + lid)

// ── Birdbath optics ─────────────────────────────────────────────
// True two-element birdbath, EACH ELEMENT HIT EXACTLY ONCE (topology "c" —
// replaces both the old single curved combiner AND the rejected "same
// beamsplitter panel hit twice" birdbath):
//   display (face up) -> flat 30/70 beamsplitter, fixed 45 deg, 1st & only
//   hit (simple relay: redirects the vertical beam to exactly horizontal)
//   -> curved partial-mirror combiner, fixed VERTICAL (90 deg), 2nd & only
//   hit (exact retro-reflection, straight back the way it came)
//   -> eye, looking back THROUGH the combiner's see-through window.
//
// Fold derivation (2D ray trace in the Y-Z plane; X is irrelevant, both
// tilts are fixed rotations about X exactly like `beamsplitter_tilt` always
// was):
//   v_in = (0,1)                       ray leaves display straight up
//   45 deg mirror swaps (a,b) -> (b,a):
//   v_out1 = (1,0)                     EXACTLY horizontal after the
//                                       beamsplitter — no residual tilt,
//                                       because beamsplitter_tilt is fixed
//                                       at 45
//   travels at constant Z to the vertical combiner, normal n = (-1,0):
//   v_out2 = v_out1 - 2*(v_out1.n)*n
//          = (-1,0)                    EXACT reversal, same Z — the
//                                       return ray re-crosses the
//                                       beamsplitter's own position
//                                       (mostly transmissive) heading
//                                       dead level to the eye, by
//                                       construction, for any gap/throw
//                                       (the tilts alone fix the
//                                       direction; the spacings only set
//                                       WHERE, not which way)
//
// display_to_beamsplitter_gap / beamsplitter_to_combiner_throw are design
// constants (display-to-beamsplitter, vertical, and beamsplitter-to-
// combiner, horizontal); everything else below is derived from them, same
// pattern as the old glass_cz/glass_cy/frame_dy block.
//
// display_to_beamsplitter_gap is set so the combiner's bottom edge lands
// EXACTLY on the forward-box lid top (box_height) — no clearance gap below
// the optic, the front wall meets the box lid flush.  Since the combiner is
// untilted (vertical, axis-aligned), its lowest Z = (body_height + gap) -
// combiner_frame_height/2; setting that equal to box_height
// (= body_height + front_lip_height) gives the expression below.  The
// beamsplitter (tilted) still clears the box top by a healthy margin at this
// gap (checked by beamsplitter_clearance_margin).
// = front_lip_height (10) + combiner_frame_height/2 (14) = 24.0; literal so it
// doesn't depend on the later definitions of those two variables.
display_to_beamsplitter_gap = 24.00; // display centre -> beamsplitter centre, vertical — combiner bottom flush with box lid top
beamsplitter_to_combiner_throw = 30.00; // beamsplitter centre -> combiner centre, horizontal (+Y)

// ── Combiner location ⇄ required lens focal length ──
// The combiner is LOCATED by the throw above (-> combiner_center_y below): it
// sits one folded-path length away from the display.  For the collimating
// lens to project the reticle to infinity (parallax-free), the OLED must lie
// at the lens focal plane, i.e. the folded display->combiner path must equal
// the lens focal length.  So the focal length is not a free input — it is
// CALCULATED FROM THE GEOMETRY: the unfolded path is the vertical gap plus the
// horizontal throw.  With the gap pinned at 24 mm by the flush-fit constraint,
// the throw is the knob that sets this length (it doesn't affect box
// clearance).  The value below is therefore the focal length the physical lens
// must have; pick/grind the lens to match it (or change the throw to match a
// lens you already have).
combiner_focal_length = display_to_beamsplitter_gap + beamsplitter_to_combiner_throw; // REQUIRED lens focal length = folded path = 24 + 30 = 54.0 mm
combiner_tilt = 90; // combiner tilt from horizontal, deg — FIXED, vertical (replaces the old derived mirror_tilt)

// Beamsplitter (flat 30/70 sheet) — plain rectangle, no arc caps.  The
// *_optic_* dims are the OPTIC (sheet) size; the holder adds
// beamsplitter_frame_border of frame on every side (see
// beamsplitter_frame()).  This makes the splitter LARGER than the old
// design, where the sheet was only width - 2*wall (27 mm) after a chunky
// 4.5 mm (wall+lip) border ate into it.
beamsplitter_optic_width = 32.00; // sheet width across X (clear optic)
beamsplitter_optic_height = 30.00; // sheet height along the tilt direction (clear optic)
beamsplitter_thickness = 2.00; // sheet thickness
beamsplitter_frame_border = 2.00; // holder frame border on ALL sides (replaces wall+lip = 4.5)
beamsplitter_rear_lip = 1.50; // rear retaining-lip overlap onto the sheet (does NOT add to the front/side border)

// Combiner — the previously-used COLLIMATING LENS (hardware/lens/lense.avif),
// a flat stadium-shaped element (rounded LEFT/RIGHT end caps), NOT a curved
// partial mirror.  The lens carries its own optical power; the holder only
// needs a flat-bottomed stadium pocket of the lens thickness.  Same tested
// holder geometry as the pre-birdbath lens_frame() — arc-cap Boolean idiom
// (cylinder ∩ bounding box) for the rounded ends — re-homed into the
// birdbath's vertical (combiner_tilt = 90°) combiner position.
combiner_optic_width = 34.00; // lens clear width across X (the 34 mm dim) [lense.avif]
combiner_optic_height = 24.00; // lens clear height along the tilt direction (the 24 mm dim) [lense.avif]
combiner_thickness = 2.74; // lens thickness (flat collimating lens) [lense.avif]
combiner_end_radius = 16.97; // radius of the rounded LEFT/RIGHT end caps (span the 24 mm height) [lense.avif]
combiner_frame_border = 2.00; // holder frame border on ALL sides — matches beamsplitter_frame_border (replaces wall+lip = 4.5)
combiner_rear_lip = 1.50; // rear retaining-lip overlap onto the lens (does NOT add to the front/side border)

// Reference dimensions for clearance checks only — NOT cut/printed geometry.
eye_relief = 50.00; // eye -> combiner hit point, along the level exit ray
exit_pupil = 8.00; // nominal exit pupil diameter, for sightline-cone checks

// ── Structure ────────────────────────────────────────────────
wall = 2.50; // generic wall / floor thickness for the screen body
shroud_wall = 3.00; // EOTech shroud wall / hood thickness (front/rear, hood)
side_edge = 8.00; // THICK left/right edges (host the joint inserts)
clearance = 0.30; // generic fit clearance for the optic pockets
body_height = 20.00; // seam height; must fit Arduino Nano + wiring
front_lip_height = 10.00; // height of the FRONT lower lip on the shroud
rear_lip_height = 4.00; // height of the REAR lip (lowered for a clear sight picture)
arm_overlap = 3.00; // how far the side arms reach INTO the optic frame

// Detachable combiner cartridge (front lens is now a separate screw-in part —
// see combiner_cartridge()).  4 M3 screws enter horizontally through the side
// walls into inserts in the cartridge's ears; 3 rear indexing stops (2 side
// walls + hood) depth-locate it on insertion.
combiner_screw_dz = 10.00; // half the vertical spacing of the 2-per-side screws (Z = combiner_center_z ± this)
combiner_ear_overlap = arm_overlap; // how far each ear laps INTO the frame end (reuse 3 mm)
combiner_fit = clearance; // sliding clearance between cartridge and the housing channel/hood (0.30)
combiner_index_size = 4.00; // cross-section of each rear indexing stop
combiner_index_depth = 3.50; // how far each stop sits BEHIND the cartridge rear plane

// Side-wall lap joint
lap_height = 14.00; // vertical overlap: skirt reaches this far below the seam
skirt_thickness = 3.00; // skirt thickness (sits in a rebate on the bottom)
joint_screw_height = 9.00; // height (Z) of the horizontal joint screws (under the PCB)

// Forward electronics box (hollow, screw-on top lid)
box_wall = 2.50; // box wall / floor thickness
lid_thickness = 2.50; // top-lid thickness
lid_clearance = 0.20; // lid-to-pocket clearance
box_boss_radius = 4.50; // lid screw-boss radius (inside box corners)
// M3 lid screws (clearance + countersink in the lid, inserts in the bosses)
// are cut by screw_mounts.scad — see box_lid() / box_lid_inserts().

// Cable routing (channel under the PCB, plug opening at the box front)
cable_channel_width = 14.00; // under-PCB cable channel width
cable_channel_height = 7.00; // channel height
cable_channel_floor_z = 9.00; // channel floor height (under the PCB pocket)
plug_opening_width = 14.00; // plug opening width  (box front face)
plug_opening_height = 9.00; // plug opening height
plug_opening_floor_z = 8.00; // plug opening bottom z

// Right-side engraving
// Version: XM-<gen>E<rev>. Bump the E<rev> ONLY after a revision is sent to
// print (not on design edits). Current: XM-1E1.
engrave_enabled = true; // set false to omit the engraved label
engrave_text = "Exacto XM-1E1"; // the label text
engrave_size = 6.00; // glyph size (mm)
engrave_depth = 0.60; // how deep the text is cut into the face
engrave_font = "Liberation Sans:style=Bold"; // engraving typeface

$fn = 48; // default facet count for all curved surfaces

// Forward box height — computed here (early) because the birdbath fold
// geometry below (gated against box_wall_top_z, the real binding clearance
// constraint in this topology) needs it before the rest of the forward
// box's geometry (which depends on body_depth/box_length/body_width,
// computed later in "Derived") is otherwise ready.
box_height = body_height + front_lip_height; // 30.00, reaches the lens opening
box_wall_top_z = box_height - lid_thickness; // 27.50, top of the box walls

// ── Derived ──────────────────────────────────────────────────
body_width = display_pcb_width + 2 * side_edge; // 58.20  (thick left/right edges)
body_depth = display_pcb_height + 2 * wall; // 34.00

// Frame envelopes for each optic.  The optic (*_optic_width/height) is
// wrapped by a uniform *_frame_border (= 2 mm) on every side, so the OUTER
// envelope = optic + 2*border in plane, and the depth = sheet/insert pocket
// + one border backing wall.  "_width" = outer width across X; "_depth" =
// depth along the optic normal; "_height" = outer extent along the tilt
// direction (in-plane).
beamsplitter_frame_width = beamsplitter_optic_width + 2 * beamsplitter_frame_border; // 36.00  outer width (X)
beamsplitter_frame_depth = (beamsplitter_thickness + clearance) + beamsplitter_frame_border; // 4.30  sheet pocket + 2 mm backing
beamsplitter_frame_height = beamsplitter_optic_height + 2 * beamsplitter_frame_border; // 34.00  outer height along tilt

// Flat collimating lens — no curved reflective face, so no sagitta term:
// the pocket is flat-bottomed and combiner_frame_depth is just the lens
// pocket + one border backing.
combiner_sagitta = 0; // flat lens (kept for the frame_depth expression below)
combiner_frame_width = combiner_optic_width + 2 * combiner_frame_border; // 38.00  outer width (X)
combiner_frame_depth = (combiner_thickness + clearance) + combiner_sagitta + combiner_frame_border; // ~5.04  lens pocket + 2 mm backing
combiner_frame_height = combiner_optic_height + 2 * combiner_frame_border; // 28.00  outer height along tilt

// World-space fold geometry (Y,Z), derived directly from the verified
// formulas above.  X stays centred on body_width/2 for both optics, exactly
// like the display's active area is centred on body_width/2.
//   beamsplitter_center = beamsplitter centroid.  Placed in Y so the
//        SHEET's (optic, not the printed frame) FORWARD-MOST edge — its
//        front face at the sheet's bottom edge, at the fixed 45 deg tilt —
//        lands exactly on the OLED active area's front edge, per explicit
//        design request.  Consequence: the chief ray rising from the
//        display centre meets the beamsplitter slightly off its centroid,
//        so the relayed image sits a touch off on the combiner (well within
//        the combiner aperture); the reflected leg is still EXACTLY
//        horizontal — the 45 deg tilt alone fixes the direction,
//        independent of where on the panel the ray lands.  Z is
//        body_height + display_to_beamsplitter_gap.
//   combiner_center = combiner centroid = beamsplitter_center +
//        beamsplitter_to_combiner_throw, SAME Z (the beamsplitter-to-
//        combiner leg is exactly horizontal by construction — see the
//        ray-trace above).
// There is no third point in this topology: each element is hit exactly
// once, so the beamsplitter's centroid IS its placement point (no
// midpoint placement) and the combiner's centroid IS its placement point
// (no "mirror vertex offset from frame centre" — the combiner is untilted,
// so its own geometric centre sits on the fold axis directly).
display_active_front_y = wall + (display_pcb_height + display_active_height) / 2; // 29.40 — OLED active-area FRONT edge (+Y)
// Forward-most corner of the beamsplitter FRAME (printed envelope),
// projected from its centroid along +Y at the fixed tilt — used for shroud /
// rear-extension sizing (mirror of beamsplitter_rear_y's formula below).
beamsplitter_frame_front_proj = (beamsplitter_frame_depth / 2) * sin(beamsplitter_tilt) + (beamsplitter_frame_height / 2) * cos(beamsplitter_tilt);
// Forward-most edge of the OPTIC (sheet) itself: its front face (local +Y,
// flush with the frame front, so half-extent beamsplitter_frame_depth/2) at
// the sheet's bottom edge (sheet is inset beamsplitter_frame_border from the
// frame Z edges, so its half-extent along Z is exactly the optic height/2).
// THIS is what aligns to the display.
beamsplitter_optic_front_proj = (beamsplitter_frame_depth / 2) * sin(beamsplitter_tilt) + (beamsplitter_optic_height / 2) * cos(beamsplitter_tilt);

beamsplitter_center_y = display_active_front_y - beamsplitter_optic_front_proj; // places the SHEET's front edge ON the active front edge
beamsplitter_center_z = body_height + display_to_beamsplitter_gap; // 50.00
combiner_center_y = beamsplitter_center_y + beamsplitter_to_combiner_throw; // 47.00
combiner_center_z = beamsplitter_center_z; // 50.00 — same height as the beamsplitter, exact (level leg)

// Mechanical clearance checks (same pattern as the old margin checks, but
// against box_wall_top_z — the real binding constraint in this topology,
// since both frames sit well above body_height and the forward box's top is
// the thing they actually have to clear).  Both must stay positive; if a
// future change to the gap/throw/tilt drives either negative, increase the
// gap.
beamsplitter_lowest_z = beamsplitter_center_z - (beamsplitter_frame_depth / 2 * cos(beamsplitter_tilt) + beamsplitter_frame_height / 2 * sin(beamsplitter_tilt));
beamsplitter_clearance_margin = beamsplitter_lowest_z - box_wall_top_z; // ~7.65 mm at the default values

combiner_lowest_z = combiner_center_z - combiner_frame_height / 2; // combiner untilted: axis-aligned box
combiner_clearance_margin = combiner_lowest_z - box_wall_top_z; // ~4.0 mm at the default values

// Eye reference point (clearance checks only, not a printed feature) —
// directly behind the combiner at the SAME height, since the return leg
// through the combiner and back out past the beamsplitter is exactly level.
eye_point_y = combiner_center_y - eye_relief;
eye_point_z = combiner_center_z;

// Shroud height — auto-sized to enclose BOTH frames at their respective
// tilts (the combiner tips higher than the beamsplitter at the default
// values, since it's the taller untilted box riding higher up).
beamsplitter_top_z = beamsplitter_center_z + (beamsplitter_frame_height / 2) * sin(beamsplitter_tilt) + (beamsplitter_frame_depth / 2) * cos(beamsplitter_tilt);
combiner_top_z = combiner_center_z + combiner_frame_height / 2; // combiner untilted: axis-aligned box
optics_top_z = max(beamsplitter_top_z, combiner_top_z);
// Flush top: hood underside (body_height + shroud_height - shroud_wall) lands
// exactly on optics_top_z, so the optics mounts seat against the hood underside
// and the hood is the shroud_wall roof above them (no extra clearance margin).
shroud_height = optics_top_z - body_height + shroud_wall;

// Rear extension — closed-form rearmost (most -Y) corner of the
// BEAMSPLITTER frame (tilted, centred at beamsplitter_center_y/_z).  In this
// topology the beamsplitter is the element nearest the display/rear, so it
// (not the combiner) is the one that could in principle swing behind Y=0 at
// a steep enough tilt.  At the fixed 45 deg default this evaluates to a
// positive rearmost Y (2.15 mm), so rear_extension is dormant (0) — kept as
// a live formula, not deleted, since it's not provably unnecessary for all
// future parameter choices.
beamsplitter_rear_y = beamsplitter_center_y - beamsplitter_frame_front_proj; // rear-most FRAME corner: mirror of the forward-most about the centroid
rear_extension = max(0, -beamsplitter_rear_y + 2.0);

// Front extension — the combiner, pushed forward by
// beamsplitter_to_combiner_throw and now untilted (full combiner_frame_depth
// projects straight along +Y, no foreshortening), can land its forward-most
// corner past the body's own front face (body_depth).  Closed-form
// forward-most corner of the combiner frame box (untilted, centred at
// combiner_center_y/_z):
combiner_front_y = combiner_center_y + combiner_frame_depth / 2;
// Rear / seating plane of the combiner cartridge (its rear-most face, -Y).  The
// 3 indexing stops sit just behind this and the cartridge butts against them.
combiner_rear_y = combiner_center_y - combiner_frame_depth / 2; // ≈43.3
// Extend the top part's side walls/hood FORWARD (in the upper region only —
// gated above box_wall_top_z, since both optics frames sit well above it
// everywhere in the extended region) far enough to fully enclose that
// corner, plus a small margin.
front_extension = max(0, combiner_front_y - body_depth + 2.0);

// Y positions of the 4 side joint screws (2 per side).
joint_screw_y = [body_depth * 0.28, body_depth * 0.72];

// Forward box geometry.  Box spans Y = body_depth .. box_front_y, sitting in
// front of the optics head; its top reaches the lens-opening bottom (lip
// top).  (box_height/box_wall_top_z are computed earlier now — see above
// "Derived".)
box_back_y = body_depth; // box back (joins the optics head)
box_front_y = body_depth + box_length; // box front (muzzle end)
// Lid screw-boss positions.  FRONT (muzzle-end) corners only — the rear pair
// of mounting screws was removed.  Pulled 2 mm toward the corners so the
// bosses MERGE into the walls (no tangent line contact).
lid_screw_x = [box_wall + box_boss_radius - 2, body_width - box_wall - box_boss_radius + 2];
lid_screw_y = [box_front_y - box_wall - box_boss_radius + 2];

// Picatinny rail runs the WHOLE length of the sight (optics head + box).
rail_length = body_depth + box_length;

// Engraving placement: centred along the box, a little above its mid-height.
engrave_center_y = (box_back_y + box_front_y) / 2;
engrave_center_z = box_wall_top_z * 0.55;

// ============================================================

module rounded_box(w, d, h, r = 2) {
  hull()for (x = [r, w - r], y = [r, d - r])
    translate([x, y, 0]) cylinder(r=r, h=h);
}

// ── Screen body ──────────────────────────────────────────────
// Optics-only housing: OLED PCB sits in a top pocket; all other
// electronics (MCU, battery, USB) live in a separate external box
// connected through the rear ribbon-cable slot.
// Display window faces UP (+Z).  Y=0 = rear, Y=body_depth = front.
module screen_body() {
  difference() {
    rounded_box(body_width, body_depth, body_height);

    // PCB pocket — display_fit_clearance (0.1 mm) gap on every side so the
    // OLED drops in freely: 0.1 mm at each X/Y edge and 0.1 mm under the PCB
    // (Z floor).
    translate(
      [
        side_edge - display_fit_clearance,
        wall - display_fit_clearance,
        body_height - display_pcb_thickness - display_fit_clearance,
      ]
    )
      cube(
        [
          display_pcb_width + 2 * display_fit_clearance,
          display_pcb_height + 2 * display_fit_clearance,
          display_pcb_thickness + display_fit_clearance + 0.1,
        ]
      );

    // Active-area window in top face
    translate(
      [
        side_edge + (display_pcb_width - display_active_width) / 2,
        wall + (display_pcb_height - display_active_height) / 2,
        body_height - wall,
      ]
    )
      cube([display_active_width, display_active_height, wall + 0.2]);

    // PCB mount: M2 heat-set insert bores below the PCB pocket floor.
    // M2 screws drop through the PCB corner holes from above and thread
    // into brass inserts pressed up into these bores.  The cutter's mouth
    // sits on the pocket floor and bores downward (insert pressed in from +Z),
    // matching insert_hole()'s convention exactly.
    for (sx = [-1, 1], sy = [-1, 1])
      translate(
        [
          side_edge + display_pcb_width / 2 + sx * (display_pcb_width / 2 - display_hole_inset_x),
          wall + display_pcb_height / 2 + sy * (display_pcb_height / 2 - display_hole_inset_y),
          body_height - display_pcb_thickness - display_fit_clearance,
        ]
      )
        insert_hole("M2");

    // Cable exits FORWARD now (see cable_channel()); no rear slot.
  }
}

// ── EOTech-style shroud ───────────────────────────────────────
// Enclosed rectangular window frame: solid left/right side walls,
// solid top hood bar, short front/rear lower lips.  Sized to enclose
// BOTH the beamsplitter and combiner frames at their respective tilts.
// The centre opening (the combiner's own see-through window, and the
// rear face BELOW rear_lip_height) is left open for viewing;
// rear_extension (above rear_lip_height) and front_extension (above
// box_wall_top_z) extend the side walls/hood, in their respective
// directions, far enough to fully enclose whichever frame corner lands
// outside the body's own footprint — rear_extension for the beamsplitter
// (rear/upper), front_extension for the combiner (forward/upper).  At the
// default fixed tilts, rear_extension is dormant (0) and front_extension is
// the dominant extension.
module eotech_shroud() {
  // Left/right side walls (thick edges, full height).  Extended backward by
  // rear_extension ONLY above rear_lip_height, so the existing lower rear
  // sight window (Y=0 face, below rear_lip_height) is untouched.  Also
  // extended FORWARD by front_extension, gated above box_wall_top_z instead
  // (both optics frames sit well above box_wall_top_z everywhere in the
  // extended region, so there is no separate lower-front-lip carve-out
  // needed the way there is at the rear).  One continuous run from
  // Y = -rear_extension to Y = body_depth + front_extension, no seam wall
  // needed at Y = body_depth.
  translate([0, -rear_extension, body_height + rear_lip_height])
    cube([side_edge, (body_depth + front_extension) - ( -rear_extension), shroud_height - rear_lip_height]);
  translate([body_width - side_edge, -rear_extension, body_height + rear_lip_height])
    cube([side_edge, (body_depth + front_extension) - ( -rear_extension), shroud_height - rear_lip_height]);
  // Lower portion of the side walls (Y >= 0, same as before) — keeps the
  // rear sight window open below rear_lip_height.
  translate([0, 0, body_height])
    cube([side_edge, body_depth, rear_lip_height]);
  translate([body_width - side_edge, 0, body_height])
    cube([side_edge, body_depth, rear_lip_height]);

  // Left/right skirts — drop below the seam to lap the bottom part's
  // rebated side faces; the horizontal joint screws pass through these.
  translate([0, 0, body_height - lap_height])
    cube([skirt_thickness, body_depth, lap_height]);
  translate([body_width - skirt_thickness, 0, body_height - lap_height])
    cube([skirt_thickness, body_depth, lap_height]);

  // Top hood bar (full width), extended backward by rear_extension AND
  // forward by front_extension — one continuous run roofing both the
  // beamsplitter (rear) and the combiner (forward).
  translate([0, -rear_extension, body_height + shroud_height - shroud_wall])
    cube([body_width, (body_depth + front_extension) - ( -rear_extension), shroud_wall]);

  // Beamsplitter housing rear wall — closes off the back of the upper
  // rear region (no viewing window needed there; only the combiner's
  // window, further forward, is meant to be seen through).
  translate([side_edge, -rear_extension, body_height + rear_lip_height])
    cube([body_width - 2 * side_edge, shroud_wall, front_lip_height]);

  // Rear lower lip (Y=0 face, between side walls) — lowered for sight picture
  translate([side_edge, 0, body_height])
    cube([body_width - 2 * side_edge, shroud_wall, rear_lip_height]);

  // Front lower lip (Y=body_depth face, between side walls) — untouched: its
  // Z range (body_height..body_height+front_lip_height = 20..30) and Y range
  // (~31..34) never overlaps the combiner's see-through window (Y ~41.8..52.2),
  // so it stays a plain low sill, NOT a closing wall across the combiner's
  // aperture.
  translate([side_edge, body_depth - shroud_wall, body_height])
    cube([body_width - 2 * side_edge, shroud_wall, front_lip_height]);

  // NOTE: deliberately NO closing wall in front of the combiner (at
  // Y = body_depth + front_extension) — the combiner's own see-through
  // window is the requested "hole through the front."  Only the side
  // walls/hood above wrap around and frame it; the front face stays open.
}

// ── Beamsplitter frame ───────────────────────────────────────
// Flat 30/70 plate — a plain rectangular pocket, NO arc caps.  A uniform
// beamsplitter_frame_border (2 mm) border wraps the optic on every side, so
// the OUTER block is beamsplitter_frame_width x _depth x _height.  Local
// coords: X spans [0, width] (outer width), Y spans [0, depth] (depth /
// panel normal), Z spans [0, height] (outer height, along the tilt
// direction).  Sheet enters from the FRONT (+Y) face into a pocket inset
// beamsplitter_frame_border on X/Z; a beamsplitter_rear_lip-wide rim on the
// rear retains it.  Held by friction fit plus adhesive.
module beamsplitter_frame() {
  frame_border = beamsplitter_frame_border; // frame border, all sides
  pocket_depth = beamsplitter_thickness + clearance; // pocket depth (sheet thickness + clearance)

  difference() {
    // outer shell — solid rectangular block
    cube([beamsplitter_frame_width, beamsplitter_frame_depth, beamsplitter_frame_height]);

    // sheet pocket — open at the +Y face, holds the optic sheet with a
    // frame_border on all in-plane sides (clearance/2 extra so it drops in)
    translate([frame_border - clearance / 2, beamsplitter_frame_depth - pocket_depth, frame_border - clearance / 2])
      cube([beamsplitter_optic_width + clearance, pocket_depth + 0.1, beamsplitter_optic_height + clearance]);

    // see-through window — open through BOTH faces so you can look/bounce
    // through the beamsplitter; inset beamsplitter_rear_lip past the sheet
    // edge, so the rear rim laps the sheet by that lip while the front/side
    // border stays frame_border.
    translate([frame_border + beamsplitter_rear_lip, -0.1, frame_border + beamsplitter_rear_lip])
      cube([beamsplitter_frame_width - 2 * (frame_border + beamsplitter_rear_lip), beamsplitter_frame_depth + 0.2, beamsplitter_frame_height - 2 * (frame_border + beamsplitter_rear_lip)]);
  }
}

// ── Combiner frame ───────────────────────────────────────────
// Holds the COLLIMATING LENS (hardware/lens/lense.avif): a flat stadium-
// shaped element — straight top/bottom, rounded LEFT/RIGHT end caps of radius
// combiner_end_radius spanning the optic height.  This is the same tested
// arc-cap Boolean idiom (cylinder ∩ bounding box) as the pre-birdbath
// lens_frame(), re-homed into the birdbath's vertical combiner position; the
// lens carries its own optical power, so the pocket is simply FLAT-bottomed
// (no curved reflective face, no sagitta).
//
// The eye looks straight THROUGH the lens (both at the real target and at the
// reflected reticle), so two cuts live in the same difference(): a flat
// stadium insert pocket open only at the +Y face, PLUS a stadium see-through
// window spanning the full local-Y depth, leaving a combiner_rear_lip-wide
// retaining rim.  The pocket and window arc caps are clipped to the optic
// height band so each end blends flush with the straight section (see the
// window's tangent-at-chord radius below).
module combiner_frame() {
  border = combiner_frame_border; // frame border, all sides (matches the beamsplitter)

  // ── stadium outline (rounded LEFT/RIGHT end caps) ──
  // Arc centres in local (X, Z); each cap spans the optic height (Z) and
  // bulges along X.  half-chord = sqrt(R² − (height/2)²).
  inner_hc = sqrt(combiner_end_radius * combiner_end_radius - (combiner_optic_height / 2) * (combiner_optic_height / 2));
  p_lcx = border + combiner_end_radius;                         // left  arc centre X
  p_rcx = border + combiner_optic_width - combiner_end_radius;  // right arc centre X
  p_cz = border + combiner_optic_height / 2;                    // arc centre Z (optic mid-height)
  p_r = combiner_end_radius + clearance / 2;                    // pocket arc radius (lens + slide clearance)

  // straight-section X bounds (arc tangent to the optic top/bottom)
  inner_lx = p_lcx - inner_hc;
  inner_rx = p_rcx + inner_hc;

  difference() {
    // ── outer shell ── plain rectangular block (keeps the cartridge ears /
    // side-arm overlap mechanics simple); the stadium is cut INTO it below.
    cube([combiner_frame_width, combiner_frame_depth, combiner_frame_height]);

    // ── lens pocket — flat-bottomed stadium, open at +Y ──
    pkt = combiner_thickness + clearance;     // pocket depth
    pky = combiner_frame_depth - pkt;         // pocket start in Y (opens at +Y)
    // straight middle
    translate([inner_lx, pky, border])
      cube([inner_rx - inner_lx, pkt + 0.1, combiner_optic_height]);
    // left arc cap
    intersection() {
      translate([p_lcx, combiner_frame_depth - pkt / 2, p_cz])
        rotate([90, 0, 0]) cylinder(r=p_r, h=pkt + 0.2, center=true, $fn=60);
      translate([-(p_r + 1), pky - 0.1, border])
        cube([p_r + 1 + inner_lx, pkt + 0.2, combiner_optic_height]);
    }
    // right arc cap
    intersection() {
      translate([p_rcx, combiner_frame_depth - pkt / 2, p_cz])
        rotate([90, 0, 0]) cylinder(r=p_r, h=pkt + 0.2, center=true, $fn=60);
      translate([inner_rx, pky - 0.1, border])
        cube([p_r + 1, pkt + 0.2, combiner_optic_height]);
    }

    // ── see-through window — open through BOTH faces so the eye looks
    // straight through the lens; a combiner_rear_lip-wide rim retains it.
    // The window is the lens stadium inset by combiner_rear_lip: the straight
    // top/bottom move in by the lip, and the arc radius is chosen so each cap
    // meets the inset straight band FLUSH at the chord (x = inner_lx/inner_rx)
    // — i.e. its half-height there equals (optic_height/2 − lip).  Deriving wr
    // from p_r − lip instead would leave the cap shy of the straight band and
    // poke a step into the rounded end (the protrusion).
    win_half_h = combiner_optic_height / 2 - combiner_rear_lip; // inset band half-height
    wr = sqrt(inner_hc * inner_hc + win_half_h * win_half_h); // tangent-at-chord arc radius
    // straight middle (Z inset by the lip)
    translate([inner_lx, -0.1, border + combiner_rear_lip])
      cube([inner_rx - inner_lx, combiner_frame_depth + 0.2, combiner_optic_height - 2 * combiner_rear_lip]);
    // left arc end (inset)
    intersection() {
      translate([p_lcx, combiner_frame_depth / 2, p_cz])
        rotate([90, 0, 0]) cylinder(r=wr, h=combiner_frame_depth + 0.2, center=true, $fn=60);
      translate([-(wr + 1), -0.1, border + combiner_rear_lip])
        cube([wr + 1 + inner_lx, combiner_frame_depth + 0.2, combiner_optic_height - 2 * combiner_rear_lip]);
    }
    // right arc end (inset)
    intersection() {
      translate([p_rcx, combiner_frame_depth / 2, p_cz])
        rotate([90, 0, 0]) cylinder(r=wr, h=combiner_frame_depth + 0.2, center=true, $fn=60);
      translate([inner_rx, -0.1, border + combiner_rear_lip])
        cube([wr + 1, combiner_frame_depth + 0.2, combiner_optic_height - 2 * combiner_rear_lip]);
    }
  }
}

// ── Beamsplitter / combiner mounts at their derived positions ──
// Each frame is centred in X; rectangular arms run from each shroud side
// wall and overlap arm_overlap mm INTO the frame.  Reuses the old
// glass_frame_mount()'s side-arm-merge-into-shroud-wall pattern, now
// parametrized per element and placed at the centre/tilt positions derived
// above.
//
// beamsplitter_mount() uses rotate([90-beamsplitter_tilt,0,0]) — at 45 this
// is rotate([45,0,0]), tilting the frame's local +Y face (its pocket
// opening, per beamsplitter_frame()'s convention) up and back toward the
// display, exactly as before.
//
// combiner_mount() CANNOT reuse that same form: plugging combiner_tilt=90
// into rotate([90-combiner_tilt,0,0]) gives rotate([0,0,0]) — no rotation at
// all — which leaves the frame's local +Y face (its pocket/window opening)
// pointing in world +Y (forward, AWAY from the display) — wrong; the
// combiner must face BACKWARD (-Y), confronting the oncoming horizontal beam
// from the beamsplitter.  Derivation: local +Y axis (y=1,z=0) maps, under
// rotate([rx,0,0]), to world (cos(rx), sin(rx)).  Need this to equal (-1,0)
// (world -Y) => rx = 180.  rx = 270 - combiner_tilt evaluates to exactly 180
// at combiner_tilt = 90 — this is the correct general form (verified
// independently: at combiner_tilt=90 the local +Y world-space direction
// dotted against the true beamsplitter-ward unit vector from the combiner's
// own position gives +1.0, i.e. exact alignment, not just "roughly facing
// the right way").  Because combiner_tilt=90 makes this a full 180 deg
// point-reflection about the X-axis, and the frame's local cross-section is
// symmetric in Y and Z (the curved pocket only varies along local X), the
// flip is geometrically clean — it doesn't distort the pocket or the
// side-arm overlap mechanics.
module beamsplitter_mount() {
  arm_length = body_width / 2 - beamsplitter_frame_width / 2 + arm_overlap;
  translate([body_width / 2, beamsplitter_center_y, beamsplitter_center_z])
    rotate([90 - beamsplitter_tilt, 0, 0]) {
      translate([-beamsplitter_frame_width / 2, -beamsplitter_frame_depth / 2, -beamsplitter_frame_height / 2])
        beamsplitter_frame();

      // Left arm: from left shroud wall, overlapping the frame end
      translate([-body_width / 2, -beamsplitter_frame_depth / 2, -beamsplitter_frame_height / 2])
        cube([arm_length, beamsplitter_frame_depth, beamsplitter_frame_height]);

      // Right arm: from right shroud wall, overlapping the frame end
      translate([beamsplitter_frame_width / 2 - arm_overlap, -beamsplitter_frame_depth / 2, -beamsplitter_frame_height / 2])
        cube([arm_length, beamsplitter_frame_depth, beamsplitter_frame_height]);
    }
}

module combiner_mount() {
  arm_length = body_width / 2 - combiner_frame_width / 2 + arm_overlap;
  translate([body_width / 2, combiner_center_y, combiner_center_z])
    rotate([270 - combiner_tilt, 0, 0]) {
      translate([-combiner_frame_width / 2, -combiner_frame_depth / 2, -combiner_frame_height / 2])
        combiner_frame();

      // Left arm: from left shroud wall, overlapping the frame end
      translate([-body_width / 2, -combiner_frame_depth / 2, -combiner_frame_height / 2])
        cube([arm_length, combiner_frame_depth, combiner_frame_height]);

      // Right arm: from right shroud wall, overlapping the frame end
      translate([combiner_frame_width / 2 - arm_overlap, -combiner_frame_depth / 2, -combiner_frame_height / 2])
        cube([arm_length, combiner_frame_depth, combiner_frame_height]);
    }
}

// ── Detachable combiner cartridge ────────────────────────────
// The front lens is a SEPARATE printed part: combiner_frame() (unchanged
// optic geometry) placed by the SAME transform combiner_mount() used, plus
// two side ears that reach from the frame ends out toward the side-wall inner
// faces.  Each ear hosts 2 M3 brass inserts (bored along ±X from its outer
// face); 4 screws enter horizontally through the housing side walls
// (combiner_screw_clearance()) and thread into them.  The cartridge is
// depth-located on insertion by 3 rear stops (combiner_index_stops()).  Built
// in WORLD coords so the horizontal inserts stay along world X (the 180° flip
// at combiner_tilt=90 preserves X, so no rotation bookkeeping is needed).
module combiner_cartridge() {
  frame_left_x = body_width / 2 - combiner_frame_width / 2; // 11.1
  frame_right_x = body_width / 2 + combiner_frame_width / 2; // 47.1
  difference() {
    union() {
      // optic frame, placed EXACTLY as combiner_mount() places it
      translate([body_width / 2, combiner_center_y, combiner_center_z])
        rotate([270 - combiner_tilt, 0, 0])
          translate([-combiner_frame_width / 2, -combiner_frame_depth / 2, -combiner_frame_height / 2])
            combiner_frame();

      // Left ear: from the side-wall inner face (+combiner_fit slide gap) in to
      // combiner_ear_overlap past the frame's left edge.  Full cartridge depth
      // (combiner_rear_y..combiner_front_y) and full frame height.
      translate([side_edge + combiner_fit, combiner_rear_y, combiner_center_z - combiner_frame_height / 2])
        cube([(frame_left_x + combiner_ear_overlap) - (side_edge + combiner_fit), combiner_frame_depth, combiner_frame_height]);
      // Right ear (mirror)
      translate([frame_right_x - combiner_ear_overlap, combiner_rear_y, combiner_center_z - combiner_frame_height / 2])
        cube([(body_width - side_edge - combiner_fit) - (frame_right_x - combiner_ear_overlap), combiner_frame_depth, combiner_frame_height]);
    }
    // 4 M3 inserts, bored along ±X from the ear outer faces (joint_inserts idiom)
    for (z = [combiner_center_z - combiner_screw_dz, combiner_center_z + combiner_screw_dz]) {
      translate([side_edge + combiner_fit, combiner_center_y, z]) // left ear, bore +X
        rotate([0, -90, 0]) insert_hole("M3");
      translate([body_width - side_edge - combiner_fit, combiner_center_y, z]) // right ear, bore -X
        rotate([0, 90, 0]) insert_hole("M3");
    }
  }
}

// M3 screw clearance holes (with countersink) through the housing side walls,
// heads flush on the OUTER faces, threading into the cartridge ear inserts.
// Mirrors joint_clearance()'s ±X idiom, at the combiner screw Y/Z.
module combiner_screw_clearance() {
  for (z = [combiner_center_z - combiner_screw_dz, combiner_center_z + combiner_screw_dz]) {
    translate([0, combiner_center_y, z]) // left wall, screw enters from -X
      rotate([0, -90, 0]) screw_hole("M3", side_edge, m3_clearance_fit);
    translate([body_width, combiner_center_y, z]) // right wall, screw enters from +X
      rotate([0, 90, 0]) screw_hole("M3", side_edge, m3_clearance_fit);
  }
}

// 3 rear indexing stops fused to the housing — front faces at combiner_rear_y,
// bodies extending combiner_index_depth BEHIND it (-Y), so the cartridge butts
// against them on insertion and is depth-located.  One on each side-wall inner
// face (contacting the ears) and one hanging from the hood underside
// (contacting the frame's top rear rim).  All sit at Y < combiner_rear_y, so
// they never collide with the cartridge, which stops at combiner_rear_y.
module combiner_index_stops() {
  s = combiner_index_size;
  y0 = combiner_rear_y - combiner_index_depth;
  // left side-wall stop (protrudes +X into the cavity)
  translate([side_edge, y0, combiner_center_z - s / 2])
    cube([s, combiner_index_depth, s]);
  // right side-wall stop (protrudes -X)
  translate([body_width - side_edge - s, y0, combiner_center_z - s / 2])
    cube([s, combiner_index_depth, s]);
  // top hood stop (hangs down from the hood underside = optics_top_z)
  translate([body_width / 2 - s / 2, y0, optics_top_z - s])
    cube([s, combiner_index_depth, s]);
}

// ── Side lap joint ───────────────────────────────────────────
// The top-part skirts lap over rebates in the bottom-part side edges;
// 4 horizontal M3 screws (2 per side, low — under the PCB) pin and clamp
// them.  The screw shanks also pin the halves against vertical separation.

// Rebate the bottom part's outer side faces so the skirts sit flush.
module side_rebates() {
  translate([-0.1, -0.1, body_height - lap_height])
    cube([skirt_thickness + 0.1, body_depth + 0.2, lap_height + 0.2]);
  translate([body_width - skirt_thickness, -0.1, body_height - lap_height])
    cube([skirt_thickness + 0.1, body_depth + 0.2, lap_height + 0.2]);
}

// M3 brass-insert bores in the thick bottom side edges (mouth on the rebate
// face, boring inward into solid material), low and below the PCB.  Mapped
// from insert_hole()'s -Z bore: rotate so local -Z points INTO the edge.
module joint_inserts() {
  for (y = joint_screw_y) {
    translate([skirt_thickness, y, joint_screw_height]) // left edge, bore +X into the solid
      rotate([0, -90, 0]) insert_hole("M3");
    translate([body_width - skirt_thickness, y, joint_screw_height]) // right edge, bore -X
      rotate([0, 90, 0]) insert_hole("M3");
  }
}

// M3 screw clearance holes (with countersink) through the top-part skirts.
// The screw enters from OUTSIDE each skirt, head flush on the outer face, so
// the cutter's Z=0 mouth sits on that face and its -Z body bore crosses the
// skirt toward the insert.
module joint_clearance() {
  for (y = joint_screw_y) {
    translate([0, y, joint_screw_height]) // left skirt, screw enters from -X
      rotate([0, -90, 0]) screw_hole("M3", skirt_thickness, m3_clearance_fit);
    translate([body_width, y, joint_screw_height]) // right skirt, screw enters from +X
      rotate([0, 90, 0]) screw_hole("M3", skirt_thickness, m3_clearance_fit);
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
      translate([0, box_back_y, 0])
        cube([body_width, box_length, box_wall_top_z]);
      // fuse block tying the box into the lower body (z <= body_height,
      // so it never clashes with the shroud lip above)
      translate([0, box_back_y - 2, 0])
        cube([body_width, 2 + box_wall, body_height]);
    }
    // interior cavity (open top)
    translate([box_wall, box_back_y + box_wall, box_wall])
      cube([body_width - 2 * box_wall, box_length - 2 * box_wall, box_height + 1]);
  }
  // lid screw bosses in the 4 inside corners (rise from the floor)
  for (bx = lid_screw_x, by = lid_screw_y)
    translate([bx, by, 0]) cylinder(r=box_boss_radius, h=box_wall_top_z + 0.01);
}

// Cable channel: opens through the PCB pocket floor, runs forward UNDER the
// PCB and through the optics-head front wall into the box, plus a plug
// opening in the box front face.  Top reaches the pocket floor so the
// display cable can drop straight down into it.
module cable_channel() {
  pcb_pocket_floor_z = body_height - display_pcb_thickness - display_fit_clearance; // 18.30 (matches the PCB pocket floor)
  translate([body_width / 2 - cable_channel_width / 2, body_depth * 0.45, cable_channel_floor_z])
    cube(
      [
        cable_channel_width,
        (box_back_y + box_wall + 1) - body_depth * 0.45,
        pcb_pocket_floor_z + 0.2 - cable_channel_floor_z,
      ]
    );
  // plug opening in the box front wall
  translate([body_width / 2 - plug_opening_width / 2, box_front_y - box_wall - 0.1, plug_opening_floor_z])
    cube([plug_opening_width, box_wall + 0.2, plug_opening_height]);
}

// Vertical M3 insert bores in the lid bosses (mouth on the boss top, boring
// down — insert pressed in from +Z, per insert_hole()'s convention).
module box_lid_inserts() {
  for (bx = lid_screw_x, by = lid_screw_y)
    translate([bx, by, box_wall_top_z])
      insert_hole("M3");
}

// Removable top lid (separate printed part), screwed to the bosses.  Each M3
// screw drops from the top: head countersunk flush at the lid's top face, the
// body bore crossing the lid thickness into the boss insert below.
module box_lid() {
  difference() {
    translate([0, box_back_y, box_wall_top_z])
      cube([body_width, box_length, lid_thickness]);
    for (bx = lid_screw_x, by = lid_screw_y)
      translate([bx, by, box_height]) // box_height = lid top face
        screw_hole("M3", lid_thickness, m3_clearance_fit);
  }
}

// Engraved label cut into the RIGHT (+X) face of the box.  The text's
// readable side faces +X (outward) so it reads correctly from the right.
module right_side_engrave() {
  translate([body_width - engrave_depth, engrave_center_y, engrave_center_z])
    rotate([90, 0, 90])
      linear_extrude(height=engrave_depth + 0.2)
        text(
          engrave_text, size=engrave_size, font=engrave_font,
          halign="center", valign="center"
        );
}

// ── Two parts ────────────────────────────────────────────────
module bottom_part() {
  difference() {
    union() {
      screen_body();
      front_box();
      // Picatinny clamp FIXED body — runs the WHOLE length on the underside.
      translate([body_width / 2, 0, 0]) picatinny_clamp_body(rail_length);
    }
    side_rebates();
    joint_inserts();
    cable_channel();
    box_lid_inserts();
    if (engrave_enabled) right_side_engrave();
  }
}

// Removable clamp bar, placed in its assembled position under the sight.
module clamp_bar() {
  translate([body_width / 2, 0, 0]) picatinny_clamp_bar(rail_length);
}

module top_part() {
  difference() {
    union() {
      eotech_shroud();
      beamsplitter_mount();
      combiner_index_stops(); // combiner is now a detachable cartridge (combiner_cartridge())
    }
    joint_clearance();
    combiner_screw_clearance();
  }
}

// ── Render selector ──────────────────────────────────────────
if (render_part == "bottom")
  bottom_part();
else if (render_part == "top")
  top_part();
else if (render_part == "combiner") // the detachable front-lens cartridge, on its own
combiner_cartridge(); else if (render_part == "bar") // the removable clamp bar, on its own
clamp_bar(); else if (render_part == "lid") // the box top lid, on its own
box_lid(); else {
  // "both" — full assembled preview
  bottom_part();
  top_part();
  combiner_cartridge();
  clamp_bar();
  box_lid();
}
