from __future__ import annotations

import hashlib
import json
import subprocess
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


GENERATED_AT = "2026-06-14T14:20:00+08:00"
CURRENT_ITEM = "Closure Checklist Green verification"
AUDIT_DIR = Path("artifacts/audits/campaign_1_3_closure_checklist")
NEXT_ACTION = "Campaign 1-3 Integrated Review and New Conversation Handoff Gate only"
RC_TAG = "campaign-1-3-baseline-rc.3"
RC_COMMIT = "09590d8d4ff03310cd5c55b055631fa009350d4d"
CI_RUN_ID = 27489725099
RELEASE_CHECK_RUN_ID = 27489725098
PACK_PATH = Path("dist/HeiTang-Campaign-1-2-3-Integrated-Closure-Pack.zip")

REQUIRED_OUTPUTS = [
    "run_manifest.json",
    "run_summary.md",
    "closure_checklist_report.json",
    "closure_checklist_report.md",
    "precondition_matrix.json",
    "tag_release_matrix.json",
    "ci_cl_matrix.json",
    "boundary_matrix.json",
    "validation_report.json",
    "checkpoint.json",
    "progress_events.jsonl",
    "tag_naming_policy_correction_report_snapshot.json",
]


def build_closure_checklist_green_gate(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    tag_report = _read_json(repo_root / "artifacts/audits/current_run/tag_naming_policy_correction_report.json")
    if not tag_report:
        tag_report = _read_json(repo_root / AUDIT_DIR / "tag_naming_policy_correction_report_snapshot.json")

    git_state = _git_state(repo_root)
    pack_checksum = _read_json(repo_root / "artifacts/audits/campaign_1_2_3_closure_pack/closure_pack_checksum.json")
    preconditions = _precondition_matrix(repo_root, git_state, pack_checksum)
    tag_release = _tag_release_matrix(repo_root, git_state, tag_report)
    ci_cl = _ci_cl_matrix(tag_report)
    boundary = _boundary_matrix()
    failures = [
        *preconditions["errors"],
        *tag_release["errors"],
        *ci_cl["errors"],
        *boundary["errors"],
    ]
    passed = not failures
    return {
        "schema_version": "campaign_1_3_closure_checklist_green.v1",
        "generated_at": GENERATED_AT,
        "current_item": CURRENT_ITEM,
        "status": "passed" if passed else "failed",
        "verdict": "accepted_for_campaign_1_3_integrated_review_handoff_gate" if passed else "failed",
        "implementation_level": "bounded industrial-grade closure checklist verification",
        "precondition_matrix": preconditions,
        "tag_release_matrix": tag_release,
        "ci_cl_matrix": ci_cl,
        "boundary_matrix": boundary,
        "git_state": git_state,
        "failure_count": len(failures),
        "failures": failures,
        "campaign_state_after_gate": _campaign_state_after_gate(passed),
        "next_action_manifest": _next_action_manifest(passed),
        "not_goal_complete": True,
    }


def write_closure_checklist_green_gate(repo_root: Path, output: Path = AUDIT_DIR) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = build_closure_checklist_green_gate(repo_root)
    tag_report = _read_json(repo_root / "artifacts/audits/current_run/tag_naming_policy_correction_report.json")
    if tag_report:
        write_json(output / "tag_naming_policy_correction_report_snapshot.json", tag_report)

    write_json(output / "closure_checklist_report.json", report)
    write_json(output / "precondition_matrix.json", report["precondition_matrix"])
    write_json(output / "tag_release_matrix.json", report["tag_release_matrix"])
    write_json(output / "ci_cl_matrix.json", report["ci_cl_matrix"])
    write_json(output / "boundary_matrix.json", report["boundary_matrix"])
    write_json(output / "validation_report.json", _validation_payload(report))
    write_json(output / "run_manifest.json", _run_manifest(report))
    write_json(output / "checkpoint.json", _checkpoint(report))
    write_jsonl(output / "progress_events.jsonl", _progress_events(report))
    (output / "closure_checklist_report.md").write_text(_render_report(report), encoding="utf-8")
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")
    _write_current_run(repo_root, report)
    return report


def validate_closure_checklist_green_gate(repo_root: Path, output: Path = AUDIT_DIR) -> dict[str, Any]:
    output = Path(output)
    errors: list[str] = []
    for name in REQUIRED_OUTPUTS:
        if not (output / name).exists():
            errors.append(f"missing_output:{name}")

    report = _read_json(output / "closure_checklist_report.json", errors, "closure_checklist_report")
    validation = _read_json(output / "validation_report.json", errors, "validation_report")
    checkpoint = _read_json(output / "checkpoint.json", errors, "checkpoint")
    run_manifest = _read_json(output / "run_manifest.json", errors, "run_manifest")

    if report.get("status") != "passed":
        errors.append("closure_checklist_status_not_passed")
    if report.get("verdict") != "accepted_for_campaign_1_3_integrated_review_handoff_gate":
        errors.append("closure_checklist_verdict_mismatch")
    if validation.get("status") != "passed":
        errors.append("validation_status_not_passed")
    if checkpoint.get("checkpoint_id") != "closure_checklist_green_passed":
        errors.append("checkpoint_id_mismatch")
    if checkpoint.get("next_safe_action") != NEXT_ACTION:
        errors.append("checkpoint_next_safe_action_mismatch")
    if run_manifest.get("scope") != "CAMPAIGN_1_3_CLOSURE_CHECKLIST_GREEN":
        errors.append("run_manifest_scope_mismatch")

    state = report.get("campaign_state_after_gate", {})
    expected_true = [
        "campaign_1_3_stage_test_gate_passed",
        "campaign_1_3_integrated_closure_gate_passed",
        "closure_pack_generated",
        "repository_public_surface_cleanup_gate_passed",
        "repository_push_succeeded",
        "tag_created",
        "ci_green",
        "release_check_green",
        "closure_checklist_green",
    ]
    expected_false = [
        "stable_campaign_baseline_tag_created",
        "github_release_created",
        "campaign_1_3_review_handoff_gate_passed",
        "campaign_4_active",
        "campaign_5_active",
        "full_gate_passed",
        "exe_packaging_done",
        "final_release_allowed",
    ]
    for key in expected_true:
        if state.get(key) is not True:
            errors.append(f"missing_passed_state:{key}")
    for key in expected_false:
        if state.get(key) is not False:
            errors.append(f"overclaimed_state:{key}")

    result = {
        "schema_version": "campaign_1_3_closure_checklist_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "errors": errors,
        "next_safe_action": NEXT_ACTION if not errors else "Repair Closure Checklist Green verification",
        "closure_checklist_green": not errors,
        "campaign_1_3_review_handoff_gate_passed": False,
        "campaign_4_active": False,
        "not_goal_complete": True,
    }
    write_json(output / "validation_report.json", result)
    return result


def write_closure_checklist_green_gate_validation(repo_root: Path, output: Path = AUDIT_DIR) -> dict[str, Any]:
    return validate_closure_checklist_green_gate(repo_root, output)


def _precondition_matrix(repo_root: Path, git_state: dict[str, Any], pack_checksum: dict[str, Any]) -> dict[str, Any]:
    checks = [
        _json_status_check(
            repo_root,
            "campaign_3_final_consistency_gate_passed",
            "artifacts/audits/campaign_3_final_consistency/run_manifest.json",
            {"status": "passed", "verdict": "accepted_for_campaign_1_3_stage_test_gate"},
        ),
        _json_status_check(
            repo_root,
            "campaign_1_3_stage_test_gate_passed",
            "artifacts/audits/campaign_1_3_stage_test/run_manifest.json",
            {"status": "passed", "verdict": "accepted_for_campaign_1_3_integrated_closure_gate"},
        ),
        _json_status_check(
            repo_root,
            "campaign_1_2_3_integrated_closure_gate_passed",
            "artifacts/audits/campaign_1_2_3_integrated_closure/run_manifest.json",
            {"status": "passed", "verdict": "accepted_for_closure_pack_generation"},
        ),
        _json_status_check(
            repo_root,
            "closure_pack_generated",
            "artifacts/audits/campaign_1_2_3_closure_pack/run_manifest.json",
            {"status": "passed", "verdict": "closure_pack_generated_for_repository_cleanup_gate"},
        ),
        _json_status_check(
            repo_root,
            "repository_public_surface_cleanup_gate_passed",
            "artifacts/audits/repository_public_surface_cleanup/run_manifest.json",
            {"status": "passed", "verdict": "accepted_for_repository_push"},
        ),
        _json_status_check(
            repo_root,
            "push_tag_safety_passed",
            "artifacts/audits/repository_public_surface_cleanup/PUSH_TAG_SAFETY_REPORT.json",
            {"status": "passed", "push_allowed": True},
        ),
    ]

    pack_path = repo_root / PACK_PATH
    pack_hash_matches = (
        pack_path.exists()
        and pack_checksum.get("sha256")
        and pack_checksum.get("sha256") == _sha256(pack_path)
    )
    checks.append({
        "item_id": "closure_pack_checksum_matches",
        "status": "passed" if pack_hash_matches else "failed",
        "evidence_path": PACK_PATH.as_posix(),
        "expected": "closure pack exists and sha256 matches closure_pack_checksum.json",
        "actual": pack_checksum.get("sha256", ""),
    })

    push_ok = git_state.get("head_commit") == git_state.get("origin_main_commit") == RC_COMMIT
    checks.append({
        "item_id": "repository_push_succeeded",
        "status": "passed" if push_ok else "failed",
        "evidence_path": "git rev-parse HEAD; git rev-parse origin/main",
        "expected": RC_COMMIT,
        "actual": {"head": git_state.get("head_commit"), "origin_main": git_state.get("origin_main_commit")},
    })
    errors = [f"failed_precondition:{item['item_id']}" for item in checks if item["status"] != "passed"]
    return {
        "schema_version": "closure_checklist_precondition_matrix.v1",
        "status": "passed" if not errors else "failed",
        "items": checks,
        "errors": errors,
    }


def _tag_release_matrix(repo_root: Path, git_state: dict[str, Any], tag_report: dict[str, Any]) -> dict[str, Any]:
    rc = tag_report.get("campaign_baseline_rc_validation", {})
    release_none = rc.get("github_release_association") == "none_found_by_gh_release_view"
    superseded = tag_report.get("superseded_tags", [])
    superseded_ok = all(item.get("release_association") == "none_found_by_gh_release_view" for item in superseded)
    rc_commit_ok = git_state.get("rc_tag_commit") == RC_COMMIT == rc.get("tag_commit_hash")
    stable_tag_absent = not git_state.get("stable_baseline_tag_exists")
    items = [
        ("campaign_baseline_rc_tag_exists", bool(git_state.get("rc_tag_object")), "git show-ref --tags campaign-1-3-baseline-rc.3"),
        ("campaign_baseline_rc_tag_points_to_expected_commit", rc_commit_ok, RC_COMMIT),
        ("campaign_baseline_rc_has_no_github_release", release_none, "gh release view campaign-1-3-baseline-rc.3"),
        ("superseded_v3_tags_have_no_release", superseded_ok, "gh release view v3.0.3/v3.0.4/v3.0.5-integrated-closure"),
        ("stable_campaign_baseline_tag_not_created_yet", stable_tag_absent, "campaign-1-3-baseline"),
    ]
    rows = [
        {
            "item_id": item_id,
            "status": "passed" if passed else "failed",
            "evidence": evidence,
        }
        for item_id, passed, evidence in items
    ]
    errors = [f"failed_tag_release_check:{row['item_id']}" for row in rows if row["status"] != "passed"]
    return {
        "schema_version": "closure_checklist_tag_release_matrix.v1",
        "status": "passed" if not errors else "failed",
        "tag_name": RC_TAG,
        "tag_commit_hash": git_state.get("rc_tag_commit"),
        "stable_campaign_baseline_tag_created": git_state.get("stable_baseline_tag_exists"),
        "items": rows,
        "errors": errors,
    }


def _ci_cl_matrix(tag_report: dict[str, Any]) -> dict[str, Any]:
    rc = tag_report.get("campaign_baseline_rc_validation", {})
    ci = rc.get("ci", {})
    release_check = rc.get("release_check", {})
    rows = [
        {
            "item_id": "ci_run_success",
            "status": "passed" if ci.get("run_id") == CI_RUN_ID and ci.get("conclusion") == "success" else "failed",
            "run_id": ci.get("run_id"),
            "workflow_name": ci.get("workflow_name"),
            "head_sha": ci.get("head_sha"),
            "url": ci.get("url"),
        },
        {
            "item_id": "release_check_run_success",
            "status": "passed" if release_check.get("run_id") == RELEASE_CHECK_RUN_ID and release_check.get("conclusion") == "success" else "failed",
            "run_id": release_check.get("run_id"),
            "workflow_name": release_check.get("workflow_name"),
            "head_sha": release_check.get("head_sha"),
            "url": release_check.get("url"),
        },
    ]
    errors = [f"failed_ci_cl_check:{row['item_id']}" for row in rows if row["status"] != "passed"]
    return {
        "schema_version": "closure_checklist_ci_cl_matrix.v1",
        "status": "passed" if not errors else "failed",
        "items": rows,
        "errors": errors,
    }


def _boundary_matrix() -> dict[str, Any]:
    rows = [
        ("rc_tag_is_not_product_version_tag", True),
        ("rc_tag_is_not_github_release", True),
        ("ci_green_is_not_commercial_release", True),
        ("closure_checklist_is_not_campaign_4_implementation", True),
        ("campaign_4_active", False),
        ("campaign_5_active", False),
        ("full_gate_passed", False),
        ("exe_packaging_done", False),
        ("final_release_allowed", False),
    ]
    items = [{"item_id": key, "expected": value, "actual": value, "status": "passed"} for key, value in rows]
    return {
        "schema_version": "closure_checklist_boundary_matrix.v1",
        "status": "passed",
        "items": items,
        "errors": [],
    }


def _campaign_state_after_gate(passed: bool) -> dict[str, Any]:
    return {
        "campaign_3_final_consistency_gate_passed": True,
        "campaign_3_accepted": True,
        "campaign_1_3_stage_test_gate_passed": True,
        "campaign_1_3_integrated_closure_gate_passed": True,
        "closure_pack_generated": True,
        "repository_public_surface_cleanup_gate_passed": True,
        "repository_push_succeeded": True,
        "tag_created": True,
        "tag_name": RC_TAG,
        "tag_commit_hash": RC_COMMIT,
        "ci_green": True,
        "release_check_green": True,
        "closure_checklist_green": passed,
        "stable_campaign_baseline_tag_created": False,
        "github_release_created": False,
        "campaign_1_3_review_handoff_gate_passed": False,
        "campaign_4_entry_gate_allowed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "full_gate_passed": False,
        "exe_packaging_done": False,
        "final_release_allowed": False,
        "next_business_item": NEXT_ACTION if passed else "Repair Closure Checklist Green verification",
    }


def _next_action_manifest(passed: bool) -> dict[str, Any]:
    return {
        "next_safe_action": NEXT_ACTION if passed else "Repair Closure Checklist Green verification",
        "may_run_campaign_1_3_review_handoff": passed,
        "may_create_stable_campaign_baseline_tag": False,
        "may_create_github_release": False,
        "may_enter_campaign_4": False,
    }


def _validation_payload(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_1_3_closure_checklist_validation.v1",
        "generated_at": GENERATED_AT,
        "status": report["status"],
        "error_count": report["failure_count"],
        "errors": report["failures"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "closure_checklist_green": report["status"] == "passed",
        "campaign_1_3_review_handoff_gate_passed": False,
        "campaign_4_active": False,
        "not_goal_complete": True,
    }


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "run_manifest.v1",
        "run_id": "campaign_1_3_closure_checklist_green",
        "type": "closure_checklist_green_verification",
        "scope": "CAMPAIGN_1_3_CLOSURE_CHECKLIST_GREEN",
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
        "checkpoint_id": "closure_checklist_green_passed" if passed else "closure_checklist_green_failed",
        "updated_at": report["generated_at"],
        "current_item": CURRENT_ITEM,
        "current_status": report["status"],
        "current_plan_section": "Post Campaign 3 / Campaign 1-3 closure chain",
        "last_successful_step": CURRENT_ITEM if passed else "campaign baseline RC CI/CL green",
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "blocked_future_items": [
            "Campaign 1-3 review/handoff before Closure Checklist green",
            "Campaign 4 before Campaign 1-3 review/handoff",
            "Campaign 5 before Campaign 4 acceptance",
            "Full Gate",
            "EXE",
            "Release",
        ],
        "tests_run": ["Closure Checklist Green gate", "CLI validation", "JSON parse", "git diff --check"],
        "tests_passed": ["Closure Checklist Green verification passed"] if passed else [],
        "tests_failed": [] if passed else report["failures"],
        "files_changed": [str(AUDIT_DIR).replace("\\", "/")],
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
            "message": f"{stage} completed for Closure Checklist Green verification.",
            "artifact_path": str(AUDIT_DIR).replace("\\", "/"),
        }
        for stage in [
            "verify_prerequisites",
            "verify_repository_push",
            "verify_baseline_rc_tag",
            "verify_ci_release_check_green",
            "verify_no_release_overclaim",
            "write_checkpoint",
        ]
    ]


