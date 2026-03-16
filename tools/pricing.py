"""
pricing.py — Pricing calculator for products.

Calculates price, COGS, and margin based on product parameters.
Uses filament weight estimation from design parameters.
"""

import json
from catalog import get_product_details

# Filament cost per kg by material type
MATERIAL_COSTS = {
    "PLA": 18.0,
    "PLA+": 20.0,
    "PETG": 22.0,
    "TPU": 28.0,
    "ABS": 20.0,
}

# Etsy fee structure
ETSY_LISTING_FEE = 0.20
ETSY_TRANSACTION_PCT = 0.065
ETSY_PAYMENT_PCT = 0.03
ETSY_PAYMENT_FLAT = 0.25

# Packaging costs by product size
PACKAGING_COSTS = {
    "small": 0.80,   # Small items (clips, mounts)
    "medium": 1.20,  # Medium items (single organizer section, can lane)
    "large": 1.80,   # Large items (full drawer organizer)
    "xlarge": 2.50,  # XL items (multi-piece sets)
}

# Shipping estimates (USPS Priority Mail)
SHIPPING_COSTS = {
    "small": 0.85,   # < 4oz
    "medium": 1.25,  # 4-8oz
    "large": 1.90,   # 8-16oz
    "xlarge": 2.80,  # 16-32oz
}

# Product-specific estimators
PRODUCT_ESTIMATORS = {
    "fifo-can-dispenser": {
        "base_weight_g": 180,
        "weight_per_extra_inch": 15,  # per inch of shelf depth beyond 10"
        "size_category": "medium",
        "default_material": "PETG",
        "base_price": 19.99,
        "multi_lane_discount": 0.88,  # 12% discount per additional lane
    },
    "utensil-drawer-organizer": {
        "weight_per_sqin": 0.9,  # grams per square inch of drawer area
        "size_category": "large",
        "default_material": "PETG",
        "price_tiers": [
            (400, 69.99),   # up to 400 sq in
            (600, 89.99),   # 401-600
            (800, 109.99),  # 601-800
        ],
    },
    "spice-drawer-organizer": {
        "base_weight_g": 120,
        "weight_per_slot": 8,
        "size_category": "medium",
        "default_material": "PETG",
        "base_price": 24.99,
    },
    "under-cabinet-kcup-holder": {
        "base_weight_g": 85,
        "size_category": "small",
        "default_material": "PETG",
        "base_price": 19.99,
    },
    "under-cabinet-tablet-holder": {
        "base_weight_g": 65,
        "size_category": "small",
        "default_material": "PETG",
        "base_price": 17.99,
    },
    "under-desk-headphone-mount": {
        "base_weight_g": 45,
        "size_category": "small",
        "default_material": "PLA",
        "base_price": 14.99,
    },
    "tpu-keyboard-wrist-rest": {
        "base_weight_g": 150,
        "size_category": "medium",
        "default_material": "TPU",
        "base_price": 24.99,
    },
    "modular-pet-puzzle-feeder": {
        "base_weight_g": 200,
        "size_category": "medium",
        "default_material": "PETG",
        "base_price": 29.99,
    },
}


def estimate_filament_weight(slug, parameters=None):
    """Estimate filament weight in grams for a product configuration."""
    parameters = parameters or {}
    estimator = PRODUCT_ESTIMATORS.get(slug, {})

    if slug == "fifo-can-dispenser":
        depth = float(parameters.get("shelf_depth_inches", 12))
        base = estimator.get("base_weight_g", 180)
        extra = (depth - 10) * estimator.get("weight_per_extra_inch", 15)
        return max(base, base + extra)

    elif slug == "utensil-drawer-organizer":
        width = float(parameters.get("drawer_width", 380))
        depth = float(parameters.get("drawer_depth", 500))
        area_sqin = (width / 25.4) * (depth / 25.4)
        return area_sqin * estimator.get("weight_per_sqin", 0.9)

    elif slug == "spice-drawer-organizer":
        slots = int(parameters.get("total_slots", 12))
        base = estimator.get("base_weight_g", 120)
        return base + slots * estimator.get("weight_per_slot", 8)

    return estimator.get("base_weight_g", 100)


