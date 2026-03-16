// FIFO Gravity-Feed Can Dispenser — Parametric Design
// Pipeline Cycle 7 — 2026-03-16
// Supports: 12oz beverage, 12oz food, 15oz (#303), 28oz (#2.5), Custom
// Parametric shelf depth: 10", 12", 14", 16"
// Modular lane system — print single lanes, snap together

/* [Can Size Preset] */
can_preset = "15oz"; // ["12oz_bev", "12oz_food", "15oz", "28oz", "Custom"]

/* [Custom Can Dimensions (only when can_preset = Custom)] */
custom_can_dia = 81;    // mm — diameter of custom can
custom_can_height = 113; // mm — height of custom can

/* [Shelf Configuration] */
shelf_depth_inches = 12; // [10:1:16] Pantry shelf depth in inches
cans_per_lane = 6;       // [4:1:8] Number of cans the lane holds

/* [Structural] */
wall_thickness = 2.0;    // mm
base_thickness = 2.0;    // mm
side_wall_height_pct = 40; // [30:5:60] % of can height for side walls
ramp_angle = 8;          // [5:1:15] degrees — slope for gravity feed
can_clearance = 2.0;     // mm — clearance on each side of can
snap_tab_width = 8;      // mm — width of snap connector tabs
snap_tab_depth = 2.0;    // mm — depth of snap tab protrusion

/* [Advanced] */
$fn = 48;
// Set to true to render the snap connectors for multi-lane assembly
render_connectors = true;

// ============================================================
// Can Dimension Database
// ============================================================

// Can dimensions: [diameter_mm, height_mm, label]
function can_dims(preset) =
    preset == "12oz_bev"  ? [66, 123, "12oz Beverage"] :
    preset == "12oz_food" ? [68, 101, "12oz Food (#1)"] :
    preset == "15oz"      ? [81, 113, "15oz (#303)"] :
    preset == "28oz"      ? [103, 119, "28oz (#2.5)"] :
    [custom_can_dia, custom_can_height, "Custom"];

_can = can_dims(can_preset);
_can_dia = _can[0];
_can_h = _can[1];

// Shelf depth in mm
_shelf_depth = shelf_depth_inches * 25.4;

// Lane dimensions
_lane_width = _can_dia + can_clearance * 2 + wall_thickness * 2;
_lane_depth = _shelf_depth - 5; // 5mm clearance from shelf edge
_side_wall_h = _can_h * (side_wall_height_pct / 100);

// Ramp geometry
_ramp_rise = _lane_depth * tan(ramp_angle);

// Loading slot height (top-rear opening)
_load_slot_h = _can_h + 10; // Can height + clearance for dropping in

// Dispense slot height (bottom-front opening)
_dispense_slot_h = _can_h + 5;

// Total lane height
_lane_height = _ramp_rise + _can_h + 15; // Rise + can + margin

// ============================================================
// Info Echo
// ============================================================

echo("=== FIFO Can Dispenser Configuration ===");
echo(str("Can preset: ", can_preset, " (", _can[2], ")"));
echo(str("Can diameter: ", _can_dia, "mm"));
echo(str("Can height: ", _can_h, "mm"));
echo(str("Shelf depth: ", shelf_depth_inches, "\" (", _shelf_depth, "mm)"));
echo(str("Cans per lane: ", cans_per_lane));
echo(str("Lane width: ", _lane_width, "mm"));
echo(str("Lane depth: ", _lane_depth, "mm"));
echo(str("Ramp angle: ", ramp_angle, " degrees"));
echo(str("Ramp rise: ", _ramp_rise, "mm"));
echo(str("Estimated filament: ~", round(_lane_width * _lane_depth * _lane_height * 0.00003 * 1.2), "g"));

// ============================================================
// Modules
// ============================================================

// The main ramp surface — angled floor for gravity feed
module ramp_floor() {
    // Angled bottom surface
    hull() {
        // Front-bottom edge (dispense end)
        translate([0, 0, base_thickness])
            cube([_lane_width, base_thickness, 0.01]);

        // Rear-top edge (loading end)
        translate([0, _lane_depth - base_thickness, base_thickness + _ramp_rise])
            cube([_lane_width, base_thickness, 0.01]);
    }

