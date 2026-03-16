"""
catalog.py — Product catalog discovery and parsing.

Discovers products from /products/ directories, parses .scad files for
parametric variables, and extracts pricing/COGS from PROFIT_MODEL.md.
"""

import os
import re
import json
from pathlib import Path

PRODUCTS_DIR = Path(__file__).parent.parent / "products"


def discover_products(products_dir=None):
    """Find all product directories and return metadata."""
    base = Path(products_dir) if products_dir else PRODUCTS_DIR
    products = {}

    for entry in sorted(base.iterdir()):
        if not entry.is_dir():
            continue
        # Extract slug from folder name (YYYY-MM-DD_slug)
        match = re.match(r"\d{4}-\d{2}-\d{2}_(.+)", entry.name)
        if not match:
            continue
        slug = match.group(1)
        scad_file = entry / "design.scad"
        if not scad_file.exists():
            continue

        products[slug] = {
            "slug": slug,
            "folder": str(entry),
            "folder_name": entry.name,
            "scad_file": str(scad_file),
            "has_spec": (entry / "SPEC.md").exists(),
            "has_marketing": (entry / "MARKETING.md").exists(),
            "has_profit_model": (entry / "PROFIT_MODEL.md").exists(),
            "has_opportunity": (entry / "OPPORTUNITY.md").exists(),
        }

    return products


def parse_scad_parameters(scad_path):
    """Parse OpenSCAD customizer parameters from a .scad file.

    Returns a list of parameter dicts with:
    - name: variable name
    - default: default value
    - type: 'number', 'string', 'boolean', 'dropdown'
    - section: customizer section name
    - comment: inline comment
    - min/max/step: for numeric ranges
    - options: for dropdown selections
    """
    params = []
    current_section = "General"

    with open(scad_path, "r") as f:
        for line in f:
            line = line.strip()

            # Section header: /* [Section Name] */
            section_match = re.match(r"/\*\s*\[(.+?)\]\s*\*/", line)
            if section_match:
                current_section = section_match.group(1)
                continue

            # Skip computed variables (underscore prefix)
            if re.match(r"_\w+\s*=", line):
                continue

            # Skip $fn and other special variables
            if re.match(r"\$\w+\s*=", line):
                continue

            # Parameter: name = value; // comment
            param_match = re.match(
                r"(\w+)\s*=\s*(.+?)\s*;\s*(?://\s*(.*))?$", line
            )
            if not param_match:
                continue

            name = param_match.group(1)
            raw_value = param_match.group(2).strip()
            comment = (param_match.group(3) or "").strip()

            param = {
                "name": name,
                "section": current_section,
                "comment": comment,
            }

            # Determine type and parse value
            if raw_value in ("true", "false"):
                param["type"] = "boolean"
                param["default"] = raw_value == "true"

            elif raw_value.startswith('"'):
                # String value — check for dropdown options
                param["default"] = raw_value.strip('"')
                dropdown_match = re.search(
                    r'\["([^"]*)"(?:\s*,\s*"([^"]*)")*\]', comment
                )
                if dropdown_match:
                    # Extract all options from the dropdown
                    options = re.findall(r'"([^"]*)"', comment)
                    param["type"] = "dropdown"
                    param["options"] = options
                else:
                    param["type"] = "string"

            else:
                # Numeric value
                try:
                    if "." in raw_value:
                        param["default"] = float(raw_value)
                    else:
                        param["default"] = int(raw_value)
                except ValueError:
                    param["default"] = raw_value

                param["type"] = "number"

                # Check for range: [min:step:max]
                range_match = re.search(
                    r"\[(-?[\d.]+):(-?[\d.]+):(-?[\d.]+)\]", comment
                )
                if range_match:
                    param["min"] = float(range_match.group(1))
                    param["step"] = float(range_match.group(2))
                    param["max"] = float(range_match.group(3))

            params.append(param)

    return params


def parse_pricing(profit_model_path):
    """Extract SKU pricing from PROFIT_MODEL.md.

    Returns a list of SKU dicts with name, price, cogs, margin.
    """
    skus = []
    if not os.path.exists(profit_model_path):
        return skus

    with open(profit_model_path, "r") as f:
        content = f.read()

    # Find pricing tables — look for rows with $ values
    for line in content.split("\n"):
        # Match table rows like: | **SKU Name** | Description | $XX.XX | $XX.XX | XX% |
        row_match = re.match(
            r"\|\s*\*?\*?(.+?)\*?\*?\s*\|.*?\$(\d+\.?\d*)\s*\|", line
        )
        if row_match:
            name = row_match.group(1).strip().strip("*")
            # Find all dollar amounts in the line
            prices = re.findall(r"\$(\d+\.?\d*)", line)
            if prices:
                sku = {"name": name, "price": float(prices[0])}
                if len(prices) > 1:
                    sku["cogs"] = float(prices[1])
                margin_match = re.search(r"(\d+)%", line)
                if margin_match:
                    sku["margin_pct"] = int(margin_match.group(1))
                skus.append(sku)

    return skus


def get_product_details(slug):
    """Get full details for a product including parameters and pricing."""
    products = discover_products()
    if slug not in products:
        return None

    product = products[slug]
    product["parameters"] = parse_scad_parameters(product["scad_file"])
    product["skus"] = parse_pricing(
        os.path.join(product["folder"], "PROFIT_MODEL.md")
    )

    return product


def list_products():
    """Print a formatted list of all products."""
    products = discover_products()
    if not products:
        print("No products found in", PRODUCTS_DIR)
        return

    print(f"\n{'='*60}")
    print(f"  Product Catalog — {len(products)} products")
    print(f"{'='*60}\n")

    for i, (slug, info) in enumerate(products.items(), 1):
        status = []
        if info["has_spec"]:
            status.append("SPEC")
        if info["has_marketing"]:
            status.append("MARKETING")
        if info["has_profit_model"]:
            status.append("PRICING")

        print(f"  {i}. {slug}")
        print(f"     Folder: {info['folder_name']}")
        print(f"     Assets: {', '.join(status)}")
        print()


if __name__ == "__main__":
    list_products()
