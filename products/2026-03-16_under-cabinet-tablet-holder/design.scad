// Under-Cabinet Tablet/Phone Holder for Kitchen Recipes — Parametric Design
// Pipeline Cycle 5 — 2026-03-16
// Supports: iPhone, iPad Mini, iPad, Samsung Galaxy Tab, Custom
// Mount: Under-cabinet hook clamp (no screws, no adhesive)
// Same hook-clamp pattern as Cycle 4 K-Cup holder

/* [Device Preset] */
// Device type selection
device_preset = "iPhone"; // ["iPhone", "iPadMini", "iPad", "GalaxyTab", "Custom"]

/* [Custom Device Dimensions (only used when device_preset = Custom)] */
custom_device_width = 78;   // mm — width of device (portrait orientation)
custom_device_depth = 10;   // mm — thickness of device (with case)

/* [Holder Configuration] */
device_clearance = 2.0;     // mm — clearance on each side of device slot
shelf_angle = 75;           // [60:5:90] degrees — viewing angle (90 = vertical, 60 = tilted back)
lip_height = 15;            // mm — front lip preventing device from sliding out
back_support_height = 40;   // mm — how tall the back support rises

/* [Cabinet Mount] */
cabinet_thickness = 18;     // [12:1:30] mm — thickness of cabinet shelf
hook_depth = 25;            // mm — how far the hook extends into the cabinet
hook_gap_tolerance = 0.5;   // mm — extra clearance in the hook slot
hook_lip = 5;               // mm — lip that grips the top of the shelf

/* [Structural] */
wall_thickness = 2.5;       // mm
base_thickness = 2.0;       // mm — thickness of the device shelf
mount_arm_width = 20;       // mm — width of each mounting arm
fillet_radius = 2.0;        // mm

/* [Advanced] */
$fn = 48;

// ============================================================
// Device Dimension Database
// ============================================================

// Device dimensions: [width_mm, depth_mm (with case), display_name]
// Width = the narrow dimension (portrait). Device sits in landscape for recipes.
// Depth = thickness including a typical case
function device_dims(preset) =
    preset == "iPhone"      ? [78, 12, "iPhone (with case)"] :
    preset == "iPadMini"    ? [135, 12, "iPad Mini (with case)"] :
    preset == "iPad"        ? [179, 12, "iPad 10th gen (with case)"] :
    preset == "GalaxyTab"   ? [165, 12, "Samsung Galaxy Tab S (with case)"] :
    // Custom fallback
    [custom_device_width, custom_device_depth, "Custom device"];

// Resolved device dimensions
_dev = device_dims(device_preset);
_dev_width = _dev[0];
_dev_depth = _dev[1];

// Slot dimensions
_slot_width = _dev_width + device_clearance * 2;
_slot_depth = _dev_depth + device_clearance * 2;

// Shelf dimensions
_shelf_width = _slot_width + wall_thickness * 2;
_shelf_depth = _slot_depth + base_thickness + lip_height;

// ============================================================
// Info Echo
// ============================================================

echo("=== Under-Cabinet Tablet/Phone Holder Configuration ===");
echo(str("Device preset: ", device_preset));
echo(str("Device width: ", _dev_width, "mm"));
echo(str("Device depth (with case): ", _dev_depth, "mm"));
echo(str("Slot width: ", _slot_width, "mm"));
echo(str("Shelf width: ", _shelf_width, "mm"));
echo(str("Shelf angle: ", shelf_angle, " degrees"));
echo(str("Cabinet thickness: ", cabinet_thickness, "mm"));

// ============================================================
// Modules
// ============================================================

// Under-cabinet hook clamp — reused pattern from K-Cup holder (Cycle 4)
module cabinet_hook(width) {
    _hook_slot = cabinet_thickness + hook_gap_tolerance;
    _hook_total_height = _hook_slot + wall_thickness * 2;
    _hook_total_depth = hook_depth + wall_thickness;

