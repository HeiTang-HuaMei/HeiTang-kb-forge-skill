from datetime import datetime, timezone
from pathlib import Path

from heitang_kb_forge.workspace.registry import workspace_status

REFRESH_OUTPUT_FILES = ["source_freshness_report.md", "stale_sources.jsonl", "refresh_plan.json"]


def make_refresh_plan(workspace: Path, stale_days: int = 30) -> tuple[list[dict], dict, str]:
    registry, _ = workspace_status(workspace)
    stale_items: list[dict] = []
    for item in registry["packages"]:
        reasons = []
        package_path = Path(item["package_path"])
        if not package_path.exists():
            reasons.append("package_missing")
        if item.get("readiness_level") in {"warning", "not_ready"}:
            reasons.append("readiness_not_ready")
        if item.get("risk_level") == "high":
            reasons.append("high_risk")
        if item.get("quality_score") is not None and item["quality_score"] < 60:
            reasons.append("quality_below_threshold")
        if reasons:
            stale_items.append({"package_path": item["package_path"], "reasons": reasons, "recommended_action": "rebuild_or_review"})
    plan = {
        "refresh_version": "1.2.0",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "workspace": str(workspace).replace("\\", "/"),
        "stale_days": stale_days,
        "stale_count": len(stale_items),
        "items": stale_items,
    }
    return stale_items, plan, _report(plan)


def _report(plan: dict) -> str:
    rows = "\n".join(f"| {item['package_path']} | {', '.join(item['reasons'])} | {item['recommended_action']} |" for item in plan["items"]) or "| - | - | - |"
    return f"""# Source Freshness Report

## Summary

- Workspace: {plan['workspace']}
- Stale packages: {plan['stale_count']}

## Refresh Plan

| Package | Reasons | Recommended Action |
| --- | --- | --- |
{rows}
"""
