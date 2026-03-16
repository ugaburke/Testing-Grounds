# SPEC.md — Under-Cabinet Tablet/Phone Holder for Recipes

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-16 | Initial design. Under-cabinet hook-clamp mount with device-width presets and angle-adjustable shelf. |

---

## Print Settings

| Setting | Recommended Value | Notes |
|---------|-------------------|-------|
| Layer Height | 0.2mm | Standard quality. |
| Infill | 30% Grid | Mounting arms need strength to hold device weight. |
| Wall Count | 3 perimeters | Solid arms and hook clamps for load-bearing. |
| Top/Bottom Layers | 4 | Solid shelf surface for smooth device contact. |
| Supports | Conditional | Hook interior needs supports if printed upright. Print arms separately to avoid. |
| Print Speed | 50–60 mm/s | Moderate speed for good layer adhesion on structural arms. |
| Brim | Recommended | 5mm brim on mounting arms for adhesion. |

---

## Print Orientation & Part Strategy

### Phone Holder (Single Piece)
- **Orientation:** Shelf flat on build plate, arms extending upward.
- **Supports:** Needed inside hook clamp geometry.
- **Print time:** ~1.5 hours

### Tablet Holder — iPad Mini / Small (Two Pieces Recommended)
- **Part 1:** Shelf with side walls — prints flat, no supports.
- **Part 2:** Mounting arm pair with cross brace — prints vertically.
- **Assembly:** Friction fit or M3×12mm bolts through pre-designed holes.
- **Print time:** ~2 hours total

### Tablet Holder — iPad / Large (Three Pieces)
- **Part 1:** Shelf — prints flat.
- **Part 2:** Left mounting arm with hook.
- **Part 3:** Right mounting arm with hook.
- **Assembly:** M3×12mm bolts connect arms to shelf.
- **Print time:** ~2.5 hours total

**Rationale for multi-part:** Full-size iPad holder exceeds 200mm in width. Splitting into parts ensures compatibility with standard 220×220mm build plates.

---

## Recommended Materials

| Material | Suitability | Notes |
|----------|-------------|-------|
| **PETG** | **Best overall** | Kitchen steam/splash resistant. Slight flex improves hook clamp fit. Consistent with all kitchen line products. |
| PLA+ | Acceptable | Works for kitchens away from steam. Less flexible — hook clamp may be tighter. |
| PLA | Not recommended | Brittle hooks, warps near heat/steam. |

---

## Estimated Print Time & Filament Usage

| Configuration | Parts | Time (est.) | Filament (est.) | Weight |
|--------------|-------|-------------|-----------------|--------|
| Phone Holder (iPhone) | 1 | 1.5 hours | ~12m / 40g | 40g |
| Tablet Holder (iPad Mini) | 2 | 2.0 hours | ~16m / 50g | 50g |
| Tablet Holder (iPad) | 3 | 2.5 hours | ~20m / 65g | 65g |
| Tablet Holder (Galaxy Tab) | 3 | 2.3 hours | ~18m / 58g | 58g |

*Estimates at 0.2mm layer height, 30% infill, 55mm/s, 0.4mm nozzle.*

Filament cost per phone holder: ~$0.80 (at $20/kg PETG)
Filament cost per iPad holder: ~$1.30 (at $20/kg PETG)

---

## Hardware Required

### Phone Holder
**None.** Single-piece friction-fit design.

### Tablet Holders (Multi-Part)
| Hardware | Quantity | Notes |
|----------|----------|-------|
| M3×12mm bolts | 4 | Connects mounting arms to shelf |
| M3 nuts | 4 | Captive nut slots in shelf |

Optional: Rubber grip pads on device shelf surface to prevent sliding. Small silicone bumpers work well.

---

## Device Dimension Reference

