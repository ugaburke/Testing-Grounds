# PROFIT_MODEL.md — Modular Pet Puzzle Feeder with Swappable Difficulty Inserts

---

## Profit Model Selection: Hybrid (Physical-Primary, Insert Expansion Model)

### Why Physical-Primary with Recurring Revenue?

This product has a fundamentally different business model from our kitchen line. The **base unit + expansion insert** model mirrors the razor-and-blades strategy:

1. **Base unit** is the entry point — priced competitively vs. Outward Hound Level 1
2. **Insert packs** are the recurring revenue — each difficulty level is a separate, lower-cost purchase
3. **Dog owners upgrade** as their dogs master each level — natural progression creates repeat purchases

**Physical is primary** because:
- Target buyer is a dog owner, not a maker — 3D printer ownership is irrelevant to this audience
- Food-safety coating (epoxy) is best applied by the seller, not the buyer
- The modular system needs to be precision-fitted — seller-printed ensures quality
- Insert packs are small, cheap to ship, high margin

**STL is secondary** because:
- Maker community exists within dog owners (r/functionalprint + r/dogs overlap)
- STL buyers can apply their own food-safe coating
- Parametric source allows customization for different dog sizes

---

## Physical Product Pricing

### SKU Structure — The Insert Expansion Model

| SKU | Description | Price | COGS | Margin |
|-----|-------------|-------|------|--------|
| **Starter Base (Level 1)** | Base tray + Level 1 sliding panel insert + 6 treat compartments | $29.99 | $8.50 | 72% |
| **Level 2 Insert Pack** | Rotating disc insert + 4 locking tabs | $9.99 | $3.20 | 68% |
| **Level 3 Insert Pack** | Sequential maze insert + sliding gates | $11.99 | $3.80 | 68% |
| **Level 4 Insert Pack** | Multi-step combination insert (hardest) | $12.99 | $4.10 | 68% |
| **Full Bundle (Base + All 4 Levels)** | Complete system | $54.99 | $16.80 | 69% |
| **Puppy Starter (Smaller Base)** | Small base + Level 1 insert for puppies/small dogs | $24.99 | $7.20 | 71% |

### COGS Breakdown (Starter Base — Level 1)

| Component | Cost |
|-----------|------|
| PETG filament (~80g @ $20/kg) | $1.60 |
| Food-safe epoxy coating (ArtResin, ~5ml per unit) | $0.80 |
| Electricity (~2.5 hr print) | $0.15 |
| Packaging (small box + insert card) | $1.20 |
| Etsy listing fee (per sale) | $0.20 |
| Etsy transaction fee (6.5%) | $1.95 |
| Etsy payment processing (3% + $0.25) | $1.15 |
| Shipping (USPS Priority Mail, ~6oz) | $1.45 |
| **Total COGS** | **$8.50** |

### COGS Breakdown (Level 2 Insert Pack)

| Component | Cost |
|-----------|------|
| PETG filament (~25g @ $20/kg) | $0.50 |
| Food-safe epoxy coating (~2ml) | $0.30 |
| Electricity (~45 min print) | $0.05 |
| Packaging (poly mailer) | $0.60 |
| Etsy listing fee | $0.20 |
| Etsy transaction fee (6.5%) | $0.65 |
| Etsy payment processing (3% + $0.25) | $0.55 |
| Shipping (USPS First Class, ~2oz) | $0.35 |
| **Total COGS** | **$3.20** |

### Customer Lifetime Value Analysis

| Scenario | Revenue | COGS | Gross Profit |
|----------|---------|------|-------------|
| Base only (Level 1) | $29.99 | $8.50 | $21.49 |
| Base + Level 2 | $39.98 | $11.70 | $28.28 |
| Base + Level 2 + 3 | $51.97 | $15.50 | $36.47 |
| Full Bundle (all 4 levels) | $54.99 | $16.80 | $38.19 |
| À la carte (all 4 levels separately) | $64.96 | $19.60 | $45.36 |

**Key insight:** The à la carte path ($64.96) is more profitable per customer than the bundle ($54.99), but the bundle captures customers who might otherwise stop at Level 2. Both paths are highly profitable.

---

## STL/Digital Product Pricing

| SKU | Description | Price |
|-----|-------------|-------|
| **STL Bundle (All Levels)** | OpenSCAD source + pre-generated STLs for all 4 levels + 2 base sizes + assembly guide + food-safe coating guide | $7.99 |
| **Single Level STL** | One insert level STL + base | $3.99 |

### STL Margin

| Component | Cost |
|-----------|------|
| Etsy listing fee | $0.20 |
| Etsy transaction fee (6.5%) | $0.52 |
| Etsy payment processing (3% + $0.25) | $0.49 |
| **Total COGS** | **$1.21** |
| **Gross Profit (Full Bundle)** | **$6.78** |
| **Margin** | **85%** |

---

## Competitive Pricing Analysis

