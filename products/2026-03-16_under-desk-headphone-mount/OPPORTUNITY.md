# OPPORTUNITY.md — Cycle 1 Market Scan & Scoring

## Stage 1 — Market Scan (Wide-Scan Mode)

**Cycle:** 1
**Date:** 2026-03-16
**Mode:** Wide-scan (no niche commitment)
**Sources:** Reddit (r/3Dprinting, r/functionalprint, r/ender3, r/BambuLab, r/boardgames, r/MechanicalKeyboards, r/HomeImprovement), Etsy, Amazon, Printables, Thingiverse, MakerWorld, Bambu Lab Community Forum, BoardGameGeek

---

### Candidate 1 — Under-Desk Headphone Mount with Cable Channel

**Problem:** Store-bought adhesive and clamp headphone holders are consistently described as "flimsy" and prone to breaking. Thingiverse's most popular desk-mount headphone holder (by mistertech) was explicitly designed because the creator's previous five prints "all cracked in the same spot." Amazon budget stands ($10–20) have mixed reviews citing weak adhesive, poor clamping, and inability to accommodate different headband widths. XDA Developers article confirms users abandon Amazon purchases in favor of 3D-printed solutions.

**Sources:**
- Thingiverse thing:2076034 — "cracked on me (I've made 5 and they all cracked in the same spot)"
- XDA Developers — "many of the budget stands I found had mixed reviews or looked flimsy"
- Amazon Lamicall Headphone Stand (B09TDG4T7G) — mixed reviews on adhesive durability
- Etsy listing 856089072 — 3D printed desk clamp hanger, 30+ color options, Star Seller

**Current Solutions & Gaps:**
- Amazon adhesive mounts: fail on textured desks, leave residue, break under weight
- Existing 3D prints: crack at stress points (narrow clamp), don't accommodate wide headbands (>45mm), lack integrated cable management
- Etsy listings: exist but typically one-size clamp with no parametric sizing

---

### Candidate 2 — Bambu Lab AMS Cardboard Spool Rim Adapter

**Problem:** Cardboard filament spools deposit residue on AMS rubber rollers, causing clogs and deforming spool edges. Bambu Lab's own wiki documents this as a known issue. Community forum threads confirm it affects "all versions of the AMS" and is "printer independent" — reproduced with 10+ spools. The fix requires 3D-printed rings that fit around spool edges to prevent fraying.

**Sources:**
- Bambu Lab Wiki — "fix filament issues caused by unlocked spools"
- Bambu Lab Forum thread — "filament gets pulled to the side of the spool and jams"
- All3DP — Mods & Accessories for Bambu Lab AMS (Mar 2025)
- MakerWorld — multiple spool adapter designs with active comments

**Current Solutions & Gaps:**
- Free designs exist on MakerWorld and Printables but are brand/size-specific
- No universal parametric design that fits multiple spool widths/diameters
- High signal: every BambuLab printer owner with AMS needs this, and many use third-party cardboard-spool filament

---

### Candidate 3 — Gridfinity Cable/Wire Spool Holder (Stackable, Adjustable)

**Problem:** Existing Gridfinity spool holders have tight-fitting bases that don't match nominal spec, require gluing magnets, only fit slim spools, and don't accommodate thicker wires (>1mm). Multiple remixes on Thingiverse and MakerWorld address individual complaints but no single design solves all issues.

**Sources:**
- MakerWorld model 1752975 — "base was a little off and had a tight fit originally"
- MakerWorld model 1827248 — "original double pinch design didn't work great with thicker wires"
- Thingiverse thing:6467741 — stackable remix because "original did not allow for stacking"

**Current Solutions & Gaps:**
- 5+ competing designs, each fixing one problem while introducing others
- No single parametric design that handles variable spool widths, stackability, and spec-compliant bases
- Gridfinity ecosystem is massive and growing — modular workshop organization is a hot category

---

### Candidate 4 — Kitchen Sponge & Dishcloth Drying Rack

**Problem:** Kitchen countertop sponge holders from stores are either suction-cup (fall off), flimsy wire (rust), or bulky plastic (collect grime). 3D printed alternatives on Etsy (shop: 3DPartsdk) are selling well with positive reviews but limited to single designs. Printables has this as a trending category.

**Sources:**
- Etsy listing 4311780610 — 3DPartsdk sponge holder, positive reviews, Scandinavian design
- Siraya Tech blog — "store-bought bag clips break or vanish too often"
- Printables Awards 2025 — Practical & Functional Objects category finalist entries

**Current Solutions & Gaps:**
- Existing Etsy listings are single-configuration (one sponge + one cloth)
- No modular/parametric version that adapts to different sink widths or sponge sizes
- Material opportunity: PETG for water resistance is underutilized in current PLA-only listings

---

### Candidate 5 — Bambu Lab Purge/Waste Bucket with Deflector

**Problem:** AMS multi-color prints purge filament at high rates when switching colors. Without a bucket + deflector, purge material falls onto the desk/floor. Identified as a "must-have" first print for every AMS owner across multiple guides and forums.

