# SPEC.md — Modular Pet Puzzle Feeder with Swappable Difficulty Inserts

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-03-16 | Initial design. Modular base with 4 difficulty levels (sliding, rotating, maze, combination). 3 size presets (Puppy, Standard, Large). |

---

## Print Settings

| Setting | Recommended Value | Notes |
|---------|-------------------|-------|
| Layer Height | 0.2mm | Good balance. 0.16mm for smoother food-contact surfaces. |
| Infill | 30% Grid | Higher than typical — must withstand dog pawing and nosing forces. |
| Wall Count | 4 perimeters | Extra durability for pet use. Dogs will push, paw, and nose aggressively. |
| Top/Bottom Layers | 5 | Strong base to handle repeated impacts. |
| Supports | None | All parts designed for support-free printing. |
| Print Speed | 50 mm/s | Moderate speed for strong layer adhesion. Structural integrity is critical. |
| Brim | Recommended for base | 5mm brim helps with the large, flat base footprint. |

---

## Print Orientation

### Base Tray
- **Orientation:** Upright as designed — open side up.
- **Rationale:** The tray is a shallow box. Prints cleanly with no overhangs.

### Level 1 — Sliding Panels
- **Orientation:** Flat on build plate.
- **2 panels per set.** Fit on a single 220mm build plate.

### Level 2 — Rotating Disc
- **Orientation:** Flat, disc face up. Flip for printing (center post points down, use a small brim).
- **Alternative:** Print disc flat, print center post separately, friction-fit assembly.

### Level 3 — Maze Frame + Gates
- **Orientation:** Frame flat. Gates flat separately.
- **4 pieces total:** 1 frame + 3 sliding gates.

### Level 4 — Combination
- **Orientation:** Bottom panel flat. Top disc flat (separate print). Pegs print with disc.
- **3 pieces total:** Bottom panel, top disc, 2 locking pegs (integrated with disc).

---

## Recommended Materials

| Material | Suitability | Notes |
|----------|-------------|-------|
| **PETG** | **Required** | Food-adjacent safe. No BPA. Must be coated with food-safe epoxy for food contact. Stainless steel nozzle recommended. |
| PLA | Not recommended | Brittle under dog force. Not food-safe. Will crack with repeated pawing. |
| ABS | Acceptable | Strong and durable. But fumes during printing, requires enclosure. Food safety similar to PETG with coating. |
| TPU | Not suitable | Too flexible for puzzle mechanics — sliding/rotating parts need rigidity. |

**Primary recommendation: PETG with food-safe epoxy coating.**

---

## Estimated Print Time & Filament Usage

| Component | Size | Time (est.) | Filament (est.) | Weight |
|-----------|------|-------------|-----------------|--------|
| Base Tray | Standard | 2.5 hours | ~26m / 80g | 80g |
| Base Tray | Puppy | 1.5 hours | ~16m / 50g | 50g |
| Base Tray | Large | 3.5 hours | ~38m / 115g | 115g |
| Level 1 — Sliding Panels (×2) | Standard | 40 min | ~7m / 20g | 20g |
| Level 2 — Rotating Disc | Standard | 50 min | ~8m / 25g | 25g |
| Level 3 — Maze + Gates | Standard | 1 hour | ~10m / 30g | 30g |
| Level 4 — Combination | Standard | 50 min | ~8m / 25g | 25g |
| **Full System (Base + All 4 Levels)** | **Standard** | **~6 hours** | **~59m / 180g** | **180g** |

*Estimates at 0.2mm layer height, 30% infill, 50mm/s, 0.4mm nozzle.*

Filament cost per full system: ~$3.60 (at $20/kg PETG)

---

## Hardware Required

**None.** All parts are friction-fit or self-contained.

- Center post for Level 2 rotator friction-fits into a hole in the base center
- Sliding gates (Level 3) slide in channels — no hardware
- Locking pegs (Level 4) are integrated with the disc — pull to release

---

## Dog Size Reference

| Size | Base Dimensions | Compartment Depth | Target Dog Weight | Preset Name |
|------|----------------|-------------------|-------------------|-------------|
| **Puppy** | 180×180mm | 22mm | Under 20 lbs | `Puppy` |
| **Standard** | 250×250mm | 30mm | 20–60 lbs | `Standard` |
| **Large** | 320×320mm | 38mm | 60+ lbs | `Large` |
| **Custom** | User-defined | User-defined | Any | `Custom` |

**Note:** Size affects treat compartment dimensions. Larger dogs need deeper compartments and wider openings. The puzzle mechanics remain the same across all sizes.

