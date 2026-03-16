# SPEC.md — Custom Utensil Drawer Organizer (Contoured Slots)

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-16 | Initial design. Parametric drawer dimensions + contoured utensil-profile slots (serving spoon, spatula, whisk, tongs, ladle, peeler) + rectangular silverware section. |

---

## Print Settings

| Setting | Recommended Value | Notes |
|---------|-------------------|-------|
| Layer Height | 0.2mm | Standard quality. 0.28mm acceptable for faster prints — slot contours are smooth enough at coarse layers. |
| Infill | 15% Grid | Light — organizer bears minimal load (utensils, not cans). Lower infill saves filament on large prints. |
| Wall Count | 3 perimeters | Structural walls between slots need rigidity. |
| Top/Bottom Layers | 3 | Base needs to be solid for drain holes; top layers form slot rims. |
| Supports | None required | Flat geometry, no overhangs. |
| Print Speed | 60–80 mm/s | Faster speeds acceptable — no fine detail beyond label embossing. |
| Brim | Recommended | Large footprint benefits from a 5mm brim to prevent warping, especially in PETG. |

---

## Print Orientation

- **Orientation:** Flat, base down on build plate.
- **Rationale:** The organizer sits in the drawer exactly as printed. Base is the floor, walls grow upward. No overhangs, no supports.

### Build Plate Splitting

Most kitchen drawers exceed typical build plate sizes (220mm–256mm). The design must be split:

| Drawer Width | Build Plate | Sections Required | Joint Type |
|-------------|-------------|-------------------|------------|
| ≤ 250mm | 256mm (Prusa/Bambu) | 1 (no split) | N/A |
| 251–500mm | 256mm | 2 (left + right) | Tongue & groove |
| 501–750mm | 256mm | 3 (left + center + right) | Tongue & groove |
| ≤ 350mm | 350mm (Bambu X1) | 1 (no split) | N/A |

**Joint method:** Tongue-and-groove interlocking edges. Apply CA glue or friction-fit. Joints align at natural divider walls between utensil slots so the seam is invisible.

---

## Recommended Materials

| Material | Suitability | Notes |
|----------|-------------|-------|
| **PETG** | **Best overall** | Durable, humidity-resistant, dishwasher-safe (top rack). Won't warp in humid kitchen environments. Consistent with kitchen product line standard. |
| **PLA** | Acceptable | Cheaper, easier to print. May warp in high-humidity kitchens over months. Not dishwasher-safe. Fine for dry climates. |
| PLA+ | Good | Better humidity tolerance than PLA. Good budget option. |
| ABS | Unnecessary | Heat/chemical resistance not needed in a drawer. Warping risk during print. |

**Primary recommendation: PETG.** Kitchen drawers see moisture from freshly washed utensils being placed back. PETG handles this. PLA is acceptable for buyers in dry climates.

---

## Estimated Print Time & Filament Usage

| Configuration | Drawer Size | Sections | Time (est.) | Filament | Weight |
|--------------|-------------|----------|-------------|----------|--------|
| Silverware-Only Insert | 250mm × 350mm | 1 | 4.5 hours | ~22m / 200g | 200g |
| Standard Drawer | 380mm × 500mm | 2 | 7.5 hours | ~38m / 350g | 350g |
| Large Drawer | 450mm × 600mm | 2 | 10 hours | ~50m / 460g | 460g |
| XL Drawer | 500mm × 750mm | 3 | 14 hours | ~68m / 620g | 620g |

*Estimates at 0.2mm layer height, 15% infill, 70mm/s, 0.4mm nozzle.*

### Filament Cost Comparison

| Product | Material Cost | Selling Price | Filament Margin |
|---------|-------------|---------------|-----------------|
| Standard Drawer (PETG) | ~$7.00 | $69.99 | 90% |
| Standard Drawer (PLA) | ~$5.25 | $69.99 | 92% |
| Silverware-Only (PETG) | ~$4.00 | $39.99 | 90% |

---

## Contoured Utensil Profiles — Design Reference

The key innovation. Each profile is a 2D polygon extruded to wall height, shaped to match the utensil's cross-section.

| Utensil | Profile Shape | Head Width | Handle Width | Notes |
|---------|--------------|------------|-------------|-------|
| **Serving Spoon** | Oval bowl → narrow handle | ~70mm | ~28mm | Bowl section holds the wide head; handle channel keeps it straight |
| **Spatula** | Wide rectangle → narrow handle | ~80mm | ~25mm | Widest profile — flat blade needs lateral space |
| **Whisk** | Bulbous bottom → tapered handle | ~65mm | ~22mm | Egg shape captures the wire cage; tight handle keeps it upright |
| **Tongs** | Medium head → long narrow body | ~50mm | ~35mm | Relatively uniform width; longer than most utensils |
| **Ladle** | Deep round bowl → narrow handle | ~85mm | ~24mm | Largest bowl — needs the most lateral space |
| **Peeler** | Slight blade widening → narrow handle | ~40mm | ~25mm | Smallest profile — narrowest slot in the organizer |

