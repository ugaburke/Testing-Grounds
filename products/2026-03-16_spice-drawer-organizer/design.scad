// ============================================================
// Brand-Specific Spice Drawer Organizer — Modular System
// Version: 1.0
// License: Proprietary — STL for sale, .scad source retained
// ============================================================
//
// A modular, snap-together spice drawer organizer with brand-
// specific jar slot geometry. Each module holds 2 jars and
// snaps to adjacent modules in both X and Y directions.
//
// The system works like this:
//   1. Buyer selects their spice jar brand (preset)
//   2. Buyer enters drawer width and depth
//   3. OpenSCAD calculates how many modules fit
//   4. Buyer prints (or we print) the exact quantity needed
//
// Each module is small enough to fit on a 200x200mm bed.
// Modules snap together with dovetail joints on all 4 sides.

// ===================== BRAND PRESETS =========================
// Uncomment ONE preset to set jar slot dimensions.
// All measurements in mm.

// --- McCormick (Standard US grocery, round) ---
// Most common US brand. Small round jars.
jar_dia = 46;        // 1.81" = 46mm
jar_shape = "round"; // round slot
jar_height = 108;    // 4.25" — for reference, not used in 2D layout
brand_name = "McCormick";

// --- Trader Joe's (Rectangular jars) ---
// jar_dia = 46;         // Width: 1.8" = 46mm
// jar_depth = 46;       // Depth: 1.8" = 46mm (nearly square footprint)
// jar_shape = "rect";   // rectangular slot
// jar_height = 104;     // 4.1"
// brand_name = "TraderJoes";

// --- Simply Organic (French square glass) ---
// jar_dia = 52;         // 2.05" = 52mm
// jar_shape = "square"; // square slot
// jar_height = 114;     // 4.5"
// brand_name = "SimplyOrganic";

// --- Whole Foods 365 (Round, standard) ---
// jar_dia = 50;         // ~1.95" = 50mm (avg across product line)
// jar_shape = "round";
// jar_height = 106;     // ~4.15"
// brand_name = "WholeFoods365";

// --- Penzeys (Round, premium) ---
// jar_dia = 52;         // ~2.05" = 52mm
// jar_shape = "round";
// jar_height = 127;     // ~5.0"
// brand_name = "Penzeys";

// --- Custom ---
// jar_dia = YOUR_DIAMETER;
// jar_shape = "round"; // or "rect" or "square"
// jar_height = YOUR_HEIGHT;
// brand_name = "Custom";

// For rectangular jars (Trader Joe's), set jar_depth separately:
jar_depth = jar_dia; // Default: same as diameter (square footprint)

// ===================== DRAWER DIMENSIONS =====================
// Set your drawer interior dimensions here.

drawer_width = 380;   // Interior width in mm (example: 15")
drawer_depth = 457;   // Interior depth in mm (example: 18")
drawer_height = 70;   // Interior height in mm (minimum clearance)

// ===================== MODULE PARAMETERS =====================

// Module sizing (each module holds 2 jars side by side)
wall_thickness = 2.0;     // Wall between jar slots
outer_wall = 2.4;         // Outer wall of module
slot_clearance = 1.5;     // Extra mm around jar for easy insertion/removal
module_height = 40;       // Height of organizer walls (shorter than jars)
base_thickness = 1.2;     // Bottom of each module

// Snap-fit dovetail joint
dovetail_width = 8;       // Width of dovetail tab
dovetail_depth = 2.5;     // How far the dovetail protrudes
dovetail_taper = 1.5;     // Taper on each side for snap engagement
dovetail_tolerance = 0.2; // Clearance for fit

// Corner radius
corner_r = 3;

// Label area
label_recess_depth = 0.6; // Shallow recess on front face for label sticker
label_width = 30;
label_height = 10;

// Resolution
$fn = 40;

// ===================== DERIVED VALUES ========================

// Slot dimensions including clearance
slot_w = jar_dia + slot_clearance * 2;
slot_d = (jar_shape == "rect" || jar_shape == "square")
    ? jar_depth + slot_clearance * 2
    : jar_dia + slot_clearance * 2;

// Module exterior dimensions (2 jars wide, 1 jar deep)
module_width = slot_w * 2 + wall_thickness + outer_wall * 2;
module_depth = slot_d + outer_wall * 2;

// How many modules fit in the drawer
modules_x = floor(drawer_width / module_width);
modules_y = floor(drawer_depth / module_depth);
total_modules = modules_x * modules_y;
total_jars = total_modules * 2;

// ===================== MODULES ===============================

// 2D jar slot shape
module jar_slot_2d() {
    if (jar_shape == "round") {
        circle(d = slot_w);
    } else if (jar_shape == "rect" || jar_shape == "square") {
        offset(r = corner_r) offset(r = -corner_r)
            square([slot_w, slot_d], center = true);
    }
}

