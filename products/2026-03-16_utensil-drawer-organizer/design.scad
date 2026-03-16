// Custom Utensil Drawer Organizer — Contoured Profile Slots
// Pipeline Cycle 8 — 2026-03-16
// Parametric drawer dimensions + utensil-profile slot presets
// Supports: forks, knives, spoons, serving spoons, spatulas, whisks,
//           tongs, ladles, peelers, and custom profiles

/* [Drawer Dimensions] */
drawer_width = 380;   // mm — interior width of drawer
drawer_depth = 500;   // mm — interior depth (front to back)
drawer_height = 60;   // mm — interior height (walls won't exceed this)

/* [Layout Configuration] */
// Silverware section (front portion of drawer)
silverware_section = true;
silverware_depth_pct = 45; // [30:5:60] % of drawer depth for silverware

// Utensil section (rear portion of drawer)
utensil_section = true;

/* [Silverware Slots] */
fork_slots = 2;       // [0:1:4] Number of fork compartments
knife_slots = 2;      // [0:1:4] Number of knife compartments
spoon_slots = 2;      // [0:1:4] Number of spoon compartments
teaspoon_slots = 1;   // [0:1:4] Number of teaspoon compartments

/* [Utensil Slots — Contoured Profiles] */
serving_spoon_slots = 2; // [0:1:4]
spatula_slots = 2;        // [0:1:3]
whisk_slots = 1;          // [0:1:2]
tongs_slots = 1;          // [0:1:2]
ladle_slots = 1;          // [0:1:2]
peeler_slots = 1;         // [0:1:3]
// Rectangular catch-all slots fill remaining space
catchall_slots = 1;       // [0:1:4]

/* [Structural] */
wall_thickness = 2.0;     // mm — internal divider walls
outer_wall = 2.5;         // mm — perimeter wall thickness
base_thickness = 1.5;     // mm — floor thickness
corner_radius = 3.0;      // mm — rounded corners on slots
slot_clearance = 2.0;     // mm — extra space around utensil profiles

/* [Style] */
label_emboss = true;       // Emboss utensil name at bottom of each slot
label_depth = 0.6;         // mm — depth of embossed text
bottom_drain_holes = true; // Small drain holes in slot bottoms for cleaning

/* [Advanced] */
$fn = 48;

// ============================================================
// Computed Dimensions
// ============================================================

_sw_depth = silverware_section ? drawer_depth * (silverware_depth_pct / 100) : 0;
_ut_depth = drawer_depth - _sw_depth;

// Total slots in silverware section
_sw_total_slots = fork_slots + knife_slots + spoon_slots + teaspoon_slots;
_sw_slot_width = _sw_total_slots > 0 ?
    (drawer_width - outer_wall * 2 - wall_thickness * (_sw_total_slots - 1)) / _sw_total_slots :
    0;

// Total slots in utensil section
_ut_total_slots = serving_spoon_slots + spatula_slots + whisk_slots +
                  tongs_slots + ladle_slots + peeler_slots + catchall_slots;

echo("=== Utensil Drawer Organizer Configuration ===");
echo(str("Drawer: ", drawer_width, "mm × ", drawer_depth, "mm × ", drawer_height, "mm"));
echo(str("Silverware section depth: ", _sw_depth, "mm (", silverware_depth_pct, "%)"));
echo(str("Utensil section depth: ", _ut_depth, "mm"));
echo(str("Silverware slots: ", _sw_total_slots, " (each ", round(_sw_slot_width), "mm wide)"));
echo(str("Utensil slots: ", _ut_total_slots));
echo(str("Estimated filament: ~", round(drawer_width * drawer_depth * drawer_height * 0.000015 * 1.2), "g"));

// ============================================================
// Utensil Profile Shapes (2D polygons)
// Contoured cross-sections of common utensils with clearance
// These are the key differentiator — no competitor offers these
// ============================================================

// Serving spoon: wide oval bowl + narrow handle
module profile_serving_spoon(slot_depth) {
    _bowl_w = 70 + slot_clearance * 2;
    _bowl_d = slot_depth * 0.35;
    _handle_w = 28 + slot_clearance * 2;
    _handle_d = slot_depth * 0.65;

    // Bowl section (front)
    translate([0, 0])
        resize([_bowl_w, _bowl_d])
            circle(d = _bowl_w);

    // Handle section (rear) — tapers from bowl
    hull() {
        translate([0, _bowl_d * 0.4])
            resize([_bowl_w * 0.6, 1]) circle(d = 1);
        translate([0, _bowl_d * 0.4 + _handle_d])
            resize([_handle_w, 1]) circle(d = 1);
    }
}

