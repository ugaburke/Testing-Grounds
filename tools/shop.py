#!/usr/bin/env python3
"""
shop.py — Unified CLI for the 3D Print Product Pipeline shop tools.

Usage:
    python shop.py catalog              List all products
    python shop.py params <slug>        Show parameters for a product
    python shop.py price <slug> [opts]  Calculate pricing
    python shop.py stl <slug> [opts]    Generate STL file
    python shop.py order new            Interactive order intake
    python shop.py order list           List all orders
    python shop.py order view <id>      View order details
    python shop.py order update <id> <status>  Update order status
    python shop.py order track <id> <tracking>  Set tracking number
    python shop.py listing <slug> [fmt] Export marketplace listing
"""

import sys
import os

# Add tools directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def cmd_catalog(args):
    from catalog import list_products
    list_products()


def cmd_params(args):
    if len(args) < 1:
        print("Usage: shop.py params <product-slug>")
        return
    sys.argv = ["generate_stl.py", args[0], "--list-params"]
    from generate_stl import main
    main()


def cmd_price(args):
    if len(args) < 1:
        print("Usage: shop.py price <product-slug> [-p NAME=VALUE] [-m MATERIAL]")
        return
    sys.argv = ["pricing.py"] + args
    from pricing import main
    main()


def cmd_stl(args):
    if len(args) < 1:
        print("Usage: shop.py stl <product-slug> [-p NAME=VALUE] [--dry-run]")
        return
    sys.argv = ["generate_stl.py"] + args
    from generate_stl import main
    main()


def cmd_order(args):
    if not args:
        print("Usage: shop.py order <new|list|view|update|track> [...]")
        return

    subcmd = args[0]

    if subcmd == "new":
        from order_intake import main
        main()
    elif subcmd in ("list", "view", "update", "create", "track"):
        sys.argv = ["order_tracker.py"] + args
        # Map 'list' to the right subcommand
        from order_tracker import main
        main()
    else:
        print(f"Unknown order subcommand: {subcmd}")
        print("Available: new, list, view, update, track")


def cmd_listing(args):
    if len(args) < 1:
        print("Usage: shop.py listing <product-slug> [etsy_physical|etsy_stl|reddit|social|all]")
        return
    sys.argv = ["export_listing.py"] + args
    from export_listing import main
    main()


def print_help():
    print("""
3D Print Product Pipeline — Shop Tools
=======================================

Commands:
  catalog                         List all products in the pipeline
  params <slug>                   Show customizable parameters for a product
  price <slug> [-p K=V] [-m MAT]  Calculate pricing for a configuration
  stl <slug> [-p K=V] [--dry-run] Generate custom STL file
  order new                       Interactive new order intake
  order list [--status STATUS]    List all orders
  order view <ORDER-ID>           View order details
  order update <ID> <STATUS>      Update order status
  order track <ID> <TRACKING>     Set shipping tracking number
  listing <slug> [format]         Export marketplace listing copy

Examples:
  python shop.py catalog
  python shop.py params fifo-can-dispenser
  python shop.py price fifo-can-dispenser -p shelf_depth_inches=14
  python shop.py stl fifo-can-dispenser -p shelf_depth_inches=14 --dry-run
  python shop.py order new
  python shop.py order list
  python shop.py listing utensil-drawer-organizer etsy_physical
""")


def main():
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help", "help"):
        print_help()
        return

    commands = {
        "catalog": cmd_catalog,
        "params": cmd_params,
        "price": cmd_price,
        "stl": cmd_stl,
        "order": cmd_order,
        "listing": cmd_listing,
    }

    cmd = args[0]
    if cmd in commands:
        commands[cmd](args[1:])
    else:
        print(f"Unknown command: {cmd}")
        print_help()


if __name__ == "__main__":
    main()
