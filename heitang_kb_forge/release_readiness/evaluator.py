from pathlib import Path
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.release_readiness.report import render_release_readiness_checklist, render_release_readiness_report
from heitang_kb_forge.schemas.release_readiness_schema import ReleaseReadinessResult

INPUT_FILES = {
    "quality_gate": "quality_gate_result.json",
    "release_blockers": "release_blockers.json",
    "regression": "regression_result.json",
    "golden_samples": "golden_sample_validation.json",
    "export_certification": "platform_export_certification.json",
    "compatibility_matrix": "compatibility_matrix.json",
}


def evaluate_release_readiness(workspace: Path, output: Path) -> ReleaseReadinessResult:
    output.mkdir(parents=True, exist_ok=True)
    inputs = {name: _status(output / file_name) for name, file_name in INPUT_FILES.items()}
    critical = []
    warnings = []
    for name, status in inputs.items():
        if status == "fail":
            critical.append(f"{name}_failed")
        elif status == "not_found":
            warnings.append(f"{name}_not_found")
        elif status == "warning":
            warnings.append(f"{name}_warning")
    score = max(0, 100 - len(critical) * 20 - len(warnings) * 5)
    status = "fail" if critical else "warning" if warnings else "pass"
    result = ReleaseReadinessResult(
        status=status,
        release_ready=status == "pass",
        overall_score=score,
        inputs=inputs,
        critical_blockers=critical,
        warnings=warnings,
        next_actions=[
            "Resolve critical blockers before release.",
            "Use v2.6 for real LLM live smoke.",
            "Use v2.7 for runtime compatibility smoke.",
        ],
    )
    write_json(output / "release_readiness_result.json", result)
    (output / "release_readiness_report.md").write_text(render_release_readiness_report(result), encoding="utf-8")
    (output / "release_readiness_checklist.md").write_text(render_release_readiness_checklist(result), encoding="utf-8")
    return result


def _status(path: Path) -> str:
    if not path.exists():
        return "not_found"
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return "fail"
    return payload.get("status", "pass")

