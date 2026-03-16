// Under-Cabinet K-Cup / Coffee Pod Holder — Parametric Design
// Pipeline Cycle 4 — 2026-03-16
// Supports: K-Cup, Nespresso Vertuo, Nespresso Original
// Mount: Under-cabinet hook clamp (no screws, no adhesive)

/* [Pod Type Preset] */
// Pod type selection
pod_preset = "KCup"; // ["KCup", "NespressoVertuo", "NespressoOriginal", "Custom"]

/* [Custom Pod Dimensions (only used when pod_preset = Custom)] */
custom_pod_top_dia = 48;    // mm — top diameter of custom pod
custom_pod_bottom_dia = 35; // mm — bottom diameter of custom pod
custom_pod_height = 42;     // mm — height of custom pod

/* [Holder Configuration] */
pods_per_rail = 6;          // [3:1:10] Number of pods per rail
pod_clearance = 1.5;        // mm — clearance around each pod

/* [Cabinet Mount] */
cabinet_thickness = 18;     // [12:1:30] mm — thickness of cabinet shelf
hook_depth = 25;            // mm — how far the hook extends into the cabinet
hook_gap_tolerance = 0.5;   // mm — extra clearance in the hook slot
hook_lip = 5;               // mm — lip that grips the top of the shelf

/* [Structural] */
wall_thickness = 2.0;       // mm
base_thickness = 1.2;       // mm
rail_thickness = 3.0;       // mm — thickness of the horizontal rail
fillet_radius = 1.5;        // mm — edge fillets for printability

/* [Advanced] */
$fn = 48;                   // Circle resolution

// ============================================================
// Pod Dimension Database
// ============================================================

// Pod dimensions: [top_dia, bottom_dia, height]
function pod_dims(preset) =
    preset == "KCup"             ? [48, 35, 42] :
    preset == "NespressoVertuo"  ? [56, 50, 54] :
    preset == "NespressoOriginal"? [37, 37, 26] :
    // Custom fallback
    [custom_pod_top_dia, custom_pod_bottom_dia, custom_pod_height];

// Resolved pod dimensions
_pod = pod_dims(pod_preset);
_pod_top_dia    = _pod[0];
_pod_bottom_dia = _pod[1];
_pod_height     = _pod[2];

// Slot dimensions (top diameter + clearance)
_slot_dia = _pod_top_dia + pod_clearance * 2;

// Pod spacing (center-to-center)
_pod_spacing = _slot_dia + wall_thickness;

// Rail total length
_rail_length = pods_per_rail * _pod_spacing + wall_thickness;

// Rail total width (single pod wide + walls)
_rail_width = _slot_dia + wall_thickness * 2;

// Rail height (enough to hold pod securely — ~60% of pod height)
_rail_height = _pod_height * 0.6;

// ============================================================
// Info Echo
// ============================================================

echo("=== Under-Cabinet Pod Holder Configuration ===");
echo(str("Pod preset: ", pod_preset));
echo(str("Pod top diameter: ", _pod_top_dia, "mm"));
echo(str("Pod bottom diameter: ", _pod_bottom_dia, "mm"));
echo(str("Pod height: ", _pod_height, "mm"));
echo(str("Slot diameter (with clearance): ", _slot_dia, "mm"));
echo(str("Pods per rail: ", pods_per_rail));
echo(str("Rail length: ", _rail_length, "mm"));
echo(str("Rail width: ", _rail_width, "mm"));
echo(str("Rail height: ", _rail_height, "mm"));
echo(str("Cabinet thickness: ", cabinet_thickness, "mm"));
echo(str("Hook depth: ", hook_depth, "mm"));

// ============================================================
// Modules
// ============================================================

// Rounded rectangle (2D)
module rounded_rect(w, h, r) {
    offset(r) offset(-r) square([w, h], center = true);
}

// Tapered pod slot — wider at top, narrower at bottom
module pod_slot() {
    hull() {
        // Top opening — full diameter
        translate([0, 0, _rail_height - 0.01])
            cylinder(d = _slot_dia, h = 0.01);
        // Bottom — narrower to cradle the pod
        _bottom_slot = _pod_bottom_dia + pod_clearance * 2;
        translate([0, 0, base_thickness])
            cylinder(d = _bottom_slot, h = 0.01);
    }
}