---

## Difficulty Level Descriptions

### Level 1 — Sliding Panels (Beginner)
- **Mechanic:** Two panels slide left/right to reveal treat compartments beneath.
- **Dog action:** Nose or paw the panel sideways.
- **Typical solve time:** 1–5 minutes for first attempt, <1 minute once learned.
- **Best for:** Puppies, puzzle beginners, senior dogs.

### Level 2 — Rotating Disc (Intermediate)
- **Mechanic:** Disc rotates on a center post. Treat holes align with compartments at specific rotations.
- **Dog action:** Nose the edge of the disc to rotate it until holes align.
- **Typical solve time:** 3–10 minutes for first attempt.
- **Best for:** Dogs who mastered Level 1 in under 2 minutes.

### Level 3 — Sequential Maze (Advanced)
- **Mechanic:** Three sliding gates in sequence. Gate A must be opened before Gate B is accessible.
- **Dog action:** Paw/nose gates open in the correct sequence.
- **Typical solve time:** 5–15 minutes for first attempt.
- **Best for:** Smart breeds (Border Collies, Poodles, GSDs, Aussies).

### Level 4 — Multi-Step Combination (Expert)
- **Mechanic:** Locking pegs must be pulled FIRST, then disc rotates, then bottom panel slides.
- **Dog action:** Multiple sequential actions — pull, rotate, slide.
- **Typical solve time:** 10–30+ minutes for first attempt.
- **Best for:** Dogs who solve Level 3 in under 5 minutes.

---

## Food Safety Protocol

### For Physical Products (Seller)
1. Print with PETG using **stainless steel nozzle** (no brass — may contain lead traces)
2. Sand all food-contact surfaces with 220-grit sandpaper to smooth layer lines
3. Clean thoroughly with isopropyl alcohol
4. Apply **2 coats food-safe epoxy** (recommended: ArtResin or Masterbond EP42HT-2FG)
5. Allow **72-hour full cure** before shipping
6. Include care card with cleaning instructions

### For STL Buyers (Self-Print)
Include a food-safe coating guide in the STL download:
- PETG with stainless steel nozzle
- Sand surfaces smooth
- Apply food-safe epoxy or polyurethane (link to recommended products)
- Cure completely before use
- Hand wash only

### Care Instructions (Included with Physical Product)
- Hand wash with warm water and mild dish soap after each use
- Do NOT put in dishwasher (may warp PETG or degrade epoxy coating)
- Inspect coating periodically — recoat if worn or chipped
- Replace if deep scratches expose bare PETG

---

## Known Failure Modes & Mitigation

| Failure Mode | Cause | Mitigation |
|-------------|-------|------------|
| **Base cracks from dog impact** | Large/strong dog pawing aggressively | Increase to 40% infill and 5 wall perimeters for Large size. Use PETG (flex absorbs impact). |
| **Insert stuck / won't slide** | Dimensional tolerance too tight | Increase `compartment_clearance` to 1.5mm. Sand rail guides. |
| **Insert too loose** | Over-tolerance | Decrease clearance to 0.7mm. |
| **Rotating disc won't turn** | Center post too tight in base hole | Sand post slightly. Ensure base hole is clean after epoxy coating. |
| **Locking pegs (L4) too hard to pull** | Dog can't grip pegs | Increase peg diameter to 8mm. Add texture to peg top. |
| **Epoxy coating chips** | Aggressive chewing (not designed for chewing) | Inspect regularly. Recoat as needed. Include warning: "Not a chew toy." |
| **Dog flips entire base** | Lightweight base, strong dog | Recommend placing on non-slip mat. Large size can be weighted by putting dry rice under base. |

---

## Customization Guide

| Parameter | Default | When to Change |
|-----------|---------|----------------|
| `dog_size` | Standard | Match to your dog's size/strength. |
| `num_compartments` | 6 | Fewer for beginners (4), more for advanced (8–9). |
| `compartment_clearance` | 1.0mm | Tune for your printer's tolerance. Test with one insert first. |
| `wall_thickness` | 3.0mm | Increase to 4.0mm for aggressive/large dogs. |
| `base_thickness` | 3.0mm | Increase for heavy dogs that paw aggressively. |
| `corner_radius` | 8.0mm | Maintain or increase for safety. Never decrease below 5mm. |

**Safety note:** All corners are rounded with 8mm radius by default. Do NOT reduce corner radius — dogs interact with their face and paws, and sharp corners can cause injury.
