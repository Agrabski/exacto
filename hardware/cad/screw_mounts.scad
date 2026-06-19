// ============================================================
// Screw mounts — reusable brass-insert + screw-hole cutters
//
// Two negative-geometry modules, meant to be subtracted (difference())
// from a part.  They are the matched halves of one fastened joint:
//
//   insert_hole(size)        bore for a brass heat-set insert, pressed
//                            into the part that the screw threads INTO.
//   screw_hole(size, length) clearance hole in the COMPLEMENTARY part the
//                            screw passes THROUGH — exact screw-body bore
//                            that tapers out (countersink) into the head.
//
// `size` is "M2" or "M3".  Dimensions for the inserts match those already
// used in sight_housing.scad (M2: ø3.20 × 4.0; M3: ø4.00 × 5.0).
//
// Orientation convention (both modules):
//   The mouth of the hole sits at the LOCAL ORIGIN on the Z=0 plane and
//   the hole bores DOWNWARD into -Z, i.e. the fastener is imagined entering
//   from +Z.  Each cutter pokes +0.1 mm past Z=0 so the Boolean cleanly
//   breaks the surface.  translate()/rotate() the call to place it on the
//   real face, exactly like the bores in sight_housing.scad.
//
//   insert_hole : insert is pressed in from +Z; bore is +Z-deep into stock.
//   screw_hole  : head sits flush at Z=0 (countersunk), body bores to -Z.
// ============================================================

// ── Fastener table ───────────────────────────────────────────
// One row per screw size.  Head thickness is the user-specified value
// (M3 = 1.75 mm, M2 = 1.50 mm); head diameter is the user-specified
// countersunk flat-head OD (M3 = 5.8, M2 = 4.0).  Body diameter is the
// nominal thread OD — the screw hole uses this EXACTLY (see screw_hole()).
function screw_body_d(size) =
  size == "M3" ? 3.00 :
  size == "M2" ? 2.00 : undef;

function screw_head_d(size) =
  size == "M3" ? 5.80 :
  size == "M2" ? 4.00 : undef;

function screw_head_t(size) =
  size == "M3" ? 1.75 :
  size == "M2" ? 1.50 : undef;

// Brass heat-set insert bore (outer dia + length) — values shared with
// sight_housing.scad's insert_d / insert_depth (M2) and join_insert_d /
// join_insert_depth (M3).
function insert_bore_d(size) =
  size == "M3" ? 4.00 :
  size == "M2" ? 3.20 : undef;

function insert_bore_depth(size) =
  size == "M3" ? 5.00 :
  size == "M2" ? 4.00 : undef;

// ── Brass-insert bore ────────────────────────────────────────
// Pocket for a heat-set insert, pressed in from +Z.  Bores `depth` into
// -Z (default = the size's standard insert length) and pokes 0.1 mm past
// the Z=0 face so the cut breaks the surface cleanly.
//   depth : override the bore depth (mm).  Leave default for the standard
//           insert length.
module insert_hole(size, depth = undef) {
  d = insert_bore_d(size);
  h = depth == undef ? insert_bore_depth(size) : depth;
  translate([0, 0, -h])
    cylinder(d = d, h = h + 0.1);
}

// ── Screw clearance hole + head countersink ──────────────────
// Cut in the complementary part the screw passes THROUGH.  The straight
// bore is EXACTLY the screw-body diameter (plus optional `clearance`,
// default 0 — a true body-diameter hole as requested); the top
// screw_head_t(size) mm flares out as a cone from the body diameter up to
// the full head diameter, so a countersunk head seats flush at Z=0.
//   length    : straight body-bore length below the taper (mm).  Set to
//               the wall/material thickness the screw shank crosses; the
//               taper sits on top of this, the bore pokes 0.1 mm past the
//               far side for a clean break.
//   clearance : added to the body diameter (mm).  Default 0 = exact body
//               diameter.  Use e.g. 0.4 for a free-fit clearance hole.
module screw_hole(size, length, clearance = 0) {
  bd = screw_body_d(size) + clearance; // straight bore = exact body dia (+fit)
  hd = screw_head_d(size);             // countersink mouth = head dia
  ht = screw_head_t(size);             // taper height = head thickness

  union() {
    // straight body-clearance bore, hanging below the taper
    translate([0, 0, -(length + ht)])
      cylinder(d = bd, h = length + 0.1);
    // head countersink: cone flaring from body dia up to head dia
    translate([0, 0, -ht])
      cylinder(d1 = bd, d2 = hd, h = ht);
    // break the top surface above the head mouth
    translate([0, 0, -0.001])
      cylinder(d = hd, h = 0.1);
  }
}

// ── Demo (only renders when this file is opened directly; `use <>`
// imports the modules/functions above and ignores everything below) ──
$fn = 48;
demo_block = 14;
// left: a block with an M3 insert bore;  right: a block with an M3 screw
// hole, sliced so the countersink + body bore are visible.
difference() {
  translate([-demo_block - 2, -demo_block / 2, -demo_block])
    cube([demo_block, demo_block, demo_block]);
  insert_hole("M3");
}
difference() {
  translate([2, -demo_block / 2, -demo_block])
    cube([demo_block, demo_block, demo_block]);
  translate([2 + demo_block / 2, 0, 0])
    screw_hole("M3", demo_block - 4);
}
