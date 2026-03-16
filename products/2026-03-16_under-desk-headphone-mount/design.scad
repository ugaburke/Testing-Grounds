// ============================================================
// Under-Desk Headphone Mount with Integrated Cable Channel
// Version: 1.0
// License: Proprietary — STL for sale, .scad source retained
// ============================================================
//
// A sturdy desk-clamp headphone hanger designed to avoid the
// stress-concentration cracking that plagues existing designs.
// Features:
//   - Adjustable clamp fits desks 15–40mm thick
//   - Wide hook accommodates headbands up to 60mm
//   - Integrated cable channel for headphone cord routing
//   - Filleted stress points to prevent cracking
//   - Prints without supports in recommended orientation
//
// Design philosophy: The clamp uses a captive-nut compression
// system rather than a printed thread (which strips). The hook
// arm uses generous fillets at the junction with the clamp body
// to distribute load and prevent the crack-at-the-bend failure
// mode documented in competing designs.

// ===================== PARAMETERS ============================
// Adjust these to customize for different desk/headphone sizes

// Desk thickness range (mm) — clamp jaw opening
desk_min = 15;       // Minimum desk thickness
desk_max = 40;       // Maximum desk thickness (screw travel)

// Hook dimensions
hook_width = 60;     // Width of the hook opening (headband clearance)
hook_depth = 35;     // How far the hook extends below the desk
hook_thickness = 6;  // Thickness of the hook arm

// Cable channel
cable_channel_dia = 8;  // Diameter of the cable routing channel

// Clamp body
clamp_body_width = 50;  // Width of the clamp (side to side)
clamp_wall = 5;         // Wall thickness of clamp body
clamp_depth = 30;       // Front-to-back depth of clamp

// Screw/hardware
screw_dia = 6.5;        // M6 bolt clearance hole
nut_width = 11.5;       // M6 nut width (across flats) + clearance
nut_height = 5.5;       // M6 nut thickness + clearance

// Fillet radius for stress relief
fillet_r = 8;

// Pad
pad_thickness = 2;      // Rubber/TPU pad recess depth
pad_width = 20;         // Contact pad width
pad_length = 40;        // Contact pad length

// Resolution
$fn = 60;

// ===================== MODULES ===============================

// Rounded cube for smooth edges
module rounded_cube(size, r) {
    hull() {
        for (x = [r, size[0]-r])
            for (y = [r, size[1]-r])
                for (z = [r, size[2]-r])
                    translate([x, y, z])
                        sphere(r=r);
    }
}

// 2D fillet for reinforcing inside corners (used in linear_extrude)
module fillet_2d(r) {
    difference() {
        square([r, r]);
        translate([r, r]) circle(r=r);
    }
}

// The main clamp body — upper jaw (fixed)
module upper_jaw() {
    difference() {
        // Main block
        rounded_cube([clamp_body_width, clamp_depth, clamp_wall + pad_thickness], 2);

        // Pad recess on the contact face (bottom of upper jaw)
        translate([(clamp_body_width - pad_width)/2,
                   (clamp_depth - pad_length)/2,
                   -0.1])
            cube([pad_width, pad_length, pad_thickness + 0.1]);
    }
}

// The lower jaw — movable, with captive nut pocket
module lower_jaw() {
    jaw_height = clamp_wall + pad_thickness;

    difference() {
        // Main block
        rounded_cube([clamp_body_width, clamp_depth, jaw_height], 2);

        // Pad recess on contact face (top of lower jaw)
        translate([(clamp_body_width - pad_width)/2,
                   (clamp_depth - pad_length)/2,
                   jaw_height - pad_thickness])
            cube([pad_width, pad_length, pad_thickness + 0.1]);

        // Screw clearance hole (vertical, centered)
        translate([clamp_body_width/2, clamp_depth/2, -0.1])
            cylinder(d=screw_dia, h=jaw_height + 0.2);

        // Captive nut pocket (hexagonal, on the bottom face)
        translate([clamp_body_width/2, clamp_depth/2, -0.1])
            cylinder(d=nut_width / cos(30), h=nut_height + 0.1, $fn=6);
    }
}

