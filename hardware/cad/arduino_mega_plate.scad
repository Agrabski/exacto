// arduino_mega_plate.scad
//
// A flat mounting plate with M2 heat-set insert pockets laid out in the
// Arduino Mega 2560 / Due mounting-hole pattern, hung under a Picatinny rail
// clamp so the whole board can be clamped onto a MIL-STD-1913 rail.
//
// Units: mm. The plate's TOP face is at Z = 0; it extends down to Z = -plate_t.
// Insert bores open on the top face (board mounts on +Z). The Picatinny clamp
// body hangs BELOW the plate (rail runs along Y, underneath), so the rail is on
// the opposite side from the board.
//
// This is a TWO-PART clamp (see picatinny.scad): the fixed body is fused to the
// plate; the removable jaw (bar) prints separately. Select with `part`:
//   "plate"   — plate + fixed clamp body   (the main printable part)
//   "bar"     — the removable clamp jaw     (print separately)
//   "spacers" — a grid of loose round M2 board spacers (print separately);
//               one per mounting hole, sit between board and plate, screw
//               passing through into the plate's inserts
//   "demo"    — assembled preview (plate + body + bar in clamped position)
//
// Dependencies (vendored as submodules / local to hardware/cad):
//   - arduino-mount/arduino.scad  — hole pattern (holePlacement, MEGA2560).
//     include (not use) so its MEGA2560/boardHoles VARIABLES resolve.
//   - pin_connectors/pins.scad    — arduino.scad's own dependency; resolved
//     via OPENSCADPATH below.
//   - scad-common/screw_mounts.scad — insert_hole() cutter.
//   - picatinny.scad              — picatinny_clamp_body() / _bar().
//
// Render (OPENSCADPATH lets arduino.scad find pin_connectors):
//   OPENSCADPATH=hardware/cad openscad -o out.stl hardware/cad/arduino_mega_plate.scad
//   OPENSCADPATH=hardware/cad openscad -o bar.stl -D 'part="bar"' hardware/cad/arduino_mega_plate.scad

include <arduino-mount/arduino.scad>
use <scad-common/screw_mounts.scad>
use <picatinny.scad>

// ---- parameters ----
part        = "plate";    // "plate" | "bar" | "spacers" | "demo"
board       = MEGA2560;   // hole pattern to use (Mega 2560 == Due footprint)
insert_size = "M2";       // heat-set insert size (M2 bore: 3.2 mm dia x 4 mm deep)
margin      = 5;          // plate border around the board footprint (mm)
plate_t     = 6;          // plate thickness (mm) — must exceed the insert depth
corner_r    = 3;          // plate corner rounding (mm)
rail_len    = 0;          // Picatinny clamp length along Y (mm); 0 = full plate length
spacer_len  = 2;          // board spacer height (mm)
spacer_od   = 5;          // board spacer outer diameter (mm)

$fn = 48;

pcb = pcbDimensions(board);   // [width, length, pcb_height]

// Full plate footprint (board + margin on every side).
plate_len = pcb[1] + 2 * margin;   // plate length along Y
// Clamp length: default (0) spans the whole plate; otherwise use the override.
clamp_len = (rail_len > 0) ? rail_len : plate_len;

// Clamp placement: centred under the board footprint, hung on the plate's
// underside. The clamp's mount face is at its local z=0 and it extends down,
// so drop it by plate_t to sit on the plate's bottom face (z = -plate_t).
clamp_x = pcb[0] / 2;
clamp_y = pcb[1] / 2 - clamp_len / 2;
clamp_z = -plate_t;

if (part == "bar") {
    // removable jaw on its own, in the clamp's native frame, for printing
    picatinny_clamp_bar(clamp_len);
} else if (part == "spacers") {
    // loose round board spacers, laid out on the bed for printing
    m2_spacers();
} else {
    plate_with_clamp_body();
    if (part == "demo")
        color("orange")
            translate([clamp_x, clamp_y, clamp_z]) picatinny_clamp_bar(clamp_len);
}

// Plate (with insert pockets) + the fixed Picatinny clamp body fused beneath.
module plate_with_clamp_body() {
    union() {
        // plate: insert pockets cut ONLY into the plate, not the clamp
        difference() {
            translate([-margin, -margin, -plate_t])
                rounded_plate(pcb[0] + 2 * margin, pcb[1] + 2 * margin, plate_t, corner_r);
            holePlacement(boardType = board)
                insert_hole(insert_size);
        }
        // fixed clamp half hanging under the plate
        translate([clamp_x, clamp_y, clamp_z])
            picatinny_clamp_body(clamp_len);
    }
}

// One round board spacer: a stud from z=0..spacer_len with an M2 screw
// clearance bore all the way through (screw passes board -> spacer -> insert).
module m2_spacer(h = spacer_len, od = spacer_od) {
    difference() {
        cylinder(d = od, h = h);
        // clearance_hole bores down from its mouth; place the mouth at the top
        translate([0, 0, h])
            clearance_hole(insert_size, h, fit = 0.4);
    }
}

// All board spacers (one per mounting hole) laid out flat in a compact grid,
// separated so they print as individual loose parts.
module m2_spacers(gap = 3) {
    n     = len(boardHoles[board]);
    cols  = ceil(sqrt(n));
    pitch = spacer_od + gap;
    for (i = [0 : n - 1])
        translate([(i % cols) * pitch, floor(i / cols) * pitch, 0])
            m2_spacer();
}

// A cuboid with vertical edges rounded to radius r, anchored at its min corner.
module rounded_plate(x, y, z, r) {
    linear_extrude(height = z)
        offset(r = r) offset(r = -r)
            square([x, y]);
}