    // Solid base under the ramp
    cube([_lane_width, _lane_depth, base_thickness]);
}

// Side walls — keep cans from rolling off
module side_walls() {
    // Left wall
    hull() {
        translate([0, 0, 0])
            cube([wall_thickness, _lane_depth, _side_wall_h]);
        translate([0, _lane_depth - wall_thickness, _ramp_rise])
            cube([wall_thickness, wall_thickness, _side_wall_h]);
    }

    // Right wall
    hull() {
        translate([_lane_width - wall_thickness, 0, 0])
            cube([wall_thickness, _lane_depth, _side_wall_h]);
        translate([_lane_width - wall_thickness, _lane_depth - wall_thickness, _ramp_rise])
            cube([wall_thickness, wall_thickness, _side_wall_h]);
    }
}

// Front stop — prevents cans from rolling out (with dispense opening)
module front_stop() {
    _stop_height = _can_dia * 0.4; // Partial wall — can is grabbed from above

    // Front wall with dispense opening
    difference() {
        cube([_lane_width, wall_thickness * 2, _stop_height]);

        // Dispense opening — sized for one can to be pulled out
        translate([wall_thickness + can_clearance, -0.01, base_thickness])
            cube([_can_dia + can_clearance, wall_thickness * 2 + 0.02, _stop_height]);
    }
}

// Rear loading guide — angled lip to guide cans into the lane
module rear_loading_guide() {
    translate([0, _lane_depth - wall_thickness * 2, _ramp_rise]) {
        // Rear wall — short, just to guide cans
        cube([_lane_width, wall_thickness * 2, _can_dia * 0.3]);
    }
}

// Snap connector tabs — for joining multiple lanes side by side
module snap_connectors() {
    if (render_connectors) {
        // Right side — protruding tabs
        for (y_pos = [_lane_depth * 0.25, _lane_depth * 0.75]) {
            translate([_lane_width, y_pos - snap_tab_width / 2, _side_wall_h * 0.3]) {
                // Tab
                cube([snap_tab_depth, snap_tab_width, snap_tab_width]);
            }
        }

        // Left side — receiving slots (cut into wall)
        // These are cut as part of the difference in the main assembly
    }
}

module snap_connector_cutouts() {
    if (render_connectors) {
        for (y_pos = [_lane_depth * 0.25, _lane_depth * 0.75]) {
            translate([-snap_tab_depth - 0.1, y_pos - snap_tab_width / 2 - 0.15, _side_wall_h * 0.3 - 0.15]) {
                cube([snap_tab_depth + 0.2, snap_tab_width + 0.3, snap_tab_width + 0.3]);
            }
        }
    }
}

// ============================================================
// Assembly — Single Lane
// ============================================================

module single_lane() {
    difference() {
        union() {
            ramp_floor();
            side_walls();
            front_stop();
            rear_loading_guide();
            snap_connectors();
        }

        // Cut snap connector receiving slots on the left side
        snap_connector_cutouts();
    }
}

// ============================================================
// Render
// ============================================================

single_lane();

// ============================================================
// Print Notes
// ============================================================
// ORIENTATION: Print with the front (dispense end) facing down on the
// build plate. The ramp angle creates a slight slope — if printed flat,
// the ramp is built into the geometry and needs no supports.
//
// ALTERNATIVE: Print flat (ramp side down). The slight angle means the
// base sits flat on the build plate and the ramp is the natural top surface.
// This is the recommended orientation — no supports needed.
//
// MODULAR ASSEMBLY:
// - Print multiple lanes separately
// - Snap tabs on right side fit into slots on left side of adjacent lane
// - Push together firmly — PETG flex allows snap-fit
// - For permanent assembly, add a drop of CA glue
//
// MATERIAL: PETG recommended (pantry temperature stability, durability)
//           PLA acceptable (pantry is a dry, room-temp environment)
//
// FILAMENT OPTIMIZATION:
// The rebeltaz design uses ~1000g per unit. Our modular lane design uses
// ~150-200g per lane depending on can size and shelf depth. A 3-lane
// setup uses ~500g — half the rebeltaz monolith for more capacity.
