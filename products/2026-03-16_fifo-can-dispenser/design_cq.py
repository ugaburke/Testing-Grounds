"""
FIFO Gravity-Feed Can Dispenser — CadQuery Parametric Design
Pipeline Cycle 7

Supports: 12oz beverage, 12oz food, 15oz (#303), 28oz (#2.5), Custom
Parametric shelf depth: 10"-16"
Modular lane system — print single lanes, snap together

Usage:
    python design_cq.py                          # Default: 15oz, 12" shelf
    python design_cq.py --preset 12oz_bev        # 12oz beverage cans
    python design_cq.py --depth 14               # 14" shelf depth
    python design_cq.py --cans 8                 # 8 cans per lane
    python design_cq.py --output my_dispenser.stl
"""

import cadquery as cq
import argparse
import os
import math

# ============================================================
# Can Dimension Database
# ============================================================

CAN_PRESETS = {
    "12oz_bev":  {"dia": 66,  "height": 123, "label": "12oz Beverage (soda/beer/seltzer)"},
    "12oz_food": {"dia": 68,  "height": 101, "label": "12oz Food (#1 can)"},
    "15oz":      {"dia": 81,  "height": 113, "label": "15oz (#303 - beans/soup/corn)"},
    "28oz":      {"dia": 103, "height": 119, "label": "28oz (#2.5 - crushed tomatoes/pumpkin)"},
}


def build_can_dispenser(
    can_preset="15oz",
    custom_dia=81,
    custom_height=113,
    shelf_depth_inches=12,
    cans_per_lane=6,
    wall_thickness=2.0,
    base_thickness=2.0,
    side_wall_height_pct=40,
    ramp_angle=8,
    can_clearance=2.0,
    snap_tab_width=8.0,
    snap_tab_depth=2.0,
    render_connectors=True,
):
    """Build a single FIFO can dispenser lane.

    Returns a CadQuery Workplane object ready for STL export.
    """

    # Resolve can dimensions
    if can_preset in CAN_PRESETS:
        can_dia = CAN_PRESETS[can_preset]["dia"]
        can_h = CAN_PRESETS[can_preset]["height"]
        label = CAN_PRESETS[can_preset]["label"]
    else:
        can_dia = custom_dia
        can_h = custom_height
        label = f"Custom ({custom_dia}mm x {custom_height}mm)"

    # Computed dimensions
    shelf_depth = shelf_depth_inches * 25.4
    lane_width = can_dia + can_clearance * 2 + wall_thickness * 2
    lane_depth = shelf_depth - 5  # 5mm clearance from shelf edge
    side_wall_h = can_h * (side_wall_height_pct / 100)
    ramp_rise = lane_depth * math.tan(math.radians(ramp_angle))
    lane_height = ramp_rise + side_wall_h + base_thickness

    print(f"=== FIFO Can Dispenser Configuration ===")
    print(f"  Can: {label}")
    print(f"  Can diameter: {can_dia}mm, height: {can_h}mm")
    print(f"  Shelf depth: {shelf_depth_inches}\" ({shelf_depth:.0f}mm)")
    print(f"  Lane: {lane_width:.1f}mm W x {lane_depth:.1f}mm D x {lane_height:.1f}mm H")
    print(f"  Ramp angle: {ramp_angle}°, rise: {ramp_rise:.1f}mm")

    # ── Base plate (flat rectangle) ──
    base = (
        cq.Workplane("XY")
        .box(lane_width, lane_depth, base_thickness, centered=False)
    )

    # ── Ramp surface ──
    # The ramp is a wedge: flat at front (dispense end), rises toward rear (loading end)
    # We build it as a lofted solid from front edge to rear edge
    ramp_pts_bottom = [
        (0, 0),
        (lane_width, 0),
        (lane_width, lane_depth),
        (0, lane_depth),
    ]
    ramp = (
        cq.Workplane("XY")
        .transformed(offset=(0, 0, base_thickness))
        .moveTo(0, 0).lineTo(lane_width, 0)
        .lineTo(lane_width, lane_depth)
        .lineTo(0, lane_depth)
        .close()
        .extrude(0.01)  # thin slab at bottom
    )

    # Build the ramp as a polyhedron using a wedge shape
    # Front face at z=base_thickness, rear face at z=base_thickness+ramp_rise
    ramp_wedge = (
        cq.Workplane("XZ")
        .moveTo(0, base_thickness)
        .lineTo(0, base_thickness + 0.1)  # tiny height at front
        .lineTo(lane_depth, base_thickness + ramp_rise)
        .lineTo(lane_depth, base_thickness)
        .close()
        .extrude(lane_width)
        .translate((0, 0, 0))
    )

    # Reorient: the XZ sketch extrudes along Y, but we need it along X
    # Let's redo this more carefully
    # The ramp runs along Y (front=0 to rear=lane_depth)
    # At Y=0: top surface is at z=base_thickness
    # At Y=lane_depth: top surface is at z=base_thickness+ramp_rise
    ramp_wedge = (
        cq.Workplane("YZ")
        .moveTo(0, base_thickness)
        .lineTo(lane_depth, base_thickness + ramp_rise)
        .lineTo(lane_depth, base_thickness)
        .close()
        .extrude(lane_width)
    )

    # ── Left wall ──
    left_wall = (
        cq.Workplane("XY")
        .box(wall_thickness, lane_depth, side_wall_h + ramp_rise + base_thickness,
             centered=False)
    )

    # ── Right wall ──
    right_wall = (
        cq.Workplane("XY")
        .transformed(offset=(lane_width - wall_thickness, 0, 0))
        .box(wall_thickness, lane_depth, side_wall_h + ramp_rise + base_thickness,
             centered=False)
    )

    # ── Front stop (partial wall with dispense opening) ──
    stop_height = can_dia * 0.4
    front_stop = (
        cq.Workplane("XY")
        .box(lane_width, wall_thickness * 2, stop_height, centered=False)
    )
    # Cut dispense opening
    opening_width = can_dia + can_clearance
    opening_x = (lane_width - opening_width) / 2
    dispense_cut = (
        cq.Workplane("XY")
        .transformed(offset=(opening_x, -0.1, base_thickness))
        .box(opening_width, wall_thickness * 2 + 0.2, stop_height, centered=False)
    )
    front_stop = front_stop.cut(dispense_cut)

    # ── Rear loading guide ──
    rear_guide_h = can_dia * 0.3
    rear_guide = (
        cq.Workplane("XY")
        .transformed(offset=(0, lane_depth - wall_thickness * 2, 0))
        .box(lane_width, wall_thickness * 2, ramp_rise + rear_guide_h + base_thickness,
             centered=False)
    )

    # ── Assembly ──
    result = base.union(ramp_wedge).union(left_wall).union(right_wall)
    result = result.union(front_stop).union(rear_guide)

    # ── Snap connectors (right side: protruding tabs) ──
    if render_connectors:
        for y_frac in [0.25, 0.75]:
            y_pos = lane_depth * y_frac - snap_tab_width / 2
            z_pos = side_wall_h * 0.3

            # Right side tab (protrusion)
            tab = (
                cq.Workplane("XY")
                .transformed(offset=(lane_width, y_pos, z_pos))
                .box(snap_tab_depth, snap_tab_width, snap_tab_width, centered=False)
            )
            result = result.union(tab)

            # Left side slot (cutout)
            slot = (
                cq.Workplane("XY")
                .transformed(offset=(-snap_tab_depth - 0.1, y_pos - 0.15, z_pos - 0.15))
                .box(snap_tab_depth + 0.2, snap_tab_width + 0.3, snap_tab_width + 0.3,
                     centered=False)
            )
            result = result.cut(slot)

    # Estimate weight
    # Rough estimate: bounding box volume * fill fraction * density
    vol_estimate = lane_width * lane_depth * lane_height * 0.15  # ~15% fill
    weight_g = vol_estimate * 1.27 / 1000  # PETG density ~1.27 g/cm³
    print(f"  Estimated weight: ~{weight_g:.0f}g")

    return result


