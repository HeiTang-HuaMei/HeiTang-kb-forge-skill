from pathlib import Path
import json

from heitang_kb_forge.evidence_gate.boundary import judge_boundary
from heitang_kb_forge.evidence_gate.grounding import find_grounding
from heitang_kb_forge.evidence_gate.refusal import refusal_reason
from heitang_kb_forge.evidence_gate.report import render_evidence_gate_report
from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.retrieval.index_builder import build_retrieval_index
from heitang_kb_forge.schemas.evidence_gate_schema import EvidenceGateResult


EVIDENCE_GATE_OUTPUT_FILES = ["evidence_gate_result.json", "evidence_gate_report.md"]


def run_evidence_gate(package: Path, output: Path, query: str) -> EvidenceGateResult:
    output.mkdir(parents=True, exist_ok=True)
    records = _load_index(package) or [record.model_dump(mode="json") for record in build_retrieval_index(package)]
    grounding = find_grounding(query, records)
    boundary = judge_boundary(query, records)
    warnings = []
    if not records:
        warnings.append("empty_retrieval_index")
    if any(item.get("review_required") for item in grounding):
        warnings.append("review_required_evidence")
    if boundary["boundary"] == "outside" or not grounding:
        decision = "refuse"
        reason = refusal_reason(boundary["boundary"], grounding)
    elif warnings:
        decision = "needs_review"
        reason = "Evidence exists but requires review."
    else:
        decision = "allow"
        reason = "Query is supported by package evidence."
    result = EvidenceGateResult(
        package=str(package).replace("\\", "/"),
        query=query,
        decision=decision,
        reason=reason,
        evidence_ids=[item.get("retrieval_id", "") for item in grounding],
        warnings=warnings,
    )
    write_json(output / "evidence_gate_result.json", result.model_dump(mode="json"))
    (output / "evidence_gate_report.md").write_text(render_evidence_gate_report(result), encoding="utf-8")
    return result


def _load_index(package: Path) -> list[dict]:
    path = package / "retrieval_index.jsonl"
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
