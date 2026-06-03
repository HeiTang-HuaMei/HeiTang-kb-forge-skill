import json
from pathlib import Path

from heitang_kb_forge.versioning.package_version import make_package_version

EVAL_DASHBOARD_OUTPUT_FILES = [
    "retrieval_eval_results.json",
    "answer_eval_results.json",
    "citation_hit_report.md",
    "quality_trend_report.md",
]


def make_eval_dashboard(package: Path, eval_results: Path | None = None) -> tuple[dict, dict, str, str]:
    trace = _read_json(package / "retrieval_trace.json")
    answer_report = _read_json(package / "answer_report.json")
    quality = _read_json(package / "quality_report.json")
    version = make_package_version(package)
    retrieved = trace.get("records", [])
    citation_hits = [record for record in retrieved if record.get("citation")]
    retrieval_results = {
        "eval_dashboard_version": "1.2.0",
        "package_hash": version.package_hash,
        "retrieved_count": len(retrieved),
        "citation_hit_count": len(citation_hits),
        "external_eval_results": _read_json(eval_results) if eval_results else {},
    }
    answer_results = {
        "answer_available": bool(answer_report),
        "citation_count": len(answer_report.get("citations", [])) if answer_report else 0,
        "insufficient_context": answer_report.get("insufficient_context") if answer_report else None,
    }
    return retrieval_results, answer_results, _citation_report(retrieval_results), _quality_trend_report(version.package_hash, quality)


def _read_json(path: Path | None) -> dict:
    if not path or not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _citation_report(results: dict) -> str:
    return f"""# Citation Hit Report

- Retrieved records: {results['retrieved_count']}
- Citation hits: {results['citation_hit_count']}
"""


def _quality_trend_report(package_hash: str, quality: dict) -> str:
    return f"""# Quality Trend Report

- Package hash: {package_hash}
- Quality score: {quality.get('quality_score')}
- Quality level: {quality.get('quality_level')}
"""
