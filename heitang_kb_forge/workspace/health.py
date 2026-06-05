from pathlib import Path
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json


def check_workspace_health(workspace: Path) -> tuple[dict, str]:
    warnings = []
    required = [
        "workspace_manifest.json",
        "registries/package_registry.jsonl",
        "registries/skill_registry.jsonl",
        "registries/agent_registry.jsonl",
        "registries/relationship_graph.json",
        "registries/provider_registry.json",
        "registries/prompt_profile_registry.json",
        "registries/llm_call_audit.jsonl",
    ]
    for name in required:
        if not (workspace / name).exists():
            warnings.append(f"missing_{name}")
    for registry in ["package_registry.jsonl", "skill_registry.jsonl", "agent_registry.jsonl"]:
        for item in _read_jsonl(workspace / "registries" / registry):
            path = Path(item.get("package_path") or item.get("skill_path") or item.get("agent_path") or "")
            if path and not path.exists():
                warnings.append(f"missing_registered_path:{path}")
    result = {
        "workspace_health_version": "1.9",
        "workspace": str(workspace).replace("\\", "/"),
        "status": "warning" if warnings else "pass",
        "warnings": warnings,
    }
    write_json(workspace / "reports" / "workspace_health_result.json", result)
    report = render_health_report(result)
    (workspace / "reports" / "workspace_health_report.md").write_text(report, encoding="utf-8")
    return result, report


def render_health_report(result: dict) -> str:
    warnings = "\n".join(f"- {item}" for item in result["warnings"]) or "- None"
    return f"# Workspace Health Report\n\n- Status: {result['status']}\n\n## Warnings\n\n{warnings}\n"


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
