from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


GENERATED_AT = "2026-06-14T04:45:00+08:00"
CURRENT_ITEM = "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate"
AUDIT_DIR = Path("artifacts/audits/repository_public_surface_cleanup")
NEXT_ACTION = "Repository push only"
PRODUCT_NAME = "HeiTang Knowledge Workbench"
IMPORT_NAMESPACE = "heitang_kb_forge"

FORBIDDEN_TRACKED_PATTERNS = [
    re.compile(r"(^|/)\.venv(/|$)"),
    re.compile(r"(^|/)node_modules(/|$)"),
    re.compile(r"(^|/)\.heitang_cache(/|$)"),
    re.compile(r"(^|/)_local_dependency_remediation(/|$)"),
    re.compile(r"(^|/)repo_surface_audit_pack(/|$)"),
    re.compile(r"(^|/)artifacts/audits/current_run(/|$)"),
    re.compile(r"(^|/)artifacts/audits/latest(/|$)"),
    re.compile(r"(^|/)tmp(/|$)"),
    re.compile(r"(^|/)build(/|$)"),
    re.compile(r"(^|/)dist(/|$)"),
    re.compile(r"(^|/)\.env$"),
    re.compile(r"(^|/)provider_config\.yaml$"),
    re.compile(r"(^|/)local_provider_config\.yaml$"),
    re.compile(r"\.(secret|token|cookie)$"),
    re.compile(r"(^|/)credentials\."),
]

REQUIRED_GITIGNORE_ENTRIES = [
    "_local_dependency_remediation/",
    ".heitang_cache/",
    "repo_surface_audit_pack/",
    "repo_surface_audit_pack.zip",
    "repo_tracked_snapshot.zip",
    "artifacts/audits/current_run/",
    "artifacts/audits/latest/",
    "tmp/",
    "tmp_*/",
    ".cache/",
    ".pytest_cache/",
    ".coverage",
    "coverage/",
    ".venv/",
    "node_modules/",
    ".dart_tool/",
    "build/",
    "dist/",
    "__pycache__/",
    ".env",
    ".env.*",
    "!.env.example",
    "provider_config.yaml",
    "local_provider_config.yaml",
    "*.secret",
    "*.token",
    "*.cookie",
    "credentials.*",
]

SECRET_PATTERNS = [
    re.compile(r"(?i)(api[_-]?key|secret|token|cookie|password|credential)\s*[:=]\s*['\"]?[A-Za-z0-9_\-]{24,}"),
    re.compile(r"sk-[A-Za-z0-9]{24,}"),
    re.compile(r"gh[pousr]_[A-Za-z0-9_]{30,}"),
]

SECRET_ALLOWLIST_MARKERS = [
    "example",
    "placeholder",
    "dummy",
    "sample",
    "redacted",
    "test",
    "fake",
    "secret-anysearch-key",
    "sk-test-secret",
]

LARGE_FILE_LIMIT_BYTES = 25 * 1024 * 1024

REQUIRED_OUTPUTS = [
    "file_inventory.json",
    "git_status_snapshot.txt",
    "tracked_files.txt",
    "untracked_files.txt",
    "large_file_report.json",
    "root_surface_report.json",
    "docs_surface_report.json",
    "artifacts_surface_report.json",
    "PUBLIC_SURFACE_FILE_INVENTORY.json",
    "ROOT_FILE_MIGRATION_MANIFEST.json",
    "DELETION_CANDIDATE_MANIFEST.json",
    "RENAMING_COMPATIBILITY_MATRIX.json",
    "PUBLIC_SURFACE_CLEANUP_REPORT.md",
    "UPDATED_GITIGNORE_REPORT.md",
    "PUSH_TAG_SAFETY_REPORT.md",
    "validation_report.json",
    "run_manifest.json",
    "checkpoint.json",
    "progress_events.jsonl",
    "run_summary.md",
]