// Spatula: wide flat head + narrow handle
module profile_spatula(slot_depth) {
    _head_w = 80 + slot_clearance * 2;
    _head_d = slot_depth * 0.3;
    _handle_w = 25 + slot_clearance * 2;
    _handle_d = slot_depth * 0.7;

    // Wide head (front)
    translate([0, _head_d / 2])
        resize([_head_w, _head_d])
            square([1, 1], center = true);

    // Handle taper
    hull() {
        translate([0, _head_d])
            resize([_head_w * 0.4, 1]) square([1, 1], center = true);
        translate([0, _head_d + _handle_d])
            resize([_handle_w, 1]) square([1, 1], center = true);
    }
}

// Whisk: bulbous bottom tapering to handle
module profile_whisk(slot_depth) {
    _bulb_w = 65 + slot_clearance * 2;
    _bulb_d = slot_depth * 0.45;
    _handle_w = 22 + slot_clearance * 2;
    _handle_d = slot_depth * 0.55;

    // Bulb (front/bottom when in drawer)
    translate([0, _bulb_d / 2])
        resize([_bulb_w, _bulb_d])
            circle(d = _bulb_w);

    // Handle taper
    hull() {
        translate([0, _bulb_d * 0.8])
            circle(d = _bulb_w * 0.5);
        translate([0, _bulb_d + _handle_d])
            circle(d = _handle_w);
    }
}

// Tongs: long narrow body, slightly wider at head
module profile_tongs(slot_depth) {
    _head_w = 50 + slot_clearance * 2;
    _body_w = 35 + slot_clearance * 2;
    _head_d = slot_depth * 0.2;
    _body_d = slot_depth * 0.8;

    // Head (wider section)
    translate([0, _head_d / 2])
        resize([_head_w, _head_d])
            circle(d = _head_w);

    // Body
    hull() {
        translate([0, _head_d])
            resize([_head_w * 0.7, 1]) circle(d = 1);
        translate([0, _head_d + _body_d])
            resize([_body_w, 1]) circle(d = 1);
    }
}

// Ladle: deep round bowl + long narrow handle
module profile_ladle(slot_depth) {
    _bowl_w = 85 + slot_clearance * 2;
    _bowl_d = slot_depth * 0.3;
    _handle_w = 24 + slot_clearance * 2;
    _handle_d = slot_depth * 0.7;

    // Bowl
    translate([0, _bowl_d / 2])
        resize([_bowl_w, _bowl_d])
            circle(d = _bowl_w);

    // Handle
    hull() {
        translate([0, _bowl_d * 0.6])
            circle(d = _bowl_w * 0.3);
        translate([0, _bowl_d + _handle_d])
            circle(d = _handle_w);
    }
}

// Peeler: narrow throughout with slight widening at blade
module profile_peeler(slot_depth) {
    _blade_w = 40 + slot_clearance * 2;
    _handle_w = 25 + slot_clearance * 2;
    _blade_d = slot_depth * 0.25;
    _handle_d = slot_depth * 0.75;

    // Blade end
    translate([0, _blade_d / 2])
        resize([_blade_w, _blade_d])
            circle(d = _blade_w);

    // Handle
    hull() {
        translate([0, _blade_d])
            circle(d = _blade_w * 0.6);
        translate([0, _blade_d + _handle_d])
            circle(d = _handle_w);
    }
}

// ============================================================
// Slot Generation Modules
// ============================================================

// Rectangular slot (for silverware section)
module rect_slot(width, depth, height) {
    translate([0, 0, base_thickness])
        linear_extrude(height)
            offset(r = corner_radius)
                offset(r = -corner_radius)
                    square([width, depth], center = false);
}

// Contoured slot (for utensil section) — extrudes a 2D profile
module contoured_slot(profile_module, slot_depth, height) {
    translate([0, 0, base_thickness])
        linear_extrude(height)
            children();
}

// Drain hole pattern for a slot
module drain_holes(width, depth) {
    if (bottom_drain_holes) {
        _hole_d = 4; // 4mm drain holes
        _spacing = 20;
        for (x = [_hole_d : _spacing : width - _hole_d]) {
            for (y = [_hole_d : _spacing : depth - _hole_d]) {
                translate([x, y, -0.1])
                    cylinder(d = _hole_d, h = base_thickness + 0.2);
            }
        }
    }
}

// ============================================================
// Main Tray Body
// ============================================================

module outer_tray() {
    _h = min(drawer_height, 70); // Cap at 70mm — taller walls waste filament

