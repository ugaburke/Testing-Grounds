# PROFIT_MODEL.md — Brand-Specific Spice Drawer Organizer

## Product: Parametric Spice Drawer Organizer with Brand-Specific Jar Presets

## Profit Model Recommendation: Hybrid (Physical-Primary)

### Rationale

1. **Physical is the primary channel.** The target buyer is a home organizer, not a 3D printer owner. They're searching Etsy for "spice drawer organizer," comparing it against $25 Amazon bamboo inserts and $129 custom-fit wooden organizers. They want to buy a finished product, not print one. The Etsy Kitchen/Home buyer has minimal overlap with the maker community.

2. **Brand-preset system eliminates the back-and-forth that plagues custom sellers.** Current top sellers (OrganizeMyDrawers at $129) require buyers to message measurements, wait for design confirmation, then wait for production. Our system: buyer selects jar brand(s) from a dropdown, enters drawer width/depth/height, and receives a perfectly fitted organizer. The parametric OpenSCAD handles the math automatically.

3. **STL bundle as secondary channel.** Sell the full parametric OpenSCAD source + pre-generated STLs for all brand presets at $9.99. This captures the maker audience and generates reviews/social proof. Makers will post "I printed my own spice drawer organizer" on r/functionalprint — free marketing for the physical product.

4. **Modular design enables upsell.** Snap-together 2-jar modules (following the Spool Forge pattern that earned Star Seller status) mean buyers can order exactly the right quantity. Start with a "starter kit" (fits a standard 15" drawer with one brand), then sell expansion modules for additional brands/drawers.

### Revenue Projections (Conservative, Month 1)

| Channel | Price | Est. Units | Revenue | Margin |
|---------|-------|-----------|---------|--------|
| Physical — Starter Kit (15" drawer, 1 brand) | $44.99 | 8–15 | $360–675 | ~60% after COGS/fees |
| Physical — Full Drawer Kit (custom) | $59.99 | 3–8 | $180–480 | ~55% |
| Physical — Expansion Module (4-pack) | $14.99 | 5–10 | $75–150 | ~70% |
| STL Bundle (all brands + parametric source) | $9.99 | 5–10 | $50–100 | ~85% |
| **Total** | | **21–43** | **$665–1,405** | |

### Cost Breakdown (Physical, Starter Kit — 15" Drawer)

| Component | Cost |
|-----------|------|
| PETG filament (~200g for a 15" x 18" organizer) | $4.00 (at $20/kg PETG) |
| Print time (4–6 hours, modular pieces) | Machine time only |
| Packaging (flat mailer or small box) | $2.00 |
| Etsy fees (~6.5% + listing) | ~$2.93 |
| Shipping (USPS Priority, flat rate) | $9.50 |
| **Total COGS per unit** | **~$18.43** |

**At $44.99 sale price: ~$26.56 margin (59%)**

### Why Physical-Primary?

The buyer persona is a home organizer browsing Etsy, not a maker browsing Printables. Etsy's Kitchen & Dining category has massive traffic from buyers who expect to receive a finished product. The $44.99 price point sits perfectly between Amazon bamboo ($25) and custom wood ($129) — affordable enough to impulse-buy, expensive enough to signal quality.

### Why Not Digital-Only?

The STL buyer pool is tiny for kitchen products. Makers who print functional kitchen items are a small subset of an already niche community. Limiting to digital leaves 90%+ of the addressable market untouched.

### Pricing Justification

- **Starter Kit at $44.99:** Undercuts custom-fit competitors (OrganizeMyDrawers $129, OldSaguaroWoodcraft $150, DrawerInsertDesigner $199, TheCrazyWoodpecker $300) by 65–85%. Costs more than Amazon bamboo ($25) but offers brand-specific fit, PETG durability, and perfect sizing — a clear value step-up.
- **Full Drawer Kit at $59.99:** For buyers with larger drawers or mixed-brand spice collections. Still 50%+ cheaper than the cheapest custom competitor.
- **Expansion Module at $14.99 (4-pack):** Low-friction upsell. Buyer already committed to the system — adding more modules is easy.
- **STL at $9.99:** Premium for STL but justified by the parametric source with 6 brand presets. Most kitchen organizer STLs on Etsy are $3–7 for fixed designs.

### Competitive Moat

The brand-specific jar dimension database IS the moat. Competitors would need to measure every brand's jars (McCormick round 1.75"–1.8", Trader Joe's rectangular 1.8"x3.8", Simply Organic square 2.0", Whole Foods 365 round 1.8"–2.1", Penzeys round 2.0") and build parametric designs around them. This research + engineering effort is our barrier to entry.
