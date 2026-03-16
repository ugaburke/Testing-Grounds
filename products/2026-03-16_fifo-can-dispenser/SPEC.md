# SPEC.md — FIFO Gravity-Feed Can Dispenser (Parametric)

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-16 | Initial design. Modular single-lane FIFO system with 4 can size presets, 7 shelf depth options, snap-together multi-lane assembly. |

---

## Print Settings

| Setting | Recommended Value | Notes |
|---------|-------------------|-------|
| Layer Height | 0.2mm | Standard quality. The ramp surface benefits from smooth layers for can rolling. |
| Infill | 20% Grid | Moderate — the unit bears static load (stacked cans), not impact. |
| Wall Count | 3 perimeters | Solid walls for structural integrity under can weight. |
| Top/Bottom Layers | 4 | Solid ramp surface ensures smooth can rolling. |
| Supports | None required | Flat geometry with gentle ramp angle. No overhangs. |
| Print Speed | 60–70 mm/s | Standard speed. Ramp surface benefits from consistent extrusion. |
| Brim | Optional | Larger prints (14"–16" shelf depth) may benefit from a 3mm brim. |

---

## Print Orientation

- **Orientation:** Flat, with the ramp surface (bottom of the dispenser) on the build plate.
- **Rationale:** The gentle ramp angle (8° default) means the base sits nearly flat. The ramp is built into the geometry as a gradual slope. No supports needed. The build plate side becomes the smooth ramp surface where cans roll.
- **Batching:** Each lane prints individually. For a 3-lane set, run 3 consecutive prints or fit 2 lanes on a 300mm+ bed.

---

## Recommended Materials

| Material | Suitability | Notes |
|----------|-------------|-------|
| **PETG** | **Best overall** | Durable, slightly flexible (helps snap-fit connectors), temperature stable. Consistent with kitchen product line. |
| **PLA** | Acceptable | Pantry is dry and room-temp. PLA works fine here. Cheaper than PETG. Snap connectors may be more brittle. |
| PLA+ | Good | Better snap-fit performance than standard PLA. Good budget option. |
| ABS | Overkill | No heat or chemical resistance needed in a pantry. |

**Primary recommendation: PETG for consistency with kitchen line. PLA acceptable for budget-conscious buyers.**

---

## Estimated Print Time & Filament Usage

| Configuration | Can Size | Shelf Depth | Time (est.) | Filament | Weight |
|--------------|----------|-------------|-------------|----------|--------|
| Single Lane (6-can) | 15oz | 12" | 3.0 hours | ~18m / 180g | 180g |
| Single Lane (6-can) | 15oz | 10" | 2.5 hours | ~15m / 150g | 150g |
| Single Lane (6-can) | 15oz | 14" | 3.5 hours | ~21m / 210g | 210g |
| Single Lane (6-can) | 15oz | 16" | 4.0 hours | ~24m / 240g | 240g |
| Single Lane (8-can) | 12oz bev | 12" | 2.5 hours | ~14m / 140g | 140g |
| Single Lane (4-can) | 28oz | 12" | 3.5 hours | ~22m / 220g | 220g |
| Double Lane (12-can) | 15oz | 12" | 6.0 hours | ~36m / 360g | 360g |
| Triple Lane (18-can) | 15oz | 12" | 9.0 hours | ~54m / 540g | 540g |

*Estimates at 0.2mm layer height, 20% infill, 65mm/s, 0.4mm nozzle.*

**Filament cost comparison:**
| Design | Filament per 6-can unit | Cost @ $20/kg |
|--------|------------------------|---------------|
| rebeltaz (monolith, ~15 cans) | ~1000g | ~$20.00 |
| **Our design (single lane, 6 cans)** | **~180g** | **~$3.60** |
| Our design (triple lane, 18 cans) | ~540g | ~$10.80 |

Our modular design uses **46% less filament** for equivalent capacity vs. the rebeltaz monolith.

---

## Hardware Required

**None.** Lanes snap together with built-in tabs and slots. No screws, no glue.

Optional: A drop of CA glue on snap connectors for permanent multi-lane assembly.

---

## Can Dimension Reference