### Why Contoured Slots Matter

1. **Utensils stay put.** A serving spoon in a rectangular slot slides around. In a contoured slot, the bowl nests into the oval and the handle sits in the channel.
2. **Space efficiency.** Rectangular slots must be wide enough for the widest part of any utensil. Contoured slots taper — the handle portion is narrow, freeing space for adjacent slots.
3. **Visual organization.** Each slot is shaped for one utensil type. You know instantly where everything goes. It's the "shadowboard" concept from workshop tool organization, applied to kitchen drawers.

---

## Label Embossing

When `label_emboss = true`, each slot gets a small embossed text label at the bottom:

| Slot Type | Label Text |
|-----------|-----------|
| Fork | FORKS |
| Knife | KNIVES |
| Spoon | SPOONS |
| Teaspoon | TEASPOONS |
| Serving Spoon | SERVING |
| Spatula | SPATULA |
| Whisk | WHISK |
| Tongs | TONGS |
| Ladle | LADLE |
| Peeler | PEELER |
| Catchall | MISC |

Labels are embossed 0.6mm deep — visible but subtle. Readable in a contrasting filament color (e.g., white text on gray organizer). Set `label_depth = 0` to disable.

---

## Known Failure Modes & Mitigation

| Failure Mode | Cause | Mitigation |
|-------------|-------|------------|
| **Organizer doesn't fit drawer** | Measurement error | Provide clear instructions: measure INTERIOR dimensions (not exterior), subtract 2mm on each side for clearance. We validate dimensions before printing. |
| **Slots too tight for utensils** | Utensil is larger than preset profile | `slot_clearance` parameter adds buffer (default 2mm per side). Increase to 3–4mm for oversized utensils. |
| **Slots too loose** | Utensil is smaller than preset profile | Reduce `slot_clearance` to 1mm. Or suggest buyer tries a different profile preset. |
| **Warping on large prints** | PETG/PLA shrinkage on large flat parts | Use brim (5mm+). Ensure heated bed at 70°C (PETG) or 60°C (PLA). Consider splitting into more sections. |
| **Section joints visible** | Tongue-and-groove seam | Joints align with divider walls — visually hidden. Sand joint edges if needed. CA glue for permanent bond. |
| **Base too thin / fragile** | Heavy utensils dropped into slots | Default 1.5mm base is sufficient. Increase to 2.0mm for heavy utensil sets. Enable drain holes (structural perforations actually add rigidity). |
| **Drain holes clog** | Food debris accumulates | Holes are 4mm diameter, 20mm spacing. Large enough to clear with running water. Remove organizer and rinse periodically. |

---

## Customization Guide

| Parameter | Default | When to Change |
|-----------|---------|----------------|
| `drawer_width` | 380mm | Measure your drawer's interior width. |
| `drawer_depth` | 500mm | Measure front-to-back interior depth. |
| `drawer_height` | 60mm | Measure interior height. Organizer won't exceed this. |
| `silverware_depth_pct` | 45% | Increase for large silverware collections; decrease if utensil section needs more space. |
| Slot counts (forks, knives, etc.) | Varies | Match your household's utensil inventory. |
| `slot_clearance` | 2.0mm | Increase for thick-handled utensils; decrease for slim Japanese-style utensils. |
| `wall_thickness` | 2.0mm | Increase to 2.5mm for extra rigidity. Decrease to 1.5mm for tight drawers. |
| `corner_radius` | 3.0mm | Aesthetic. Increase to 5mm for softer look; set to 0 for sharp corners. |
| `label_emboss` | true | Set false for plain slots. |
| `bottom_drain_holes` | true | Set false if you prefer a solid base. |

---

## Ordering Workflow (Physical Product)

For Etsy orders, the buyer provides:

1. **Drawer dimensions** — width, depth, height (interior measurements)
2. **Utensil inventory** — how many of each type (forks, knives, serving spoons, etc.)
3. **Material preference** — PETG (recommended) or PLA
4. **Color** — from available PETG/PLA colors

We then:
1. Validate dimensions (flag anything suspicious — e.g., a 100mm-wide "drawer" is probably wrong)
2. Generate the parametric design with their slot configuration
3. Split for build plate if needed
4. Print, assemble sections (if split), quality check
5. Ship in flat packaging with assembly instructions (if multi-section)

**Turnaround:** 3–5 business days (print time + QC + ship). Faster than wood custom (2–3 weeks).