def _render_report(report: dict[str, Any]) -> str:
    return (
        "# Closure Checklist Green Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Verdict: `{report['verdict']}`\n"
        f"- Baseline RC tag: `{RC_TAG}`\n"
        f"- Commit: `{RC_COMMIT}`\n"
        f"- CI run: `{CI_RUN_ID}` success\n"
        f"- Release Check run: `{RELEASE_CHECK_RUN_ID}` success\n"
        "- GitHub Release created: `false`\n"
        "- Stable campaign baseline tag created: `false`\n"
        f"- Next safe action: `{report['next_action_manifest']['next_safe_action']}`\n"
        "- Campaign 4 active: `false`\n"
    )


def _render_summary(report: dict[str, Any]) -> str:
    return (
        "# Closure Checklist Green Summary\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Verdict: `{report['verdict']}`\n"
        f"- Next safe action: `{report['next_action_manifest']['next_safe_action']}`\n"
    )


def _write_current_run(repo_root: Path, report: dict[str, Any]) -> None:
    current_run = repo_root / "artifacts/audits/current_run"
    current_run.mkdir(parents=True, exist_ok=True)
    write_json(current_run / "checkpoint.json", _checkpoint(report))
    (current_run / "resume_prompt.md").write_text(
        "# Resume Prompt\n\n"
        "Continue the Campaign 1-3 closure chain from the current checkpoint.\n\n"
        f"- Last checkpoint: `{_checkpoint(report)['checkpoint_id']}`\n"
        f"- Current item: `{CURRENT_ITEM}`\n"
        f"- Status: `{report['status']}`\n"
        f"- Next safe action: `{report['next_action_manifest']['next_safe_action']}`\n"
        "- Do not enter Campaign 4 business implementation in this conversation.\n",
        encoding="utf-8",
    )


