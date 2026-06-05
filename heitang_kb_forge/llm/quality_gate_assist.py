from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


def run_llm_quality_gate_assist(workspace: Path, output: Path, provider: str = "mock") -> dict:
    output.mkdir(parents=True, exist_ok=True)
    suggestions = [
        {
            "category": "release_blocker_wording",
            "suggestion": "Keep blocker wording evidence-based and do not claim real platform verification.",
        },
        {
            "category": "policy_text",
            "suggestion": "Ensure XHS is described as local package preparation, not an official upload API.",
        },
        {
            "category": "regression_cases",
            "suggestion": "Keep v1.6-v2.4 regression coverage tied to commands, modules, schemas, and tests.",
        },
    ]
    result = {
        "status": "pass",
        "provider": provider,
        "mock_provider": provider == "mock",
        "network_called": False,
        "suggestion_only": True,
        "human_review_required": True,
        "suggestion_count": len(suggestions),
    }
    write_json(output / "llm_quality_gate_assist_result.json", result)
    write_jsonl(output / "llm_quality_gate_suggestions.jsonl", suggestions)
    write_jsonl(output / "llm_call_audit.jsonl", [{"provider": provider, "network_called": False, "task": "quality_gate_assist"}])
    (output / "llm_quality_gate_assist_report.md").write_text(_render_report(result), encoding="utf-8")
    return result


def _render_report(result: dict) -> str:
    return f"""# LLM Quality Gate Assist Report

- Status: {result['status']}
- Provider: {result['provider']}
- Network called: {result['network_called']}
- Suggestion only: {result['suggestion_only']}
- Human review required: {result['human_review_required']}
"""

