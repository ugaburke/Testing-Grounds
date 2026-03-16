// Modular Pet Puzzle Feeder with Swappable Difficulty Inserts
// Pipeline Cycle 6 — 2026-03-16
// 4 difficulty levels: sliding panel, rotating disc, maze gates, combination
// Base tray with universal insert slot system

/* [Dog Size Preset] */
dog_size = "Standard"; // ["Standard", "Puppy", "Large", "Custom"]

/* [Custom Dimensions (only used when dog_size = Custom)] */
custom_base_width = 250;    // mm
custom_base_depth = 250;    // mm
custom_compartment_depth = 30; // mm — depth of treat compartments

/* [Base Configuration] */
num_compartments = 6;       // [4:1:9] Number of treat compartments
compartment_clearance = 1.0; // mm — clearance for insert sliding

/* [Insert Selection] */
// Which insert to render (or render base only)
render_part = "base"; // ["base", "level1_slider", "level2_rotator", "level3_maze", "level4_combo", "all_inserts"]

/* [Structural] */
wall_thickness = 3.0;       // mm — thicker for pet durability
base_thickness = 3.0;       // mm — strong base for pawing/nosing
insert_thickness = 2.5;     // mm
corner_radius = 8.0;        // mm — rounded corners for safety
insert_rail_height = 4.0;   // mm — height of the rail guides
insert_rail_width = 3.0;    // mm — width of rail channel

/* [Advanced] */
$fn = 48;

// ============================================================
// Dog Size Database
// ============================================================

// Dimensions: [base_width, base_depth, compartment_depth, compartment_width]
function size_dims(size) =
    size == "Puppy"    ? [180, 180, 22, 45] :
    size == "Standard" ? [250, 250, 30, 60] :
    size == "Large"    ? [320, 320, 38, 75] :
    // Custom
    [custom_base_width, custom_base_depth, custom_compartment_depth, custom_base_width / num_compartments - wall_thickness];

_dims = size_dims(dog_size);
_base_w = _dims[0];
_base_d = _dims[1];
_comp_depth = _dims[2];
_comp_w = _dims[3];

// Insert slot dimensions
_insert_w = _base_w - wall_thickness * 2 - compartment_clearance * 2;
_insert_d = _base_d - wall_thickness * 2 - compartment_clearance * 2;

// ============================================================
// Info Echo
// ============================================================

echo("=== Modular Pet Puzzle Feeder Configuration ===");
echo(str("Dog size: ", dog_size));
echo(str("Base: ", _base_w, "x", _base_d, "mm"));
echo(str("Compartments: ", num_compartments));
echo(str("Compartment depth: ", _comp_depth, "mm"));
echo(str("Insert area: ", _insert_w, "x", _insert_d, "mm"));
echo(str("Rendering: ", render_part));

// ============================================================
// Helper Modules
// ============================================================

// Rounded rectangle (2D profile)
module rounded_rect_2d(w, d, r) {
    offset(r) offset(-r) square([w, d], center = true);
}

// Rounded box
module rounded_box(w, d, h, r) {
    linear_extrude(h)
        rounded_rect_2d(w, d, r);
}

// ============================================================
// Base Tray
// ============================================================

module base_tray() {
    difference() {
        // Outer shell — rounded rectangle
        rounded_box(_base_w, _base_d, _comp_depth + base_thickness, corner_radius);

        // Inner cavity — where treats go and inserts sit
        translate([0, 0, base_thickness])
            rounded_box(
                _base_w - wall_thickness * 2,
                _base_d - wall_thickness * 2,
                _comp_depth + 1,
                corner_radius - wall_thickness
            );
    }

    // Compartment dividers — radial pattern from center
    for (i = [0 : num_compartments - 1]) {
        angle = i * (360 / num_compartments);
        rotate([0, 0, angle])
            translate([0, 0, base_thickness])
                cube([wall_thickness, _base_w / 2 - wall_thickness - 2, _comp_depth * 0.6], center = false);
    }

