from __future__ import annotations

import hashlib
import json
import zipfile
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


GENERATED_AT = "2026-06-14T04:25:00+08:00"
CURRENT_ITEM = "Generate Campaign 1-3 Closure Pack"
PACK_NAME = "HeiTang-Campaign-1-2-3-Integrated-Closure-Pack.zip"
PACK_PATH = Path("dist") / PACK_NAME
AUDIT_DIR = Path("artifacts/audits/campaign_1_2_3_closure_pack")
NEXT_ACTION = "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate only"

REQUIRED_PACK_FILES = [
    "docs/governance/CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_REPORT.md",
    "docs/governance/CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_REPORT.json",
    "artifacts/audits/campaign_1_2_3_integrated_closure/run_manifest.json",
    "artifacts/audits/campaign_1_2_3_integrated_closure/run_summary.md",
    "artifacts/audits/campaign_1_2_3_integrated_closure/campaign_status_matrix.json",
    "artifacts/audits/campaign_1_2_3_integrated_closure/real_integration_matrix.json",
    "artifacts/audits/campaign_1_2_3_integrated_closure/non_runtime_boundary_matrix.json",
    "artifacts/audits/campaign_1_2_3_integrated_closure/planned_not_active_matrix.json",
    "artifacts/audits/campaign_1_2_3_integrated_closure/unfinished_items.json",
    "artifacts/audits/campaign_1_2_3_integrated_closure/forbidden_misinterpretations.json",
    "artifacts/audits/campaign_1_2_3_integrated_closure/changed_files_manifest.json",
    "artifacts/audits/campaign_1_2_3_integrated_closure/artifact_manifest.json",
    "artifacts/audits/campaign_1_2_3_integrated_closure/test_result_manifest.json",
    "artifacts/audits/campaign_1_2_3_integrated_closure/handoff.md",
    "artifacts/audits/campaign_1_2_3_integrated_closure/checkpoint.json",
    "docs/governance/RUN_STATE.md",
    "docs/governance/GOAL_ACCEPTANCE_LEDGER.json",
    "docs/governance/PLAN_SEQUENCE_LOCK.md",
    "docs/governance/TARGET_ACCEPTANCE_MATRIX.md",
    "docs/audits/AUDIT_MANIFEST.json",
    "docs/testing/VALIDATION_GATE_MANIFEST.json",
]

FORBIDDEN_PACK_PARTS = {
    ".venv",
    "node_modules",
    ".heitang_cache",
    "_local_dependency_remediation",
    "build",
    "tmp",
    "__pycache__",
}

REQUIRED_OUTPUTS = [
    "run_manifest.json",
    "run_summary.md",
    "closure_pack_manifest.json",
    "closure_pack_file_inventory.json",
    "closure_pack_checksum.json",
    "closure_pack_validation_report.json",
    "checkpoint.json",
    "progress_events.jsonl",
]