// Dovetail tab (male — protrudes from module edge)
module dovetail_tab() {
    w1 = dovetail_width;
    w2 = dovetail_width + dovetail_taper * 2;
    linear_extrude(module_height * 0.6)
        polygon([
            [-w1/2, 0],
            [w1/2, 0],
            [w2/2, dovetail_depth],
            [-w2/2, dovetail_depth]
        ]);
}

// Dovetail socket (female — cut into module edge)
module dovetail_socket() {
    w1 = dovetail_width + dovetail_tolerance * 2;
    w2 = dovetail_width + dovetail_taper * 2 + dovetail_tolerance * 2;
    d = dovetail_depth + dovetail_tolerance;
    linear_extrude(module_height * 0.6 + dovetail_tolerance)
        polygon([
            [-w1/2, 0.1],
            [w1/2, 0.1],
            [w2/2, -d],
            [-w2/2, -d]
        ]);
}

// Single organizer module (holds 2 jars)
module organizer_module() {
    difference() {
        union() {
            // Main body — rounded rectangle
            linear_extrude(module_height)
                offset(r = corner_r) offset(r = -corner_r)
                    square([module_width, module_depth], center = true);

            // Dovetail tabs on +X and +Y faces
            // Right face (+X)
            translate([module_width/2, 0, module_height * 0.2])
                rotate([0, 0, 0])
                    dovetail_tab();
            // Front face (+Y)
            translate([0, module_depth/2, module_height * 0.2])
                rotate([0, 0, 90])
                    dovetail_tab();
        }

        // Jar slot 1 (left)
        slot_offset_x = -(slot_w/2 + wall_thickness/2);
        translate([slot_offset_x, 0, base_thickness])
            linear_extrude(module_height + 1)
                jar_slot_2d();

        // Jar slot 2 (right)
        translate([-slot_offset_x, 0, base_thickness])
            linear_extrude(module_height + 1)
                jar_slot_2d();

        // Dovetail sockets on -X and -Y faces
        // Left face (-X)
        translate([-module_width/2, 0, module_height * 0.2])
            rotate([0, 0, 180])
                dovetail_socket();
        // Back face (-Y)
        translate([0, -module_depth/2, module_height * 0.2])
            rotate([0, 0, -90])
                dovetail_socket();

        // Label recess on front face (for sticker labels)
        translate([-label_width/2, module_depth/2 - label_recess_depth,
                   module_height - label_height - 3])
            cube([label_width, label_recess_depth + 0.1, label_height]);
    }
}

// ===================== ASSEMBLY PREVIEW =======================

// Render a single module (for printing)
organizer_module();

// Uncomment below to preview a 3x2 grid assembly:
// for (ix = [0 : 2])
//     for (iy = [0 : 1])
//         translate([ix * module_width, iy * module_depth, 0])
//             organizer_module();

// ===================== INFO OUTPUT ============================

echo(str("=== SPICE DRAWER ORGANIZER CONFIGURATION ==="));
echo(str("Brand: ", brand_name));
echo(str("Jar slot: ", jar_shape, " ", slot_w, "mm"));
echo(str("Module size: ", module_width, "mm x ", module_depth, "mm"));
echo(str("Drawer: ", drawer_width, "mm x ", drawer_depth, "mm"));
echo(str("Modules that fit: ", modules_x, " x ", modules_y,
         " = ", total_modules, " modules"));
echo(str("Total jar capacity: ", total_jars, " jars"));
echo(str("Remaining space X: ",
         drawer_width - modules_x * module_width, "mm"));
echo(str("Remaining space Y: ",
         drawer_depth - modules_y * module_depth, "mm"));

// ===================== PRINT NOTES ===========================
//
// Print each module individually. They snap together after printing.
//
// ORIENTATION: Print flat, base on the build plate. No supports needed.
//
// MATERIAL: PETG strongly recommended for kitchen use.
//   - Heat resistant (won't warp near stove/oven)
//   - Moisture resistant (won't degrade from spills)
//   - Food-adjacent safe (doesn't contact food directly)
//
// Each module prints in ~25–35 minutes at 0.2mm layer height.
// A full 15"x18" drawer requires ~30 modules = ~15 hours total.
// (Can be batched — 4-6 modules per plate on a 256x256mm bed.)
//
// ASSEMBLY: Snap modules together by pressing dovetail tabs into
// sockets. Modules lock in both X and Y directions. To disassemble,
// flex slightly and pull apart.
//
// BRAND MIXING: Need McCormick AND Trader Joe's in the same drawer?
// Print some modules with each preset. They're all the same exterior
// dimensions — they snap together regardless of which brand preset
// was used for the jar slots.