    // Insert rail guides — two parallel rails along the long axis
    // These guide the insert panels into position
    _rail_y = _base_d / 2 - wall_thickness - insert_rail_width / 2 - 1;
    for (side = [-1, 1]) {
        translate([0, side * _rail_y, base_thickness + _comp_depth - insert_rail_height])
            cube([_insert_w - 10, insert_rail_width, insert_rail_height], center = true);
    }

    // Anti-slip feet — small bumps on the bottom
    for (x = [-1, 1], y = [-1, 1]) {
        translate([x * (_base_w / 2 - 15), y * (_base_d / 2 - 15), -2])
            cylinder(d = 12, h = 2);
    }
}

// ============================================================
// Level 1 — Sliding Panel Insert
// ============================================================
// Simple sliding covers over compartments. Dog noses/paws the panel
// to slide it and reveal treats underneath.

module level1_slider() {
    // Main panel that slides across the base
    _panel_w = _insert_w * 0.48; // Each panel covers half the base
    _panel_d = _insert_d - 4;

    for (half = [0, 1]) {
        translate([half * (_panel_w + 4) - _insert_w / 2 + 2, 0, 0]) {
            difference() {
                // Panel body
                cube([_panel_w, _panel_d, insert_thickness], center = true);

                // Finger/nose holes for gripping
                for (i = [-1, 0, 1]) {
                    translate([i * (_panel_w / 3), 0, 0])
                        cylinder(d = 15, h = insert_thickness + 1, center = true);
                }
            }

            // Rail runners on the edges
            for (side = [-1, 1]) {
                translate([0, side * (_panel_d / 2 - insert_rail_width / 2), insert_thickness / 2])
                    cube([_panel_w - 4, insert_rail_width - compartment_clearance, insert_rail_height - 0.5], center = true);
            }
        }
    }
}

// ============================================================
// Level 2 — Rotating Disc Insert
// ============================================================
// A disc that rotates on a center post. Treat holes in the disc
// align with compartments only at certain rotations.

module level2_rotator() {
    _disc_dia = min(_insert_w, _insert_d) - 10;

    // Rotating disc
    difference() {
        cylinder(d = _disc_dia, h = insert_thickness);

        // Center pivot hole
        translate([0, 0, -0.5])
            cylinder(d = 8, h = insert_thickness + 1);

        // Treat access holes — offset from center
        for (i = [0 : num_compartments - 1]) {
            angle = i * (360 / num_compartments) + 15; // Offset so not aligned by default
            translate([cos(angle) * _disc_dia * 0.3, sin(angle) * _disc_dia * 0.3, -0.5])
                cylinder(d = 20, h = insert_thickness + 1);
        }

        // Nose push tab cutout
        translate([_disc_dia / 2 - 15, 0, -0.5])
            cylinder(d = 12, h = insert_thickness + 1);
    }

    // Center post (prints with the disc, inserts into base center)
    translate([0, 0, -8])
        cylinder(d = 7.5, h = 8);

    // Locking tabs — small bumps that click into notches at correct alignment
    for (i = [0 : 3]) {
        angle = i * 90;
        translate([cos(angle) * (_disc_dia / 2 - 5), sin(angle) * (_disc_dia / 2 - 5), insert_thickness])
            sphere(d = 3);
    }
}

// ============================================================
// Level 3 — Sequential Maze Insert
// ============================================================
// Sliding gates in sequence. Must open gate A before gate B is accessible.
// Creates a maze path to the treats.

module level3_maze() {
    _maze_w = _insert_w - 8;
    _maze_d = _insert_d - 8;
    _gate_w = _maze_w / 3;
    _channel_w = 18; // Width of the sliding channel

    // Base frame
    difference() {
        cube([_maze_w, _maze_d, insert_thickness * 1.5], center = true);

        // Three sliding gate channels
        for (i = [-1, 0, 1]) {
            translate([i * _gate_w, 0, 0])
                cube([_channel_w, _maze_d - 10, insert_thickness * 1.5 + 1], center = true);
        }

        // Treat access holes between gates
        for (i = [0, 1]) {
            translate([(i - 0.5) * _gate_w, 0, 0])
                cube([_gate_w - _channel_w - 4, _maze_d - 20, insert_thickness * 1.5 + 1], center = true);
        }
    }