// Single pod cradle with lip to prevent pods falling through
module pod_cradle() {
    _bottom_slot = _pod_bottom_dia + pod_clearance * 2;
    // The base has a hole slightly smaller than the pod bottom
    // so the pod rim catches on the lip
    _catch_dia = _pod_bottom_dia - 4; // 2mm lip on each side

    difference() {
        // Solid cylinder for the cradle area
        cylinder(d = _slot_dia + wall_thickness * 2, h = _rail_height);

        // Tapered slot from top
        pod_slot();

        // Drainage/weight-reduction hole in the base
        if (_catch_dia > 10) {
            translate([0, 0, -0.01])
                cylinder(d = _catch_dia, h = base_thickness + 0.02);
        }
    }
}

// The main rail body — a rectangular beam with pod slots cut out
module rail_body() {
    difference() {
        // Main rail body
        translate([0, 0, _rail_height / 2])
            cube([_rail_length, _rail_width, _rail_height], center = true);

        // Cut pod slots
        for (i = [0 : pods_per_rail - 1]) {
            _x = -_rail_length / 2 + wall_thickness + _slot_dia / 2 + i * _pod_spacing;
            translate([_x, 0, 0])
                pod_slot();

            // Drainage holes in base
            _catch_dia = _pod_bottom_dia - 4;
            if (_catch_dia > 10) {
                translate([_x, 0, -0.01])
                    cylinder(d = _catch_dia, h = base_thickness + 0.02);
            }
        }
    }
}

// Under-cabinet hook clamp — slides over the shelf edge
module cabinet_hook() {
    _hook_slot = cabinet_thickness + hook_gap_tolerance;
    _hook_outer_width = _rail_width;  // Same width as the rail
    _hook_total_height = _hook_slot + rail_thickness * 2;
    _hook_total_depth = hook_depth + rail_thickness;

    translate([0, 0, 0]) {
        difference() {
            // Outer hook body — C-shaped clamp
            union() {
                // Top plate (sits on top of shelf)
                translate([0, 0, _hook_slot + rail_thickness])
                    cube([_hook_outer_width, _hook_total_depth, rail_thickness], center = false);

                // Back wall (connects top and bottom)
                translate([0, _hook_total_depth - rail_thickness, 0])
                    cube([_hook_outer_width, rail_thickness, _hook_total_height], center = false);

                // Bottom plate (goes under the shelf — this is the mounting surface)
                translate([0, hook_depth * 0.3, 0])
                    cube([_hook_outer_width, _hook_total_depth - hook_depth * 0.3, rail_thickness], center = false);

                // Lip at the front of the top plate (prevents sliding off)
                translate([0, 0, _hook_slot + rail_thickness])
                    cube([_hook_outer_width, rail_thickness, rail_thickness + hook_lip], center = false);
            }

            // Internal slot for the cabinet shelf
            translate([-0.01, -0.01, rail_thickness])
                cube([_hook_outer_width + 0.02, _hook_total_depth - rail_thickness + 0.01, _hook_slot], center = false);
        }
    }
}

// ============================================================
// Assembly
// ============================================================

module complete_holder() {
    // Rail body — positioned hanging below
    translate([0, 0, 0])
        rail_body();

    // Hook clamps at each end of the rail
    // Left hook
    translate([-_rail_length / 2, -_rail_width / 2, _rail_height])
        cabinet_hook();

    // Right hook
    translate([_rail_length / 2 - _rail_width, -_rail_width / 2, _rail_height])
        cabinet_hook();
}

// Render
complete_holder();

// ============================================================
// Print Orientation Note
// ============================================================
// Print UPSIDE DOWN — hooks pointing up on the build plate.
// The flat top of the rail (which becomes the bottom when mounted)
// should face the build plate. This eliminates overhangs on the
// hook geometry and provides the best surface finish on the
// visible underside of the rail.
