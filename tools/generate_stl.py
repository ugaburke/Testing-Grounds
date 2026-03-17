"""
generate_stl.py — Automated STL generation from customer parameters.

Supports two backends:
  1. CadQuery (Python) — preferred, no external tools needed
  2. OpenSCAD CLI — fallback if CadQuery designs not available

Takes a product slug and parameter overrides, generates a custom STL file.
"""

import os
import re
import subprocess
import shutil
import json
import sys
import importlib
from pathlib import Path
from datetime import datetime

from catalog import get_product_details, parse_scad_parameters


OUTPUT_DIR = Path(__file__).parent.parent / "output"

# Map product slugs to their CadQuery design modules
CADQUERY_DESIGNS = {
    "fifo-can-dispenser": "products/2026-03-16_fifo-can-dispenser/design_cq.py",
    "utensil-drawer-organizer": "products/2026-03-16_utensil-drawer-organizer/design_cq.py",
}

# Map .scad parameter names to CadQuery function argument names
PARAM_MAPPINGS = {
    "fifo-can-dispenser": {
        "can_preset": "can_preset",
        "custom_can_dia": "custom_dia",
        "custom_can_height": "custom_height",
        "shelf_depth_inches": "shelf_depth_inches",
        "cans_per_lane": "cans_per_lane",
        "wall_thickness": "wall_thickness",
        "base_thickness": "base_thickness",
        "side_wall_height_pct": "side_wall_height_pct",
        "ramp_angle": "ramp_angle",
        "can_clearance": "can_clearance",
        "snap_tab_width": "snap_tab_width",
        "snap_tab_depth": "snap_tab_depth",
        "render_connectors": "render_connectors",
    },
    "utensil-drawer-organizer": {
        "drawer_width": "drawer_width",
        "drawer_depth": "drawer_depth",
        "drawer_height": "drawer_height",
        "wall_thickness": "wall_thickness",
        "fork_slots": "fork_slots",
        "knife_slots": "knife_slots",
        "spoon_slots": "spoon_slots",
        "teaspoon_slots": "teaspoon_slots",
        "serving_spoon_slots": "serving_spoon_slots",
        "spatula_slots": "spatula_slots",
        "whisk_slots": "whisk_slots",
        "tongs_slots": "tongs_slots",
        "ladle_slots": "ladle_slots",
        "peeler_slots": "peeler_slots",
        "catchall_slots": "catchall_slots",
        "bottom_drain_holes": "drain_holes",
    },
}


def has_cadquery():
    """Check if CadQuery is available."""
    try:
        import cadquery
        return True
    except ImportError:
        return False


def generate_stl_cadquery(slug, overrides, output_path):
    """Generate STL using CadQuery Python backend.

    Returns dict with 'success', 'output_path', 'errors'.
    """
    import cadquery as cq

    repo_root = Path(__file__).parent.parent
    design_path = repo_root / CADQUERY_DESIGNS[slug]

    # Load the design module dynamically
    spec = importlib.util.spec_from_file_location("design_cq", str(design_path))
    design_mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(design_mod)

    # Map parameter names and build kwargs
    param_map = PARAM_MAPPINGS.get(slug, {})
    kwargs = {}
    for scad_name, value in overrides.items():
        cq_name = param_map.get(scad_name, scad_name)
        kwargs[cq_name] = value

    # Call the build function
    if slug == "fifo-can-dispenser":
        result_obj = design_mod.build_can_dispenser(**kwargs)
    elif slug == "utensil-drawer-organizer":
        result_obj = design_mod.build_drawer_organizer(**kwargs)
    else:
        return {"success": False, "errors": [f"No CadQuery builder for: {slug}"]}

    # Export
    cq.exporters.export(result_obj, output_path)
    file_size = os.path.getsize(output_path)

    return {
        "success": True,
        "output_path": output_path,
        "file_size": file_size,
        "backend": "cadquery",
    }


