from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.quality_gate.report import finding_rows, render_quality_gate_report, scorecard
from heitang_kb_forge.quality_gate.rules import QUALITY_GATE_OBJECTS, gate_status
from heitang_kb_forge.quality_gate.scoring import score_gates
from heitang_kb_forge.schemas.quality_gate_schema import QualityGateFinding, QualityGateResult


def run_quality_gate(workspace: Path, output: Path, release_threshold: int = 80) -> QualityGateResult:
    output.mkdir(parents=True, exist_ok=True)
    gates = {name: gate_status(workspace, files) for name, files in QUALITY_GATE_OBJECTS.items()}
    blockers = [f"{name}_failed" for name, status in gates.items() if status == "fail"]
    warnings = [f"{name}_{status}" for name, status in gates.items() if status in {"warning", "not_found", "not_enabled"}]
    score = score_gates(gates)
    status = "fail" if blockers else "warning" if warnings or score < release_threshold else "pass"
    result = QualityGateResult(
        status=status,
        release_ready=status == "pass" and score >= release_threshold,
        overall_score=score,
        gates=gates,
        blockers=blockers,
        warnings=warnings,
        recommendations=["Review warnings before release.", "Run release-readiness after all v2.5 checks."],
    )
    findings = [
        QualityGateFinding(gate=name, severity="medium" if value == "warning" else "low", message=value)
        for name, value in gates.items()
        if value != "pass"
    ]
    write_json(output / "quality_gate_result.json", result)
    write_json(output / "quality_gate_scorecard.json", scorecard(result))
    write_jsonl(output / "quality_gate_findings.jsonl", finding_rows(findings))
    (output / "quality_gate_report.md").write_text(render_quality_gate_report(result), encoding="utf-8")
    return result

