"""
order_intake.py — Interactive CLI for collecting buyer measurements and creating orders.

Walks through product parameters interactively, validates inputs,
calculates pricing, and creates an order with STL generation.
"""

import sys
from catalog import get_product_details, discover_products
from pricing import calculate_price, print_price_breakdown
from order_tracker import create_order
from generate_stl import generate_stl


def prompt_value(param):
    """Prompt user for a single parameter value."""
    name = param["name"]
    ptype = param["type"]
    default = param["default"]
    comment = param.get("comment", "")

    # Build prompt string
    if ptype == "dropdown":
        options = param.get("options", [])
        print(f"\n  {name}:")
        if comment:
            clean = comment.split("[")[0].strip()
            if clean:
                print(f"    {clean}")
        for i, opt in enumerate(options, 1):
            marker = " (default)" if opt == default else ""
            print(f"    {i}. {opt}{marker}")
        while True:
            raw = input(f"  Choose [1-{len(options)}] (Enter for default): ").strip()
            if not raw:
                return default
            try:
                idx = int(raw)
                if 1 <= idx <= len(options):
                    return options[idx - 1]
            except ValueError:
                if raw in options:
                    return raw
            print(f"    Invalid. Enter 1-{len(options)} or option name.")

    elif ptype == "boolean":
        label = "yes" if default else "no"
        raw = input(f"  {name} [{label}]: ").strip().lower()
        if not raw:
            return default
        return raw in ("true", "yes", "y", "1")

    elif ptype == "number":
        range_str = ""
        if "min" in param:
            range_str = f" (range: {param['min']}-{param['max']})"
        while True:
            raw = input(f"  {name} [{default}]{range_str}: ").strip()
            if not raw:
                return default
            try:
                val = float(raw)
                if "min" in param and (val < param["min"] or val > param["max"]):
                    print(f"    Must be between {param['min']} and {param['max']}")
                    continue
                return int(val) if isinstance(default, int) and val == int(val) else val
            except ValueError:
                print(f"    Enter a number.")

    else:  # string
        raw = input(f"  {name} [{default}]: ").strip()
        return raw if raw else default


def run_intake():
    """Interactive order intake flow."""
    products = discover_products()
    if not products:
        print("No products found.")
        return

    # Step 1: Select product
    slugs = list(products.keys())
    print(f"\n{'='*60}")
    print("  New Order — Product Selection")
    print(f"{'='*60}\n")
    for i, slug in enumerate(slugs, 1):
        print(f"  {i}. {slug}")

    while True:
        raw = input(f"\n  Select product [1-{len(slugs)}]: ").strip()
        try:
            idx = int(raw)
            if 1 <= idx <= len(slugs):
                slug = slugs[idx - 1]
                break
        except ValueError:
            if raw in slugs:
                slug = raw
                break
        print(f"  Invalid. Enter 1-{len(slugs)} or product name.")

    product = get_product_details(slug)

    # Step 2: Customer info
    print(f"\n{'='*60}")
    print(f"  Customer Information")
    print(f"{'='*60}")
    customer_name = input("\n  Customer name: ").strip()
    if not customer_name:
        customer_name = "Anonymous"

    # Step 3: Configure parameters
    print(f"\n{'='*60}")
    print(f"  Configure: {slug}")
    print(f"{'='*60}")
    print(f"  (Press Enter to accept defaults)\n")

    overrides = {}
    current_section = None
    for param in product["parameters"]:
        # Skip advanced/internal sections unless user asks
        if param["section"] == "Advanced":
            continue

        if param["section"] != current_section:
            current_section = param["section"]
            print(f"\n  --- {current_section} ---")

        value = prompt_value(param)
        if value != param["default"]:
            overrides[param["name"]] = value

    # Step 4: Material selection
    print(f"\n  --- Material ---")
    print(f"    1. PETG (recommended for kitchen/wet)")
    print(f"    2. PLA (budget, dry environments)")
    print(f"    3. PLA+ (middle ground)")
    print(f"    4. TPU (flexible items)")
    mat_raw = input(f"  Choose [1-4] (Enter for PETG): ").strip()
    material_map = {"1": "PETG", "2": "PLA", "3": "PLA+", "4": "TPU"}
    material = material_map.get(mat_raw, "PETG")

    # Step 5: Pricing preview
    print(f"\n{'='*60}")
    print(f"  Pricing Preview")
    print(f"{'='*60}")
    price_result = calculate_price(slug, overrides, material)
    print_price_breakdown(price_result)

    # Step 6: Confirm order
    confirm = input("  Create this order? [Y/n]: ").strip().lower()
    if confirm in ("n", "no"):
        print("  Order cancelled.")
        return

    # Step 7: Create order
    order = create_order(
        slug, customer_name, overrides,
        notes=f"Material: {material}",
    )

    # Step 8: Generate STL
    gen = input("\n  Generate STL now? [Y/n]: ").strip().lower()
    if gen not in ("n", "no"):
        result = generate_stl(slug, overrides, dry_run=False)
        if result["success"]:
            from order_tracker import set_stl_file, update_status
            set_stl_file(order["id"], result["output_path"])
            update_status(order["id"], "generating", "STL generated")
        else:
            print(f"  STL generation failed: {result.get('errors', [])}")
            print("  You can retry later with: python generate_stl.py")

    print(f"\n  Order {order['id']} is ready!")
    print(f"  Next steps: print the STL, QC, and ship.")


def main():
    try:
        run_intake()
    except KeyboardInterrupt:
        print("\n\n  Cancelled.")
    except EOFError:
        print("\n\n  Input ended.")


if __name__ == "__main__":
    main()
