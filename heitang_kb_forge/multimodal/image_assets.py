from pathlib import Path

from heitang_kb_forge.multimodal.assets import make_asset
from heitang_kb_forge.multimodal.classifier import classify_asset
from heitang_kb_forge.schemas.multimodal_schema import MultimodalAsset


def make_image_asset(path: Path) -> MultimodalAsset:
    asset_type = classify_asset(path)
    return make_asset(
        path,
        asset_type,
        description="Standalone image-like source preserved for review.",
        confidence="low",
        extraction_method="fallback",
        review_required=True,
    )