**Sources:**
- Bambu Lab Forum — "P1S+AMS must-have printable upgrades" thread (Feb 2025)
- All3DP — listed as essential AMS mod
- Obico blog — "Best Upgrades for Bambu Lab 3D Printers"

**Current Solutions & Gaps:**
- Heavily covered category with many free designs
- Low differentiation opportunity — existing solutions are adequate
- Market is saturated with free alternatives

---

### Candidate 6 — Remote Control Caddy (Multi-Remote, Felt-Lined)

**Problem:** Living room remote clutter. Etsy seller MoonFlowerState has a Star Seller badge selling a 3D printed multi-remote holder with felt lining, suggesting proven demand.

**Sources:**
- Etsy listing 1793609357 — MoonFlowerState, Star Seller, multiple color options
- Etsy market page for "3D printed remote control holder" — active category

**Current Solutions & Gaps:**
- Proven sales exist but design is generic (rectangular caddy)
- Opportunity for couch-arm clip version, wall-mount version, or modular slot system
- Lower pain intensity — "nice to have" not "need to have"

---

### Candidate 7 — Custom-Width Cable Management Clips for Braided Sleeving

**Problem:** Store-bought cable clips assume standard round cable diameters and fail with braided sleeving, flat ribbon cables, or bundled cable runs. XDA Developers article confirms "typical cable clips sold online simply fail to account for various wire diameters."

**Sources:**
- XDA Developers — explicit mention of wire diameter mismatch
- r/functionalprint — cable management is a perennial top category
- Printables — cable clip designs are among most downloaded functional prints

**Current Solutions & Gaps:**
- Thousands of cable clip designs exist, but most are fixed-size
- A parametric clip system with size options (8mm, 12mm, 16mm, 20mm for braided sleeving) could differentiate
- Risk: commodity category, hard to charge premium

---

### Candidate 8 — Board Game Insert System (Modular, Parametric)

**Problem:** Board game box inserts are one of the most active 3D printing categories on BoardGameGeek, Printables, and Cults3D. Each game needs a custom insert. Current designs are game-specific one-offs.

**Sources:**
- BoardGameGeek geeklist 308792 — "My Favorite 3D Printed Boardgame Inserts"
- Printables tag: boardgamesinsert — active community
- Cults3D — 428+ free board game organizer models

**Current Solutions & Gaps:**
- Massive existing library of free game-specific inserts
- Opportunity: modular base system with customizable divider heights/widths
- Challenge: each game has unique component sets, hard to generalize
- High competition from free designs on Printables

---

### Candidate 9 — Toothpaste Tube Squeezer (Ratchet Mechanism)

**Problem:** Trending functional print. Ratchet-mechanism tube squeezers are cited as "game changers" across multiple 3D printing blogs. Printables lists them as popular functional prints for 2025.

**Sources:**
- Printables Awards 2025 — functional category
- 3D-Printed.org — "Game-Changing Functional 3D Prints" list
- Multiple blog roundups cite this as top useful print

**Current Solutions & Gaps:**
- Well-covered on Printables with many free designs
- Etsy opportunity exists for finished printed product (non-printer owners)
- Differentiator: wider tube compatibility, aesthetic finish, or multi-pack pricing

---

### Candidate 10 — Parametric Drawer Divider System

