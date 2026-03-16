# OPPORTUNITY.md — Cycle 7 Market Scan & Scoring

## Stage 1 — Market Scan (Primary Niche Operation, Cycle 7)

**Cycle:** 7
**Date:** 2026-03-16
**Mode:** Primary Niche Operation — Kitchen/Home (1 product per cycle)
**Sources:** Etsy, Amazon, Printables, MakerWorld, Thingiverse, Cults3D, MyMiniFactory, kitchen-home-deep-dive.md

---

### Candidate 1 — FIFO Gravity-Feed Can Dispenser (Parametric Shelf Depth + Can Size)

**Problem:** Canned goods get buried in the pantry. The can you need is always behind three others. Expiration dates get missed. FIFO (First In, First Out) dispensers solve this with gravity-feed: load from top, dispense from bottom-front. The oldest can is always next. But every pantry shelf is a different depth (10"–16"), and can sizes vary wildly (12oz beverages to 28oz tomatoes). No current product addresses both variables.

**Deep Findings:**
- **Etsy STL seller ElainesSweetLife:** 10,600+ sales and 1,200+ reviews on rolling can storage STL files. Proves massive demand for the digital product.
- **Etsy physical seller (listing 1879516522):** 3D printed 8-can dispenser for fridge, gravity-feed design. Limited to standard beverage cans only.
- **Free STL — rebeltaz design:** The most popular free can organizer across 6 platforms (Printables, Thingiverse, Cults3D, MyMiniFactory, Pinshape). WARNING: uses ~1kg filament (~$20) per unit — too expensive for most users.
- **Amazon — OnDisplay FIFO organizer:** BPA-free plastic, holds 10–12 cans, $15–25. Standard size only.
- **Amazon — BingoHive rolling organizer:** Standard 12oz cans only.
- **Key buyer feedback:** "I'd like to see the same design adapted to accommodate two different can sizes." "Wish there was a 12-inch deep version." "Great design but takes almost a full spool."
- **Buyer behavior:** Etsy seller reports customers ordering 5+ units after first purchase — strong repeat signal.

**Can Size Reference (Measured):**