| Device | Width (Portrait) | Depth (w/ Case) | Preset Name |
|--------|-----------------|-----------------|-------------|
| **iPhone** (14/15/16 series) | 78mm (3.07") | 12mm | `iPhone` |
| **iPad Mini** (6th gen) | 135mm (5.31") | 12mm | `iPadMini` |
| **iPad** (10th gen) | 179mm (7.05") | 12mm | `iPad` |
| **Samsung Galaxy Tab S** | 165mm (6.50") | 12mm | `GalaxyTab` |
| **Custom** | User-defined | User-defined | `Custom` |

**Note:** Width is measured in portrait orientation. The device sits in the holder in landscape for optimal recipe viewing. Depth includes a typical protective case (~3mm added to bare device thickness).

**Device clearance** of 2.0mm per side is added automatically. This allows easy insertion/removal even with bulky cases while keeping the device stable.

---

## Cabinet Compatibility

Same hook-clamp system as the K-Cup holder (Cycle 4):

| Parameter | Default | Range | Notes |
|-----------|---------|-------|-------|
| `cabinet_thickness` | 18mm | 12–30mm | Standard kitchen cabinets are 16–19mm. |
| `hook_depth` | 25mm | 15–35mm | Deeper = more secure. |
| `hook_gap_tolerance` | 0.5mm | 0.3–1.0mm | Tune for your cabinet. |
| `hook_lip` | 5mm | 3–8mm | Front lip prevents sliding. |

---

## Viewing Angle

| Angle Setting | Use Case |
|--------------|----------|
| 90° (vertical) | Best for wall-mounted cabinets at eye level |
| 80° | Slight tilt — good for upper cabinets viewed from below |
| 75° (default) | Natural reading angle for most under-cabinet positions |
| 70° | More tilted — good for high cabinets |
| 60° | Maximum tilt — for very high cabinets or seated viewing |

The angle is parametric via `shelf_angle` in OpenSCAD. Physical product comes in the default 75° angle. STL buyers can customize.

---

## Known Failure Modes & Mitigation

| Failure Mode | Cause | Mitigation |
|-------------|-------|------------|
| **Device slides out of shelf** | Shelf angle too steep, no lip contact | Decrease `shelf_angle` (more tilt). Increase `lip_height`. Add rubber bumper to shelf surface. |
| **Hook too tight on cabinet** | Cabinet thicker than measured | Increase `hook_gap_tolerance` to 0.8mm. |
| **Hook too loose** | Cabinet thinner than expected | Decrease `hook_gap_tolerance`. Add rubber grip pad inside hook. |
| **Arms flex under device weight** | Tablet too heavy, thin arms | Increase `mount_arm_width` to 25mm. Use 40% infill on arms. |
| **Shelf sags with heavy tablet** | iPad + case = ~500g | Increase `base_thickness` to 3.0mm. Increase infill to 40%. |
| **Multi-part joints loose** | Bolt holes too large, tolerance issue | Use M3 bolts with lock nuts. Apply a drop of thread-lock if permanent. |
| **Splash damage to device** | Cooking splatter reaches screen | Mount away from stovetop. The holder keeps device higher and angled, reducing splash risk vs. counter placement. |

---

## Customization Guide

| Parameter | Default | When to Change |
|-----------|---------|----------------|
| `device_preset` | iPhone | Change to match your device. |
| `shelf_angle` | 75° | Adjust for cabinet height — higher cabinet = lower angle. |
| `lip_height` | 15mm | Increase for heavier tablets, decrease for phones. |
| `back_support_height` | 40mm | Increase if device tips backward. |
| `cabinet_thickness` | 18mm | Measure your cabinet shelf. |
| `device_clearance` | 2.0mm | Decrease to 1.5mm for a snugger fit, increase to 3.0mm for bulky cases. |
| `wall_thickness` | 2.5mm | Increase to 3.0mm for heavy tablets. |

**Test print recommendation:** Print the hook clamp portion first (just one arm) to verify fit on your cabinet before printing the full holder.