def validate_parameters(params_spec, overrides):
    """Validate parameter overrides against .scad parameter specs.

    Returns (validated_dict, errors_list).
    """
    validated = {}
    errors = []
    spec_map = {p["name"]: p for p in params_spec}

    for name, value in overrides.items():
        if name not in spec_map:
            errors.append(f"Unknown parameter: {name}")
            continue

        spec = spec_map[name]

        if spec["type"] == "boolean":
            if isinstance(value, str):
                value = value.lower() in ("true", "1", "yes")
            validated[name] = bool(value)

        elif spec["type"] == "dropdown":
            if str(value) not in spec.get("options", []):
                errors.append(
                    f"{name}: '{value}' not in options {spec['options']}"
                )
                continue
            validated[name] = str(value)

        elif spec["type"] == "number":
            try:
                value = float(value)
            except (ValueError, TypeError):
                errors.append(f"{name}: '{value}' is not a number")
                continue

            if "min" in spec and value < spec["min"]:
                errors.append(
                    f"{name}: {value} below minimum {spec['min']}"
                )
                continue
            if "max" in spec and value > spec["max"]:
                errors.append(
                    f"{name}: {value} above maximum {spec['max']}"
                )
                continue

            # Preserve int vs float
            if isinstance(spec.get("default"), int) and value == int(value):
                validated[name] = int(value)
            else:
                validated[name] = value

        elif spec["type"] == "string":
            validated[name] = str(value)

    return validated, errors


def build_openscad_args(params):
    """Convert parameter dict to OpenSCAD -D arguments."""
    args = []
    for name, value in params.items():
        if isinstance(value, bool):
            args.extend(["-D", f"{name}={'true' if value else 'false'}"])
        elif isinstance(value, str):
            args.extend(["-D", f'{name}="{value}"'])
        else:
            args.extend(["-D", f"{name}={value}"])
    return args


def find_openscad():
    """Locate the OpenSCAD binary."""
    openscad = shutil.which("openscad")
    if openscad:
        return openscad

    # Common install locations
    candidates = [
        "/usr/bin/openscad",
        "/usr/local/bin/openscad",
        "/snap/bin/openscad",
        "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD",
    ]
    for path in candidates:
        if os.path.isfile(path):
            return path

    return None


def generate_stl(slug, overrides=None, output_path=None, dry_run=False):
    """Generate an STL file for a product with custom parameters.

    Args:
        slug: Product slug (e.g., 'fifo-can-dispenser')
        overrides: Dict of parameter name → value overrides
        output_path: Custom output path. Default: output/<slug>_<timestamp>.stl
        dry_run: If True, print the command but don't run it.

    Returns:
        dict with 'success', 'output_path', 'command', 'errors'
    """
    overrides = overrides or {}

    product = get_product_details(slug)
    if not product:
        return {"success": False, "errors": [f"Product not found: {slug}"]}

    # Validate parameters
    validated, errors = validate_parameters(product["parameters"], overrides)
    if errors:
        return {"success": False, "errors": errors}

    # Build output path
    if not output_path:
        OUTPUT_DIR.mkdir(exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = str(OUTPUT_DIR / f"{slug}_{timestamp}.stl")

    # Try CadQuery backend first (preferred — no external tools needed)
    if slug in CADQUERY_DESIGNS and has_cadquery() and not dry_run:
        print(f"Generating STL for {slug} (CadQuery backend)...")
        print(f"  Parameters: {json.dumps(validated)}")
        print(f"  Output: {output_path}")

        try:
            result = generate_stl_cadquery(slug, validated, output_path)
            if result["success"]:
                print(f"  Done! STL generated: {output_path} ({result['file_size']:,} bytes)")
            result["parameters"] = validated
            result["command"] = f"python design_cq.py (CadQuery)"
            return result
        except Exception as e:
            print(f"  CadQuery failed: {e}")
            print(f"  Falling back to OpenSCAD...")

    # Fallback: OpenSCAD CLI
    openscad = find_openscad()
    if not openscad and not dry_run:
        if has_cadquery() and slug not in CADQUERY_DESIGNS:
            return {
                "success": False,
                "errors": [
                    f"No CadQuery design for '{slug}' and OpenSCAD not found. "
                    f"Install OpenSCAD: sudo apt install openscad"
                ],
            }
        return {
            "success": False,
            "errors": [
                "Neither CadQuery nor OpenSCAD available. "
                "Install CadQuery: pip install cadquery — or — "
                "Install OpenSCAD: sudo apt install openscad"
            ],
        }

    # Build command
    cmd = [openscad or "openscad", "-o", output_path]
    cmd.extend(build_openscad_args(validated))
    cmd.append(product["scad_file"])

    result = {
        "command": " ".join(cmd),
        "parameters": validated,
        "scad_file": product["scad_file"],
        "output_path": output_path,
    }

    if dry_run:
        result["success"] = True
        result["dry_run"] = True
        print(f"\n[DRY RUN] Would execute:")
        print(f"  {result['command']}")
        print(f"\n  Parameters: {json.dumps(validated, indent=2)}")
        print(f"  Output: {output_path}")
        return result

    # Execute OpenSCAD
    print(f"Generating STL for {slug}...")
    print(f"  Parameters: {json.dumps(validated)}")
    print(f"  Output: {output_path}")
    print(f"  Running OpenSCAD...")

    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=600,  # 10 minute timeout for complex models
        )

        if proc.returncode != 0:
            result["success"] = False
            result["errors"] = [f"OpenSCAD failed: {proc.stderr}"]
            print(f"  ERROR: {proc.stderr[:200]}")
        else:
            result["success"] = True
            file_size = os.path.getsize(output_path) if os.path.exists(output_path) else 0
            result["file_size"] = file_size
            print(f"  Done! STL generated: {output_path} ({file_size:,} bytes)")

            # Print any echo output from OpenSCAD
            if proc.stderr:
                echo_lines = [
                    l for l in proc.stderr.split("\n")
                    if l.startswith("ECHO:")
                ]
                if echo_lines:
                    print("\n  Design info:")
                    for line in echo_lines[:10]:
                        print(f"    {line}")

    except subprocess.TimeoutExpired:
        result["success"] = False
        result["errors"] = ["OpenSCAD timed out (>10 minutes)"]
    except FileNotFoundError:
        result["success"] = False
        result["errors"] = ["OpenSCAD binary not found at runtime"]

    return result