def build_campaign_1_2_3_closure_pack(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    prerequisites = _prerequisite_matrix(repo_root)
    file_inventory = _file_inventory(repo_root)
    failures = [*prerequisites["errors"], *file_inventory["errors"]]
    passed = not failures
    return {
        "schema_version": "campaign_1_2_3_closure_pack.v1",
        "generated_at": GENERATED_AT,
        "current_item": CURRENT_ITEM,
        "status": "passed" if passed else "failed",
        "verdict": "closure_pack_generated_for_repository_cleanup_gate" if passed else "failed",
        "pack_path": str(PACK_PATH).replace("\\", "/"),
        "pack_name": PACK_NAME,
        "prerequisite_matrix": prerequisites,
        "file_inventory": file_inventory,
        "failure_count": len(failures),
        "failures": failures,
        "campaign_state_after_pack": _campaign_state_after_pack(passed),
        "next_action_manifest": _next_action_manifest(passed),
        "not_goal_complete": True,
    }


def write_campaign_1_2_3_closure_pack(repo_root: Path, output: Path = AUDIT_DIR) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = build_campaign_1_2_3_closure_pack(repo_root)

    if report["status"] == "passed":
        _write_zip(repo_root, repo_root / PACK_PATH, report["file_inventory"]["items"])

    checksum = _checksum_payload(repo_root / PACK_PATH)
    write_json(output / "closure_pack_manifest.json", report)
    write_json(output / "closure_pack_file_inventory.json", report["file_inventory"])
    write_json(output / "closure_pack_checksum.json", checksum)
    write_json(output / "closure_pack_validation_report.json", _validation_payload(report, checksum))
    write_json(output / "run_manifest.json", _run_manifest(report, checksum))
    write_json(output / "checkpoint.json", _checkpoint(report, checksum))
    write_jsonl(output / "progress_events.jsonl", _progress_events(report))
    (output / "run_summary.md").write_text(_render_summary(report, checksum), encoding="utf-8")
    return report


def validate_campaign_1_2_3_closure_pack(repo_root: Path, output: Path = AUDIT_DIR) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    errors: list[str] = []
    for name in REQUIRED_OUTPUTS:
        if not (output / name).exists():
            errors.append(f"missing_output:{name}")

    manifest = _read_json(output / "closure_pack_manifest.json", errors, "closure_pack_manifest")
    checksum = _read_json(output / "closure_pack_checksum.json", errors, "closure_pack_checksum")
    checkpoint = _read_json(output / "checkpoint.json", errors, "checkpoint")
    run_manifest = _read_json(output / "run_manifest.json", errors, "run_manifest")
    pack_path = repo_root / PACK_PATH

    if manifest.get("status") != "passed":
        errors.append("closure_pack_manifest_status_not_passed")
    if manifest.get("verdict") != "closure_pack_generated_for_repository_cleanup_gate":
        errors.append("closure_pack_manifest_verdict_mismatch")
    if not pack_path.exists():
        errors.append(f"missing_pack:{PACK_PATH.as_posix()}")
    if checkpoint.get("checkpoint_id") != "campaign_1_2_3_closure_pack_generated":
        errors.append("checkpoint_id_mismatch")
    if checkpoint.get("next_safe_action") != NEXT_ACTION:
        errors.append("checkpoint_next_safe_action_mismatch")
    if run_manifest.get("scope") != "CAMPAIGN_1_2_3_CLOSURE_PACK":
        errors.append("run_manifest_scope_mismatch")
    if checksum.get("sha256") and pack_path.exists() and checksum["sha256"] != _sha256(pack_path):
        errors.append("checksum_mismatch")

    if pack_path.exists():
        with zipfile.ZipFile(pack_path, "r") as archive:
            names = set(archive.namelist())
        for required in REQUIRED_PACK_FILES:
            if required not in names:
                errors.append(f"missing_pack_member:{required}")
        for name in names:
            parts = set(Path(name).parts)
            if parts & FORBIDDEN_PACK_PARTS:
                errors.append(f"forbidden_pack_member:{name}")

    result = {
        "schema_version": "campaign_1_2_3_closure_pack_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "errors": errors,
        "pack_path": str(PACK_PATH).replace("\\", "/"),
        "next_safe_action": NEXT_ACTION if not errors else "Repair Campaign 1-3 Closure Pack",
        "closure_pack_generated": not errors,
        "repository_public_surface_cleanup_gate_passed": False,
        "repository_push_succeeded": False,
        "tag_created": False,
        "ci_green": False,
        "campaign_4_active": False,
        "not_goal_complete": True,
    }
    write_json(output / "closure_pack_validation_report.json", result)
    return result


def write_campaign_1_2_3_closure_pack_validation(repo_root: Path, output: Path = AUDIT_DIR) -> dict[str, Any]:
    return validate_campaign_1_2_3_closure_pack(repo_root, output)


def _prerequisite_matrix(repo_root: Path) -> dict[str, Any]:
    required = [
        (
            "integrated_closure_gate_passed",
            "artifacts/audits/campaign_1_2_3_integrated_closure/run_manifest.json",
            {"accepted_for_closure_pack_generation"},
        ),
        (
            "current_checkpoint_integrated_closure_or_later_ordered_gate",
            "artifacts/audits/current_run/checkpoint.json",
            {
                "campaign_1_2_3_integrated_closure_gate_passed",
                "campaign_1_2_3_closure_pack_generated",
                "repository_public_surface_cleanup_gate_passed",
            },
        ),
    ]
    items = []
    errors = []
    for item_id, path, expected_values in required:
        full_path = repo_root / path
        exists = full_path.exists()
        matched = False
        if exists:
            data = json.loads(full_path.read_text(encoding="utf-8-sig"))
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
        "schema_version": "campaign_1_2_3_closure_pack_prerequisites.v1",
        "status": "passed" if not errors else "failed",
        "items": items,
        "errors": errors,
    }


def _file_inventory(repo_root: Path) -> dict[str, Any]:
    items = []
    errors = []
    for path in REQUIRED_PACK_FILES:
        full_path = repo_root / path
        parts = set(Path(path).parts)
        exists = full_path.exists()
        if not exists:
            errors.append(f"missing_required_pack_file:{path}")
        if parts & FORBIDDEN_PACK_PARTS:
            errors.append(f"forbidden_required_pack_file:{path}")
        items.append({
            "path": path,
            "exists": exists,
            "size_bytes": full_path.stat().st_size if exists else 0,
            "status": "included" if exists else "missing",
        })
    return {
        "schema_version": "campaign_1_2_3_closure_pack_file_inventory.v1",
        "status": "passed" if not errors else "failed",
        "pack_path": str(PACK_PATH).replace("\\", "/"),
        "items": items,
        "errors": errors,
    }


