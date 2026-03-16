"""
order_tracker.py — Order management with JSON file storage.

Each order is stored as a JSON file in /orders/<order_id>.json.
"""

import os
import json
import sys
from pathlib import Path
from datetime import datetime

ORDERS_DIR = Path(__file__).parent.parent / "orders"


def _next_order_id():
    """Generate next sequential order ID."""
    ORDERS_DIR.mkdir(exist_ok=True)
    existing = [
        f.stem for f in ORDERS_DIR.glob("*.json")
        if f.stem.startswith("ORD-")
    ]
    if not existing:
        return "ORD-0001"
    nums = [int(x.split("-")[1]) for x in existing if x.split("-")[1].isdigit()]
    return f"ORD-{max(nums) + 1:04d}"


def create_order(product_slug, customer_name, parameters, sku=None, notes=""):
    """Create a new order.

    Args:
        product_slug: Product identifier
        customer_name: Buyer name or Etsy username
        parameters: Dict of custom parameters for this order
        sku: SKU name from PROFIT_MODEL (e.g., 'Standard Drawer')
        notes: Any additional notes

    Returns:
        Order dict with ID.
    """
    ORDERS_DIR.mkdir(exist_ok=True)
    order_id = _next_order_id()

    order = {
        "id": order_id,
        "product": product_slug,
        "customer": customer_name,
        "sku": sku or "custom",
        "parameters": parameters,
        "notes": notes,
        "status": "received",
        "created": datetime.now().isoformat(),
        "updated": datetime.now().isoformat(),
        "history": [
            {
                "status": "received",
                "timestamp": datetime.now().isoformat(),
                "note": "Order created",
            }
        ],
        "stl_file": None,
        "tracking_number": None,
    }

    order_path = ORDERS_DIR / f"{order_id}.json"
    with open(order_path, "w") as f:
        json.dump(order, f, indent=2)

    print(f"Order {order_id} created for {customer_name}")
    print(f"  Product: {product_slug}")
    print(f"  Status: received")
    print(f"  File: {order_path}")

    return order


def update_status(order_id, new_status, note=""):
    """Update an order's status.

    Valid statuses: received, generating, printing, quality_check, shipped, delivered, cancelled
    """
    valid_statuses = [
        "received", "generating", "printing",
        "quality_check", "shipped", "delivered", "cancelled",
    ]
    if new_status not in valid_statuses:
        print(f"Invalid status: {new_status}")
        print(f"Valid statuses: {', '.join(valid_statuses)}")
        return None

    order_path = ORDERS_DIR / f"{order_id}.json"
    if not order_path.exists():
        print(f"Order not found: {order_id}")
        return None

    with open(order_path, "r") as f:
        order = json.load(f)

    order["status"] = new_status
    order["updated"] = datetime.now().isoformat()
    order["history"].append({
        "status": new_status,
        "timestamp": datetime.now().isoformat(),
        "note": note,
    })

    with open(order_path, "w") as f:
        json.dump(order, f, indent=2)

    print(f"Order {order_id}: {order['status']} → {new_status}")
    if note:
        print(f"  Note: {note}")

    return order


def set_stl_file(order_id, stl_path):
    """Record the generated STL file path for an order."""
    order_path = ORDERS_DIR / f"{order_id}.json"
    if not order_path.exists():
        print(f"Order not found: {order_id}")
        return None

    with open(order_path, "r") as f:
        order = json.load(f)

    order["stl_file"] = str(stl_path)
    order["updated"] = datetime.now().isoformat()

    with open(order_path, "w") as f:
        json.dump(order, f, indent=2)

    return order


def set_tracking(order_id, tracking_number):
    """Record shipping tracking number."""
    order_path = ORDERS_DIR / f"{order_id}.json"
    if not order_path.exists():
        print(f"Order not found: {order_id}")
        return None

    with open(order_path, "r") as f:
        order = json.load(f)

    order["tracking_number"] = tracking_number
    order["updated"] = datetime.now().isoformat()

    with open(order_path, "w") as f:
        json.dump(order, f, indent=2)

    print(f"Order {order_id}: tracking set to {tracking_number}")
    return order


