# SPEC.md — Under-Desk Headphone Mount with Integrated Cable Channel

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-16 | Initial design. Two-piece clamp with captive nut, U-hook with cable channel. |

---

## Print Settings

| Setting | Recommended Value | Notes |
|---------|-------------------|-------|
| Layer Height | 0.2mm | Balance of strength and speed. 0.16mm for cosmetic finish. |
| Infill | 40% | Critical for clamp strength. Do not go below 30%. |
| Infill Pattern | Cubic or Gyroid | Better multi-directional strength than grid/lines. |
| Wall Count | 4 perimeters | Minimum 3. More walls = stronger clamp jaws. |
| Top/Bottom Layers | 5 | Ensures solid pad recess surfaces. |
| Supports | None required | See print orientation below. |
| Brim | Optional | 3-5mm brim on mount body for bed adhesion if needed. |
| Print Speed | 50–80 mm/s | Slower on the hook curve for better surface quality. |

---

## Print Orientation

### Mount Body (main piece)
- **Orientation:** Upright, with the bottom of the U-hook flat on the build plate.
- **Rationale:** Layer lines run parallel to the arm's primary load direction (vertical tension when headphones hang). The U-hook curve prints as a gradual overhang that self-supports. The upper jaw prints last, with horizontal layers providing compressive strength against the desk surface.
- **No supports needed** if your printer handles 45° overhangs (most FDM printers do).

### Lower Jaw (second piece)
- **Orientation:** Flat, with the nut pocket facing the build plate (print nut pocket upside-down).
- **Rationale:** The screw hole prints vertically for clean bore. The nut pocket cavity on the bottom prints bridging only over a small span (~11.5mm).

---

## Recommended Materials

| Material | Suitability | Notes |
|----------|-------------|-------|
| **PETG** | **Best overall** | Excellent layer adhesion (resists cracking), moderate flexibility under clamping load, good UV/heat resistance for desk-adjacent use. |
| **PLA+** | Good | Stiffer than PETG, adequate for light headphones (<400g). May crack under sustained clamping pressure on thick desks in warm environments. |
| **PLA** | Acceptable | Works for light-duty use. Not recommended if desk is near a window (heat warping risk). |
| **ABS/ASA** | Good | High strength and heat resistance, but requires enclosure and produces fumes. Overkill for this application. |
| **TPU** | Pad inserts only | Print the pad recesses in TPU (Shore 95A) for grip. Not suitable for the structural body. |

**Primary recommendation: PETG** for the best balance of printability, strength, and crack resistance — directly addressing the failure mode that plagues existing designs.

---

## Estimated Print Time & Filament Usage

| Part | Time (est.) | Filament (est.) | Weight (est.) |
|------|-------------|-----------------|---------------|
| Mount body | 2h 15min | 18m / 55g | 55g |
| Lower jaw | 25min | 4m / 12g | 12g |
| **Total** | **~2h 40min** | **22m / 67g** | **67g** |

*Estimates at 0.2mm layer height, 40% infill, 60mm/s, using a standard 0.4mm nozzle.*

Filament cost: ~$1.35 (at $20/kg PETG spool)

---

## Hardware Required (Not Printed)

| Item | Specification | Qty | Est. Cost |
|------|--------------|-----|-----------|
| Hex bolt | M6 x 50mm (or M6 x 60mm for desks >35mm) | 1 | $0.30 |
| Hex nut | M6 | 1 | $0.10 |
| Rubber pads | Self-adhesive silicone, ~20x40mm, 2mm thick | 2 | $0.50 |

**Total hardware cost:** ~$0.90

**Alternative:** Print TPU pad inserts instead of buying rubber pads. A TPU pad STL is included in the parametric design (set `pad_thickness` parameter).

---

## Known Failure Modes & Mitigation

| Failure Mode | Cause | Mitigation |
|-------------|-------|------------|
| **Crack at arm-to-jaw junction** | Stress concentration at sharp inside corner | Design includes 8mm fillet radius at all junctions. Print in PETG for superior layer adhesion. |
| **Screw strips printed thread** | PLA/PETG threads wear under repeated adjustment | Design uses captive M6 nut instead of printed threads. Metal-on-metal threading is durable. |
| **Clamp slips on desk** | Smooth desk surface + smooth PLA contact | Rubber pads in recesses provide grip. TPU inserts as alternative. |
| **Hook bows under heavy headphones** | Undersized hook arm for 500g+ headphones | 6mm hook thickness + 40% infill handles up to ~800g. For heavier: increase hook_thickness to 8mm in parameters. |
| **Layer delamination on hook curve** | Poor layer adhesion on curved overhang | PETG bonds layers better than PLA. Print slow (40mm/s) on the curve. Ensure no cooling fan on first curved layers. |

---

## Assembly Instructions

1. Print mount body and lower jaw per orientation above.
2. Press M6 nut into the hexagonal pocket on the lower jaw (should be a snug press-fit; use a vise or clamp if needed).
3. Apply rubber pads (or insert TPU pads) into both the upper jaw recess and lower jaw recess.
4. Thread M6 bolt through the arm's screw hole, through the lower jaw clearance hole, and into the captive nut.
5. Open the clamp jaws wide enough to slide over your desk edge.
6. Tighten the bolt by hand until the clamp grips the desk firmly. Do not overtighten — the rubber pads provide most of the grip.
7. Route headphone cable through the cable channel in the hook arm.
8. Hang headphones on the hook.

---

## Parametric Customization Guide

The OpenSCAD source is fully parametric. Key parameters to adjust:

| Parameter | Default | When to Change |
|-----------|---------|---------------|
| `desk_max` | 40mm | Increase for thicker desks (use longer bolt accordingly) |
| `hook_width` | 60mm | Decrease to 45mm for slim headbands, increase to 70mm for oversized gaming headsets |
| `hook_depth` | 35mm | Increase if headphones slide off; decrease for tighter desk clearance |
| `cable_channel_dia` | 8mm | Increase for thick cables or multiple cables |
| `clamp_body_width` | 50mm | Decrease to 35mm for a more compact look (reduces strength slightly) |
| `fillet_r` | 8mm | Increase to 12mm for maximum stress relief on heavy headphones |