    difference() {
        union() {
            // Top plate (sits on top of shelf)
            translate([0, 0, _hook_slot + wall_thickness])
                cube([width, _hook_total_depth, wall_thickness]);

            // Back wall (connects top and bottom)
            translate([0, _hook_total_depth - wall_thickness, 0])
                cube([width, wall_thickness, _hook_total_height]);

            // Bottom plate (goes under the shelf)
            translate([0, hook_depth * 0.3, 0])
                cube([width, _hook_total_depth - hook_depth * 0.3, wall_thickness]);

            // Front lip (prevents sliding off)
            translate([0, 0, _hook_slot + wall_thickness])
                cube([width, wall_thickness, wall_thickness + hook_lip]);
        }

        // Internal slot for cabinet shelf
        translate([-0.01, -0.01, wall_thickness])
            cube([width + 0.02, _hook_total_depth - wall_thickness + 0.01, _hook_slot]);
    }
}

// The angled device shelf
module device_shelf() {
    // Shelf base — angled platform where the device rests
    difference() {
        cube([_shelf_width, _shelf_depth, base_thickness]);

        // Device slot — a groove for the device bottom edge
        translate([wall_thickness, base_thickness, -0.01])
            cube([_slot_width, _slot_depth, base_thickness + 0.02]);
    }

    // Front lip — prevents device from sliding off the shelf
    translate([0, 0, 0])
        cube([_shelf_width, base_thickness, lip_height]);

    // Back support — keeps device upright at the set angle
    translate([0, _shelf_depth - wall_thickness, 0])
        cube([_shelf_width, wall_thickness, back_support_height]);

    // Side walls for device guidance
    // Left wall
    cube([wall_thickness, _shelf_depth, back_support_height * 0.6]);
    // Right wall
    translate([_shelf_width - wall_thickness, 0, 0])
        cube([wall_thickness, _shelf_depth, back_support_height * 0.6]);
}

// Mounting arm — connects hook clamp to angled shelf
module mount_arm() {
    _hook_height = cabinet_thickness + hook_gap_tolerance + wall_thickness * 2;
    _arm_length = 30; // mm — distance shelf hangs below cabinet

    // Vertical arm from hook down to shelf
    cube([mount_arm_width, wall_thickness * 2, _hook_height + _arm_length]);

    // Hook at the top
    translate([0, 0, _arm_length])
        cabinet_hook(mount_arm_width);
}

// ============================================================
// Assembly
// ============================================================

module complete_holder() {
    _hook_height = cabinet_thickness + hook_gap_tolerance + wall_thickness * 2;
    _arm_drop = 30; // how far below cabinet the shelf hangs

    // Angled device shelf
    rotate([-(90 - shelf_angle), 0, 0])
        device_shelf();

    // Left mounting arm
    translate([-mount_arm_width - 2, -wall_thickness, 0])
        mount_arm();

    // Right mounting arm
    translate([_shelf_width + 2, -wall_thickness, 0])
        mount_arm();

    // Cross brace connecting arms behind the shelf (rigidity)
    _brace_z = _arm_drop * 0.5;
    translate([-mount_arm_width - 2, 0, _brace_z])
        cube([_shelf_width + mount_arm_width * 2 + 4, wall_thickness, wall_thickness * 2]);
}

// Render the complete holder
complete_holder();

// ============================================================
// Print Notes
// ============================================================
// This design prints in 2-3 parts for larger devices:
//
// OPTION A (Small devices — phone):
//   Print as one piece, shelf flat on build plate, arms pointing up.
//   May need supports for the hook geometry.
//
// OPTION B (Large devices — iPad):
//   Print shelf and arms separately, join with M3 bolts or friction fit.
//   Shelf prints flat. Each arm prints vertically.
//
// For the STL bundle, we provide both single-piece and multi-part versions.
//
// Material: PETG recommended (kitchen steam/splash resistance)
// Infill: 30% for arms (structural), 20% for shelf
// Layer height: 0.2mm