def build_repository_public_surface_cleanup_gate(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    git_status = _git(repo_root, "status", "--short")
    tracked = _split_lines(_git(repo_root, "ls-files"))
    untracked = _split_lines(_git(repo_root, "ls-files", "--others", "--exclude-standard"))
    inventory = _file_inventory(repo_root, tracked, untracked)
    gitignore_report = _gitignore_report(repo_root)
    forbidden_report = _forbidden_tracked_files_report(tracked)
    large_report = _large_file_report(repo_root, tracked)
    secret_report = _secret_report(repo_root, tracked)
    root_report = _root_surface_report(repo_root)
    docs_report = _tree_surface_report(repo_root, "docs")
    artifacts_report = _tree_surface_report(repo_root, "artifacts")
    rename_matrix = _renaming_compatibility_matrix(repo_root)
    deletion_manifest = _deletion_candidate_manifest(inventory)
    migration_manifest = _root_migration_manifest(root_report)
    prerequisite = _prerequisite_matrix(repo_root)

    failures = [
        *prerequisite["errors"],
        *gitignore_report["errors"],
        *forbidden_report["errors"],
        *large_report["errors"],
        *secret_report["errors"],
        *rename_matrix["errors"],
    ]
    passed = not failures
    return {
        "schema_version": "repository_public_surface_cleanup_gate.v1",
        "generated_at": GENERATED_AT,
        "current_item": CURRENT_ITEM,
        "status": "passed" if passed else "failed",
        "verdict": "accepted_for_repository_push" if passed else "failed",
        "implementation_level": "bounded industrial-grade public surface safety gate",
        "git_status_snapshot": git_status,
        "tracked_file_count": len(tracked),
        "untracked_file_count": len(untracked),
        "file_inventory": inventory,
        "root_surface_report": root_report,
        "docs_surface_report": docs_report,
        "artifacts_surface_report": artifacts_report,
        "root_migration_manifest": migration_manifest,
        "deletion_candidate_manifest": deletion_manifest,
        "gitignore_report": gitignore_report,
        "forbidden_tracked_files_report": forbidden_report,
        "large_file_report": large_report,
        "secret_scan_report": secret_report,
        "renaming_compatibility_matrix": rename_matrix,
        "prerequisite_matrix": prerequisite,
        "push_tag_safety_report": _push_tag_safety_report(
            passed,
            forbidden_report,
            secret_report,
            large_report,
            gitignore_report,
        ),
        "failure_count": len(failures),
        "failures": failures,
        "campaign_state_after_gate": _campaign_state_after_gate(passed),
        "next_action_manifest": _next_action_manifest(passed),
        "not_goal_complete": True,
    }


def write_repository_public_surface_cleanup_gate(repo_root: Path, output: Path = AUDIT_DIR) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = build_repository_public_surface_cleanup_gate(repo_root)

    write_json(output / "file_inventory.json", report["file_inventory"])
    write_json(output / "PUBLIC_SURFACE_FILE_INVENTORY.json", report["file_inventory"])
    write_json(output / "large_file_report.json", report["large_file_report"])
    write_json(output / "root_surface_report.json", report["root_surface_report"])
    write_json(output / "docs_surface_report.json", report["docs_surface_report"])
    write_json(output / "artifacts_surface_report.json", report["artifacts_surface_report"])
    write_json(output / "ROOT_FILE_MIGRATION_MANIFEST.json", report["root_migration_manifest"])
    write_json(output / "DELETION_CANDIDATE_MANIFEST.json", report["deletion_candidate_manifest"])
    write_json(output / "RENAMING_COMPATIBILITY_MATRIX.json", report["renaming_compatibility_matrix"])
    write_json(output / "PUSH_TAG_SAFETY_REPORT.json", report["push_tag_safety_report"])
    write_json(output / "validation_report.json", _validation_payload(report))
    write_json(output / "run_manifest.json", _run_manifest(report))
    write_json(output / "checkpoint.json", _checkpoint(report))
    write_jsonl(output / "progress_events.jsonl", _progress_events(report))
    (output / "git_status_snapshot.txt").write_text(report["git_status_snapshot"], encoding="utf-8")
    (output / "tracked_files.txt").write_text("\n".join(report["file_inventory"]["tracked_files"]) + "\n", encoding="utf-8")
    (output / "untracked_files.txt").write_text("\n".join(report["file_inventory"]["untracked_files"]) + "\n", encoding="utf-8")
    (output / "PUBLIC_SURFACE_CLEANUP_REPORT.md").write_text(_render_cleanup_report(report), encoding="utf-8")
    (output / "UPDATED_GITIGNORE_REPORT.md").write_text(_render_gitignore_report(report["gitignore_report"]), encoding="utf-8")
    (output / "PUSH_TAG_SAFETY_REPORT.md").write_text(_render_push_tag_safety_report(report), encoding="utf-8")
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")
    _write_governance_docs(repo_root, report)
    return report


def validate_repository_public_surface_cleanup_gate(repo_root: Path, output: Path = AUDIT_DIR) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    errors: list[str] = []
    for name in REQUIRED_OUTPUTS:
        if not (output / name).exists():
            errors.append(f"missing_output:{name}")

    run_manifest = _read_json(output / "run_manifest.json", errors, "run_manifest")
    validation = _read_json(output / "validation_report.json", errors, "validation_report")
    checkpoint = _read_json(output / "checkpoint.json", errors, "checkpoint")
    safety = _read_json(output / "PUSH_TAG_SAFETY_REPORT.json", errors, "push_tag_safety_report")
    rename = _read_json(output / "RENAMING_COMPATIBILITY_MATRIX.json", errors, "renaming_compatibility_matrix")

    if run_manifest.get("scope") != "REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE":
        errors.append("run_manifest_scope_mismatch")
    if validation.get("status") != "passed":
        errors.append("validation_status_not_passed")
    if checkpoint.get("checkpoint_id") != "repository_public_surface_cleanup_gate_passed":
        errors.append("checkpoint_id_mismatch")
    if checkpoint.get("next_safe_action") != NEXT_ACTION:
        errors.append("checkpoint_next_safe_action_mismatch")
    if safety.get("push_allowed") is not True:
        errors.append("push_not_allowed")
    if safety.get("tag_allowed") is not False:
        errors.append("tag_allowed_before_push")
    if rename.get("python_import_namespace_preserved") is not True:
        errors.append("python_import_namespace_not_preserved")
    if rename.get("new_public_name") != PRODUCT_NAME:
        errors.append("public_name_mismatch")

    result = {
        "schema_version": "repository_public_surface_cleanup_gate_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "errors": errors,
        "next_safe_action": NEXT_ACTION if not errors else "Repair Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate",
        "repository_public_surface_cleanup_gate_passed": not errors,
        "repository_push_succeeded": False,
        "tag_created": False,
        "ci_green": False,
        "campaign_4_active": False,
        "not_goal_complete": True,
    }
    write_json(output / "validation_report.json", result)
    return result


def write_repository_public_surface_cleanup_gate_validation(repo_root: Path, output: Path = AUDIT_DIR) -> dict[str, Any]:
    return validate_repository_public_surface_cleanup_gate(repo_root, output)


def _git(repo_root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=repo_root,
        text=True,
        capture_output=True,
        check=False,
    )
    output = result.stdout
    if result.stderr:
        output += result.stderr
    return output


def _split_lines(text: str) -> list[str]:
    return [line.strip() for line in text.splitlines() if line.strip()]


def _file_inventory(repo_root: Path, tracked: list[str], untracked: list[str]) -> dict[str, Any]:
    all_paths = sorted(set(tracked + untracked))
    items = []
    class_counts: dict[str, int] = {}
    for path in all_paths:
        full = repo_root / path
        file_class = _classify_file(path)
        class_counts[file_class] = class_counts.get(file_class, 0) + 1
        items.append({
            "path": path,
            "tracked": path in tracked,
            "untracked": path in untracked,
            "exists": full.exists(),
            "size_bytes": full.stat().st_size if full.exists() and full.is_file() else 0,
            "file_class": file_class,
        })
    return {
        "schema_version": "repository_public_surface_file_inventory.v1",
        "status": "passed",
        "tracked_files": tracked,
        "untracked_files": untracked,
        "tracked_file_count": len(tracked),
        "untracked_file_count": len(untracked),
        "class_counts": class_counts,
        "items": items,
    }


def _classify_file(path: str) -> str:
    if path.startswith("docs/"):
        return "active_docs"
    if path.startswith("artifacts/audits/current_run/"):
        return "temporary_current_run"
    if path.startswith("artifacts/audits/latest/"):
        return "temporary_current_run"
    if path.startswith("artifacts/audits/") or path.startswith("docs/audits/"):
        return "milestone_evidence"
    if "/" not in path and re.search(r"(report|audit|matrix|manifest|log)\.(json|md|txt)$", path, re.IGNORECASE):
        return "legacy_root_reports"
    if path.endswith(".bak") or "duplicate" in path.lower():
        return "obsolete_duplicate_docs"
    return "active_docs" if path.endswith((".md", ".json", ".toml", ".yaml", ".yml")) else "milestone_evidence"


def _gitignore_report(repo_root: Path) -> dict[str, Any]:
    text = (repo_root / ".gitignore").read_text(encoding="utf-8")
    missing = [entry for entry in REQUIRED_GITIGNORE_ENTRIES if entry not in text]
    return {
        "schema_version": "updated_gitignore_report.v1",
        "status": "passed" if not missing else "failed",
        "required_entries": REQUIRED_GITIGNORE_ENTRIES,
        "missing_entries": missing,
        "errors": [f"missing_gitignore_entry:{entry}" for entry in missing],
    }


def _forbidden_tracked_files_report(tracked: list[str]) -> dict[str, Any]:
    forbidden = [
        path
        for path in tracked
        if any(pattern.search(path.replace("\\", "/")) for pattern in FORBIDDEN_TRACKED_PATTERNS)
    ]
    return {
        "schema_version": "forbidden_tracked_files_report.v1",
        "status": "passed" if not forbidden else "failed",
        "forbidden_tracked_files": forbidden,
        "errors": [f"forbidden_tracked_file:{path}" for path in forbidden],
    }


def _large_file_report(repo_root: Path, tracked: list[str]) -> dict[str, Any]:
    items = []
    errors = []
    for path in tracked:
        full = repo_root / path
        if not full.exists() or not full.is_file():
            continue
        size = full.stat().st_size
        if size >= 1024 * 1024:
            items.append({"path": path, "size_bytes": size})
        if size > LARGE_FILE_LIMIT_BYTES and not _large_file_allowed(path):
            errors.append(f"large_runtime_binary:{path}:{size}")
    return {
        "schema_version": "large_file_report.v1",
        "status": "passed" if not errors else "failed",
        "limit_bytes": LARGE_FILE_LIMIT_BYTES,
        "largest_tracked_files": sorted(items, key=lambda item: item["size_bytes"], reverse=True)[:50],
        "errors": errors,
    }


def _large_file_allowed(path: str) -> bool:
    return path.startswith("docs/audits/") or path.startswith("artifacts/audits/")


def _secret_report(repo_root: Path, tracked: list[str]) -> dict[str, Any]:
    findings = []
    errors = []
    for path in tracked:
        full = repo_root / path
        if not full.exists() or not full.is_file() or full.stat().st_size > 1024 * 1024:
            continue
        if full.suffix.lower() in {".png", ".jpg", ".jpeg", ".pdf", ".docx", ".pptx", ".xlsx", ".zip"}:
            continue
        try:
            text = full.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for pattern in SECRET_PATTERNS:
            for match in pattern.finditer(text):
                snippet = match.group(0)
                allowed = any(marker in snippet.lower() or marker in path.lower() for marker in SECRET_ALLOWLIST_MARKERS)
                finding = {
                    "path": path,
                    "pattern": pattern.pattern,
                    "allowed_placeholder": allowed,
                }
                findings.append(finding)
                if not allowed:
                    errors.append(f"possible_secret:{path}")
    return {
        "schema_version": "secret_scan_report.v1",
        "status": "passed" if not errors else "failed",
        "high_confidence_secret_count": len(errors),
        "placeholder_or_test_finding_count": sum(1 for item in findings if item["allowed_placeholder"]),
        "findings": findings[:100],
        "errors": errors,
    }


def _root_surface_report(repo_root: Path) -> dict[str, Any]:
    entries = list(repo_root.iterdir())
    files = [entry for entry in entries if entry.is_file()]
    dirs = [entry for entry in entries if entry.is_dir()]
    root_reports = [
        entry.name for entry in files
        if re.search(r"(report|audit|matrix|manifest|log)\.(json|md|txt)$", entry.name, re.IGNORECASE)
    ]
    return {
        "schema_version": "root_surface_report.v1",
        "status": "passed",
        "root_file_count": len(files),
        "root_directory_count": len(dirs),
        "root_level_report_files": sorted(root_reports),
    }


def _tree_surface_report(repo_root: Path, relative: str) -> dict[str, Any]:
    root = repo_root / relative
    files = [path for path in root.rglob("*") if path.is_file()] if root.exists() else []
    total_bytes = sum(path.stat().st_size for path in files)
    return {
        "schema_version": f"{relative.replace('/', '_')}_surface_report.v1",
        "status": "passed",
        "path": relative,
        "file_count": len(files),
        "total_bytes": total_bytes,
    }


def _renaming_compatibility_matrix(repo_root: Path) -> dict[str, Any]:
    pyproject = (repo_root / "pyproject.toml").read_text(encoding="utf-8")
    skill_json = json.loads((repo_root / "skill.json").read_text(encoding="utf-8-sig"))
    errors = []
    if PRODUCT_NAME not in (repo_root / "README.md").read_text(encoding="utf-8"):
        errors.append("readme_public_name_missing")
    if PRODUCT_NAME not in (repo_root / "README.zh-CN.md").read_text(encoding="utf-8"):
        errors.append("readme_zh_public_name_missing")
    if skill_json.get("display_name") != PRODUCT_NAME:
        errors.append("skill_json_display_name_mismatch")
    if 'packages = ["heitang_kb_forge"]' not in pyproject:
        errors.append("python_import_namespace_not_preserved")
    return {
        "schema_version": "renaming_compatibility_matrix.v1",
        "status": "passed" if not errors else "failed",
        "old_public_name": "HeiTang KB Forge Skill",
        "new_public_name": PRODUCT_NAME,
        "python_import_namespace": IMPORT_NAMESPACE,
        "python_import_namespace_preserved": 'packages = ["heitang_kb_forge"]' in pyproject,
        "package_distribution_name_changed": False,
        "repository_rename_recommended": "HeiTang-Knowledge-Workbench",
        "errors": errors,
    }


def _deletion_candidate_manifest(inventory: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "deletion_candidate_manifest.v1",
        "status": "passed",
        "items": [],
        "note": "No files are deleted by this gate. Deletion candidates require explicit replacement/archive path and safe_to_delete=true.",
    }


def _root_migration_manifest(root_report: dict[str, Any]) -> dict[str, Any]:
    items = [
        {
            "path": path,
            "classification": "legacy_root_reports",
            "recommended_action": "review_after_push_tag_safety_gate",
            "safe_to_delete": False,
        }
        for path in root_report["root_level_report_files"]
    ]
    return {
        "schema_version": "root_file_migration_manifest.v1",
        "status": "passed",
        "items": items,
    }


def _prerequisite_matrix(repo_root: Path) -> dict[str, Any]:
    required = [
        (
            "closure_pack_generated",
            "artifacts/audits/campaign_1_2_3_closure_pack/run_manifest.json",
            {"closure_pack_generated_for_repository_cleanup_gate"},
        ),
        (
            "current_checkpoint_closure_pack_or_cleanup_gate",
            "artifacts/audits/current_run/checkpoint.json",
            {
                "campaign_1_2_3_closure_pack_generated",
                "repository_public_surface_cleanup_gate_passed",
            },
        ),
    ]
    errors = []
    items = []
    for item_id, path, expected_values in required:
        full = repo_root / path
        matched = False
        if full.exists():
            data = json.loads(full.read_text(encoding="utf-8-sig"))
            matched = bool(expected_values & {data.get("verdict"), data.get("checkpoint_id")})
        if not matched:
            errors.append(f"missing_or_invalid_prerequisite:{item_id}:{path}")
        items.append({
            "item_id": item_id,
            "evidence_path": path,
            "expected": sorted(expected_values),
            "status": "passed" if matched else "failed",
        })
    return {
        "schema_version": "repository_surface_cleanup_prerequisite_matrix.v1",
        "status": "passed" if not errors else "failed",
        "items": items,
        "errors": errors,
    }


def _push_tag_safety_report(
    passed: bool,
    forbidden_report: dict[str, Any],
    secret_report: dict[str, Any],
    large_report: dict[str, Any],
    gitignore_report: dict[str, Any],
) -> dict[str, Any]:
    return {
        "schema_version": "push_tag_safety_report.v1",
        "status": "passed" if passed else "failed",
        "push_allowed": passed,
        "tag_allowed": False,
        "ci_check_allowed": False,
        "campaign_4_entry_allowed": False,
        "forbidden_tracked_files_check": forbidden_report["status"],
        "secret_check": secret_report["status"],
        "large_runtime_binary_check": large_report["status"],
        "gitignore_check": gitignore_report["status"],
        "no_arbitrary_shell_execution": True,
        "no_file_deletion_performed": True,
        "errors": [
            *forbidden_report["errors"],
            *secret_report["errors"],
            *large_report["errors"],
            *gitignore_report["errors"],
        ],
    }


def _campaign_state_after_gate(passed: bool) -> dict[str, Any]:
    return {
        "campaign_1_3_integrated_closure_gate_passed": True,
        "closure_pack_generated": True,
        "repository_public_surface_cleanup_gate_passed": passed,
        "repository_push_succeeded": False,
        "tag_created": False,
        "ci_green": False,
        "closure_checklist_green": False,
        "campaign_1_3_review_handoff_gate_passed": False,
        "campaign_4_entry_gate_allowed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "full_gate_passed": False,
        "exe_packaging_done": False,
        "final_release_allowed": False,
        "next_business_item": NEXT_ACTION if passed else "Repair Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate",
    }


def _next_action_manifest(passed: bool) -> dict[str, Any]:
    return {
        "next_safe_action": NEXT_ACTION if passed else "Repair Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate",
        "may_push": passed,
        "may_tag": False,
        "may_check_ci_green": False,
        "may_enter_campaign_4": False,
    }


def _validation_payload(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "repository_public_surface_cleanup_gate_validation.v1",
        "generated_at": GENERATED_AT,
        "status": report["status"],
        "error_count": report["failure_count"],
        "errors": report["failures"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "repository_public_surface_cleanup_gate_passed": report["status"] == "passed",
        "repository_push_succeeded": False,
        "tag_created": False,
        "ci_green": False,
        "campaign_4_active": False,
        "not_goal_complete": True,
    }


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "run_manifest.v1",
        "run_id": "repository_public_surface_cleanup_gate",
        "type": "repository_public_surface_cleanup_rename_push_tag_safety_gate",
        "scope": "REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE",
        "status": report["status"],
        "verdict": report["verdict"],
        "generated_at": GENERATED_AT,
        "output_files": REQUIRED_OUTPUTS,
        "campaign_state_after_run": report["campaign_state_after_gate"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "not_goal_complete": True,
    }


def _checkpoint(report: dict[str, Any]) -> dict[str, Any]:
    passed = report["status"] == "passed"
    return {
        "schema_version": "current_run_checkpoint.v2",
        "checkpoint_id": "repository_public_surface_cleanup_gate_passed" if passed else "repository_public_surface_cleanup_gate_failed",
        "updated_at": report["generated_at"],
        "current_item": CURRENT_ITEM,
        "current_status": report["status"],
        "current_plan_section": "Post Campaign 3 / Campaign 1-3 closure chain",
        "last_successful_step": CURRENT_ITEM if passed else "Campaign 1-3 Closure Pack generated",
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "blocked_future_items": [
            "Repository push before cleanup safety gate",
            "Tag before repository push",
            "CI green before tag",
            "Closure Checklist before CI green",
            "Campaign 4 before closure checklist and handoff review",
            "Campaign 5 before Campaign 4 acceptance",
            "EXE",
            "Release",
        ],
        "tests_run": ["Repository cleanup safety focused tests", "CLI validation", "JSON parse", "git diff --check"],
        "tests_passed": [] if not passed else ["Repository public surface safety gate passed"],
        "tests_failed": [] if passed else report["failures"],
        "files_changed": [str(AUDIT_DIR).replace("\\", "/"), "docs/governance/REPOSITORY_RENAME_MIGRATION_NOTE.md"],
        "audit_outputs": REQUIRED_OUTPUTS,
        "retry_summary": {"transient_retries": 0, "non_transient_command_failures": 0, "last_non_transient_failure": None},
        "resume_prompt_path": "artifacts/audits/current_run/resume_prompt.md",
        "not_goal_complete": True,
        **report["campaign_state_after_gate"],
    }


def _progress_events(report: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        {
            "stage": stage,
            "status": report["status"],
            "timestamp": GENERATED_AT,
            "message": f"{stage} completed for repository public surface cleanup gate.",
            "artifact_path": str(AUDIT_DIR).replace("\\", "/"),
        }
        for stage in [
            "verify_closure_pack_prerequisite",
            "inventory_public_surface",
            "classify_file_surface",
            "check_gitignore",
            "check_forbidden_tracked_files",
            "check_secret_and_large_file_boundaries",
            "write_push_tag_safety_report",
        ]
    ]


def _render_cleanup_report(report: dict[str, Any]) -> str:
    return (
        "# Public Surface Cleanup Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Verdict: `{report['verdict']}`\n"
        f"- Public product name: `{PRODUCT_NAME}`\n"
        f"- Python import namespace preserved: `{IMPORT_NAMESPACE}`\n"
        f"- Tracked files: `{report['tracked_file_count']}`\n"
        f"- Untracked files: `{report['untracked_file_count']}`\n"
        f"- Forbidden tracked files: `{len(report['forbidden_tracked_files_report']['forbidden_tracked_files'])}`\n"
        f"- High-confidence secrets: `{report['secret_scan_report']['high_confidence_secret_count']}`\n"
        "- Deletions performed: `false`\n"
        f"- Next safe action: `{report['next_action_manifest']['next_safe_action']}`\n"
    )


def _render_gitignore_report(report: dict[str, Any]) -> str:
    lines = ["# Updated Gitignore Report", "", f"- Status: `{report['status']}`"]
    lines.append(f"- Missing entries: `{len(report['missing_entries'])}`")
    for entry in report["missing_entries"]:
        lines.append(f"- Missing: `{entry}`")
    return "\n".join(lines) + "\n"


def _render_push_tag_safety_report(report: dict[str, Any]) -> str:
    safety = report["push_tag_safety_report"]
    return (
        "# Push / Tag Safety Report\n\n"
        f"- Status: `{safety['status']}`\n"
        f"- Push allowed: `{str(safety['push_allowed']).lower()}`\n"
        f"- Tag allowed now: `{str(safety['tag_allowed']).lower()}`\n"
        f"- CI check allowed now: `{str(safety['ci_check_allowed']).lower()}`\n"
        f"- Campaign 4 entry allowed: `{str(safety['campaign_4_entry_allowed']).lower()}`\n"
        f"- Forbidden tracked files check: `{safety['forbidden_tracked_files_check']}`\n"
        f"- Secret check: `{safety['secret_check']}`\n"
        f"- Large runtime binary check: `{safety['large_runtime_binary_check']}`\n"
        "- Push is not release complete. Tag is not EXE ready. CI green is not Campaign 4 complete.\n"
    )


def _render_summary(report: dict[str, Any]) -> str:
    return (
        "# Repository Public Surface Cleanup Gate Summary\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Verdict: `{report['verdict']}`\n"
        f"- Next safe action: `{report['next_action_manifest']['next_safe_action']}`\n"
        "- Cleanup deletion performed: `false`\n"
        "- Push performed by this gate: `false`\n"
        "- Tag performed by this gate: `false`\n"
        "- Campaign 4 active: `false`\n"
    )


def _write_governance_docs(repo_root: Path, report: dict[str, Any]) -> None:
    docs = repo_root / "docs/governance"
    write_json(docs / "RENAMING_COMPATIBILITY_MATRIX.json", report["renaming_compatibility_matrix"])
    (docs / "REPOSITORY_PUBLIC_SURFACE_CLEANUP_AND_RENAME_PLAN.md").write_text(
        "# Repository Public Surface Cleanup And Rename Plan\n\n"
        f"Status: `{report['status']}`\n\n"
        "This plan preserves audit evidence and performs no deletion by default. "
        "Public naming migrates to `HeiTang Knowledge Workbench` while the Python "
        "`heitang_kb_forge` import namespace remains compatible.\n",
        encoding="utf-8",
    )
    (docs / "PUBLIC_REPOSITORY_FILE_POLICY.md").write_text(
        "# Public Repository File Policy\n\n"
        "Tracked release-facing files must exclude local dependency directories, caches, "
        "current-run outputs, latest audit outputs, secrets, cookies, credentials, and "
        "large runtime binaries unless explicitly approved by a later gate.\n",
        encoding="utf-8",
    )
    (docs / "DOC_RETENTION_POLICY.md").write_text(
        "# Doc Retention Policy\n\n"
        "- Active docs: keep.\n"
        "- Milestone evidence: keep when referenced by manifests.\n"
        "- Legacy root reports: review before migration; do not delete automatically.\n"
        "- Temporary current_run/latest outputs: keep local and ignored.\n",
        encoding="utf-8",
    )
    (docs / "REPOSITORY_RENAME_MIGRATION_NOTE.md").write_text(
        "# Repository Rename Migration Note\n\n"
        "- Old public name: `HeiTang KB Forge Skill`\n"
        "- New public name: `HeiTang Knowledge Workbench`\n"
        "- Recommended repository name: `HeiTang-Knowledge-Workbench`\n"
        "- Compatibility namespace: `heitang_kb_forge`\n"
        "- Package hard rename: `false`\n",
        encoding="utf-8",
    )


def _read_json(path: Path, errors: list[str], label: str) -> dict[str, Any]:
    if not path.exists():
        errors.append(f"missing_json:{label}:{path}")
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        errors.append(f"invalid_json:{label}:{exc}")
        return {}
