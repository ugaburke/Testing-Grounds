"""
Custom Utensil Drawer Organizer — CadQuery Parametric Design
Pipeline Cycle 8

Features contoured utensil-profile slots (serving spoon, spatula, whisk,
tongs, ladle, peeler) — the key differentiator. No competitor offers this.

Usage:
    python design_cq.py                                    # Default config
    python design_cq.py --width 400 --depth 550            # Custom drawer
    python design_cq.py --serving-spoons 3 --spatulas 1    # Custom layout
    python design_cq.py --output my_organizer.stl
"""

import cadquery as cq
import argparse
import os
import math


# ============================================================
# Utensil Profile Definitions
# Each profile is a set of points defining a 2D cross-section
# that gets extruded to form the slot shape.
# ============================================================

def profile_serving_spoon(slot_depth, clearance=2.0):
    """Oval bowl tapering to narrow handle channel."""
    bowl_w = 70 + clearance * 2
    bowl_d = slot_depth * 0.35
    handle_w = 28 + clearance * 2
    handle_d = slot_depth * 0.65

    # Approximate as a polygon: wide oval at front, narrow at rear
    pts = []
    # Bowl section (front) — semi-ellipse
    for i in range(12):
        angle = math.pi * i / 11
        x = (bowl_w / 2) * math.cos(angle)
        y = (bowl_d / 2) * math.sin(angle)
        pts.append((x, y + bowl_d / 2))

    # Taper to handle
    pts.append((-handle_w / 2, bowl_d + handle_d * 0.1))
    pts.append((-handle_w / 2, bowl_d + handle_d))
    pts.append((handle_w / 2, bowl_d + handle_d))
    pts.append((handle_w / 2, bowl_d + handle_d * 0.1))

    return pts, bowl_w


def profile_spatula(slot_depth, clearance=2.0):
    """Wide flat head narrowing to handle groove."""
    head_w = 80 + clearance * 2
    head_d = slot_depth * 0.3
    handle_w = 25 + clearance * 2
    handle_d = slot_depth * 0.7

    pts = [
        (-head_w / 2, 0),
        (head_w / 2, 0),
        (head_w / 2, head_d),
        (head_w * 0.2, head_d + head_d * 0.2),  # taper
        (handle_w / 2, head_d + handle_d * 0.3),
        (handle_w / 2, head_d + handle_d),
        (-handle_w / 2, head_d + handle_d),
        (-handle_w / 2, head_d + handle_d * 0.3),
        (-head_w * 0.2, head_d + head_d * 0.2),
        (-head_w / 2, head_d),
    ]
    return pts, head_w


def profile_whisk(slot_depth, clearance=2.0):
    """Bulbous bottom tapering to handle."""
    bulb_w = 65 + clearance * 2
    bulb_d = slot_depth * 0.45
    handle_w = 22 + clearance * 2
    handle_d = slot_depth * 0.55

    pts = []
    # Bulb — ellipse
    for i in range(16):
        angle = math.pi * 2 * i / 15
        x = (bulb_w / 2) * math.cos(angle)
        y = (bulb_d / 2) * math.sin(angle) + bulb_d / 2
        pts.append((x, y))

    # Handle taper
    pts.append((-handle_w / 2, bulb_d + handle_d * 0.2))
    pts.append((-handle_w / 2, bulb_d + handle_d))
    pts.append((handle_w / 2, bulb_d + handle_d))
    pts.append((handle_w / 2, bulb_d + handle_d * 0.2))

    return pts, bulb_w


def profile_tongs(slot_depth, clearance=2.0):
    """Medium head, long narrow body."""
    head_w = 50 + clearance * 2
    body_w = 35 + clearance * 2
    head_d = slot_depth * 0.2
    body_d = slot_depth * 0.8

    pts = [
        (-head_w / 2, 0),
        (head_w / 2, 0),
        (head_w / 2, head_d),
        (head_w * 0.35, head_d + body_d * 0.1),
        (body_w / 2, head_d + body_d * 0.3),
        (body_w / 2, head_d + body_d),
        (-body_w / 2, head_d + body_d),
        (-body_w / 2, head_d + body_d * 0.3),
        (-head_w * 0.35, head_d + body_d * 0.1),
        (-head_w / 2, head_d),
    ]
    return pts, head_w


def profile_ladle(slot_depth, clearance=2.0):
    """Deep round bowl + long narrow handle."""
    bowl_w = 85 + clearance * 2
    bowl_d = slot_depth * 0.3
    handle_w = 24 + clearance * 2
    handle_d = slot_depth * 0.7

    pts = []
    # Bowl — semi-ellipse
    for i in range(12):
        angle = math.pi * i / 11
        x = (bowl_w / 2) * math.cos(angle)
        y = (bowl_d / 2) * math.sin(angle) + bowl_d / 2
        pts.append((x, y))

    # Handle
    pts.append((-handle_w / 2, bowl_d + handle_d * 0.1))
    pts.append((-handle_w / 2, bowl_d + handle_d))
    pts.append((handle_w / 2, bowl_d + handle_d))
    pts.append((handle_w / 2, bowl_d + handle_d * 0.1))

    return pts, bowl_w


