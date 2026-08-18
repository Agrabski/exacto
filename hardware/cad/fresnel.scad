// ============================================================
// Fresnel collimator frame — flat sheet in the reflex path
//
// A thin, FLAT Fresnel sheet between the tilted OLED and the combiner, square
// to the reflected chief ray (so, parallel to the display), gathering the
// display's light before the combiner folds it into the eye.
//
//   fresnel_frame(...)      positive geometry: a slab spanning the shroud's two
//                           side walls, tilted onto the ray, carrying the sheet.
//   fresnel_negatives(...)  the matching cuts: the sheet slot (open at the REAR
//                           face, so the sheet slides in from the eye side) and
//                           the clear aperture through the rims either side.
//
// It rides in the TOP part, not on the OLED seat: the board is dropped into its
// seat through exactly the space the sheet occupies, so anything mounted there
// would trap the display.  With the halves apart, the slab is reached through
// the open rear of the shroud.
//
// Everything is expressed in the OLED seat's LOCAL frame — the same
// translate(pos) rotate([pitch, 0, 0]) that oled_seat()/oled_cavity() use:
//
//   local Z = 0          the display pocket floor
//   local Z = screen_z   the OLED's emitting surface (the PCB's front face)
//   local +Z             points up the reflected chief ray, at the combiner
//
// so the sheet comes out square to the display and to the chief ray by
// construction, and `gap` is a true on-axis distance from the lit surface.
// Nothing else in the sight moves: the frame grows into the space `oled_dist`
// already leaves between the display and the combiner.
//
// Focal length: `gap` is the display→sheet distance, so it wants to be the
// sheet's back focal length to throw the reticle to infinity.  Note how sharp
// that is at short focal lengths — at f = 8 mm a 0.2 mm error puts the virtual
// image at ~0.3 m instead of infinity, and 0.2 mm is ordinary print/joint
// tolerance.  A longer focal length is far more forgiving (f = 30 mm, same
// error → ~4.5 m), but needs a bigger gap than `oled_dist` leaves; raise
// `oled_dist` to buy the room, which slides the display down the ray without
// disturbing the reflex fold.
//
// The sheet is captured by a rim on BOTH faces, lapping its edge by `lip`, and
// is retained by friction plus a dab of adhesive like the other optics here.
// ============================================================

// Rim over each face of the sheet.  The lower one bridges the aperture, so
// keep it thin.
function fresnel_rim_t() = 1.20;

// Sheet underside and the slab's two faces, in local Z.
function fresnel_sheet_z(screen_z, gap) = screen_z + gap;
function fresnel_slab_z0(screen_z, gap) = screen_z + gap - fresnel_rim_t();
function fresnel_slab_z1(screen_z, gap, fresnel, clearance) =
  screen_z + gap + fresnel[2] + clearance + fresnel_rim_t();

// Depth of the slab along the local Y axis (its extent toward the front lip).
function fresnel_slab_d(fresnel, clearance, wall) = fresnel[1] + clearance + 2 * wall;

// ── Frame ────────────────────────────────────────────────────
// Slab spanning wall to wall, so it fuses into the shroud's thick side edges
// (and into the combiner's plumb columns, which share that space).
// fresnel = [w (local X), d (local Y), t] — the flat sheet, cut to size.
module fresnel_frame(fresnel, clearance, wall, body_w, side_edge,
                     pos, pitch, screen_z, gap, embed = 1.0) {
  assert(gap > fresnel_rim_t(),
         "fresnel_gap must exceed the rim thickness — the slab would foul the display");
  sd = fresnel_slab_d(fresnel, clearance, wall);
  z0 = fresnel_slab_z0(screen_z, gap);
  z1 = fresnel_slab_z1(screen_z, gap, fresnel, clearance);
  // Reach `embed` into each side wall so the union is solid, not a kiss.
  x0 = -(body_w / 2 - side_edge + embed);
  translate(pos)
    rotate([pitch, 0, 0])
      translate([x0, -sd / 2, z0])
        cube([-2 * x0, sd, z1 - z0]);
}

// ── Frame negatives ──────────────────────────────────────────
module fresnel_negatives(fresnel, clearance, wall, lip, pos, pitch, screen_z, gap) {
  pw = fresnel[0] + clearance; // slot width  (local X)
  pd = fresnel[1] + clearance; // slot depth  (local Y)
  ph = fresnel[2] + clearance; // slot height (local Z)
  sd = fresnel_slab_d(fresnel, clearance, wall);
  zs = fresnel_sheet_z(screen_z, gap);
  z0 = fresnel_slab_z0(screen_z, gap);
  z1 = fresnel_slab_z1(screen_z, gap, fresnel, clearance);

  translate(pos)
    rotate([pitch, 0, 0]) {
      // Sheet slot — runs out through the slab's REAR (−Y) face so the sheet
      // slides in from the eye side; rims above and below capture it.
      translate([-pw / 2, -(sd / 2 + 0.1), zs])
        cube([pw, sd / 2 + pd / 2 + 0.1, ph]);
      // Clear aperture — through both rims, inset by `lip` from the slot.
      translate([-(pw / 2 - lip), -(pd / 2 - lip), z0 - 0.1])
        cube([pw - 2 * lip, pd - 2 * lip, z1 - z0 + 0.2]);
    }
}
