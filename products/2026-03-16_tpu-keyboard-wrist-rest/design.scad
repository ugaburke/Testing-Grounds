// ============================================================
// TPU Lattice Wrist Rest — Keyboard-Specific Sizing
// Version: 1.0
// License: Proprietary — STL for sale, .scad source retained
// ============================================================
//
// A flexible TPU wrist rest with gyroid-inspired lattice infill
// for natural cushioning. Sized to match specific mechanical
// keyboards by width and front-edge profile.
//
// The design uses a solid base shell with an internal lattice
// structure that provides progressive resistance — soft at first
// contact, firmer under sustained pressure. The top surface has
// a gentle ergonomic slope (5° decline toward the keyboard).
//
// TPU Printing Notes:
//   - Direct-drive extruder REQUIRED (Bowden will jam)
//   - Print speed: 20-30 mm/s max
//   - Retraction: minimal (0.5-1mm) or disabled
//   - Temperature: 220-235°C (material dependent)
//   - Bed: 50°C with glue stick or PEI
//   - No supports needed in this orientation

// ===================== KEYBOARD PRESETS =======================
// Uncomment ONE preset, or set custom dimensions below.
// All measurements in mm, representing the keyboard's front edge
// width and the desk-level depth the rest should occupy.

// --- 60% Keyboards ---
// Keychron Q4 / K6: ~295mm wide
// kb_width = 295; kb_name = "60pct";

// --- 65% Keyboards ---
// Keychron Q2 / K2: ~317mm wide
// kb_width = 317; kb_name = "65pct";

// --- 75% Keyboards ---
// Keychron Q1 Pro / GMMK Pro: ~332mm wide
kb_width = 332; kb_name = "75pct";

// --- TKL (Tenkeyless) ---
// Keychron Q3 / K8: ~358mm wide
// kb_width = 358; kb_name = "TKL";

// --- Full Size ---
// Keychron Q5 / K10: ~440mm wide
// kb_width = 440; kb_name = "fullsize";

// --- Custom ---
// kb_width = YOUR_WIDTH; kb_name = "custom";

// ===================== PARAMETERS ============================

// Rest dimensions
rest_width = kb_width;       // Matches keyboard width
rest_depth = 80;             // Front-to-back depth (wrist contact zone)
rest_height_front = 18;      // Height at the front edge (closest to user)
rest_height_back = 22;       // Height at the back edge (closest to keyboard)

// Ergonomic slope is derived: atan((back - front) / depth) ≈ 2.9°

// Shell thickness
shell_wall = 1.6;            // Outer wall thickness (4 perimeters at 0.4mm)
shell_top = 1.2;             // Top surface thickness (3 layers at 0.4mm)
shell_bottom = 1.2;          // Bottom surface thickness

// Lattice parameters
lattice_cell = 8;            // Lattice cell size (mm) — smaller = firmer
lattice_wall = 1.2;          // Lattice wall thickness — thicker = firmer
// Firmness guide:
//   Soft:   cell=10, wall=0.8
//   Medium: cell=8,  wall=1.2 (default)
//   Firm:   cell=6,  wall=1.6

// Corner rounding
corner_r = 8;                // Radius of rounded corners

// Anti-slip base
grip_dot_dia = 3;            // Diameter of grip dots on the bottom
grip_dot_height = 0.6;       // Height of grip dots (printed in first layers)
grip_dot_spacing = 12;       // Center-to-center spacing

// Resolution
$fn = 40;

// ===================== MODULES ===============================

// Rounded rectangle as a 2D profile
module rounded_rect_2d(w, d, r) {
    offset(r) offset(-r)
        square([w, d], center=true);
}

// The outer shell envelope — a tapered box with slope
module shell_envelope() {
    hull() {
        // Front face (lower)
        translate([0, -rest_depth/2, 0])
            linear_extrude(0.01)
                rounded_rect_2d(rest_width, 0.01, corner_r);
        translate([0, -rest_depth/2, rest_height_front])
            linear_extrude(0.01)
                rounded_rect_2d(rest_width, 0.01, corner_r);

        // Back face (higher)
        translate([0, rest_depth/2, 0])
            linear_extrude(0.01)
                rounded_rect_2d(rest_width, 0.01, corner_r);
        translate([0, rest_depth/2, rest_height_back])
            linear_extrude(0.01)
                rounded_rect_2d(rest_width, 0.01, corner_r);
    }
}

// Interior cavity (shell minus walls)
module interior_cavity() {
    iw = rest_width - 2 * shell_wall;
    id = rest_depth - 2 * shell_wall;
    ih_front = rest_height_front - shell_bottom - shell_top;
    ih_back = rest_height_back - shell_bottom - shell_top;

