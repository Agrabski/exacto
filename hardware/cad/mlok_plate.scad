// ============================================================
// 50 x 20 mm plate with male M-LOK lugs on the underside.
//
// Uses the Mlok-Openscad library (git submodule at ./mlok). Its entry
// point mlok.scad pulls in BOSL2 (installed in OpenSCAD's global library
// dir) plus the M-LOK modules and constants (MLOK_LUG_H, etc).
//
// The lug pair runs along X (the plate length); Y is the plate width.
// num_lugs = 2 is a single M-LOK slot (two half-lug tabs). Following the
// library demos (examples/sling_stud.scad, examples/handstop.scad), each
// lug gets its own bolt bore (screw_interval = 1): with the default
// interval of 2 only one lug is bored, and the un-bored lug sits coplanar
// on the plate's bottom face and fails to fuse (renders as a loose solid).
// ============================================================

include <mlok/mlok.scad>

// ---- plate parameters ----
plate_l  = 50;    // length, along the M-LOK slot axis (X)
plate_w  = 20;    // width (Y)
plate_t  = 6;     // plate thickness (Z)
rounding = 1.5;   // corner rounding of the plate
num_lugs = 2;     // 2 = one M-LOK slot (two half-lug tabs)
slop     = 0.15;  // per-side print clearance on the lugs

$fn = 64;

// The plate sits top-face up; lugs hang below the bottom face.
// diff("screw_hole") subtracts the bolt bore each lug tags: an 8 mm T-nut
// pocket in the lug, a 5.2 mm shaft through the plate, and a head
// counterbore that opens on the top face. (clear_screw_top is left at its
// default 0 — it only applies when a tall body sits above the lugs, e.g.
// the post in examples/sling_stud.scad; on a flat plate it would leave the
// counterbore standing proud as a solid post.)
diff("screw_hole")
  cuboid([plate_l, plate_w, plate_t], rounding=rounding, edges="Z", anchor=BOTTOM)
    position(BOTTOM)
      mlok_male_lugs(
        num_lugs       = num_lugs,
        h              = MLOK_LUG_H,
        slop           = slop,
        parent_height  = plate_t,
        screw_interval = 1,        // a bolt bore through every lug
        anchor         = TOP
      );