def get_order(order_id):
    """Load an order by ID."""
    order_path = ORDERS_DIR / f"{order_id}.json"
    if not order_path.exists():
        return None
    with open(order_path, "r") as f:
        return json.load(f)


def list_orders(status_filter=None):
    """List all orders, optionally filtered by status."""
    ORDERS_DIR.mkdir(exist_ok=True)
    orders = []
    for path in sorted(ORDERS_DIR.glob("ORD-*.json")):
        with open(path, "r") as f:
            order = json.load(f)
        if status_filter and order["status"] != status_filter:
            continue
        orders.append(order)

    if not orders:
        print("No orders found." + (f" (filter: {status_filter})" if status_filter else ""))
        return orders

    # Status symbols
    symbols = {
        "received": "📥", "generating": "⚙️", "printing": "🖨️",
        "quality_check": "🔍", "shipped": "📦", "delivered": "✅",
        "cancelled": "❌",
    }

    print(f"\n{'='*70}")
    print(f"  Orders — {len(orders)} total" + (f" (filter: {status_filter})" if status_filter else ""))
    print(f"{'='*70}\n")

    for order in orders:
        sym = symbols.get(order["status"], "?")
        print(f"  {sym} {order['id']}  |  {order['product']}  |  {order['customer']}")
        print(f"     Status: {order['status']}  |  SKU: {order.get('sku', 'n/a')}")
        print(f"     Created: {order['created'][:16]}")
        if order.get("tracking_number"):
            print(f"     Tracking: {order['tracking_number']}")
        print()

    return orders


def main():
    """CLI interface for order management."""
    import argparse

    parser = argparse.ArgumentParser(description="Order tracking system")
    sub = parser.add_subparsers(dest="command")

    # Create order
    create_cmd = sub.add_parser("create", help="Create a new order")
    create_cmd.add_argument("product", help="Product slug")
    create_cmd.add_argument("customer", help="Customer name")
    create_cmd.add_argument("--sku", help="SKU name")
    create_cmd.add_argument("--notes", default="", help="Order notes")
    create_cmd.add_argument(
        "-p", "--param", action="append", metavar="NAME=VALUE",
        help="Custom parameter (repeatable)",
    )

    # Update status
    update_cmd = sub.add_parser("update", help="Update order status")
    update_cmd.add_argument("order_id", help="Order ID (e.g., ORD-0001)")
    update_cmd.add_argument(
        "status",
        choices=[
            "received", "generating", "printing",
            "quality_check", "shipped", "delivered", "cancelled",
        ],
    )
    update_cmd.add_argument("--note", default="", help="Status change note")

    # View order
    view_cmd = sub.add_parser("view", help="View order details")
    view_cmd.add_argument("order_id", help="Order ID")

    # List orders
    list_cmd = sub.add_parser("list", help="List all orders")
    list_cmd.add_argument("--status", help="Filter by status")

    # Set tracking
    track_cmd = sub.add_parser("track", help="Set tracking number")
    track_cmd.add_argument("order_id", help="Order ID")
    track_cmd.add_argument("tracking_number", help="Shipping tracking number")

    args = parser.parse_args()

    if args.command == "create":
        params = {}
        if args.param:
            for p in args.param:
                name, value = p.split("=", 1)
                params[name] = value
        create_order(args.product, args.customer, params, args.sku, args.notes)

    elif args.command == "update":
        update_status(args.order_id, args.status, args.note)

    elif args.command == "view":
        order = get_order(args.order_id)
        if order:
            print(json.dumps(order, indent=2))
        else:
            print(f"Order not found: {args.order_id}")

    elif args.command == "list":
        list_orders(args.status)

    elif args.command == "track":
        set_tracking(args.order_id, args.tracking_number)

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
