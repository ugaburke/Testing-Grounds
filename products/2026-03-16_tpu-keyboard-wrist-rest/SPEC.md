# SPEC.md — TPU Lattice Wrist Rest (Keyboard-Specific)

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-16 | Initial design. Parametric TPU wrist rest with cubic lattice, keyboard presets, grip dots. |

---

## Print Settings

| Setting | Recommended Value | Notes |
|---------|-------------------|-------|
| Layer Height | 0.2mm | TPU handles 0.2mm well. Avoid 0.12mm — doubles print time with minimal benefit. |
| Infill | 15–20% Gyroid | Gyroid complements the internal lattice for progressive cushioning. |
| Infill Pattern | Gyroid | Gyroid provides omnidirectional flex, better than grid for cushion feel. |
| Wall Count | 4 perimeters | Matches shell_wall = 1.6mm. Provides structural integrity and smooth exterior. |
| Top/Bottom Layers | 3 | Matches shell_top/bottom = 1.2mm. |
| Supports | None required | Gentle slope (~3°) self-supports easily. |
| Print Speed | 20–30 mm/s | **Critical.** TPU will buckle, jam, or string above 30mm/s on most printers. |
| Retraction | 0.5–1.0mm, 25mm/s | Direct-drive only. Disable retraction entirely if using Bowden (but results will suffer). |
| Travel Speed | 100–150 mm/s | Keep travel fast to reduce stringing, but enable Z-hop. |
| Z-hop | 0.2mm | Prevents nozzle from dragging through soft TPU on travel moves. |
| Nozzle Temp | 220–235°C | Material dependent. eSUN eTPU-95A: 220°C. NinjaFlex: 230°C. |
| Bed Temp | 50°C | Glue stick on glass, or bare PEI. Too hot = bottom deforms. |
| Cooling Fan | 50% after layer 3 | Some cooling helps with bridging inside the lattice. |
| Flow Rate | 100–105% | TPU may need slight over-extrusion for good layer bonding. Test first. |

---

## Print Orientation

- **Orientation:** Flat, bottom face on the build plate.
- **Rationale:** The rest's bottom is the largest flat surface, providing excellent bed adhesion for the long print. The gentle ergonomic slope (~3°) prints without supports. Grip dots print as part of the first few layers.
- **No supports needed.**
- **Brim:** Recommended — 5mm brim improves adhesion for TPU (which tends to warp at corners on long prints). Easy to peel off TPU.

---

## Recommended Materials

| Material | Shore | Suitability | Feel Description |
|----------|-------|-------------|-----------------|
| **TPU 95A** | 95A | **Best overall** | Firm cushion with slight give. Recovers shape immediately. Best for typing. |
| TPU 85A | 85A | Softer option | Very squishy, noticeable compression under wrist weight. Some users prefer this. |
| TPU 98A | 98A | Firmer option | Barely compresses. Better for users who prefer minimal cushion but need anti-fatigue support. |

**Primary recommendation: TPU Shore 95A.** This is the most widely available, best-documented TPU durometer and provides the cushioning most users expect from a wrist rest.

**Specific filament recommendations:**
- eSUN eTPU-95A: Excellent price/performance, widely available, prints at 220°C
- Overture TPU 95A: Good layer adhesion, consistent diameter
- NinjaTek NinjaFlex: Premium option, slightly more elastic, prints at 230°C
- Polymaker PolyFlex TPU95: Excellent surface finish, easy to print

**NOT recommended:** PLA, PETG, ABS. These are rigid materials with zero cushioning — they defeat the entire purpose of a wrist rest.

---

## Estimated Print Time & Filament Usage

| Keyboard Size | Width | Time (est.) | Filament (est.) | Weight (est.) |
|---------------|-------|-------------|-----------------|---------------|
| 60% | 295mm | 2h 45min | ~95g | 95g |
| 65% | 317mm | 3h 00min | ~105g | 105g |
| 75% (default) | 332mm | 3h 15min | ~115g | 115g |
| TKL | 358mm | 3h 30min | ~125g | 125g |
| Full Size | 440mm | 4h 15min | ~155g | 155g |

*Estimates at 0.2mm layer height, 20% gyroid infill, 25mm/s, 0.4mm nozzle.*

Filament cost per unit: $2.85–$4.65 (at $30/kg TPU spool)

---

## Hardware Required

**None.** This is a single-piece print with no additional hardware.

Optional: Apply a thin coat of silicone spray to the top surface for smoother skin contact (some TPU has a "grippy" texture that can feel sticky).

---

## Known Failure Modes & Mitigation

| Failure Mode | Cause | Mitigation |
|-------------|-------|------------|
| **TPU jam/buckle in extruder** | Bowden tube gap, excessive retraction, too-fast speed | Direct-drive only. Retraction ≤1mm. Speed ≤30mm/s. |
| **Stringing between lattice walls** | TPU oozes easily at high temps | Lower temp to 220°C. Enable Z-hop 0.2mm. Accept minor stringing — it's internal and won't affect function. |
| **Bottom warping / corner lift** | TPU shrinks slightly on cooling, long print dimension | 5mm brim. Bed at 50°C. Glue stick on glass. PEI works without adhesive. |
| **Lattice walls not bonding to shell** | Under-extrusion on thin walls | Flow rate 100–105%. Ensure 4 perimeters match shell_wall. Slow down to 20mm/s for shell layers. |
| **Too soft / bottoming out** | Lattice too open, TPU too soft | Decrease lattice_cell to 6, increase lattice_wall to 1.6, or use 98A TPU. |
| **Too firm / no cushion feel** | Lattice too dense, TPU too hard | Increase lattice_cell to 10, decrease lattice_wall to 0.8, or use 85A TPU. |
| **Grip dots too aggressive on desk** | Dots catch on fabric desk mats | Reduce grip_dot_height to 0.4mm or remove dots entirely for cloth desk mat users. |

---

## Keyboard Sizing Reference

These widths were measured from commonly available keyboard specifications. Verify your specific model before printing — manufacturers vary ±5mm between revisions.

| Layout | Example Keyboards | Width (mm) | Preset |
|--------|-------------------|-----------|--------|
| 60% | Keychron Q4, K6, Anne Pro 2, Ducky One 2 Mini | 290–300 | `kb_width = 295` |
| 65% | Keychron Q2, K2, Drop ALT, Ducky One 2 SF | 313–321 | `kb_width = 317` |
| 75% | Keychron Q1 Pro, GMMK Pro, Varmilo VA87M | 327–337 | `kb_width = 332` |
| TKL | Keychron Q3, K8, Ducky One 2 TKL, Leopold FC750R | 354–362 | `kb_width = 358` |
| Full | Keychron Q5, K10, Ducky One 2, Leopold FC900R | 435–445 | `kb_width = 440` |

---

## Firmness Customization Guide

| Setting | Soft | Medium (Default) | Firm |
|---------|------|-------------------|------|
| `lattice_cell` | 10mm | 8mm | 6mm |
| `lattice_wall` | 0.8mm | 1.2mm | 1.6mm |
| TPU Durometer | 85A | 95A | 98A |
| Slicer Infill | 10% | 15–20% | 25–30% |

Mix and match — e.g., 95A TPU with soft lattice settings gives a "medium-soft" feel. The parametric design makes experimentation easy.
