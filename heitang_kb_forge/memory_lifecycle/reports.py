from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.memory_lifecycle.compaction import build_memory_compaction_plan
from heitang_kb_forge.memory_lifecycle.schema import build_memory_lifecycle_schema
from heitang_kb_forge.memory_lifecycle.token_budget import build_token_budget_policy


V39_MEMORY_LIFECYCLE_OUTPUT_FILES = [
    "memory_lifecycle_report.json",
    "memory_lifecycle_report.md",
    "memory_compaction_plan.json",
    "memory_index_contract.json",
    "token_budget_policy.json",
    "memory_retention_policy.json",
]


def write_memory_lifecycle_outputs(
    output: Path,
    *,
    max_context_memory_items: int = 20,
    max_estimated_context_tokens: int = 4000,
    compaction_strategy: str = "deterministic_summary_placeholder",
    promote_candidates: bool = False,
) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    lifecycle = build_memory_lifecycle_schema()
    compaction = build_memory_compaction_plan(compaction_strategy)
    token_budget = build_token_budget_policy(max_context_memory_items, max_estimated_context_tokens)
    memory_index = {
        "memory_index_contract_version": "3.9.0-alpha.1",
        "backend": "local_workspace",
        "index_records": [],
        "raw_memory_embedded": False,
        "agent_runtime_memory_implemented": False,
    }
    retention = {
        "memory_retention_policy_version": "3.9.0-alpha.1",
        "session_log": "retain_short_term_then_compact",
        "short_term_memory": "compact_to_summary_memory",
        "summary_memory": "retain_until_review_or_archive",
        "long_term_memory": "retain_after_review",
        "memory_candidates": "review_required_before_promotion",
        "promote_candidates": promote_candidates,
    }
    write_json(output / "memory_lifecycle_report.json", lifecycle)
    (output / "memory_lifecycle_report.md").write_text(render_memory_lifecycle_report(lifecycle, token_budget), encoding="utf-8")
    write_json(output / "memory_compaction_plan.json", compaction)
    write_json(output / "memory_index_contract.json", memory_index)
    write_json(output / "token_budget_policy.json", token_budget)
    write_json(output / "memory_retention_policy.json", retention)
    return {
        "status": "pass",
        "output_files": V39_MEMORY_LIFECYCLE_OUTPUT_FILES,
        "memory_lifecycle_report": lifecycle,
        "memory_compaction_plan": compaction,
        "token_budget_policy": token_budget,
    }


def render_memory_lifecycle_report(lifecycle: dict, token_budget: dict) -> str:
    rows = "\n".join(
        f"| {item['name']} | {item['injectable_by_default']} | {item['purpose']} |"
        for item in lifecycle["memory_classes"]
    )
    return f"""# Memory Lifecycle Report

- Status: {lifecycle['status']}
- Private memory default: {lifecycle['private_memory_default']}
- Workflow shared memory: {lifecycle['workflow_shared_memory']}
- Prevent all-history injection: {token_budget['prevent_all_history_injection']}

| Memory class | Injectable by default | Purpose |
| --- | --- | --- |
{rows}
"""