| Can Type | Common Use | Diameter | Height |
|----------|-----------|----------|--------|
| 12oz Beverage | Soda, beer, seltzer | 66mm (2.6") | 123mm (4.83") |
| 12oz Food (#1) | Small vegetables | 68mm (2.69") | 101mm (4.0") |
| 15oz (#303) | Beans, diced tomatoes, soups | 81mm (3.19") | 113mm (4.44") |
| 28oz (#2.5) | Crushed tomatoes, peaches, pumpkin | 103mm (4.06") | 119mm (4.69") |

**Current Solutions & Gaps:**
- rebeltaz free STL is popular but uses 1kg filament — needs optimization
- No parametric design adjusting for shelf depth
- No can-size presets (most designs are standard 12oz or 15oz only)
- No modular lane system (print one lane, snap together for multi-lane)
- Physical Etsy sellers are few (2–3) and offer limited size options
- STL market is mature but our physical + parametric angle is novel

---

### Candidate 2 — Custom Utensil Drawer Organizer (Carried from Deep Dive — 4.2 Score)

**Problem:** Every kitchen drawer is a different size. Mass-produced organizers leave gaps. Wood custom organizers on Etsy cost $129–199.

**Sources:** kitchen-home-deep-dive.md (Opportunity 1)

**Current Solutions & Gaps:**
- OrganizeMyDrawers on Etsy charges $0.33/sq inch (10"×20" = $66) with 551 reviews
- 2–3 serious 3D printed sellers exist
- Free parametric STLs available but require OpenSCAD knowledge
- Contoured utensil-profile slots (shaped for whisks, spatulas) = no one does this

---

### Candidate 3 — Custom-Width Sink Sponge Holder (Carried — 3.9 Score)

**Problem:** Sink sponge holders don't fit non-standard sink divider widths. Explicit complaint: "It's too wide for my sink, so it slops around and falls off all the time."

**Sources:** kitchen-home-deep-dive.md (Opportunity 4)

**Current Solutions & Gaps:**
- Spool Forge is Star Seller with 4.8+ stars
- But no seller offers custom-width for specific sink dividers
- Silicone/stainless Amazon options are cheap ($8–15) but generic

---

### Candidate 4 — Cabinet Door-Mount Modular Organizer (Carried — 3.7 Score)

**Problem:** Under-sink cabinet doors are wasted space. Modular rail system with snap-on baskets.

**Sources:** kitchen-home-deep-dive.md (Opportunity 5)

**Current Solutions & Gaps:**
- McMaster3D has 2,300+ reviews for cabinet door pocket
- Free STLs exist on Printables
- Low competition for modular rail systems specifically
- But McMaster3D's lead is hard to overcome

---

### Candidate 5 — Bottle-Specific Pantry Organizer (Wine, Sauce, Water Bottles)

**Problem:** Pantry organizers focus on cans. Bottles (wine, hot sauce, water bottles, olive oil) have different dimensions and roll differently. No 3D printed bottle-specific pantry organizer exists.

**Sources:** kitchen-home-deep-dive.md gap analysis

**Current Solutions & Gaps:**
- Amazon has wine racks and generic bottle holders
- No 3D printed parametric bottle organizer on Etsy
- Niche within a niche — smaller market than cans
- Could be a product line extension of the can dispenser

---

### Candidate 6 — Tablet Holder v1.1 (Charging Pass-Through + Splash Guard Upgrade)

**Problem:** Our Cycle 5 tablet holder could be upgraded with two novel features: charging cable pass-through and splash guard for above-stove mounting.

**Sources:** kitchen-home-deep-dive.md gap analysis (no competitor offers these)

**Current Solutions & Gaps:**
- This is an upgrade to an existing product, not a new product
- Better executed as a v1.1 revision than a new pipeline entry
- Deferred to a revision cycle

---

## Stage 2 — Opportunity Scoring

| # | Candidate | Pain | Size | Feasibility | Competition Gap | Profit | **Avg** |
|---|-----------|------|------|-------------|-----------------|--------|---------|
| 1 | FIFO Can Dispenser (Parametric Depth + Size) | 4 | 5 | 4 | 4 | 4 | **4.2** |
| 2 | Custom Utensil Drawer Organizer | 4 | 5 | 3 | 3 | 4 | **3.8** |
| 3 | Custom-Width Sink Sponge Holder | 3 | 3 | 5 | 3 | 3 | **3.4** |
| 4 | Cabinet Door Modular Organizer | 3 | 4 | 4 | 2 | 3 | **3.2** |
| 5 | Bottle-Specific Pantry Organizer | 3 | 3 | 4 | 4 | 3 | **3.4** |
| 6 | Tablet Holder v1.1 (Upgrade) | 3 | 5 | 5 | 3 | 4 | **4.0** |

### Scoring Rationale for Top Candidate

**Candidate 1 — FIFO Can Dispenser (4.2 avg) ✅ ADVANCING**
- **Pain (4):** Cans getting buried and expiring is a real, recurring frustration. Not urgent but pervasive — affects every household with a stocked pantry. The buyer ordering 5+ units confirms strong satisfaction.
- **Size (5):** Massive market. Nearly every household has canned goods. 10,600+ STL sales from one seller alone proves demand at scale.
- **Feasibility (4):** Pure geometry — no moving parts, just sloped surfaces for gravity feed. Main challenge is filament usage (rebeltaz design uses 1kg). Our modular lane approach reduces per-print size. PETG recommended but PLA acceptable (dry pantry environment).
- **Competition Gap (4):** No parametric design with shelf depth presets AND can size presets. Physical sellers on Etsy are few (2–3) and offer single-size designs. The STL market is more crowded but we differentiate on physical + parametric.
- **Profit (4):** Physical at $30–50 per unit (multi-lane). STL at $6–8. Filament cost is higher than our other products (~$5–8 per unit at 250–400g PETG) but still 70%+ margin on physical. Repeat purchase behavior (5+ units) is exceptional.

### Held / Killed

| # | Candidate | Status | Reason |
|---|-----------|--------|--------|
| 2 | Utensil Drawer Organizer | Held for C8 | Strong candidate (3.8) but higher engineering effort. Natural next Kitchen product. |
| 3 | Sink Sponge Holder | Held | Moderate opportunity. Quick win for a future cycle. |
| 4 | Cabinet Door Organizer | Killed | McMaster3D's 2,300+ reviews create insurmountable moat. |
| 5 | Bottle Pantry Organizer | Held | Product line extension of can dispenser — add after C7 launch. |
| 6 | Tablet Holder v1.1 | Deferred | Better as a revision update than a new cycle entry. |

---

## Decision: Advancing Candidate 1 (FIFO Gravity-Feed Can Dispenser) as primary product.

**Rationale:** Highest score (4.2) with strong demand validation (10,600+ STL sales). Parametric shelf depth + can size presets fill a genuine gap. Modular lane design keeps individual prints manageable. Fourth Kitchen/Home product strengthens the "pantry organization" sub-line alongside the existing "under-cabinet" and "drawer" sub-lines.

**Product line strategy:** This launches the "pantry organization" sub-category within Kitchen/Home. Future extensions include bottle-specific organizers and tiered shelf risers.
