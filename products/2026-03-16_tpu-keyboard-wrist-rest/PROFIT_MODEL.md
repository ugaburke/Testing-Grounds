# PROFIT_MODEL.md — TPU Lattice Wrist Rest (Keyboard-Specific)

## Product: TPU Lattice Wrist Rest Sized to Specific Mechanical Keyboards

## Profit Model Recommendation: Physical-First (Hybrid)

### Rationale

This is the rare product where **physical-first** is the correct strategy, inverting our default digital-first approach:

1. **The TPU barrier makes physical the primary channel.** TPU is notoriously difficult to print — it requires a direct-drive extruder (not Bowden), slow speeds (20–30mm/s), careful retraction settings, and dry filament. The majority of hobbyist 3D printer owners either can't print TPU (Bowden setup) or avoid it. This means the buyer pool for a TPU STL file is small. The physical product captures the much larger market of keyboard enthusiasts who want the product but can't make it themselves.

2. **The keyboard community pays premium for matched accessories.** Custom keycap sets sell for $50–150. Desk mats sell for $30–50. Artisan keycaps sell for $50–200 each. A $29.99–$39.99 wrist rest sized exactly to a Keychron Q1 Pro in a matching color is well within this community's spending norms.

3. **STL as a secondary channel for advanced makers.** Offer the parametric OpenSCAD source at $6.99 for users who own direct-drive printers and want to customize. This captures the long tail without cannibalizing physical sales — only experienced TPU printers will buy it, and they'd never buy the physical anyway.

4. **Low competition sustains pricing.** Because few sellers can reliably print TPU at quality, price pressure stays low. This isn't a PLA product where anyone with a $200 printer can undercut you overnight.

### Revenue Projections (Conservative, Month 1)

| Channel | Price | Est. Units | Revenue | Margin |
|---------|-------|-----------|---------|--------|
| Physical — 65% (Etsy) | $34.99 | 10–20 | $350–700 | ~65% after COGS/fees |
| Physical — 75% (Etsy) | $29.99 | 5–10 | $150–300 | ~60% |
| STL (Etsy) | $6.99 | 5–10 | $35–70 | ~85% |
| **Total** | | **20–40** | **$535–1,070** | |

**Note:** The 65% and 75% product lines refer to different keyboard sizes — 65% keyboards (compact, e.g., Keychron Q2) and 75% keyboards (e.g., Keychron Q1, GMMK Pro).

### Cost Breakdown (Physical, per unit)

| Component | Cost |
|-----------|------|
| TPU filament (~120g) | $3.60 (at $30/kg TPU spool) |
| Print time (3–4 hours at 25mm/s) | Machine time only |
| Packaging (small box + bubble wrap) | $1.50 |
| Etsy fees (~6.5% + listing) | ~$2.30 |
| Shipping (USPS First Class, ~200g) | $4.50 |
| **Total COGS per unit** | **~$11.90** |

**At $34.99 sale price: ~$23.09 margin (66%)**
**At $29.99 sale price: ~$18.09 margin (60%)**

### Why Not Digital-Only?

Digital-only abandons the largest buyer segment — keyboard enthusiasts who don't own 3D printers capable of TPU. The subreddit survey data consistently shows only 15–20% of r/MechanicalKeyboards members own 3D printers. The other 80% want to buy, not make.

### Why Not Physical-Only?

Leaving STL revenue on the table is wasteful, and advanced makers who can print TPU provide valuable social proof (review photos, Reddit posts, "I printed this" threads) that drives physical sales.

### Pricing Justification

- **Physical at $29.99–$34.99:** Artisan wood wrist rests on Etsy sell for $30–80. Foam/gel rests on Amazon sell for $15–25. Our TPU lattice rest offers cushioning superior to wood (which has zero give) and longevity superior to foam (which compresses permanently). $29.99–$34.99 positions us below premium artisan but above commodity foam. The keyboard-specific sizing justifies the premium over generic options.
- **STL at $6.99:** Higher than typical functional print STLs ($3–5) because: (a) TPU-compatible designs are rare, (b) parametric source adds customization value, (c) the buyer segment (experienced TPU printers) skews toward willingness to pay for quality. Few free alternatives exist.
