# OPPORTUNITY.md — Cycle 8 Market Scan & Scoring

## Stage 1 — Market Scan (Primary Niche Operation, Cycle 8)

**Cycle:** 8
**Date:** 2026-03-16
**Mode:** Primary Niche Operation — Kitchen/Home
**Sources:** Etsy, Amazon, Printables, MakerWorld, Thingiverse, kitchen-home-deep-dive.md, fresh web search

---

### Candidate 1 — Custom Utensil Drawer Organizer with Contoured Slots

**Problem:** Kitchen drawer organizers universally use rectangular grid compartments. Every spoon, spatula, whisk, and tongs gets the same boxy slot. Result: wasted space, utensils don't nest neatly, tall items tip over, and wide utensils (serving spoons, spatulas) don't fit in narrow rectangular slots. Meanwhile, wood custom organizers cost $129–199 on Etsy with 2–3 week lead times.

**Evidence & Competitive Analysis:**

| Seller | Platform | Price | Design | Reviews | Gap |
|--------|----------|-------|--------|---------|-----|
| MavisLab (Custom Silverware/Utensil) | Etsy | ~$50–80 custom | Rectangular grid, per-sq-inch pricing | 56 favorites | No shaped slots |
| PrintopiaLA3D (Fork & Spoon Holder) | Etsy | ~$20–35 | Pre-made rectangular compartments | New listing (Jan 2026) | Fixed sizes, no custom |
| Budget Utility Divider | Etsy | ~$30–50 | No-bottom, 1/8" walls, rectangular | Good reviews | Budget-only, no profiles |
| Drawer Organizer Generator (OpenSCAD STL) | Etsy | ~$5–10 digital | Parametric rectangular grid, Bambu 3mf | New listing | Generator, but still rectangles only |
| OrganizeMyDrawers | Etsy | $0.33/sq in ($66–$95) | Custom rectangular grid | 551+ reviews | Dominant but rectangles only |
| DoopyWoopy Modular Parametric | Printables | Free | Dovetail modular, Fusion 360 | Popular download | Free threat, but still rectangular |
| MakerWorld Customizable | MakerWorld | Free | Full parametric, instant download | Popular | Free threat, rectangular |
| OldSaguaroWoodcraft (Wood) | Etsy | $129–199 | Custom wood, hand-made | 241+ reviews, Star Seller | Premium benchmark, 2–3 week wait |
| Neat Shop (Wood) | Web | $129–199 | Custom wood | 570+ reviews | Premium benchmark |

**The Gap:** Every single competitor — paid and free, physical and digital — uses rectangular compartments. No one offers **utensil-profile slots** where the compartment shape matches the utensil:
- A **serving spoon slot** is oval-shaped with a narrow handle channel
- A **spatula slot** is wide and flat
- A **whisk slot** is tapered
- A **tongs slot** is long and narrow with a wider head

This is the equivalent of what high-end wood organizers do by hand (custom-routed channels for each utensil). We do it parametrically.

**Additional Signals:**
- "I wish my drawer organizer actually held utensils in place instead of them sliding around" — recurring complaint on Amazon reviews of bamboo expandable organizers
- IKEA-specific organizers (Alex drawers) are Star Sellers on Etsy, confirming brand-specific/size-specific demand
- Gridfinity kitchen kits gaining traction but still rectangular bins
- One-time cost for buyers vs. $129–199 wood = massive value proposition

---

### Candidate 2 — Bottle-Specific Pantry Organizer (Carried from C7)

**Problem:** Pantry organizers focus on cans. Bottles (wine, hot sauce, water bottles, olive oil) roll, tip, and waste space. No 3D printed bottle-specific parametric organizer exists.

**Source:** kitchen-home-deep-dive.md gap analysis, C7 backlog

---

### Candidate 3 — Custom-Width Sink Sponge Holder (Carried from C7 — 3.9)

**Problem:** Sink sponge holders don't fit non-standard sink divider widths. Explicit complaint: "too wide for my sink."

**Source:** kitchen-home-deep-dive.md (Opportunity 4)

---

### Candidate 4 — Under-Shelf Hanging Basket (Pantry/Cabinet)

**Problem:** Under-shelf baskets are popular on Amazon in wire ($10–20). A 3D-printed version with custom shelf-thickness clips could serve non-standard shelving.

**Source:** kitchen-home-deep-dive.md gap analysis (Category 4)

---

### Candidate 5 — "Whole Kitchen" Bundle Pricing Model (Business Model, Not Product)