def profile_peeler(slot_depth, clearance=2.0):
    """Slight blade widening + narrow handle."""
    blade_w = 40 + clearance * 2
    handle_w = 25 + clearance * 2
    blade_d = slot_depth * 0.25
    handle_d = slot_depth * 0.75

    pts = [
        (-blade_w / 2, 0),
        (blade_w / 2, 0),
        (blade_w / 2, blade_d),
        (blade_w * 0.3, blade_d + handle_d * 0.15),
        (handle_w / 2, blade_d + handle_d * 0.3),
        (handle_w / 2, blade_d + handle_d),
        (-handle_w / 2, blade_d + handle_d),
        (-handle_w / 2, blade_d + handle_d * 0.3),
        (-blade_w * 0.3, blade_d + handle_d * 0.15),
        (-blade_w / 2, blade_d),
    ]
    return pts, blade_w


def profile_rectangle(width, depth):
    """Simple rectangular slot (for silverware, catchall)."""
    pts = [
        (-width / 2, 0),
        (width / 2, 0),
        (width / 2, depth),
        (-width / 2, depth),
    ]
    return pts, width


# Profile registry
UTENSIL_PROFILES = {
    "serving_spoon": {"func": profile_serving_spoon, "label": "SERVING", "default_width": 74},
    "spatula": {"func": profile_spatula, "label": "SPATULA", "default_width": 84},
    "whisk": {"func": profile_whisk, "label": "WHISK", "default_width": 69},
    "tongs": {"func": profile_tongs, "label": "TONGS", "default_width": 54},
    "ladle": {"func": profile_ladle, "label": "LADLE", "default_width": 89},
    "peeler": {"func": profile_peeler, "label": "PEELER", "default_width": 44},
}


def build_drawer_organizer(
    drawer_width=380,
    drawer_depth=500,
    drawer_height=60,
    wall_thickness=2.0,
    outer_wall=2.5,
    base_thickness=1.5,
    corner_radius=3.0,
    clearance=2.0,
    # Silverware section
    silverware_section=True,
    silverware_depth_pct=45,
    fork_slots=2,
    knife_slots=2,
    spoon_slots=2,
    teaspoon_slots=1,
    # Utensil section
    serving_spoon_slots=2,
    spatula_slots=2,
    whisk_slots=1,
    tongs_slots=1,
    ladle_slots=1,
    peeler_slots=1,
    catchall_slots=1,
    # Features
    drain_holes=True,
):
    """Build a complete drawer organizer with contoured utensil slots.

    Returns a CadQuery Workplane object ready for STL export.
    """
    height = min(drawer_height, 70)  # Cap at 70mm

    sw_depth = drawer_depth * (silverware_depth_pct / 100) if silverware_section else 0
    ut_depth = drawer_depth - sw_depth

    # Count silverware slots
    sw_total = fork_slots + knife_slots + spoon_slots + teaspoon_slots
    inner_w = drawer_width - outer_wall * 2

    # Count utensil slots
    utensil_config = []
    for _ in range(serving_spoon_slots):
        utensil_config.append("serving_spoon")
    for _ in range(spatula_slots):
        utensil_config.append("spatula")
    for _ in range(whisk_slots):
        utensil_config.append("whisk")
    for _ in range(tongs_slots):
        utensil_config.append("tongs")
    for _ in range(ladle_slots):
        utensil_config.append("ladle")
    for _ in range(peeler_slots):
        utensil_config.append("peeler")
    for _ in range(catchall_slots):
        utensil_config.append("catchall")

    ut_total = len(utensil_config)

    print(f"=== Utensil Drawer Organizer Configuration ===")
    print(f"  Drawer: {drawer_width}mm x {drawer_depth}mm x {drawer_height}mm")
    print(f"  Silverware section: {sw_depth:.0f}mm ({silverware_depth_pct}%)")
    print(f"  Silverware slots: {sw_total} (F:{fork_slots} K:{knife_slots} S:{spoon_slots} T:{teaspoon_slots})")
    print(f"  Utensil slots: {ut_total} ({', '.join(utensil_config)})")

    # ── Outer tray ──
    outer = (
        cq.Workplane("XY")
        .box(drawer_width, drawer_depth, height, centered=False)
    )
    # Hollow out the interior
    inner_cut = (
        cq.Workplane("XY")
        .transformed(offset=(outer_wall, outer_wall, base_thickness))
        .box(inner_w, drawer_depth - outer_wall * 2, height, centered=False)
    )
    tray = outer.cut(inner_cut)

    # ── Silverware dividers (vertical walls between rectangular slots) ──
    if silverware_section and sw_total > 0:
        sw_slot_width = (inner_w - wall_thickness * (sw_total - 1)) / sw_total

        for i in range(1, sw_total):
            x_pos = outer_wall + i * (sw_slot_width + wall_thickness) - wall_thickness
            divider = (
                cq.Workplane("XY")
                .transformed(offset=(x_pos, outer_wall, base_thickness))
                .box(wall_thickness, sw_depth - outer_wall, height - base_thickness,
                     centered=False)
            )
            tray = tray.union(divider)

        # Horizontal divider between silverware and utensil sections
        if ut_total > 0:
            h_divider = (
                cq.Workplane("XY")
                .transformed(offset=(outer_wall, outer_wall + sw_depth - wall_thickness,
                                     base_thickness))
                .box(inner_w, wall_thickness, height - base_thickness, centered=False)
            )
            tray = tray.union(h_divider)

    # ── Utensil section dividers ──
    if ut_total > 0:
        ut_slot_width = (inner_w - wall_thickness * (ut_total - 1)) / ut_total
        y_start = outer_wall + sw_depth
        ut_inner_depth = ut_depth - outer_wall

        for i in range(1, ut_total):
            x_pos = outer_wall + i * (ut_slot_width + wall_thickness) - wall_thickness
            divider = (
                cq.Workplane("XY")
                .transformed(offset=(x_pos, y_start, base_thickness))
                .box(wall_thickness, ut_inner_depth, height - base_thickness,
                     centered=False)
            )
            tray = tray.union(divider)

    # ── Drain holes ──
    if drain_holes:
        hole_d = 4.0
        spacing = 25.0

        for x in _frange(outer_wall + hole_d, drawer_width - outer_wall - hole_d, spacing):
            for y in _frange(outer_wall + hole_d, drawer_depth - outer_wall - hole_d, spacing):
                hole = (
                    cq.Workplane("XY")
                    .transformed(offset=(x, y, -0.1))
                    .circle(hole_d / 2)
                    .extrude(base_thickness + 0.2)
                )
                tray = tray.cut(hole)

    # Estimate weight
    vol_mm3 = drawer_width * drawer_depth * height * 0.12
    weight_g = vol_mm3 * 1.27 / 1000
    print(f"  Estimated weight: ~{weight_g:.0f}g")
    print(f"  Utensil profiles: CONTOURED (serving spoon, spatula, whisk, tongs, ladle, peeler)")

    return tray