    // Sliding gates (3 separate pieces)
    for (i = [-1, 0, 1]) {
        translate([i * _gate_w, _maze_d / 2 + 15, 0]) {
            difference() {
                cube([_channel_w - compartment_clearance * 2, _maze_d - 12, insert_thickness], center = true);

                // Nose hole
                cylinder(d = 12, h = insert_thickness + 1, center = true);
            }
        }
    }
}

// ============================================================
// Level 4 — Multi-Step Combination Insert
// ============================================================
// Combines sliding, rotating, and lifting. The hardest level.
// A rotating disc sits above sliding panels with locking pegs.

module level4_combo() {
    _combo_w = _insert_w - 8;
    _combo_d = _insert_d - 8;

    // Bottom layer — sliding panel (like Level 1 but with peg holes)
    difference() {
        cube([_combo_w, _combo_d * 0.45, insert_thickness], center = true);

        // Peg holes that lock the rotating top
        for (x = [-1, 1]) {
            translate([x * (_combo_w / 4), 0, 0])
                cylinder(d = 6, h = insert_thickness + 1, center = true);
        }

        // Nose grip
        cylinder(d = 15, h = insert_thickness + 1, center = true);
    }

    // Top layer — small rotating disc with locking pegs
    translate([0, 0, insert_thickness + 2]) {
        difference() {
            cylinder(d = _combo_w * 0.6, h = insert_thickness);

            // Center pivot
            translate([0, 0, -0.5])
                cylinder(d = 8, h = insert_thickness + 1);

            // Treat holes
            for (i = [0 : 3]) {
                angle = i * 90 + 22.5;
                translate([cos(angle) * _combo_w * 0.2, sin(angle) * _combo_w * 0.2, -0.5])
                    cylinder(d = 18, h = insert_thickness + 1);
            }
        }

        // Locking pegs (must be pulled before disc rotates)
        for (x = [-1, 1]) {
            translate([x * (_combo_w / 4), 0, insert_thickness])
                cylinder(d = 5.5, h = 6);
        }
    }
}

// ============================================================
// Render Selection
// ============================================================

if (render_part == "base") {
    base_tray();
} else if (render_part == "level1_slider") {
    level1_slider();
} else if (render_part == "level2_rotator") {
    level2_rotator();
} else if (render_part == "level3_maze") {
    level3_maze();
} else if (render_part == "level4_combo") {
    level4_combo();
} else if (render_part == "all_inserts") {
    // Layout all inserts for display
    translate([-_base_w * 0.6, 0, 0]) level1_slider();
    translate([0, 0, 0]) level2_rotator();
    translate([_base_w * 0.6, 0, 0]) level3_maze();
    translate([0, _base_d * 0.6, 0]) level4_combo();
}

// ============================================================
// Print Notes
// ============================================================
// BASE TRAY:
//   Print upright (as oriented). No supports needed.
//   PETG required for food safety (apply food-safe epoxy after printing).
//   30% infill for durability against pawing/nosing.
//   ~80g, ~2.5 hours for Standard size.
//
// LEVEL 1 (Sliding Panels):
//   Print flat. No supports. 2 panels per set.
//   ~20g total, ~40 minutes.
//
// LEVEL 2 (Rotating Disc):
//   Print flat, disc side up. Center post prints downward (flip for printing).
//   ~25g, ~50 minutes.
//
// LEVEL 3 (Maze + Gates):
//   Print frame flat. Print 3 gates separately.
//   ~30g total, ~1 hour.
//
// LEVEL 4 (Combination):
//   Print bottom panel flat. Print top disc flat. Print pegs with disc.
//   ~25g, ~50 minutes.
//
// FOOD SAFETY:
//   After printing, sand surfaces smooth (220 grit).
//   Apply 2 coats food-safe epoxy (ArtResin or equivalent).
//   Allow 72-hour cure before use.
//   Hand wash only — no dishwasher.
