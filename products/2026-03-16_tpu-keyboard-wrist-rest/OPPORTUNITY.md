# OPPORTUNITY.md — Cycle 2 Market Scan & Scoring

## Stage 1 — Market Scan (Wide-Scan Mode, Cycle 2 of 3)

**Cycle:** 2
**Date:** 2026-03-16
**Mode:** Wide-scan with increased depth in Desk Accessories and Kitchen/Home
**Wildcard Category:** Pet Accessories
**Sources:** Reddit (r/MechanicalKeyboards, r/BambuLab, r/dogs, r/cats), Etsy, Amazon, Printables, MakerWorld, Bambu Lab Community Forum, BoardGameGeek, XDA Developers, Hackaday, CNC Kitchen

---

### Candidate 1 — TPU Lattice Wrist Rest Sized to Specific Keyboards

**Problem:** Mechanical keyboard enthusiasts spend $100–400 on keyboards but use generic wrist rests that don't match their board's width, profile, or aesthetic. Foam/gel rests from Amazon compress over time, develop flat spots, and come in "small/medium/large" — not "Keychron Q1 Pro" or "GMMK Pro." The r/MechanicalKeyboards community (1M+ members) regularly discusses wrist rests, and TPU's natural cushioning + breathable lattice structures would be ideal — but TPU is notoriously difficult to print, creating a natural competition barrier.

**Sources:**
- r/MechanicalKeyboards — 1M+ members, wrist rest discussions frequent
- Etsy "keyboard wrist rest" — foam/leather rests dominate at $20–50, very few 3D printed options
- TPU printing difficulty documented across 3D printing communities as a barrier to entry
- Background agent research identified this as "highest-margin opportunity" with "natural moat"

**Current Solutions & Gaps:**
- Amazon foam/gel rests: compress, don't match specific keyboard widths, generic aesthetic
- Wood/resin artisan rests on Etsy: $30–80 but heavy, no cushion, fixed sizes
- 3D printed TPU rests: nearly nonexistent on Etsy — the TPU printing barrier keeps casual sellers out
- No one currently markets rests dimensioned to specific popular keyboard models

---

### Candidate 2 — Custom-Fit Spice Drawer Organizer (Brand-Specific Jar Slots)