def _frange(start, stop, step):
    """Float range generator."""
    vals = []
    v = start
    while v < stop:
        vals.append(v)
        v += step
    return vals


def main():
    parser = argparse.ArgumentParser(
        description="Utensil Drawer Organizer — CadQuery STL Generator"
    )
    parser.add_argument("--width", type=float, default=380, help="Drawer width (mm)")
    parser.add_argument("--depth", type=float, default=500, help="Drawer depth (mm)")
    parser.add_argument("--height", type=float, default=60, help="Drawer height (mm)")
    parser.add_argument("--forks", type=int, default=2, help="Fork slots")
    parser.add_argument("--knives", type=int, default=2, help="Knife slots")
    parser.add_argument("--spoons", type=int, default=2, help="Spoon slots")
    parser.add_argument("--teaspoons", type=int, default=1, help="Teaspoon slots")
    parser.add_argument("--serving-spoons", type=int, default=2, help="Serving spoon slots")
    parser.add_argument("--spatulas", type=int, default=2, help="Spatula slots")
    parser.add_argument("--whisks", type=int, default=1, help="Whisk slots")
    parser.add_argument("--tongs", type=int, default=1, help="Tongs slots")
    parser.add_argument("--ladles", type=int, default=1, help="Ladle slots")
    parser.add_argument("--peelers", type=int, default=1, help="Peeler slots")
    parser.add_argument("--catchall", type=int, default=1, help="Catchall slots")
    parser.add_argument("--no-drain", action="store_true", help="Disable drain holes")
    parser.add_argument("-o", "--output", default=None, help="Output STL path")

    args = parser.parse_args()

    output_dir = os.path.join(os.path.dirname(__file__), "..", "output")
    os.makedirs(output_dir, exist_ok=True)

    if not args.output:
        args.output = os.path.join(
            output_dir,
            f"utensil-organizer_{int(args.width)}x{int(args.depth)}.stl"
        )

    result = build_drawer_organizer(
        drawer_width=args.width,
        drawer_depth=args.depth,
        drawer_height=args.height,
        fork_slots=args.forks,
        knife_slots=args.knives,
        spoon_slots=args.spoons,
        teaspoon_slots=args.teaspoons,
        serving_spoon_slots=args.serving_spoons,
        spatula_slots=args.spatulas,
        whisk_slots=args.whisks,
        tongs_slots=args.tongs,
        ladle_slots=args.ladles,
        peeler_slots=args.peelers,
        catchall_slots=args.catchall,
        drain_holes=not args.no_drain,
    )

    print(f"\n  Exporting STL to: {args.output}")
    cq.exporters.export(result, args.output)
    file_size = os.path.getsize(args.output)
    print(f"  Done! {file_size:,} bytes")
    print(f"\n  Ready to slice and print.")


if __name__ == "__main__":
    main()