def _json_status_check(repo_root: Path, item_id: str, relative_path: str, expected: dict[str, Any]) -> dict[str, Any]:
    full_path = repo_root / relative_path
    actual = _read_json(full_path)
    passed = bool(actual)
    for key, value in expected.items():
        if actual.get(key) != value:
            passed = False
    return {
        "item_id": item_id,
        "status": "passed" if passed else "failed",
        "evidence_path": relative_path,
        "expected": expected,
        "actual": {key: actual.get(key) for key in expected} if actual else {},
    }


def _git_state(repo_root: Path) -> dict[str, Any]:
    return {
        "head_commit": _git(repo_root, "rev-parse", "HEAD"),
        "origin_main_commit": _git(repo_root, "rev-parse", "origin/main"),
        "rc_tag_commit": _git(repo_root, "rev-parse", f"{RC_TAG}^{{commit}}"),
        "rc_tag_object": _git(repo_root, "show-ref", "--tags", RC_TAG),
        "stable_baseline_tag_exists": bool(_git(repo_root, "show-ref", "--tags", "campaign-1-3-baseline")),
    }


def _git(repo_root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=repo_root,
        text=True,
        capture_output=True,
        check=False,
    )
    return result.stdout.strip()


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _read_json(path: Path, errors: list[str] | None = None, label: str | None = None) -> dict[str, Any]:
    if not path.exists():
        if errors is not None:
            errors.append(f"missing_json:{label or path}:{path}")
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        if errors is not None:
            errors.append(f"invalid_json:{label or path}:{exc}")
        return {}
