# SPEC.md — Under-Cabinet K-Cup/Coffee Pod Holder

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-16 | Initial design. Under-cabinet hook-clamp mount with pod-type presets (K-Cup, Nespresso Vertuo, Nespresso Original). |

---

## Print Settings

| Setting | Recommended Value | Notes |
|---------|-------------------|-------|
| Layer Height | 0.2mm | Standard quality. 0.16mm for smoother pod slot walls. |
| Infill | 30% Grid | Slightly higher than typical — hooks bear the weight of loaded pods. |
| Wall Count | 3 perimeters | Solid hooks and pod slot walls. |
| Top/Bottom Layers | 4 | Solid base prevents pod push-through. |
| Supports | Minimal | Hook interior may need supports depending on orientation. Print upside-down to avoid. |
| Print Speed | 50–70 mm/s | Slow to 40 mm/s for hook clamp area for better layer adhesion under load. |
| Brim | Recommended | Hooks create a small contact patch — brim improves adhesion. 5mm brim. |

---

## Print Orientation

- **Orientation:** Upside-down — hooks pointing UP on the build plate, rail flat side down.
- **Rationale:** This orientation places the visible underside of the rail against the build plate (smooth finish) and prints the hook geometry growing upward, minimizing overhangs. The hook's C-shape internal slot prints cleanly as a bridge rather than an overhang.
- **Alternative:** Right-side-up with supports inside the hook clamp. Works but wastes material and leaves rough surfaces inside the hook slot.

---

## Recommended Materials

| Material | Suitability | Notes |
|----------|-------------|-------|
| **PETG** | **Best overall** | Kitchen-safe, heat resistant, slightly flexible for hook clamp fit. Ideal for the snap-on mounting mechanism. |
| PLA+ | Acceptable | Works if cabinet is away from heat sources. Less flexible than PETG — hook clamp may be tighter. |
| PLA | Not recommended | Brittle hooks may crack during installation. Warps near heat. |
| ABS | Overkill | Good mechanical properties but requires enclosure and produces fumes. |

**Primary recommendation: PETG.** Consistent with all kitchen products in our line.

---

## Estimated Print Time & Filament Usage

| Configuration | Pods | Time (est.) | Filament (est.) | Weight |
|--------------|------|-------------|-----------------|--------|
| Single Rail (6-pod, K-Cup) | 6 | 55–70 min | ~8m / 25g | 25g |
| Single Rail (6-pod, Nespresso Vertuo) | 6 | 65–80 min | ~10m / 30g | 30g |
| Single Rail (6-pod, Nespresso Original) | 6 | 40–50 min | ~6m / 18g | 18g |
| Double Pack (K-Cup) | 12 | 1.8–2.3 hours | ~16m / 50g | 50g |
| Starter Set (3 rails, K-Cup) | 18 | 2.7–3.5 hours | ~24m / 75g | 75g |

*Estimates at 0.2mm layer height, 30% infill, 60mm/s, 0.4mm nozzle.*

Filament cost per rail (K-Cup): ~$0.50 (at $20/kg PETG)

---

## Hardware Required

**None.** The hook clamp slides over the cabinet shelf edge — no screws, no adhesive, no tools.

Optional: Rubber grip pads inside the hook slot to prevent sliding on smooth shelf surfaces. A small strip of shelf liner works well.

---

## Pod Dimension Reference