**Problem:** No Etsy seller offers bundled custom organizers across multiple drawers. A "measure your 3 drawers, get all 3 organizers" package could increase AOV.

**Source:** kitchen-home-deep-dive.md gap analysis

---

### Candidate 6 — Costco Bulk Roll Dispenser (Under-Cabinet, >12" Width)

**Problem:** All under-cabinet wrap dispensers assume standard 12" rolls. Costco/bulk rolls are wider (15"–18"). No dispenser fits them.

**Source:** kitchen-home-deep-dive.md gap analysis (Category 2, low priority)

---

## Stage 2 — Opportunity Scoring

| # | Candidate | Pain | Size | Feasibility | Competition Gap | Profit | **Avg** |
|---|-----------|------|------|-------------|-----------------|--------|---------|
| 1 | Utensil Drawer Organizer (Contoured Slots) | 4 | 5 | 4 | 5 | 5 | **4.6** |
| 2 | Bottle-Specific Pantry Organizer | 3 | 3 | 4 | 4 | 3 | **3.4** |
| 3 | Custom-Width Sink Sponge Holder | 3 | 3 | 5 | 3 | 3 | **3.4** |
| 4 | Under-Shelf Hanging Basket | 3 | 4 | 3 | 3 | 3 | **3.2** |
| 5 | Whole Kitchen Bundle (Business Model) | 3 | 4 | 5 | 4 | 4 | **4.0** |
| 6 | Costco Bulk Roll Dispenser | 2 | 2 | 5 | 4 | 2 | **3.0** |

### Scoring Rationale — Top Candidate

**Candidate 1 — Utensil Drawer Organizer with Contoured Slots (4.6 avg) ✅ ADVANCING**

- **Pain (4):** Utensils sliding around, not fitting, wasted space — recurring frustration in every kitchen. Not emergency-level pain but universally relatable. Wood custom organizers solving this are priced at $129–199 and still sell strongly.
- **Size (5):** Every household has a utensil drawer. The custom wood market alone has multiple Star Sellers with 200–500+ reviews each. 3D printed sellers have 50–551 reviews. Massive addressable market.
- **Feasibility (4):** Contoured slots are more complex than rectangular grids — requires profiling common utensil shapes (serving spoon, spatula, whisk, tongs, ladle, etc.). OpenSCAD can handle this with 2D polygon extrusion. The custom drawer sizing is proven (our C3 spice organizer uses the same parametric workflow). One complexity: each customer may have unique utensils, so we need sensible presets rather than per-utensil customization.
- **Competition Gap (5):** **Zero competitors offer contoured/profiled utensil slots.** Not one. Every Etsy seller, every free STL, every MakerWorld model uses rectangular grids. This is the widest gap we've found since the spice organizer's brand-specific jar presets (C3, also scored 5 on competition gap).
- **Profit (5):** Wood custom organizers sell for $129–199. 3D printed rectangular versions sell for $50–95. Our contoured version slots between: premium over rectangular ($65–110 for a full drawer), massive discount vs. wood. Material cost: ~$8–15 in PETG. Margins above 75%. STL market is also strong — the Drawer Organizer Generator on Etsy proves people will pay for parametric source files.

### Held / Killed

| # | Candidate | Status | Reason |
|---|-----------|--------|--------|
| 2 | Bottle Pantry Organizer | Held for C9+ | Niche within niche. Better as pantry sub-line extension after FIFO establishes. |
| 3 | Sink Sponge Holder | Held | Quick win for a slow cycle. |
| 4 | Under-Shelf Hanging Basket | Killed | Feasibility concern — clip mechanism varies too much across shelf types. |
| 5 | Whole Kitchen Bundle | Noted | Business model improvement, not a product cycle. Implement when portfolio has 3+ kitchen drawer products. |
| 6 | Costco Bulk Roll Dispenser | Killed | Too niche, Amazon competition too strong, weak 3D printing advantage. |

---

## Decision: Advancing Candidate 1 (Custom Utensil Drawer Organizer with Contoured Slots)

**Rationale:** Highest score this pipeline has produced (4.6, tied with C3 Spice Organizer). The contoured slot innovation is a genuine differentiator with zero competition. Natural extension of the drawer sub-line. Same parametric workflow as proven products. Premium pricing justified by design complexity and unique value proposition.

**Sub-line positioning:** This is the second product in the "Drawer Organization" sub-line, alongside the C3 Spice Drawer Organizer. Together, they form the foundation for the "Whole Kitchen Bundle" business model (Candidate 5) when a third drawer product is added.
