from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workspace_storage.cleanup import build_cleanup_plan, render_cleanup_plan_md
from heitang_kb_forge.workspace_storage.dedup import build_dedup_report
from heitang_kb_forge.workspace_storage.registry import REGISTRY_TYPES, scan_workspace, workspace_registry
from heitang_kb_forge.workspace_storage.retention import build_retention_policy_report
from heitang_kb_forge.workspace_storage.storage_report import build_storage_usage_report, render_storage_report_md


V39_WORKSPACE_STORAGE_OUTPUT_FILES = [
    "workspace_registry.json",
    "package_registry.json",
    "skill_registry.json",
    "agent_registry.json",
    "memory_registry.json",
    "document_registry.json",
    "index_registry.json",
    "storage_report.json",
    "storage_report.md",
    "storage_usage_report.json",
    "cleanup_plan.json",
    "cleanup_plan.md",
    "retention_policy_report.json",
    "archive_plan.json",
    "dedup_report.json",
]


def write_workspace_storage_outputs(
    workspace_root: Path,
    output: Path | None = None,
    *,
    track_content_hash: bool = True,
    destructive_cleanup: bool = False,
) -> dict:
    target = output or workspace_root
    target.mkdir(parents=True, exist_ok=True)
    registries = scan_workspace(workspace_root, track_hash=track_content_hash)
    workspace = workspace_registry(workspace_root, registries)
    usage = build_storage_usage_report(registries)
    dedup = build_dedup_report(registries)
    cleanup = build_cleanup_plan(registries, dedup)
    cleanup["destructive_cleanup_enabled"] = bool(destructive_cleanup)
    cleanup["destructive_action_taken"] = False
    retention = build_retention_policy_report()

    write_json(target / "workspace_registry.json", workspace)
    for asset_type in REGISTRY_TYPES:
        write_json(target / f"{asset_type}_registry.json", {"registry_version": "3.9.0-alpha.1", "asset_type": asset_type, "entries": registries.get(asset_type, [])})
    write_json(target / "storage_report.json", usage)
    write_json(target / "storage_usage_report.json", usage)
    (target / "storage_report.md").write_text(render_storage_report_md(usage), encoding="utf-8")
    write_json(target / "dedup_report.json", dedup)
    write_json(target / "cleanup_plan.json", cleanup)
    (target / "cleanup_plan.md").write_text(render_cleanup_plan_md(cleanup), encoding="utf-8")
    write_json(target / "retention_policy_report.json", retention)
    write_json(target / "archive_plan.json", retention["archive_plan"])
    return {
        "status": "pass",
        "output_files": V39_WORKSPACE_STORAGE_OUTPUT_FILES,
        "registries": registries,
        "storage_usage_report": usage,
        "cleanup_plan": cleanup,
        "dedup_report": dedup,
    }
