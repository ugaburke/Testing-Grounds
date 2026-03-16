"""
export_listing.py — Extract and format marketplace listings from MARKETING.md.

Parses MARKETING.md files and outputs clean, paste-ready listing content
for Etsy, Amazon, or Reddit.
"""

import re
import sys
from pathlib import Path
from catalog import discover_products


def parse_marketing_md(marketing_path):
    """Parse a MARKETING.md file into structured sections.

    Returns dict with keys: etsy_physical, etsy_stl, reddit, social, pricing_rationale
    """
    with open(marketing_path, "r") as f:
        content = f.read()

    sections = {}
    current_section = None
    current_content = []

    for line in content.split("\n"):
        # Detect top-level section headers
        if re.match(r"^## \d+\.", line):
            if current_section:
                sections[current_section] = "\n".join(current_content).strip()
            current_content = []

            if "Physical Product" in line or "Primary Channel" in line:
                current_section = "etsy_physical"
            elif "STL" in line or "Digital" in line or "Secondary Channel" in line:
                current_section = "etsy_stl"
            elif "Reddit" in line:
                current_section = "reddit"
            elif "Social" in line:
                current_section = "social"
            elif "Pricing" in line or "Competitive" in line:
                current_section = "pricing_rationale"
            else:
                current_section = line.strip("# ").strip()
        else:
            current_content.append(line)

    if current_section:
        sections[current_section] = "\n".join(current_content).strip()

    return sections


def extract_field(section_text, field_name):
    """Extract a named field from a section (e.g., ### Title, ### Description)."""
    pattern = rf"###\s*{field_name}\s*\n(.*?)(?=###|\Z)"
    match = re.search(pattern, section_text, re.DOTALL)
    if match:
        return match.group(1).strip()
    return None


def extract_tags(section_text):
    """Extract numbered tag list from a section."""
    tags = []
    in_tags = False
    for line in section_text.split("\n"):
        if "### Tags" in line or "### Tag" in line:
            in_tags = True
            continue
        if in_tags:
            if line.startswith("###"):
                break
            tag_match = re.match(r"\d+\.\s*(.+)", line.strip())
            if tag_match:
                tags.append(tag_match.group(1).strip())
    return tags


def format_etsy_listing(section_text, listing_type="physical"):
    """Format an Etsy listing section for paste-ready output."""
    title = extract_field(section_text, "Title")
    description = extract_field(section_text, "Description")
    tags = extract_tags(section_text)
    category = extract_field(section_text, "Category Path")

    output = []
    output.append("=" * 60)
    output.append(f"  ETSY LISTING — {'PHYSICAL' if listing_type == 'physical' else 'DIGITAL (STL)'}")
    output.append("=" * 60)

    if title:
        output.append(f"\nTITLE (copy this):")
        output.append(f"  {title}")

    if description:
        # Clean markdown formatting for Etsy plain text
        clean = description.replace("**", "").replace("*", "")
        output.append(f"\nDESCRIPTION (copy this):")
        output.append(f"{'─'*40}")
        output.append(clean)
        output.append(f"{'─'*40}")

    if tags:
        output.append(f"\nTAGS ({len(tags)} tags — paste into Etsy tag fields):")
        for i, tag in enumerate(tags, 1):
            output.append(f"  {i}. {tag}")

    if category:
        output.append(f"\nCATEGORY PATH:")
        output.append(f"  {category}")

    return "\n".join(output)


def format_reddit_post(section_text):
    """Format a Reddit post for paste-ready output."""
    # Extract title and body
    title = None
    body_lines = []
    subreddit = None

    for line in section_text.split("\n"):
        if "**Title:**" in line or "**Title**" in line:
            title = re.sub(r"\*\*Title:?\*\*\s*", "", line).strip()
        elif "**Target subreddit:**" in line:
            subreddit = re.sub(r"\*\*Target subreddit:\*\*\s*", "", line).strip()
        elif "**Body:**" in line or "**Body**" in line:
            continue  # Skip the label line
        elif "**Cross-post" in line:
            continue
        else:
            body_lines.append(line)

    output = []
    output.append("=" * 60)
    output.append("  REDDIT POST")
    output.append("=" * 60)

    if subreddit:
        output.append(f"\nSUBREDDIT: {subreddit}")
    if title:
        output.append(f"\nTITLE (copy this):")
        output.append(f"  {title}")

    body = "\n".join(body_lines).strip()
    if body:
        clean = body.replace("**", "").replace("*", "")
        output.append(f"\nBODY (copy this):")
        output.append(f"{'─'*40}")
        output.append(clean)
        output.append(f"{'─'*40}")

    return "\n".join(output)


def export_listing(slug, format_type="etsy_physical"):
    """Export a formatted listing for a product.

    Args:
        slug: Product slug
        format_type: 'etsy_physical', 'etsy_stl', 'reddit', 'social', 'all'
    """
    products = discover_products()
    if slug not in products:
        print(f"Product not found: {slug}")
        return

    marketing_path = Path(products[slug]["folder"]) / "MARKETING.md"
    if not marketing_path.exists():
        print(f"No MARKETING.md found for: {slug}")
        return

    sections = parse_marketing_md(str(marketing_path))

    if format_type == "all":
        for fmt in ["etsy_physical", "etsy_stl", "reddit", "social"]:
            if fmt in sections:
                export_listing(slug, fmt)
                print("\n")
        return

    if format_type == "etsy_physical" and "etsy_physical" in sections:
        print(format_etsy_listing(sections["etsy_physical"], "physical"))

    elif format_type == "etsy_stl" and "etsy_stl" in sections:
        print(format_etsy_listing(sections["etsy_stl"], "stl"))

    elif format_type == "reddit" and "reddit" in sections:
        print(format_reddit_post(sections["reddit"]))

    elif format_type == "social" and "social" in sections:
        print(f"\n{'='*60}")
        print("  SOCIAL SNIPPET (≤280 chars)")
        print(f"{'='*60}")
        text = sections["social"].strip()
        # Clean markdown
        text = re.sub(r"\*\*.*?:\*\*\s*", "", text)
        text = text.replace("**", "")
        print(f"\n{text}")
        print(f"\n  ({len(text)} characters)")

    else:
        print(f"Section '{format_type}' not found in MARKETING.md")
        print(f"Available sections: {', '.join(sections.keys())}")


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Export marketplace listings")
    parser.add_argument("slug", help="Product slug")
    parser.add_argument(
        "format",
        nargs="?",
        default="all",
        choices=["etsy_physical", "etsy_stl", "reddit", "social", "all"],
        help="Listing format to export (default: all)",
    )

    args = parser.parse_args()
    export_listing(args.slug, args.format)


if __name__ == "__main__":
    main()