    translate([0, 0, shell_bottom])
    hull() {
        translate([0, -id/2, 0])
            linear_extrude(0.01)
                rounded_rect_2d(iw, 0.01, corner_r - shell_wall);
        translate([0, -id/2, ih_front])
            linear_extrude(0.01)
                rounded_rect_2d(iw, 0.01, corner_r - shell_wall);

        translate([0, id/2, 0])
            linear_extrude(0.01)
                rounded_rect_2d(iw, 0.01, corner_r - shell_wall);
        translate([0, id/2, ih_back])
            linear_extrude(0.01)
                rounded_rect_2d(iw, 0.01, corner_r - shell_wall);
    }
}

// 3D lattice grid — intersected with the cavity to create
// internal cushioning structure. Uses a simple cubic lattice
// (the slicer's gyroid infill will add additional compliance).
module lattice_structure() {
    iw = rest_width - 2 * shell_wall;
    id = rest_depth - 2 * shell_wall;
    ih = rest_height_back;  // Max height

    // Lattice in X direction (vertical walls running front-to-back)
    for (x = [-iw/2 : lattice_cell : iw/2]) {
        translate([x - lattice_wall/2, -id/2, 0])
            cube([lattice_wall, id, ih]);
    }

    // Lattice in Y direction (vertical walls running left-to-right)
    for (y = [-id/2 : lattice_cell : id/2]) {
        translate([-iw/2, y - lattice_wall/2, 0])
            cube([iw, lattice_wall, ih]);
    }

    // Lattice in Z direction (horizontal shelves)
    for (z = [0 : lattice_cell : ih]) {
        translate([-iw/2, -id/2, z])
            cube([iw, id, lattice_wall]);
    }
}

// Anti-slip grip dots on the bottom surface
module grip_dots() {
    dot_count_x = floor(rest_width / grip_dot_spacing) - 1;
    dot_count_y = floor(rest_depth / grip_dot_spacing) - 1;

    for (xi = [0 : dot_count_x - 1])
        for (yi = [0 : dot_count_y - 1]) {
            x = -rest_width/2 + grip_dot_spacing + xi * grip_dot_spacing;
            y = -rest_depth/2 + grip_dot_spacing + yi * grip_dot_spacing;
            translate([x, y, 0])
                cylinder(d=grip_dot_dia, h=grip_dot_height);
        }
}

// ===================== ASSEMBLY ==============================

module wrist_rest() {
    // Start with the solid shell
    difference() {
        shell_envelope();
        interior_cavity();
    }

    // Add lattice inside the cavity
    intersection() {
        interior_cavity();
        lattice_structure();
    }

    // Add grip dots to the bottom
    // (These print as part of the first layers — slightly raised bumps)
    mirror([0, 0, 1])
        translate([0, 0, -grip_dot_height])
            grip_dots();
}

// Render
wrist_rest();

// ===================== PRINT NOTES ===========================
//
// MATERIAL: TPU Shore 95A (e.g., NinjaTek NinjaFlex, Overture TPU,
//           eSUN eTPU-95A). Shore 95A gives the best balance of
//           cushion and support. Shore 85A is softer (squishier),
//           Shore 98A is firmer.
//
// ORIENTATION: Print flat, bottom face on the build plate. The
//   slight slope prints naturally with no supports.
//
// SLICER SETTINGS:
//   - Infill: 15-20% gyroid (the lattice structure is the primary
//     support — slicer infill fills remaining gaps in the lattice
//     cells for additional compliance)
//   - Perimeters: 4 (matches shell_wall = 1.6mm)
//   - Top/bottom layers: 3 (matches shell_top/bottom = 1.2mm)
//   - Speed: 20-30 mm/s (TPU max reliable speed)
//   - Retraction: 0.5-1mm direct drive, DISABLED for Bowden
//   - Temperature: 220-235°C nozzle, 50°C bed
//   - Cooling fan: 50% after first 3 layers
//   - Z-hop: 0.2mm (helps prevent nozzle dragging on TPU)
//
// Print time estimate: 3-4 hours for 75% layout at 25mm/s
// Filament estimate: ~100-130g TPU depending on keyboard size
//
// FIRMNESS TUNING:
//   Adjust lattice_cell and lattice_wall parameters:
//   - Softer: increase cell to 10, decrease wall to 0.8
//   - Firmer: decrease cell to 6, increase wall to 1.6
//   - Or change TPU durometer (85A softer, 98A firmer)
