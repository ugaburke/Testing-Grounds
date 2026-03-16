# SPEC.md — Brand-Specific Spice Drawer Organizer

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-16 | Initial design. Modular 2-jar snap-together system with 6 brand presets, dovetail joints. |

---

## Print Settings

| Setting | Recommended Value | Notes |
|---------|-------------------|-------|
| Layer Height | 0.2mm | Good balance of speed and surface quality. |
| Infill | 20% Grid | Modules are small — 20% is plenty for structural integrity. |
| Wall Count | 3 perimeters | Ensures solid dovetail joints and jar slot walls. |
| Top/Bottom Layers | 4 | Solid base prevents flex and supports jar weight. |
| Supports | None required | Flat geometry, no overhangs. |
| Print Speed | 60–80 mm/s | Standard speed works fine. Slow to 40 for dovetail joints if snap-fit is too tight. |
| Brim | Not needed | Small footprint with flat base adheres well. |

---

## Print Orientation

- **Orientation:** Flat, base on the build plate.
- **Rationale:** The module is essentially a shallow box — no overhangs, no bridges, no supports. Prints cleanly in any slicer with default settings.
- **Batching:** Fit 4–6 modules on a single build plate (256x256mm). A full drawer (~30 modules) takes 5–6 print runs.

---

## Recommended Materials

| Material | Suitability | Notes |
|----------|-------------|-------|
| **PETG** | **Best overall** | Heat resistant (no warping near stove), moisture resistant (kitchen spills), food-adjacent safe. Slightly flexible = better snap-fit dovetails. |
| PLA+ | Acceptable | Works for drawers away from heat sources. Cheaper than PETG. Brittle dovetails may crack over time. |
| PLA | Not recommended | Warps above 55°C (kitchen drawers near ovens can exceed this). Brittle snap joints. |
| ABS | Overkill | More heat resistant than needed. Requires enclosure, produces fumes. |

**Primary recommendation: PETG.** FourEyedShop (Etsy Star Seller) explicitly uses PETG for their spice organizers and markets it as a selling point. Follow their lead.

---

## Estimated Print Time & Filament Usage

| Configuration | Modules | Time (est.) | Filament (est.) | Weight |
|--------------|---------|-------------|-----------------|--------|
| Starter Kit (15" drawer, 1 brand) | ~30 modules | 14–16 hours | ~180m / 540g | 540g |
| Half Drawer (15" x 9") | ~15 modules | 7–8 hours | ~90m / 270g | 270g |
| Single Module | 1 | 25–35 min | ~6m / 18g | 18g |
| Expansion 4-Pack | 4 | 1.5–2 hours | ~24m / 72g | 72g |

*Estimates at 0.2mm layer height, 20% infill, 70mm/s, 0.4mm nozzle.*

Filament cost per module: ~$0.36 (at $20/kg PETG)
Filament cost per Starter Kit: ~$10.80

---

## Hardware Required

**None.** Fully snap-together system with no fasteners, screws, or glue.

Optional: felt or silicone pads on drawer-contact surface to prevent sliding (most drawers have enough friction without this).

---

## Brand-Specific Jar Dimensions Reference

These dimensions were researched and measured from product listings and specification databases. Verify with your own jars before committing to a large print run.

| Brand | Diameter/Width | Depth | Height | Shape | Preset Name |
|-------|---------------|-------|--------|-------|-------------|
| **McCormick** (standard) | 46mm (1.81") | 46mm | 108mm (4.25") | Round | `McCormick` |
| **Trader Joe's** | 46mm (1.8") | 46mm (1.8") | 104mm (4.1") | Rectangular | `TraderJoes` |
| **Simply Organic** | 52mm (2.05") | 52mm | 114mm (4.5") | Square | `SimplyOrganic` |
| **Whole Foods 365** | 50mm (1.95") | 50mm | 106mm (4.15") | Round | `WholeFoods365` |
| **Penzeys** | 52mm (2.05") | 52mm | 127mm (5.0") | Round | `Penzeys` |
| **Custom** | User-defined | User-defined | User-defined | Any | `Custom` |

**Important:** Slot clearance of 1.5mm is added automatically on each side. This means a 46mm jar gets a 49mm slot — enough for easy insertion while preventing rattle.

### Mixed-Brand Drawers

Most kitchens have spices from multiple brands. The modular system handles this elegantly: print some modules with McCormick preset, others with Trader Joe's preset, etc. All modules have identical exterior dimensions, so they snap together regardless of internal slot shape.

---

## Known Failure Modes & Mitigation

| Failure Mode | Cause | Mitigation |
|-------------|-------|------------|
| **Dovetail too tight / won't snap** | Printer dimensional accuracy, PETG tends to print slightly oversized | Increase `dovetail_tolerance` to 0.3mm. Sand dovetail tabs lightly if needed. |
| **Dovetail too loose / modules separate** | Over-tolerance, PLA shrinkage | Decrease `dovetail_tolerance` to 0.15mm. Add a small dot of CA glue if permanent connection preferred. |
| **Module doesn't fit drawer** | Drawer measurement error | Measure drawer interior carefully. Subtract 2–3mm for clearance. Always print ONE test module first. |
| **Jars too tight in slots** | Brand variation between specific spice products | Increase `slot_clearance` to 2.0mm. Some brands have slight diameter variation between products. |
| **Base flexes under heavy jars** | Infill too low on large modules | Increase to 30% infill or increase `base_thickness` to 1.6mm. |
| **PETG warping on large modules** | Bed adhesion issue, typical of PETG | Bed at 80°C, PEI sheet, or glue stick on glass. Ensure first layer squish is correct. |

---

## Assembly Instructions

1. Print the required number of modules for your drawer (use the echo output from OpenSCAD to calculate).
2. Arrange modules on a flat surface in the desired grid pattern.
3. Press modules together — dovetail tabs click into sockets.
   - **X-direction:** Push right-side tab of left module into left-side socket of right module.
   - **Y-direction:** Push front tab of back module into back socket of front module.
4. Continue until all modules are connected.
5. Place the assembled organizer into the drawer.
6. Insert spice jars into slots.

**Disassembly:** Flex the modules slightly at the joint and pull apart. PETG is flexible enough to allow repeated snap/unsnap cycles.

---

## Customization Guide

| Parameter | Default | When to Change |
|-----------|---------|---------------|
| `jar_dia` | Brand-specific | Change for non-standard jars. Measure your jar's widest point with calipers. |
| `jar_shape` | Brand-specific | "round" for most brands. "rect" for Trader Joe's. "square" for Simply Organic. |
| `slot_clearance` | 1.5mm | Increase to 2.0mm if jars are tight. Decrease to 1.0mm if jars rattle. |
| `module_height` | 40mm | Increase if jars tip over in the drawer. Decrease if drawer clearance is tight. |
| `wall_thickness` | 2.0mm | Increase to 2.4mm for heavier jars. |
| `drawer_width` / `drawer_depth` | Your measurement | Measure the INTERIOR of your drawer, not the exterior. Subtract 2–3mm for safe clearance. |
| `dovetail_tolerance` | 0.2mm | Tune based on your printer's dimensional accuracy. Print a test pair first. |
