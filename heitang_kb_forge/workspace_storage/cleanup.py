from __future__ import annotations


def build_cleanup_plan(registries: dict[str, list[dict]], dedup_report: dict) -> dict:
    recommendations = []
    if dedup_report["duplicate_group_count"]:
        recommendations.append(
            {
                "action": "review_duplicate_assets",
                "asset_count": sum(group["asset_count"] for group in dedup_report["duplicate_groups"]),
                "destructive": False,
            }
        )
    failed = [
        entry
        for entries in registries.values()
        for entry in entries
        if entry.get("status") in {"failed", "stale"} or "failed" in entry.get("path", "").lower()
    ]
    if failed:
        recommendations.append({"action": "archive_failed_outputs", "asset_count": len(failed), "destructive": False})
    generated_docs = registries.get("document", [])
    if len(generated_docs) > 20:
        recommendations.append({"action": "archive_old_generated_documents", "asset_count": len(generated_docs), "destructive": False})
    return {
        "cleanup_plan_version": "3.9.0-alpha.1",
        "recommendation_only": True,
        "destructive_cleanup_enabled": False,
        "destructive_action_taken": False,
        "recommendations": recommendations,
        "stale_temp_files": [],
        "cache_candidates": [],
    }


def render_cleanup_plan_md(plan: dict) -> str:
    rows = "\n".join(
        f"- {item['action']}: {item['asset_count']} assets, destructive={item['destructive']}"
        for item in plan["recommendations"]
    ) or "- No cleanup recommended."
    return f"""# Cleanup Plan

- Recommendation only: {plan['recommendation_only']}
- Destructive cleanup enabled: {plan['destructive_cleanup_enabled']}

## Recommendations

{rows}
"""
