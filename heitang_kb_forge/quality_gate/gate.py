import json
from pathlib import Path

QUALITY_GATE_OUTPUT_FILES = ["quality_gate_report.json", "quality_gate_summary.md", "package_acceptance_report.md"]


def evaluate_quality_gate(package: Path) -> tuple[dict, str, str]:
    quality = _read_json(package / "quality_report.json")
    validation = _read_json(package / "package_validation_report.json")
    llm_quality = _read_json(package / "llm_quality_report.json")
    risks = _read_jsonl(package / "risk_labels.jsonl")
    reasons: list[str] = []
    warnings: list[str] = []

    if int(quality.get("chunk_count", 0)) == 0:
        reasons.append("chunk_count_is_zero")
    if float(quality.get("citation_coverage", 0)) < 0.8:
        warnings.append("citation_coverage_below_0.8")
    if float(quality.get("source_path_coverage", 0)) < 0.8:
        warnings.append("source_path_coverage_below_0.8")
    if int(quality.get("empty_chunk_count", 0)) > 0:
        reasons.append("empty_chunks_present")
    if validation.get("readiness_level") == "not_ready":
        reasons.append("package_not_ready")
    if validation.get("hallucination_risk_level") == "high":
        reasons.append("high_hallucination_risk")
    if llm_quality and llm_quality.get("llm_quality_level") == "poor":
        reasons.append("poor_llm_quality")
    if any(item.get("severity") == "high" for item in risks):
        reasons.append("high_risk_labels_present")

    status = "fail" if reasons else "warning" if warnings else "pass"
    report = {
        "quality_gate_version": "1.2.1",
        "status": status,
        "reasons": reasons,
        "warnings": warnings,
        "quality_score": quality.get("quality_score"),
        "quality_level": quality.get("quality_level"),
        "readiness_level": validation.get("readiness_level"),
        "hallucination_risk_level": validation.get("hallucination_risk_level"),
        "risk_label_count": len(risks),
    }
    return report, _summary(report), _acceptance(report)


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _summary(report: dict) -> str:
    reasons = "\n".join(f"- {item}" for item in report["reasons"]) or "- None"
    warnings = "\n".join(f"- {item}" for item in report["warnings"]) or "- None"
    return f"""# Quality Gate Summary

- Status: {report['status']}
- Quality score: {report.get('quality_score')}
- Quality level: {report.get('quality_level')}
- Readiness: {report.get('readiness_level')}
- Hallucination risk: {report.get('hallucination_risk_level')}

## Fail Reasons

{reasons}

## Warnings

{warnings}
"""


def _acceptance(report: dict) -> str:
    return f"""# Package Acceptance Report

- Acceptance status: {report['status']}
- Strict mode recommendation: {'block' if report['status'] == 'fail' else 'allow'}
"""
