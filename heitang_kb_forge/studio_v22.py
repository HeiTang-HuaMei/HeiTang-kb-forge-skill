from pathlib import Path
from datetime import datetime, timezone

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


def write_studio_v22_outputs(workspace: Path) -> dict:
    workspace.mkdir(parents=True, exist_ok=True)
    actions = {
        "action_center_version": "2.2",
        "actions": [
            {"action": "review_master_skill", "status": "available"},
            {"action": "check_agent_compat", "status": "available"},
            {"action": "refresh_workspace", "status": "available"},
        ],
    }
    summary = {
        "studio_version": "2.2",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "master_skill_learning": "available",
        "agent_compatibility": "available",
        "workspace_refresh": "available",
        "provider_readiness": "available",
        "prompt_profile_versioning": "available",
    }
    run = {"run_id": f"studio-v22-{summary['generated_at']}", "status": "recorded", "created_at": summary["generated_at"]}
    write_json(workspace / "action_center.json", actions)
    write_jsonl(workspace / "run_history.jsonl", [run])
    write_json(workspace / "studio_v22_summary.json", summary)
    return summary