def main():
    """CLI interface for STL generation."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Generate custom STL files from product designs"
    )
    parser.add_argument("slug", help="Product slug (e.g., fifo-can-dispenser)")
    parser.add_argument(
        "-p", "--param",
        action="append",
        metavar="NAME=VALUE",
        help="Parameter override (repeatable). E.g., -p shelf_depth_inches=14",
    )
    parser.add_argument("-o", "--output", help="Output STL path")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print command without executing",
    )
    parser.add_argument(
        "--list-params",
        action="store_true",
        help="List available parameters for the product",
    )

    args = parser.parse_args()

    if args.list_params:
        product = get_product_details(args.slug)
        if not product:
            print(f"Product not found: {args.slug}")
            sys.exit(1)

        print(f"\nParameters for: {args.slug}")
        print(f"{'='*60}")
        current_section = None
        for p in product["parameters"]:
            if p["section"] != current_section:
                current_section = p["section"]
                print(f"\n  [{current_section}]")
            desc = ""
            if p["type"] == "dropdown":
                desc = f" (options: {', '.join(p['options'])})"
            elif "min" in p:
                desc = f" (range: {p['min']}–{p['max']}, step {p['step']})"
            print(f"    {p['name']} = {p['default']}{desc}")
            if p.get("comment"):
                clean = re.sub(r"\[.*?\]", "", p["comment"]).strip()
                if clean:
                    print(f"      {clean}")
        return

    # Parse parameter overrides
    overrides = {}
    if args.param:
        for param_str in args.param:
            if "=" not in param_str:
                print(f"Invalid parameter format: {param_str} (use NAME=VALUE)")
                sys.exit(1)
            name, value = param_str.split("=", 1)
            overrides[name] = value

    result = generate_stl(
        args.slug,
        overrides=overrides,
        output_path=args.output,
        dry_run=args.dry_run,
    )

    if not result["success"]:
        print(f"\nErrors:")
        for err in result.get("errors", []):
            print(f"  - {err}")
        sys.exit(1)


if __name__ == "__main__":
    main()