// The vertical arm connecting upper jaw to hook
module arm() {
    arm_length = desk_max + 20; // Extra length for screw mechanism clearance
    arm_width = clamp_body_width;

    difference() {
        union() {
            // Main vertical arm
            cube([arm_width, hook_thickness, arm_length]);

            // Fillet at top (arm-to-upper-jaw junction)
            // This is the critical stress relief zone
            translate([0, hook_thickness, arm_length])
                rotate([0, 90, 0])
                    linear_extrude(arm_width)
                        fillet_2d(fillet_r);

            // Fillet at bottom (arm-to-hook junction)
            translate([0, hook_thickness, 0])
                rotate([90, 0, 0])
                    rotate([0, 90, 0])
                        linear_extrude(arm_width)
                            fillet_2d(fillet_r);
        }

        // Screw channel through the arm (for clamping bolt)
        translate([arm_width/2, -0.1, arm_length - clamp_depth/2])
            rotate([-90, 0, 0])
                cylinder(d=screw_dia, h=hook_thickness + fillet_r + 0.2);
    }
}

// The hook that holds the headphones
module hook() {
    hook_inner_width = hook_width;
    hook_outer_width = hook_inner_width + 2 * hook_thickness;

    // U-shaped hook profile
    difference() {
        // Outer rounded rectangle
        hull() {
            // Left pillar base
            translate([0, 0, 0])
                cube([hook_thickness, hook_thickness, 1]);
            // Right pillar base
            translate([hook_inner_width + hook_thickness, 0, 0])
                cube([hook_thickness, hook_thickness, 1]);
            // Bottom curve
            translate([hook_outer_width/2, 0, -hook_depth])
                rotate([-90, 0, 0])
                    cylinder(d=hook_outer_width, h=hook_thickness);
        }

        // Inner cutout
        hull() {
            translate([hook_thickness, -0.1, 0])
                cube([hook_inner_width, hook_thickness + 0.2, 1]);
            translate([hook_outer_width/2, -0.1, -hook_depth])
                rotate([-90, 0, 0])
                    cylinder(d=hook_inner_width, h=hook_thickness + 0.2);
        }

        // Cable channel — a through-hole in the hook arm for cord routing
        translate([hook_outer_width/2, hook_thickness/2, -hook_depth * 0.6])
            rotate([0, 90, 0])
                cylinder(d=cable_channel_dia, h=hook_outer_width + 2, center=true);
    }
}

// ===================== ASSEMBLY ==============================

// Position: hook hangs below, arm goes up, clamp at top

module assembled_mount() {
    arm_length = desk_max + 20;
    hook_outer_width = hook_width + 2 * hook_thickness;

    // Center the hook under the arm
    hook_offset_x = (clamp_body_width - hook_outer_width) / 2;

    // Hook (at origin, hanging down)
    translate([hook_offset_x, 0, 0])
        hook();

    // Arm (going up from hook)
    translate([0, 0, 0])
        arm();

    // Upper jaw (at top of arm, extending backward)
    translate([0, hook_thickness, arm_length])
        upper_jaw();
}

// Render the main mount body
assembled_mount();

// Lower jaw — rendered separately for printing as a second piece
// Uncomment to preview in assembly position:
// translate([0, -clamp_depth - 10, desk_max + 20])
//     lower_jaw();

// To export the lower jaw separately, comment out assembled_mount()
// above and uncomment:
// lower_jaw();

// ===================== PRINT NOTES ===========================
// Print orientation: Mount body prints upright (hook pointing down
// on the build plate). The U-shaped hook bottom becomes the first
// layer, and the arm + upper jaw build upward. This avoids supports
// entirely and places layer lines parallel to the load direction.
//
// The lower jaw prints flat (pad recess facing up).
//
// Hardware needed:
//   - 1x M6 x 50mm hex bolt (or longer for thicker desks)
//   - 1x M6 hex nut
//   - 2x rubber/silicone pads (self-adhesive, ~20x40mm) OR
//     print pad inserts in TPU
//
// Recommended: Print a test clamp section first to verify desk fit.
