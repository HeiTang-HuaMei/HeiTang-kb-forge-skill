from hashlib import sha256
from pathlib import Path

from heitang_kb_forge.schemas.multimodal_schema import MultimodalAsset


def stable_asset_id(source_file: Path, asset_type: str, *, slide_number: int | None = None, index: int | None = None) -> str:
    payload = f"{source_file.as_posix()}:{asset_type}:{slide_number}:{index}"
    return "asset_" + sha256(payload.encode("utf-8")).hexdigest()[:16]


def make_asset(
    source_file: Path,
    asset_type: str,
    *,
    slide_number: int | None = None,
    extracted_text: str = "",
    description: str = "",
    structure: dict | None = None,
    confidence: str = "low",
    extraction_method: str = "fallback",
    review_required: bool = True,
    index: int | None = None,
) -> MultimodalAsset:
    return MultimodalAsset(
        asset_id=stable_asset_id(source_file, asset_type, slide_number=slide_number, index=index),
        asset_type=asset_type,
        source_file=str(source_file).replace("\\", "/"),
        slide_number=slide_number,
        extracted_text=extracted_text,
        description=description,
        structure=structure or {},
        confidence=confidence,
        extraction_method=extraction_method,
        review_required=review_required,
    )