| Can Type | Common Contents | Diameter | Height | Preset Name |
|----------|----------------|----------|--------|-------------|
| **12oz Beverage** | Soda, beer, seltzer, sparkling water | 66mm (2.6") | 123mm (4.83") | `12oz_bev` |
| **12oz Food (#1)** | Small vegetables, tomato paste | 68mm (2.69") | 101mm (4.0") | `12oz_food` |
| **15oz (#303)** | Beans, diced tomatoes, soups, corn | 81mm (3.19") | 113mm (4.44") | `15oz` |
| **28oz (#2.5)** | Crushed tomatoes, peaches, pumpkin | 103mm (4.06") | 119mm (4.69") | `28oz` |
| **Custom** | User-defined | User-defined | User-defined | `Custom` |

**Can clearance** of 2.0mm per side is added automatically. Cans roll freely without jamming.

---

## Shelf Depth Compatibility

| Shelf Depth | Inches | mm | Common In |
|-------------|--------|-----|-----------|
| 10" | 10 | 254 | Narrow pantries, closets, small apartments |
| 11" | 11 | 279 | Older homes, non-standard shelving |
| 12" | 12 | 305 | **Most common** standard pantry shelf |
| 13" | 13 | 330 | Deeper pantries |
| 14" | 14 | 356 | Deep shelving units |
| 15" | 15 | 381 | Walk-in pantries |
| 16" | 16 | 406 | Deep utility shelving, garage pantries |

The lane depth is automatically calculated from the shelf depth parameter. 5mm clearance is subtracted so the unit doesn't protrude past the shelf edge.

---

## FIFO Mechanism — How It Works

1. **Load cans from the top-rear:** Drop cans into the loading slot at the back of the lane. Gravity pulls them down the ramp toward the front.
2. **Dispense from the front-bottom:** The front stop holds all cans in place. Reach in and pull the frontmost can out through the dispense opening.
3. **Auto-advance:** When the front can is removed, all remaining cans roll forward one position. The next can is now at the front.
4. **First In, First Out:** The first can loaded (bottom of the stack) is the first can dispensed. Newer cans are always behind older ones. No more expired cans hiding in the back.

### Ramp Angle

The default 8° ramp angle provides reliable gravity feed without cans accelerating too fast. Adjustable from 5° (gentle, for heavier 28oz cans) to 15° (steeper, for lighter beverage cans).

---

## Known Failure Modes & Mitigation

| Failure Mode | Cause | Mitigation |
|-------------|-------|------------|
| **Cans don't roll (stuck)** | Ramp angle too shallow, rough ramp surface | Increase `ramp_angle` to 10–12°. Ensure ramp surface is smooth (print face-down on build plate). |
| **Cans roll too fast (slam forward)** | Ramp too steep, lightweight cans | Decrease `ramp_angle` to 5–6°. Default 8° is good for most cans. |
| **Cans jam in lane** | Lane too narrow, can diameter variation | Increase `can_clearance` to 3.0mm. Some can brands have slight diameter variation. |
| **Lane doesn't fit shelf** | Shelf depth measurement error | Measure actual shelf depth (front edge to wall). Round DOWN to nearest inch. |
| **Snap connectors too tight** | PETG printed oversized | Sand snap tabs lightly. Increase `snap_tab_depth` tolerance. |
| **Snap connectors too loose** | PLA brittle or over-tolerance | Use CA glue for permanent bond. Or print in PETG for flex. |
| **Lane tips forward when loaded** | Center of gravity shifts with full cans | The ramp angle and front stop prevent this. If concerned, add a non-slip pad under the rear. |
| **Print exceeds build plate** | 16" shelf depth + 28oz cans | Lane may exceed 256mm. Print at slight diagonal or split into front/rear sections. |

---

## Customization Guide

| Parameter | Default | When to Change |
|-----------|---------|----------------|
| `can_preset` | 15oz | Change to match your most common canned goods. |
| `shelf_depth_inches` | 12 | Measure your pantry shelf depth. |
| `cans_per_lane` | 6 | Fewer for short shelves, more for deep ones. |
| `ramp_angle` | 8° | Increase for light cans, decrease for heavy cans. |
| `can_clearance` | 2.0mm | Increase if cans jam, decrease if they rattle. |
| `wall_thickness` | 2.0mm | Increase to 2.5mm for 28oz heavy cans. |
| `side_wall_height_pct` | 40% | Increase to 60% for tall, narrow cans that might tip. |
| `render_connectors` | true | Set false if printing a standalone single lane. |

**Test print recommendation:** Print one lane at your most common can size and shelf depth. Load it with cans and verify smooth rolling before printing a full set.
