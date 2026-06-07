from __future__ import annotations


def build_retention_policy_report() -> dict:
    return {
        "retention_policy_report_version": "3.9.0-alpha.1",
        "policy": {
            "packages": "retain_until_user_archive",
            "skills": "retain_until_user_archive",
            "agents": "retain_until_user_archive",
            "memory": "compact_before_context_injection",
            "generated_documents": "archive_old_versions_by_recommendation",
            "indexes": "rebuildable_cache_with_registry_reference",
        },
        "archive_plan": {
            "archive_plan_version": "3.9.0-alpha.1",
            "recommendation_only": True,
            "destructive_action_taken": False,
            "archive_targets": [],
        },
    }
