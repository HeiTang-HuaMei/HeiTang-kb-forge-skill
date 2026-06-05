from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.reliability.report import render_reliability_report
from heitang_kb_forge.schemas.reliability_schema import ReliabilityScore


DIMENSIONS = {
    "knowledge_package": ["registries/package_registry.jsonl"],
    "evidence": ["registries/relationship_graph.json"],
    "multimodal_assets": [],
    "contract": ["stable_check_result.json"],
    "governance": ["registries/package_registry.jsonl"],
    "retrieval": ["registries/package_registry.jsonl"],
    "evidence_gate": ["registries/package_registry.jsonl"],
    "skill_validation": ["registries/skill_registry.jsonl"],
    "agent_package": ["registries/agent_registry.jsonl"],
    "workspace": ["workspace_manifest.json"],
    "provider_registry": ["registries/provider_registry.json"],
    "llm_audit": ["registries/llm_call_audit.jsonl"],
}


def make_reliability_score(workspace: Path, threshold: int = 80) -> tuple[ReliabilityScore, str]:
    scores = {}
    warnings = []
    for dimension, files in DIMENSIONS.items():
        if not files or all((workspace / file_name).exists() for file_name in files):
            scores[dimension] = 100
        else:
            scores[dimension] = 50
            warnings.append(f"{dimension}_incomplete")
    overall = round(sum(scores.values()) / len(scores))
    result = ReliabilityScore(
        overall_score=overall,
        status="pass" if overall >= threshold else "warning",
        scores=scores,
        release_ready=overall >= threshold,
        warnings=warnings,
    )
    write_json(workspace / "reliability_score.json", result.model_dump(mode="json"))
    report = render_reliability_report(result)
    (workspace / "reliability_report.md").write_text(report, encoding="utf-8")
    return result, report
