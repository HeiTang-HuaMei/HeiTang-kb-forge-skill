import json
from pathlib import Path

from heitang_kb_forge.schemas.package_validation_schema import PackageValidationReport

VALIDATION_OUTPUT_FILES = ["package_validation_report.json", "package_readiness_report.md"]
STANDARD_PACKAGE_FILES = [
    "chunks.jsonl",
    "cards.jsonl",
    "qa_pairs.jsonl",
    "glossary.jsonl",
    "manifest.json",
    "ingest_report.md",
    "quality_report.json",
]


def validate_package(package_path: Path) -> tuple[PackageValidationReport, str]:
    missing_files = [name for name in STANDARD_PACKAGE_FILES if not (package_path / name).exists()]
    assets = _load_assets(package_path)
    citation_coverage = _coverage(assets, "citation")
    source_path_coverage = _coverage(assets, "source_path")
    chunk_id_coverage = _coverage(assets, "chunk_id")
    warnings = _manifest_warnings(package_path)
    table_warning_count = sum(1 for warning in warnings if "table" in warning.lower())
    ocr_warning_count = sum(1 for warning in warnings if "ocr" in warning.lower())
    missing_citation_count = sum(1 for item in assets if not str(item.get("citation", "")).strip())
    low_confidence_count = sum(
        1
        for item in assets
        if item.get("confidence") is not None and _float(item.get("confidence")) < 0.5
    )
    readiness_level = _readiness_level(missing_files, citation_coverage, source_path_coverage)
    hallucination_risk_level = _risk_level(missing_citation_count, low_confidence_count, ocr_warning_count, table_warning_count)

    report = PackageValidationReport(
        package_path=str(package_path).replace("\\", "/"),
        standard_files_present=not missing_files,
        missing_files=missing_files,
        citation_coverage=citation_coverage,
        source_path_coverage=source_path_coverage,
        chunk_id_coverage=chunk_id_coverage,
        missing_citation_asset_count=missing_citation_count,
        low_confidence_asset_count=low_confidence_count,
        ocr_low_confidence_warning_count=ocr_warning_count,
        table_extraction_warning_count=table_warning_count,
        readiness_for_rag=readiness_level,
        readiness_for_embedding=readiness_level,
        readiness_for_agent_template=readiness_level,
        readiness_for_downstream_export=readiness_level,
        readiness_level=readiness_level,
        hallucination_risk_level=hallucination_risk_level,
        warnings=warnings,
    )
    return report, _render_readiness_report(report)


def _load_assets(package_path: Path) -> list[dict]:
    assets: list[dict] = []
    for name in ["chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl"]:
        path = package_path / name
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.strip():
                assets.append(json.loads(line))
    return assets


def _manifest_warnings(package_path: Path) -> list[str]:
    path = package_path / "manifest.json"
    if not path.exists():
        return []
    return list(json.loads(path.read_text(encoding="utf-8")).get("warnings", []))


def _coverage(items: list[dict], field: str) -> float:
    if not items:
        return 0.0
    return round(sum(1 for item in items if str(item.get(field, "")).strip()) / len(items), 4)


def _float(value: object) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0


def _readiness_level(missing_files: list[str], citation_coverage: float, source_path_coverage: float) -> str:
    if missing_files:
        return "not_ready"
    if citation_coverage < 0.8 or source_path_coverage < 0.8:
        return "warning"
    return "ready"


def _risk_level(missing_citation_count: int, low_confidence_count: int, ocr_warning_count: int, table_warning_count: int) -> str:
    total = missing_citation_count + low_confidence_count + ocr_warning_count + table_warning_count
    if total == 0:
        return "low"
    if total <= 3:
        return "medium"
    return "high"


def _render_readiness_report(report: PackageValidationReport) -> str:
    missing = "\n".join(f"- {name}" for name in report.missing_files) or "- None"
    warnings = "\n".join(f"- {warning}" for warning in report.warnings) or "- None"
    return f"""# Package Readiness Report

## Summary

- Readiness level: {report.readiness_level}
- Hallucination risk level: {report.hallucination_risk_level}
- Standard files present: {report.standard_files_present}

## Coverage

- Citation coverage: {report.citation_coverage}
- Source path coverage: {report.source_path_coverage}
- Chunk ID coverage: {report.chunk_id_coverage}

## Risk Signals

- Missing citation assets: {report.missing_citation_asset_count}
- Low confidence assets: {report.low_confidence_asset_count}
- OCR warning count: {report.ocr_low_confidence_warning_count}
- Table extraction warning count: {report.table_extraction_warning_count}

## Missing Files

{missing}

## Warnings

{warnings}
"""