| Pod Type | Top Diameter | Bottom Diameter | Height | Preset Name |
|----------|-------------|-----------------|--------|-------------|
| **K-Cup** (standard) | 48mm (1.89") | 35mm (1.38") | 42mm (1.65") | `KCup` |
| **Nespresso Vertuo** (standard) | 56mm (2.20") | 50mm (1.97") | 54mm (2.13") | `NespressoVertuo` |
| **Nespresso Original** | 37mm (1.46") | 37mm (1.46") | 26mm (1.02") | `NespressoOriginal` |
| **Custom** | User-defined | User-defined | User-defined | `Custom` |

**Note:** Slot clearance of 1.5mm is added automatically on each side. Pods drop in easily and are held securely by the tapered slot shape.

### Pod Slot Design

The slot is tapered — wider at the top (matching the pod's top diameter) and narrower at the bottom (matching the pod's bottom diameter). This creates a natural cradle:
- K-Cups: The wide rim sits at the top of the slot, the tapered body nests into the narrower bottom
- Nespresso Vertuo: Similar taper profile, larger overall
- Nespresso Original: Nearly cylindrical — minimal taper, small drainage hole in base

A drainage hole in the base of each slot prevents liquid accumulation from any pod drips.

---

## Cabinet Compatibility

| Parameter | Default | Range | Notes |
|-----------|---------|-------|-------|
| `cabinet_thickness` | 18mm | 12–30mm | Standard kitchen cabinets are 16–19mm (⅝"–¾"). IKEA cabinets are typically 18mm. |
| `hook_depth` | 25mm | 15–35mm | How far the hook extends onto the top of the shelf. Deeper = more secure. |
| `hook_gap_tolerance` | 0.5mm | 0.3–1.0mm | Extra clearance in the hook slot. Increase for a looser fit, decrease for tighter grip. |
| `hook_lip` | 5mm | 3–8mm | Front lip prevents the holder from sliding off. |

### Installation

1. Slide the hook clamp over the front edge of the cabinet shelf from below.
2. Push the holder back until the front lip catches on the shelf edge.
3. The holder hangs securely under the cabinet.
4. Load pods into the slots from below.

### Weight Capacity

Each rail holds 6 pods. Loaded weights:
- K-Cup rail: 6 × 12g (pod) + 25g (rail) = **~97g** (3.4 oz)
- Nespresso Vertuo rail: 6 × 14g + 30g = **~114g** (4.0 oz)
- Nespresso Original rail: 6 × 6g + 18g = **~54g** (1.9 oz)

These weights are well within the capacity of the hook clamp design.

---

## Known Failure Modes & Mitigation

| Failure Mode | Cause | Mitigation |
|-------------|-------|------------|
| **Hook too tight on shelf** | Cabinet slightly thicker than measured, or PETG printed oversized | Increase `hook_gap_tolerance` to 0.8–1.0mm. Sand inside of hook slot. |
| **Hook too loose / slides** | Cabinet thinner than measured | Decrease `hook_gap_tolerance` to 0.3mm. Add rubber grip pad inside hook. |
| **Pods fall through slots** | Pod smaller than preset dimensions | Decrease `pod_clearance` to 1.0mm. Or switch to correct pod preset. |
| **Pods too tight in slots** | Pod variation within brand | Increase `pod_clearance` to 2.0mm. |
| **Rail sags under load** | Too many pods, too thin rail | Increase `rail_thickness` to 4.0mm. Use 40% infill. |
| **Hook breaks during install** | PLA brittleness, forcing onto shelf | Use PETG. Gently slide on — don't force. Warm PLA slightly before install. |
| **Rail doesn't fit cabinet width** | Cabinet narrower than rail length | Reduce `pods_per_rail` to 4 or 5. |

---

## Customization Guide

| Parameter | Default | When to Change |
|-----------|---------|----------------|
| `pod_preset` | KCup | Change to match your pod type. |
| `pods_per_rail` | 6 | Decrease for narrow cabinets, increase for wide ones. |
| `pod_clearance` | 1.5mm | Increase if pods are tight, decrease if they rattle. |
| `cabinet_thickness` | 18mm | Measure your cabinet shelf thickness with calipers. |
| `hook_depth` | 25mm | Increase for more security on deep shelves. |
| `hook_gap_tolerance` | 0.5mm | Tune for your printer and cabinet. Print a test hook first. |
| `wall_thickness` | 2.0mm | Increase to 2.4mm for heavier Vertuo pods. |
| `rail_thickness` | 3.0mm | Increase to 4.0mm if rail sags under full load. |

**Always print one test rail first** to verify hook fit on your specific cabinet before printing a full set.