def main():
    parser = argparse.ArgumentParser(
        description="FIFO Can Dispenser — CadQuery STL Generator"
    )
    parser.add_argument(
        "--preset", default="15oz",
        choices=list(CAN_PRESETS.keys()) + ["custom"],
        help="Can size preset (default: 15oz)",
    )
    parser.add_argument("--dia", type=float, default=81, help="Custom can diameter (mm)")
    parser.add_argument("--height", type=float, default=113, help="Custom can height (mm)")
    parser.add_argument("--depth", type=float, default=12, help="Shelf depth (inches)")
    parser.add_argument("--cans", type=int, default=6, help="Cans per lane")
    parser.add_argument("--angle", type=float, default=8, help="Ramp angle (degrees)")
    parser.add_argument("--wall", type=float, default=2.0, help="Wall thickness (mm)")
    parser.add_argument("--clearance", type=float, default=2.0, help="Can clearance (mm)")
    parser.add_argument("--no-connectors", action="store_true", help="Omit snap connectors")
    parser.add_argument("-o", "--output", default=None, help="Output STL path")

    args = parser.parse_args()

    output_dir = os.path.join(os.path.dirname(__file__), "..", "output")
    os.makedirs(output_dir, exist_ok=True)

    if not args.output:
        args.output = os.path.join(
            output_dir,
            f"fifo-can-dispenser_{args.preset}_{args.depth}in.stl"
        )

    result = build_can_dispenser(
        can_preset=args.preset,
        custom_dia=args.dia,
        custom_height=args.height,
        shelf_depth_inches=args.depth,
        cans_per_lane=args.cans,
        wall_thickness=args.wall,
        ramp_angle=args.angle,
        can_clearance=args.clearance,
        render_connectors=not args.no_connectors,
    )

    print(f"\n  Exporting STL to: {args.output}")
    cq.exporters.export(result, args.output)
    file_size = os.path.getsize(args.output)
    print(f"  Done! {file_size:,} bytes")
    print(f"\n  Ready to slice and print.")


if __name__ == "__main__":
    main()
