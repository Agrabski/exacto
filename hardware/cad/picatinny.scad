// ============================================================
// Picatinny rail connector — MIL-STD-1913  (TWO-PART clamp)
//
//   picatinny_clamp_body(length)  female clamp FIXED half — ceiling +
//                             right (fixed) jaw + recoil lug.  Built
//                             "hanging": its flat MOUNTING FACE is at z=0
//                             and it extends DOWN, so it unions straight
//                             onto the underside of a part at z=0.
//   picatinny_clamp_bar(length)   the separate, removable LEFT jaw.  Two
//                             cross-bolts pull it toward the body.
//
// The clamp CAPTURES the rail's dovetail: the rail is widest at the 45°
// clamping shoulders, with an undercut below.  Both jaws hook under that
// undercut so the rail can't drop out.  Mounting (mid-rail, no end needed):
// hook the fixed right jaw on the rail, swing the rail up under the
// ceiling, fit the bar onto the left shoulder, then tighten the 2 cross-
// bolts (heads on the bar, running ALL THE WAY THROUGH the clamp into
// brass inserts pressed into the far/outer face of the body) to clamp.
// A recoil lug drops into a transverse slot to take recoil.
// ============================================================

// ── MIL-STD-1913 profile (widest at the shoulders, undercut below) ──
pic_width      = 21.20;  // max width across the clamping shoulders
pic_top_w      = 15.60;  // width of the top flat
pic_body_w     = 15.60;  // width of the rail body / neck (below undercut)
pic_bevel      = (pic_width - pic_top_w) / 2;   // 2.80, 45° run
pic_neck_z     =  1.00;  // body height below the undercut
pic_shoulder_z = pic_neck_z + pic_bevel;        // 3.80, widest clamping line
pic_top_z      = pic_shoulder_z + pic_bevel;    // 6.60, rail top
pic_slot_w     =  5.35;  // recoil-groove width
pic_slot_pitch = 10.00;  // recoil-groove pitch
pic_slot_depth =  2.00;  // recoil-groove depth from the top flat

// ── Clamp / fit ──────────────────────────────────────────────
pic_clear     = 0.30;    // slide-fit clearance on the channel
pic_ceil_t    = 5.00;    // ceiling thickness above the rail top
                         // (tall enough for the cross-bolts to run through)
pic_jaw_t     = 6.00;    // side-jaw thickness
pic_clamp_w   = pic_width + 2 * pic_jaw_t;   // 33.20 overall clamp width
pic_clamp_top = pic_top_z + pic_ceil_t;      // 11.60 mount-face height

// Two-part split: a vertical plane at the rail's left-top edge separates
// the removable bar (left) from the fixed body (right).
pic_split_x   = -pic_top_w / 2;  // -7.80 mating plane
pic_split_gap = 0.50;            // gap so the bolts can draw the bar inward

// Cross-bolts (2): head on the bar (outer left), the bolt runs all the way
// through the bar AND the body, and threads into a brass insert pressed into
// the body's outer (right) face — on the opposite side from the bolt head.
pic_bolt_clear     = 4.30;  // M4 through-bolt clearance (bar + body)
pic_bolt_insert_d  = 6.00;  // M4 brass insert OD (far face of body)
pic_bolt_insert_depth = 6.00;

$fn = 48;

// Rail cross-section (X = width, second coord = height above base).
// Body -> flare OUT to the widest shoulder (undercut) -> bevel IN to top.
function _pic_profile() = [
  [-pic_body_w / 2, 0],
  [ pic_body_w / 2, 0],
  [ pic_body_w / 2, pic_neck_z],
  [ pic_width / 2, pic_shoulder_z],
  [ pic_top_w / 2, pic_top_z],
  [-pic_top_w / 2, pic_top_z],
  [-pic_width / 2, pic_shoulder_z],
  [-pic_body_w / 2, pic_neck_z],
];

// Extrude the (optionally grown) rail profile along +Y, base at z=0.
module _pic_extrude(length, grow = 0) {
  translate([0, length, 0])
    rotate([90, 0, 0])
      linear_extrude(height = length)
        offset(r = grow)
          polygon(_pic_profile());
}

// Bolt height: mid-way up the ceiling band (above the rail top, so the
// bolts run through solid material clear of the channel).
function _pic_bolt_z() = pic_top_z + pic_ceil_t / 2;

// Whole (un-split) clamp solid in "up" coords: jaw+ceiling block minus the
// rail channel, plus the recoil lug.
module _clamp_solid_up(length) {
  difference() {
    translate([-pic_clamp_w / 2, 0, pic_neck_z])
      cube([pic_clamp_w, length, pic_clamp_top - pic_neck_z + 0.2]);
    translate([0, -1, 0]) _pic_extrude(length + 2, pic_clear);
  }
  // recoil lugs — one tooth per rail slot, as many as fit at the slot
  // pitch, centred along the length (all stay with the fixed body)
  lug_w  = pic_slot_w - 2 * pic_clear;
  n_lugs = max(1, floor((length - lug_w) / pic_slot_pitch) + 1);
  for (i = [0 : n_lugs - 1])
    translate([-6,
               length / 2 + (i - (n_lugs - 1) / 2) * pic_slot_pitch - lug_w / 2,
               pic_top_z - pic_slot_depth + pic_clear])
      cube([12, lug_w, pic_slot_depth + 0.6]);
}

// ── Fixed body (hanging: mount face at z=0, body below) ──────
module picatinny_clamp_body(length) {
  bolt_z = _pic_bolt_z();
  translate([0, 0, -pic_clamp_top + 0.2])
    difference() {
      // keep everything right of the split plane (+ gap)
      intersection() {
        _clamp_solid_up(length);
        translate([pic_split_x + pic_split_gap, -1, pic_neck_z - 1])
          cube([pic_clamp_w, length + 2, pic_clamp_top + 2]);
      }
      for (yy = [length * 0.28, length * 0.72]) {
        // through-bolt clearance: from the mating face all the way out the
        // far (right) face, so the screw passes fully through the body
        translate([pic_split_x - 1, yy, bolt_z])
          rotate([0, 90, 0]) cylinder(d = pic_bolt_clear, h = pic_clamp_w);
        // brass insert pressed into the OUTER (right) face — opposite the head
        translate([pic_clamp_w / 2 - pic_bolt_insert_depth, yy, bolt_z])
          rotate([0, 90, 0]) cylinder(d = pic_bolt_insert_d, h = pic_bolt_insert_depth + 0.2);
      }
    }
}

// ── Removable bar / left jaw (same coord frame as the body) ──
module picatinny_clamp_bar(length) {
  bolt_z = _pic_bolt_z();
  translate([0, 0, -pic_clamp_top + 0.2])
    difference() {
      // keep everything left of the split plane
      intersection() {
        _clamp_solid_up(length);
        translate([-pic_clamp_w / 2 - 1, -1, pic_neck_z - 1])
          cube([pic_split_x - (-pic_clamp_w / 2 - 1), length + 2, pic_clamp_top + 2]);
      }
      // bolt clearance (head bears on the outer left face — no counterbore)
      for (yy = [length * 0.28, length * 0.72])
        translate([-pic_clamp_w / 2 - 0.1, yy, bolt_z])
          rotate([0, 90, 0]) cylinder(d = pic_bolt_clear, h = pic_clamp_w / 2 + 2);
    }
}

// ── Demo (ignored when this file is `use`d) ──────────────────
picatinny_clamp_body(40);
color("orange") picatinny_clamp_bar(40);