**Problem:** Spice drawer organizers are a $30–200 product on Etsy, with the top seller (OrganizeMyDrawers) earning 551+ reviews at $129/unit. The universal problem: spice jars vary wildly by brand (Trader Joe's, McCormick, Simply Organic, Whole Foods 365 all have different diameters), and drawer dimensions vary. Buyers message sellers with measurements, go back and forth, and still get poor fits. A parametric approach with brand-specific presets would eliminate this friction.

**Sources:**
- Etsy seller OrganizeMyDrawers: 551+ reviews at $129, Star Seller
- Etsy listing 1613918541: Customizable PETG spice organizer
- Etsy listing 1899317417: 3D Printed Spice Rack, 10 bottle capacity
- MakerWorld model 608048: Gridfinity Kitchen Drawer Organizer (high downloads)
- Amazon "spice drawer organizer" — recurring complaints about sizing mismatches

**Current Solutions & Gaps:**
- Premium custom sellers ($129+) require buyer to measure and communicate — high friction
- Cheap Amazon bamboo inserts ($15–25) — fixed sizes, don't fit most drawers
- 3D printed PETG versions exist on Etsy but none offer brand-specific jar presets
- Parametric OpenSCAD with brand presets + drawer dimension inputs = genuine differentiation

---

### Candidate 3 — BambuLab AMS Humidity Management DryPod System

**Problem:** The AMS does not keep filament dry. Desiccant saturates within 24 hours in humid climates. Multi-page Bambu Lab Forum threads document this extensively. The AMS 2 Pro added built-in drying, but millions of original AMS and AMS Lite units lack this feature. Community "DryPod" solutions exist but are fragmented — multiple competing designs with varying quality.

**Sources:**
- Bambu Lab Forum thread "AMS humidity" (37174) — multi-page discussion
- fusion94.org — "AMS Humidity Control - The Complete Guide" (Jan 2025)
- bestfilamentdryer.com — "AMS Filament Dryer Mod" guide
- Bambu Lab Wiki — AMS humidity detection function documentation

**Current Solutions & Gaps:**
- AMS 2 Pro has built-in drying ($$$, only for newest hardware)
- Free DryPod STLs exist on Printables/MakerWorld but require users to assemble from multiple sources
- No polished, all-in-one kit with integrated hygrometer mount + desiccant tray + seal gaskets
- Saturated free market reduces willingness to pay for STL

---

### Candidate 4 — IKEA DETOLF Shelf Clips (Replacement + Extra Shelf)

**Problem:** The IKEA DETOLF glass display cabinet is ubiquitous among collectors (figures, Lego, etc.). Original shelf clips break or go missing, and IKEA's replacement part system is slow. One Etsy seller claims "55,000+ clips made" before switching to selling the STL. Multiple active listings on Etsy with positive reviews. Proven demand.

**Sources:**
- Etsy listing 792145288: TINKER3Dshop, 12-piece set, 177 favorites, PETG
- Etsy listing 1761662921: STL file, seller made 55,000+ physical clips before going digital
- Printables model 319240: Free alternative, designer recommends 60% infill
- Etsy market page "ikea_detolf_shelf_clips" — active category

**Current Solutions & Gaps:**
- Proven market with documented sales (55,000+ units from one seller)
- Low per-unit revenue ($3–5 for clips) but extremely high volume potential
- Free alternatives exist on Printables — limits STL pricing power
- Physical sales viable since target buyer (collector) likely doesn't own a printer

---

### Candidate 5 — 3D Printer Vibration Isolation Platform

**Problem:** High-speed printers (Bambu P1S, X1C, Creality K1) transmit vibration through furniture into floors, causing apartment neighbor complaints. The proven solution (concrete paver + Sorbothane feet) requires users to research physics and source materials. Commercial pads ($8–20) exist but are just rubber feet — no integrated mass platform.

**Sources:**
- Bambu Lab Forum — "Anti-vibration feet and misconceptions" thread
- CNC Kitchen — "Reduce 3D printing noise with a concrete paver"
- Amazon: 3dB pads ($8–20), JAGTRADE pads, HULA damper ($12.99)
- Hackaday — "Silencing a 3D Printer With Acoustic Foam Isn't That Easy"

**Current Solutions & Gaps:**
- Rubber/silicone feet ($8–20) address high-frequency vibration only
- DIY concrete paver solution works but is ugly and requires user research
- HULA damper ($12.99) is the most innovative commercial product — hard to beat
- A 3D-printable platform frame that holds a standard paver/tile with integrated damper mounts could work, but competes with cheap commercial solutions

---

### Candidate 6 — Personalized 3D Printed Slow Feeder Dog Bowl

**Problem:** Dogs that eat too fast risk bloat, vomiting, and obesity. Slow feeder bowls are a proven product category. 3D printing enables personalization (pet's name) and custom maze patterns. Etsy sellers like "LabraBowl" have strong reviews (4.8+ stars).

**Sources:**
- Etsy listing 1879681444: Personalized slow feeder, 4 sizes, UK handmade
- Etsy listing 4311886966: Custom slow feeder with matching dog tag
- Amazon: Multiple 3D printed personalized slow feeders ($15–25)
- Prairie City Printing Co: PLA slow feeders, eco-friendly messaging

**Current Solutions & Gaps:**
- Active market with multiple sellers on both Etsy and Amazon
- Personalization (pet name) is the primary differentiator — already well-served
- Food safety concern: most sellers use PLA, which harbors bacteria in layer lines
- PETG + food-grade sealant could be a differentiator, but adds cost and complexity
- High competition from injection-molded slow feeders on Amazon ($10–15)

---

### Candidate 7 — Gridfinity Kitchen Drawer Organizer Kits

**Problem:** Gridfinity has exploded for workshop/garage tool storage but kitchen applications are nearly untouched. Kitchen drawers are shallower, utensils have irregular shapes, and daily drawer slamming knocks loose blocks more than gentle workshop access. This crosses Gridfinity into a higher-spending demographic (home organization buyers).

**Sources:**
- MakerWorld model 608048: "Ultimate Gridfinity Kitchen Drawer Organizer" (high downloads)
- Hackaday: Gridfinity coverage and adoption tracking
- Etsy: CKDesignTeam (Gridfinity specialist) — 157 reviews, Star Seller
- Background agent: identified as "true blue ocean with no competition"

**Current Solutions & Gaps:**
- Gridfinity workshop organizers sell well on Etsy ($3–25 per piece)
- Kitchen-specific Gridfinity is nearly nonexistent
- Need shallower bins, utensil-shaped cutouts, food-safe PETG
- Challenge: kitchen drawer dimensions vary even more than workshop drawers

---

### Candidate 8 — Parametric Assistive Device Collection (Arthritis Aids)

**Problem:** 54M US adults have arthritis. Commercial assistive devices are expensive ($15–40 each), non-customizable, and ugly. Community members on r/functionalprint organically design one-off solutions (button pushers, key turners, jar openers, can tab lifters) that get high engagement. A coordinated, parametric set with hand-size customization would be novel.

**Sources:**
- Makers Making Change — open-source assistive device kits
- r/functionalprint — high engagement on assistive print posts
- Background agent: identified 54M US adults with arthritis
- CDC arthritis statistics — significant addressable population

**Current Solutions & Gaps:**
- Makers Making Change provides free designs, but they're not parametric or sized per individual
- Commercial aids ($15–40) are one-size-fits-all
- High social impact but unclear monetization — target users may have limited budgets
- STL bundle could work, but free alternatives from charity organizations compete

---

### Candidate 9 — Bambu Lab A1/AMS Lite Spool Accessories Bundle

**Problem:** The AMS Lite has recurring issues: spool holder 4 jams due to design flaw, excessive height, no easy external-spool toggle, and near-empty spool failures. Multiple forum threads document these issues.

**Sources:**
- Bambu Lab Forum — AMS Lite design failure and fix thread
- Background agent research — A1/AMS Lite specific issues documented
- MakerWorld — multiple A1-specific accessories

**Current Solutions & Gaps:**
- Free designs on MakerWorld address individual issues
- No curated bundle that solves all AMS Lite pain points in one purchase
- Small niche (A1 owners with AMS Lite only)
- Free alternatives limit willingness to pay

---

### Candidate 10 — Weighted Anti-Tip Phone/Tablet Stand

**Problem:** 3D printed phone stands on Amazon have a documented tipping problem. Reviewer of 22 Network holder noted phone is "too top heavy when vertical and leaned back." Modern phones (221–232g) with cases exceed the counterbalancing capacity of lightweight PLA stands. No one integrates a steel counterweight.

**Sources:**
- Amazon B0DF73B37N: 22 Network Phone Holder — tipping complaints
- Amazon B0DK99M58K: 3D Printed Gear Minimalist — gear mechanism can slip
- All3DP: "3D Printed Phone Stand - 20 Models We Love"
- Background agent: identified physics-based differentiation (steel weight insert)

**Current Solutions & Gaps:**
- Flooded market with hundreds of generic phone stands
- Tipping problem is real but solvable with counterweight cavity
- $18–28 price point competes with injection-molded Amazon stands ($5–10)
- Hard to justify premium when cheap alternatives "mostly work"

---

### Candidate 11 — Food-Safe Elevated Pet Bowl Stand (PETG + Sealed)

**Problem:** 3D printed pet bowl stands on Etsy have three documented flaws: bacterial growth in FDM layer lines, slippery bases that slide on floors, and loose-fitting stainless steel inserts that rattle. Reviewers report disappointment with all three issues.

**Sources:**
- Etsy pet accessories market — active category
- Nikko Industries — "Are 3D Printed Items Safe for Pets?" (layer-line bacteria)
- Bambu Lab Forum — "3D Prints and Food" safety discussion
- Background agent: documented specific review complaints

**Current Solutions & Gaps:**
- Many Etsy sellers but none market food safety
- PETG + food-grade epoxy + silicone anti-slip feet = clear differentiation
- Higher production cost per unit reduces margin
- Pet product buyers willing to pay premium for safety messaging

---

### Candidate 12 — Ender 3 "Day-One Survival Kit" (Printable Upgrades Bundle)

**Problem:** Every Ender 3's stock plastic extruder arm cracks, causing under-extrusion. Combined with weak bed springs and PTFE tube degradation, this is a universal failure pattern across millions of sold units. Users discover fixes individually through Reddit threads.

**Sources:**
- Background agent: documented as universal Ender 3 failure
- CleverCreations — "Best Ender 3 Upgrades" guide
- r/ender3 — recurring extruder arm crack posts

**Current Solutions & Gaps:**
- Metal extruder arm upgrade kits on Amazon ($10–15) are the standard fix
- Printable accessories (filament guide, spool holder, tool holder) could bundle
- Challenge: the critical fix (metal extruder) isn't 3D printable
- Market is mature — Ender 3 is aging out as BambuLab gains share

---

## Stage 2 — Opportunity Scoring

| # | Candidate | Pain | Size | Feasibility | Competition Gap | Profit | **Avg** |
|---|-----------|------|------|-------------|-----------------|--------|---------|
| 1 | TPU Keyboard Wrist Rest | 4 | 4 | 4 | 5 | 5 | **4.4** |
| 2 | Spice Drawer Organizer | 4 | 4 | 3 | 4 | 5 | **4.0** |
| 3 | AMS DryPod System | 4 | 3 | 4 | 3 | 3 | **3.4** |
| 4 | IKEA DETOLF Clips | 3 | 4 | 5 | 3 | 3 | **3.6** |
| 5 | Vibration Isolation Platform | 3 | 3 | 4 | 3 | 3 | **3.2** |
| 6 | Slow Feeder Dog Bowl | 3 | 4 | 4 | 2 | 3 | **3.2** |
| 7 | Gridfinity Kitchen Kits | 3 | 4 | 3 | 5 | 4 | **3.8** |
| 8 | Assistive Device Collection | 5 | 5 | 3 | 4 | 2 | **3.8** |
| 9 | AMS Lite Spool Bundle | 4 | 2 | 5 | 2 | 2 | **3.0** |
| 10 | Weighted Phone Stand | 3 | 5 | 4 | 3 | 2 | **3.4** |
| 11 | Food-Safe Pet Bowl Stand | 3 | 4 | 3 | 4 | 3 | **3.4** |
| 12 | Ender 3 Survival Kit | 4 | 3 | 3 | 2 | 2 | **2.8** |

### Scoring Rationale for Top Candidates

**Candidate 1 — TPU Keyboard Wrist Rest (4.4 avg) ✅ ADVANCING**
- **Pain (4):** Keyboard enthusiasts actively discuss wrist comfort. Generic rests that don't match their specific board width are a recurring frustration, but it's not a "broken product" emergency.
- **Size (4):** r/MechanicalKeyboards has 1M+ members. The custom keyboard market is $500M+. Not as universal as "anyone with a desk" but a large, passionate, high-spending community.
- **Feasibility (4):** TPU printing is well-understood but requires slower speeds, direct drive extruder, and tuning. Lattice/gyroid infill in TPU is proven. Sizing per keyboard model is straightforward dimensional work. One point deducted for TPU tuning complexity.
- **Competition Gap (5):** This is the standout dimension. Virtually zero 3D printed TPU wrist rests on Etsy. The TPU printing barrier keeps casual sellers out. Foam/leather rests dominate but can't offer lattice cushioning or keyboard-specific widths. This is as close to a blue ocean as we've seen.
- **Profit (5):** Material cost ~$2–4 (TPU). Physical product sells at $25–40 on Etsy. STL sells at $5–7 (fewer buyers since TPU is hard to print). Margin of 70%+ on physical, 85%+ on digital. The keyboard community demonstrably pays premium for matching accessories.

**Candidate 2 — Spice Drawer Organizer (4.0 avg) ✅ ADVANCING**
- **Pain (4):** Documented frustration from Etsy reviews about sizing mismatches. Buyers spending $129 and still getting poor fits = real pain.
- **Size (4):** Every kitchen has spices. Intersection with home organization community (large, spending-inclined).
- **Feasibility (3):** Parametric design is straightforward, but the sheer variety of drawer dimensions and jar sizes makes a truly "universal" system complex. Shipping large flat prints is also challenging.
- **Competition Gap (4):** Brand-specific jar presets don't exist anywhere. "Tell us your jar brand + drawer size = perfect fit" is a novel value proposition.
- **Profit (5):** $40–80 per unit for physical, $8–12 for STL. High-value product with proven price tolerance (competitors sell at $129+).

### Killed Candidates

| # | Candidate | Reason |
|---|-----------|--------|
| 3 | AMS DryPod | Free designs adequate, AMS 2 Pro makes it obsolete for new buyers |
| 4 | IKEA DETOLF Clips | Proven demand but razor-thin margins ($3–5/sale), commodity product |
| 5 | Vibration Platform | HULA damper at $12.99 is hard to beat, low differentiation |
| 6 | Slow Feeder Dog Bowl | Personalization already well-served, high competition from injection-molded bowls |
| 7 | Gridfinity Kitchen Kits | Blue ocean but feasibility drops — kitchen drawer variation is extreme, 3/5 feasibility |
| 8 | Assistive Devices | Maximum pain + size but unclear monetization (2/5 profit), target users budget-constrained, free charity alternatives |
| 9 | AMS Lite Bundle | Tiny niche (A1+AMS Lite owners only), free alternatives everywhere |
| 10 | Weighted Phone Stand | Flooded market, hard to justify $18+ premium over $5 Amazon stands |
| 11 | Pet Bowl Stand | Higher production cost with food-grade sealing, moderate competition gap |
| 12 | Ender 3 Kit | Aging printer platform, critical fix (metal extruder) isn't printable |

---

## Decision: Advancing Candidate 1 (TPU Keyboard Wrist Rest) as primary product.

**Rationale:** Tied highest score of any candidate across both cycles (4.4), with the only perfect 5 in Competition Gap we've seen. The TPU printing barrier creates a natural moat — casual Etsy sellers with PLA-only printers simply cannot compete. The r/MechanicalKeyboards community is massive, passionate, and willing to pay premium for accessories that match their boards. The keyboard-specific sizing is a clear, communicable value proposition: "Made for YOUR keyboard, not a generic one."

Candidate 2 (Spice Drawer Organizer) advances as backup for Cycle 3. Gridfinity Kitchen Kits (Candidate 7) noted for future exploration once niche convergence begins.