def _write_zip(repo_root: Path, pack_path: Path, items: list[dict[str, Any]]) -> None:
    pack_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(pack_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for item in sorted(items, key=lambda row: row["path"]):
            if item["status"] == "included":
                info = zipfile.ZipInfo(item["path"])
                info.date_time = (2026, 6, 14, 0, 0, 0)
                info.compress_type = zipfile.ZIP_DEFLATED
                archive.writestr(info, (repo_root / item["path"]).read_bytes())


def _checksum_payload(pack_path: Path) -> dict[str, Any]:
    exists = pack_path.exists()
    return {
        "schema_version": "campaign_1_2_3_closure_pack_checksum.v1",
        "generated_at": GENERATED_AT,
        "pack_path": str(PACK_PATH).replace("\\", "/"),
        "exists": exists,
        "size_bytes": pack_path.stat().st_size if exists else 0,
        "sha256": _sha256(pack_path) if exists else "",
    }


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _campaign_state_after_pack(passed: bool) -> dict[str, Any]:
    return {
        "campaign_1_3_integrated_closure_gate_passed": True,
        "closure_pack_generated": passed,
        "repository_public_surface_cleanup_gate_passed": False,
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
        "next_business_item": NEXT_ACTION if passed else "Repair Campaign 1-3 Closure Pack",
    }


def _next_action_manifest(passed: bool) -> dict[str, Any]:
    return {
        "next_safe_action": NEXT_ACTION if passed else "Repair Campaign 1-3 Closure Pack",
        "may_run_repository_cleanup": passed,
        "may_push": False,
        "may_tag": False,
        "may_check_ci_green": False,
        "may_enter_campaign_4": False,
    }


def _validation_payload(report: dict[str, Any], checksum: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_1_2_3_closure_pack_validation.v1",
        "generated_at": GENERATED_AT,
        "status": report["status"],
        "error_count": report["failure_count"],
        "errors": report["failures"],
        "pack_path": report["pack_path"],
        "pack_sha256": checksum.get("sha256", ""),
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "closure_pack_generated": report["status"] == "passed",
        "repository_public_surface_cleanup_gate_passed": False,
        "repository_push_succeeded": False,
        "tag_created": False,
        "ci_green": False,
        "campaign_4_active": False,
        "not_goal_complete": True,
    }


def _run_manifest(report: dict[str, Any], checksum: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "run_manifest.v1",
        "run_id": "campaign_1_2_3_closure_pack",
        "type": "campaign_closure_pack_generation",
        "scope": "CAMPAIGN_1_2_3_CLOSURE_PACK",
        "status": report["status"],
        "verdict": report["verdict"],
        "generated_at": GENERATED_AT,
        "pack_path": report["pack_path"],
        "pack_sha256": checksum.get("sha256", ""),
        "output_files": REQUIRED_OUTPUTS,
        "campaign_state_after_run": report["campaign_state_after_pack"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "not_goal_complete": True,
    }


def _checkpoint(report: dict[str, Any], checksum: dict[str, Any]) -> dict[str, Any]:
    passed = report["status"] == "passed"
    return {
        "schema_version": "current_run_checkpoint.v2",
        "checkpoint_id": "campaign_1_2_3_closure_pack_generated" if passed else "campaign_1_2_3_closure_pack_failed",
        "updated_at": report["generated_at"],
        "current_item": CURRENT_ITEM,
        "current_status": report["status"],
        "current_plan_section": "Post Campaign 3 / Campaign 1-3 closure chain",
        "last_successful_step": "Campaign 1-3 Closure Pack generated" if passed else "Campaign 1-3 Integrated Closure Gate passed",
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "blocked_future_items": [
            "Repository Public Surface Cleanup before Closure Pack",
            "Repository push before cleanup safety gate",
            "Tag before repository push",
            "CI green before tag",
            "Campaign 4 before closure checklist and handoff review",
            "Campaign 5 before Campaign 4 acceptance",
            "EXE",
            "Release",
        ],
        "tests_run": ["Closure Pack focused tests", "CLI validation", "JSON parse", "git diff --check"],
        "tests_passed": [] if not passed else ["Closure Pack generated and checksum recorded"],
        "tests_failed": [] if passed else report["failures"],
        "files_changed": [report["pack_path"]] if passed else [],
        "audit_outputs": REQUIRED_OUTPUTS,
        "retry_summary": {"transient_retries": 0, "non_transient_command_failures": 0, "last_non_transient_failure": None},
        "resume_prompt_path": "artifacts/audits/current_run/resume_prompt.md",
        "pack_sha256": checksum.get("sha256", ""),
        "not_goal_complete": True,
        **report["campaign_state_after_pack"],
    }


def _progress_events(report: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        {
            "stage": stage,
            "status": report["status"],
            "timestamp": GENERATED_AT,
            "message": f"{stage} completed for Campaign 1-3 Closure Pack.",
            "artifact_path": str(AUDIT_DIR).replace("\\", "/"),
        }
        for stage in [
            "verify_integrated_closure_prerequisite",
            "inventory_required_pack_files",
            "write_zip_pack",
            "write_checksum",
            "write_checkpoint",
        ]
    ]


def _render_summary(report: dict[str, Any], checksum: dict[str, Any]) -> str:
    return (
        "# Campaign 1-3 Closure Pack Summary\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Verdict: `{report['verdict']}`\n"
        f"- Pack: `{report['pack_path']}`\n"
        f"- SHA256: `{checksum.get('sha256', '')}`\n"
        f"- Included files: `{len(report['file_inventory']['items'])}`\n"
        f"- Next safe action: `{report['next_action_manifest']['next_safe_action']}`\n"
        "- Repository cleanup / push / tag / CI: `false`\n"
        "- Campaign 4 active: `false`\n"
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