| Competitor | Platform | Price | Levels | Material | Modular? |
|-----------|----------|-------|--------|----------|----------|
| Outward Hound Level 1 (Dog Smart) | Amazon/Chewy | $10–13 | 1 | Injection-molded plastic | No |
| Outward Hound Level 2 (Dog Brick) | Amazon/Chewy | $12–18 | 1 | Injection-molded plastic | No |
| Outward Hound Level 3 (Dog Twister) | Amazon/Chewy | $15–25 | 1 | Injection-molded plastic | No |
| Outward Hound Level 4 (MultiPuzzle) | Amazon/Chewy | $25–30 | 1 | Injection-molded plastic | No |
| **All 4 Outward Hound levels** | — | **$62–86** | 4 separate products | — | **No** |
| TheDogPuzzleShop | Etsy | $25–40 | Multi-level | Laser-cut wood | Partially |
| PiperzLab (STL only) | Etsy | ~$5–8 | 6 levels | Digital only | Yes (STL) |
| juancv3d (STL only) | Cults3D | ~$5 | 5 accessories | Digital only | Yes (STL) |

### Our Positioning

| | Our Starter Base | Our Full Bundle | Our STL |
|---|-----------------|----------------|---------|
| Price | $29.99 | $54.99 | $7.99 |
| Levels | 1 (expandable) | 4 | 4 |
| Material | PETG + food-safe epoxy | Same | Buyer's choice |
| Modular | Yes — swappable inserts | Yes | Yes |
| Dog Sizes | Standard + Puppy | Both | Parametric |

### Why This Pricing Works

**Starter Base at $29.99:**
- More expensive than a single Outward Hound Level 1 ($10–13) but includes the modular base that grows with the dog
- The pitch: "Buy one system instead of four separate toys"
- Cheaper than buying Outward Hound Levels 1+2 combined ($22–31)

**Full Bundle at $54.99:**
- 36% cheaper than buying all 4 Outward Hound levels separately ($62–86)
- The "save money + less plastic waste" angle resonates with eco-conscious pet owners
- Wood puzzle alternatives on Etsy ($25–40) only offer a single difficulty

**Insert Packs at $9.99–$12.99:**
- Impulse-purchase price point for a returning customer
- Material cost is ~$0.50–$0.80 per insert — enormous margins
- Each insert is a small, lightweight package — cheap to ship

---

## Revenue Projections (Conservative)

### Month 1–3 (Launch Phase)

| Channel | Units/Month | Avg Revenue | Monthly Revenue |
|---------|------------|-------------|-----------------|
| Physical — Starter Base | 10–18 | $29.99 | $300–$540 |
| Physical — Insert Packs | 5–10 | $11.00 | $55–$110 |
| Physical — Full Bundle | 3–6 | $54.99 | $165–$330 |
| STL | 5–10 | $7.99 | $40–$80 |
| **Total** | | | **$560–$1,060** |

### Month 4–6 (Growth + Repeat Purchase Phase)

| Channel | Units/Month | Avg Revenue | Monthly Revenue |
|---------|------------|-------------|-----------------|
| Physical — Starter Base | 20–35 | $29.99 | $600–$1,050 |
| Physical — Insert Packs | 15–30 | $11.00 | $165–$330 |
| Physical — Full Bundle | 8–15 | $54.99 | $440–$825 |
| STL | 10–18 | $7.99 | $80–$144 |
| **Total** | | | **$1,285–$2,349** |

**Note:** Insert pack revenue grows over time as the installed base of Starter Base owners increases. Month 6+ insert sales should exceed new base sales.

---

## Cross-Sell Strategy

| From | To | Pitch |
|------|-----|-------|
| Base buyer (30 days later) | Level 2 Insert | "Has [dog name] mastered Level 1? Time for a challenge!" |
| Level 2 buyer (30 days later) | Level 3 Insert | "Ready for the next step? Level 3 adds sequential gates." |
| Level 3 buyer | Level 4 Insert | "The ultimate challenge — even Border Collies struggle with this one." |
| Any pet buyer | Kitchen products | "Love organization? Check out our Kitchen Under-Cabinet collection." |

The 30-day follow-up cadence mirrors natural dog learning progression. Etsy's messaging system allows post-purchase outreach.

---

## Food Safety Protocol

For physical products sold on Etsy:
1. Print with PETG using stainless steel nozzle
2. Sand smooth to reduce layer line bacteria traps
3. Apply 2 coats food-safe epoxy (ArtResin or equivalent)
4. Allow 72-hour full cure before shipping
5. Include care card: "Hand wash with mild soap. Do not dishwasher. Inspect periodically for coating wear."

For STL buyers, include a detailed food-safe coating guide in the download package.

---

## Decision Summary

| Dimension | Choice |
|-----------|--------|
| **Primary channel** | Physical (Etsy) |
| **Secondary channel** | STL (Etsy) |
| **Lead SKU** | Starter Base (Level 1) @ $29.99 |
| **Expansion SKUs** | Level 2 $9.99, Level 3 $11.99, Level 4 $12.99 |
| **Bundle** | Full system (all 4 levels) @ $54.99 |
| **STL price** | $7.99 (all levels), $3.99 (single) |
| **Target margin** | 68–72% physical, 85% digital |
| **Revenue model** | Recurring — insert packs drive LTV |
| **Food safety** | PETG + food-safe epoxy coating |
