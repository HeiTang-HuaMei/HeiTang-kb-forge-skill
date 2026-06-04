from collections import Counter

from heitang_kb_forge.schemas.multimodal_schema import MultimodalAsset


def make_multimodal_report(assets: list[MultimodalAsset]) -> str:
    if not assets:
        return "# Multimodal Report\n\nNo multimodal assets found.\n"
    counts = Counter(asset.asset_type for asset in assets)
    review_required = [asset for asset in assets if asset.review_required]
    count_rows = "\n".join(f"- {asset_type}: {count}" for asset_type, count in sorted(counts.items()))
    review_rows = "\n".join(f"- {asset.asset_id}: {asset.source_file}" for asset in review_required) or "- None"
    return f"""# Multimodal Report

## Summary

- Total assets: {len(assets)}
- Review required: {len(review_required)}

## Asset Types

{count_rows}

## Review Required Assets

{review_rows}

## Boundary

Multimodal extraction is bounded best-effort. Low-confidence or fallback assets require human review.
"""