def calculate_price(slug, parameters=None, material=None, quantity=1):
    """Calculate price, COGS, and margin for a product order.

    Returns dict with price, cogs breakdown, margin.
    """
    parameters = parameters or {}
    estimator = PRODUCT_ESTIMATORS.get(slug, {})
    material = material or estimator.get("default_material", "PLA")

    # Estimate weight
    weight_g = estimate_filament_weight(slug, parameters)

    # Material cost
    mat_cost_per_kg = MATERIAL_COSTS.get(material, 20.0)
    filament_cost = (weight_g / 1000) * mat_cost_per_kg

    # Print time estimate (~60g/hour for standard settings)
    print_hours = weight_g / 60

    # Electricity (~$0.065/hour)
    electricity = print_hours * 0.065

    # Size category for packaging/shipping
    size = estimator.get("size_category", "medium")
    packaging = PACKAGING_COSTS.get(size, 1.20)
    shipping = SHIPPING_COSTS.get(size, 1.25)

    # Determine selling price
    if slug == "utensil-drawer-organizer":
        width = float(parameters.get("drawer_width", 380))
        depth = float(parameters.get("drawer_depth", 500))
        area_sqin = (width / 25.4) * (depth / 25.4)
        price = 69.99  # default
        for max_area, tier_price in estimator.get("price_tiers", []):
            if area_sqin <= max_area:
                price = tier_price
                break
        else:
            price = estimator.get("price_tiers", [])[-1][1] if estimator.get("price_tiers") else 69.99
    else:
        price = estimator.get("base_price", 19.99)

    # Multi-unit discount
    if quantity > 1 and "multi_lane_discount" in estimator:
        discount = estimator["multi_lane_discount"]
        price = price + price * discount * (quantity - 1)
        weight_g *= quantity
        filament_cost *= quantity
        electricity *= quantity

    # Etsy fees
    etsy_listing = ETSY_LISTING_FEE
    etsy_transaction = price * ETSY_TRANSACTION_PCT
    etsy_payment = price * ETSY_PAYMENT_PCT + ETSY_PAYMENT_FLAT

    # Total COGS
    total_cogs = (
        filament_cost + electricity + packaging +
        etsy_listing + etsy_transaction + etsy_payment + shipping
    )

    gross_profit = price - total_cogs
    margin_pct = (gross_profit / price * 100) if price > 0 else 0

    return {
        "product": slug,
        "material": material,
        "quantity": quantity,
        "price": round(price, 2),
        "weight_g": round(weight_g, 1),
        "print_hours": round(print_hours, 1),
        "cogs": {
            "filament": round(filament_cost, 2),
            "electricity": round(electricity, 2),
            "packaging": round(packaging, 2),
            "shipping": round(shipping, 2),
            "etsy_listing": round(etsy_listing, 2),
            "etsy_transaction": round(etsy_transaction, 2),
            "etsy_payment": round(etsy_payment, 2),
            "total": round(total_cogs, 2),
        },
        "gross_profit": round(gross_profit, 2),
        "margin_pct": round(margin_pct, 1),
    }


def print_price_breakdown(result):
    """Print a formatted price breakdown."""
    print(f"\n{'='*50}")
    print(f"  Pricing: {result['product']}")
    print(f"{'='*50}")
    print(f"  Material: {result['material']}")
    print(f"  Weight: {result['weight_g']}g")
    print(f"  Print time: ~{result['print_hours']} hours")
    if result["quantity"] > 1:
        print(f"  Quantity: {result['quantity']}")
    print(f"\n  Selling Price:     ${result['price']:>8.2f}")
    print(f"\n  COGS Breakdown:")
    cogs = result["cogs"]
    print(f"    Filament:        ${cogs['filament']:>8.2f}")
    print(f"    Electricity:     ${cogs['electricity']:>8.2f}")
    print(f"    Packaging:       ${cogs['packaging']:>8.2f}")
    print(f"    Shipping:        ${cogs['shipping']:>8.2f}")
    print(f"    Etsy listing:    ${cogs['etsy_listing']:>8.2f}")
    print(f"    Etsy transaction:${cogs['etsy_transaction']:>8.2f}")
    print(f"    Etsy payment:    ${cogs['etsy_payment']:>8.2f}")
    print(f"    {'─'*30}")
    print(f"    Total COGS:      ${cogs['total']:>8.2f}")
    print(f"\n  Gross Profit:      ${result['gross_profit']:>8.2f}")
    print(f"  Margin:            {result['margin_pct']:>7.1f}%")
    print()


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Pricing calculator")
    parser.add_argument("slug", help="Product slug")
    parser.add_argument("-m", "--material", help="Material (PLA, PETG, TPU)")
    parser.add_argument("-q", "--quantity", type=int, default=1, help="Quantity")
    parser.add_argument(
        "-p", "--param", action="append", metavar="NAME=VALUE",
        help="Product parameter (repeatable)",
    )
    parser.add_argument("--json", action="store_true", help="Output as JSON")

    args = parser.parse_args()

    params = {}
    if args.param:
        for p in args.param:
            name, value = p.split("=", 1)
            params[name] = value

    result = calculate_price(args.slug, params, args.material, args.quantity)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print_price_breakdown(result)


if __name__ == "__main__":
    main()