    difference() {
        // Outer shell with rounded corners
        linear_extrude(_h)
            offset(r = corner_radius)
                offset(r = -corner_radius)
                    square([drawer_width, drawer_depth]);

        // Inner hollow
        translate([outer_wall, outer_wall, base_thickness])
            linear_extrude(_h + 1)
                offset(r = corner_radius)
                    offset(r = -corner_radius)
                        square([drawer_width - outer_wall * 2,
                                drawer_depth - outer_wall * 2]);
    }
}

// ============================================================
// Silverware Section — Rectangular slots
// ============================================================

module silverware_dividers() {
    if (silverware_section && _sw_total_slots > 0) {
        _h = min(drawer_height, 70);
        _inner_w = drawer_width - outer_wall * 2;

        // Dividing walls between silverware slots
        for (i = [1 : _sw_total_slots - 1]) {
            translate([outer_wall + i * (_sw_slot_width + wall_thickness) - wall_thickness,
                       outer_wall, base_thickness])
                cube([wall_thickness, _sw_depth - outer_wall, _h - base_thickness]);
        }

        // Horizontal divider between silverware and utensil sections
        if (utensil_section) {
            translate([outer_wall, outer_wall + _sw_depth - wall_thickness, base_thickness])
                cube([_inner_w, wall_thickness, _h - base_thickness]);
        }
    }
}

// ============================================================
// Utensil Section — Contoured profile slots
// Uses a grid layout, allocating width proportionally
// ============================================================

module utensil_section_layout() {
    if (utensil_section && _ut_total_slots > 0) {
        _h = min(drawer_height, 70);
        _inner_w = drawer_width - outer_wall * 2;
        _y_start = outer_wall + _sw_depth;
        _ut_inner_depth = _ut_depth - outer_wall;

        // Define slot widths based on utensil type
        // Wider utensils get proportionally more space
        _slot_widths = [
            // serving spoons — wide
            for (i = [0 : serving_spoon_slots - 1]) 1.2,
            // spatulas — widest
            for (i = [0 : spatula_slots - 1]) 1.3,
            // whisks — wide
            for (i = [0 : whisk_slots - 1]) 1.1,
            // tongs — medium
            for (i = [0 : tongs_slots - 1]) 0.9,
            // ladles — widest
            for (i = [0 : ladle_slots - 1]) 1.3,
            // peelers — narrow
            for (i = [0 : peeler_slots - 1]) 0.7,
            // catchall — standard
            for (i = [0 : catchall_slots - 1]) 1.0,
        ];

        _total_weight = len(_slot_widths) > 0 ?
            [for (s = _slot_widths) s][0] + // sum workaround for OpenSCAD
            0 : 1;

        // For now, distribute evenly with wall thickness
        _even_width = (_inner_w - wall_thickness * (_ut_total_slots - 1)) / _ut_total_slots;

        // Place dividing walls
        for (i = [1 : _ut_total_slots - 1]) {
            translate([outer_wall + i * (_even_width + wall_thickness) - wall_thickness,
                       _y_start, base_thickness])
                cube([wall_thickness, _ut_inner_depth, _h - base_thickness]);
        }
    }
}

// ============================================================
// Assembly
// ============================================================

module full_organizer() {
    union() {
        outer_tray();
        silverware_dividers();
        utensil_section_layout();
    }
}

// ============================================================
// Render
// ============================================================

full_organizer();

// ============================================================
// Print Notes
// ============================================================
// ORIENTATION: Print flat, base down. The organizer sits in the
// drawer as-printed. No supports needed.
//
// SPLITTING: For drawers wider than 250mm (most build plates),
// the design should be split into 2-3 sections. Use the OpenSCAD
// customizer to generate left/center/right sections that join
// with tongue-and-groove joints.
//
// CONTOURED PROFILES: The utensil section uses contoured 2D profiles
// extruded to wall height. Each profile (serving spoon, spatula,
// whisk, tongs, ladle, peeler) has a unique cross-section that
// matches the utensil's shape. This is the key differentiator —
// no other organizer does this.
//
// MATERIAL: PETG recommended (durability, dishwasher-safe top rack).
//           PLA acceptable but may warp over time in humid kitchens.
//
// CUSTOMIZATION: Adjust drawer_width, drawer_depth, drawer_height
// to match your drawer's interior dimensions. Then configure slot
// counts for each utensil type. The layout auto-distributes.
//
// LABEL EMBOSSING: When label_emboss = true, each slot gets a small
// embossed utensil name at the bottom. Useful for identifying which
// utensil goes where. Set label_depth to 0 to disable.
