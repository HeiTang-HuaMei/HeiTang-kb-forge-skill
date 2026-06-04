from pathlib import Path

from heitang_kb_forge.multimodal.assets import make_asset
from heitang_kb_forge.schemas.multimodal_schema import MultimodalAsset


def maybe_formula_asset(path: Path) -> MultimodalAsset | None:
    value = path.stem.lower()
    if not any(token in value for token in ["formula", "equation", "公式"]):
        return None
    return make_asset(
        path,
        "formula",
        description="Formula-like source detected by filename.",
        confidence="low",
        extraction_method="fallback",
        review_required=True,
    )
