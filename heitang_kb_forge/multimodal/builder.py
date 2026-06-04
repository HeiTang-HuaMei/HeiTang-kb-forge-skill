from dataclasses import dataclass, field
from pathlib import Path

from heitang_kb_forge.multimodal.classifier import IMAGE_SUFFIXES, SLIDE_SUFFIXES
from heitang_kb_forge.multimodal.evidence import make_multimodal_evidence_map
from heitang_kb_forge.multimodal.formula_assets import maybe_formula_asset
from heitang_kb_forge.multimodal.image_assets import make_image_asset
from heitang_kb_forge.multimodal.report import make_multimodal_report
from heitang_kb_forge.multimodal.slide_assets import make_slide_assets
from heitang_kb_forge.schemas.multimodal_schema import MultimodalAsset


@dataclass
class MultimodalOptions:
    enabled: bool = False
    images: bool = True
    charts: bool = True
    slides: bool = True
    formulas: bool = True
    mindmaps: bool = True
    diagrams: bool = True
    report: bool = True
    require_evidence_refs: bool = True
    review_low_confidence: bool = True


@dataclass
class MultimodalResult:
    assets: list[MultimodalAsset] = field(default_factory=list)
    slide_chunks: list[dict] = field(default_factory=list)
    evidence_map: dict = field(default_factory=dict)
    report: str = ""
    output_files: list[str] = field(default_factory=list)

    @property
    def review_required_count(self) -> int:
        return sum(1 for asset in self.assets if asset.review_required)


def build_multimodal_assets(input_path: Path, source_files: list[Path], options: MultimodalOptions) -> MultimodalResult:
    if not options.enabled:
        return MultimodalResult()
    candidates = _collect_candidates(input_path, source_files)
    assets: list[MultimodalAsset] = []
    slide_chunks: list[dict] = []
    for path in candidates:
        suffix = path.suffix.lower()
        formula_asset = maybe_formula_asset(path) if options.formulas else None
        if formula_asset:
            assets.append(formula_asset)
            continue
        if suffix in IMAGE_SUFFIXES and options.images:
            asset = make_image_asset(path)
            if _type_enabled(asset.asset_type, options):
                assets.append(asset)
        elif suffix in SLIDE_SUFFIXES and options.slides:
            slide_assets, chunks = make_slide_assets(path)
            assets.extend(slide_assets)
            slide_chunks.extend(chunks)
    evidence_map = make_multimodal_evidence_map(assets, slide_chunks)
    output_files = ["multimodal_assets.jsonl", "multimodal_evidence_map.json", "multimodal_report.md"]
    if slide_chunks:
        output_files.append("slide_chunks.jsonl")
    return MultimodalResult(
        assets=assets,
        slide_chunks=slide_chunks,
        evidence_map=evidence_map,
        report=make_multimodal_report(assets),
        output_files=output_files,
    )


def _collect_candidates(input_path: Path, source_files: list[Path]) -> list[Path]:
    files = set(source_files)
    if input_path.is_file():
        files.add(input_path)
    else:
        files.update(path for path in input_path.rglob("*") if path.is_file())
    suffixes = IMAGE_SUFFIXES | SLIDE_SUFFIXES
    return sorted(path for path in files if path.suffix.lower() in suffixes or maybe_formula_asset(path))


def _type_enabled(asset_type: str, options: MultimodalOptions) -> bool:
    return {
        "chart": options.charts,
        "diagram": options.diagrams,
        "mindmap": options.mindmaps,
    }.get(asset_type, True)