**Problem:** Mass-market drawer dividers from Amazon are spring-loaded (pop out), bamboo (fixed sizes), or plastic (don't fit). SkyRye Design notes "most commercial organizers are one-piece designs — if one compartment doesn't work, the whole thing fails."

**Sources:**
- SkyRye Design blog — modular advantage of 3D prints over fixed commercial organizers
- Etsy market gap — "drawer divider" didn't surface prominently in 3D printed Etsy searches
- Amazon — spring-loaded dividers have common "doesn't stay" complaints

**Current Solutions & Gaps:**
- Free designs exist but are rarely parametric
- Etsy gap: few 3D printed drawer divider listings vs. high demand category
- Challenge: size variation is extreme (every drawer is different)

---

### Candidate 11 — Self-Watering Hydroponic Planter ("Robert Planter" Style)

**Problem:** Houseplant owners over/under-water constantly. Self-watering planters using wicking/hydroponics are popular on Printables (the "Robert Planter" is iconic). Growing houseplant community on Reddit.

**Sources:**
- Printables — Robert Planter is one of most popular functional plant prints
- 3D4Create — listed in "30 Coolest and Most Useful 3D Prints" roundup
- r/houseplants — large, active community

**Current Solutions & Gaps:**
- Robert Planter exists as a free, well-loved design
- Hard to differentiate from established free design
- Physical sale opportunity for non-printer-owners on Etsy

---

### Candidate 12 — Bambu Lab Y-Splitter Filament Guide

**Problem:** Switching between AMS and external spool without disconnecting the AMS requires a Y-shaped filament guide. Identified as one of the first mods every BambuLab user should print.

**Sources:**
- Bambu Lab Forum — "must-have printable upgrades" thread
- All3DP — listed as recommended mod
- FranksWorld — "15 Must-Have Upgrades for Bambu Lab A1"

**Current Solutions & Gaps:**
- Well-covered with free designs on MakerWorld
- Low differentiation — existing solutions work adequately
- Saturated free market

---

## Stage 2 — Opportunity Scoring

### Scoring Rubric (1–5 scale)

| # | Candidate | Pain | Size | Feasibility | Competition Gap | Profit | **Avg** |
|---|-----------|------|------|-------------|-----------------|--------|---------|
| 1 | Under-Desk Headphone Mount | 4 | 5 | 5 | 4 | 4 | **4.4** |
| 2 | AMS Cardboard Spool Adapter | 5 | 3 | 5 | 3 | 3 | **3.8** |
| 3 | Gridfinity Cable Spool Holder | 3 | 3 | 4 | 3 | 3 | **3.2** |
| 4 | Kitchen Sponge Drying Rack | 3 | 4 | 5 | 4 | 4 | **4.0** |
| 5 | Bambu Purge Bucket | 4 | 3 | 5 | 2 | 2 | **3.2** |
| 6 | Remote Control Caddy | 2 | 4 | 5 | 3 | 4 | **3.6** |
| 7 | Cable Clips (Braided Sleeving) | 3 | 4 | 5 | 2 | 2 | **3.2** |
| 8 | Board Game Insert System | 4 | 4 | 3 | 2 | 3 | **3.2** |
| 9 | Toothpaste Tube Squeezer | 3 | 4 | 5 | 2 | 3 | **3.4** |
| 10 | Parametric Drawer Dividers | 3 | 5 | 3 | 4 | 3 | **3.6** |
| 11 | Self-Watering Planter | 3 | 4 | 4 | 2 | 3 | **3.2** |
| 12 | Bambu Y-Splitter | 4 | 3 | 5 | 2 | 2 | **3.2** |

### Scoring Rationale for Top Candidates

**Candidate 1 — Under-Desk Headphone Mount (4.4 avg) ✅ ADVANCING**
- **Pain (4):** Documented frustration — existing mounts crack repeatedly, Amazon options are flimsy, adhesive fails. This is a recurring problem across multiple sources.
- **Size (5):** Enormous addressable market. Anyone with a desk + headphones. Gamers, WFH workers, students, streamers. Hundreds of millions of potential customers.
- **Feasibility (5):** Simple clamp geometry. No moving parts beyond a tightening mechanism. PLA/PETG suitable. Printable without supports in the right orientation.
- **Competition Gap (4):** Amazon products are cheap but break. Existing 3D printed designs crack at stress concentration points. Etsy listings exist but are not parametric. A well-engineered design with proper stress distribution, adjustable clamp width, and integrated cable routing would be clearly superior.
- **Profit (4):** STL at $3–5, printed at $15–25. Strong gift potential. Low print cost (~$0.50 filament, 1–2 hours print time).

**Candidate 4 — Kitchen Sponge Drying Rack (4.0 avg) ✅ ADVANCING**
- **Pain (3):** Moderate — people tolerate bad sponge holders, but the "things I 3D printed that replaced Amazon purchases" genre consistently features kitchen items.
- **Size (4):** Every kitchen has sponges. Large addressable market, though conversion requires reaching non-printer-owners (physical/Etsy).
- **Feasibility (5):** Simple geometry, no moving parts, drainage features are straightforward.
- **Competition Gap (4):** Etsy has a few sellers but limited design variety. PETG water-resistant version would differentiate.
- **Profit (4):** Physical product at $12–18, STL at $3–4. Kitchen items have proven Etsy demand.

### Killed Candidates

| # | Candidate | Reason |
|---|-----------|--------|
| 2 | AMS Spool Adapter | Niche market (BambuLab AMS owners only), free designs adequate, low willingness to pay |
| 3 | Gridfinity Spool Holder | Saturated free market, low pain intensity, commodity product |
| 5 | Bambu Purge Bucket | Saturated, free designs work fine, no competition gap |
| 6 | Remote Control Caddy | Low pain intensity ("nice to have"), existing Star Seller on Etsy already owns the niche |
| 7 | Cable Clips | Commodity product, thousands of free designs, near-zero willingness to pay for STL |
| 8 | Board Game Inserts | Each game needs custom design (not scalable), massive free library on Printables |
| 9 | Toothpaste Squeezer | Saturated free market on Printables, low competition gap |
| 10 | Drawer Dividers | Extreme size variation makes parametric design complex, low feasibility score |
| 11 | Self-Watering Planter | Robert Planter is iconic and free, hard to differentiate |
| 12 | Bambu Y-Splitter | Saturated free market, no competition gap |

---

## Decision: Advancing Candidate 1 (Under-Desk Headphone Mount) as primary product.

**Rationale:** Highest overall score (4.4), strongest combination of market size and competition gap. The documented failure mode of existing designs (cracking at the clamp) provides a clear engineering improvement opportunity. The product serves an enormous market (desk workers, gamers, streamers) and has proven demand on both Amazon and Etsy. Both digital (STL) and physical (printed) sales channels are viable.

Candidate 4 (Kitchen Sponge Rack) advances as backup and may be pursued in Cycle 2.
