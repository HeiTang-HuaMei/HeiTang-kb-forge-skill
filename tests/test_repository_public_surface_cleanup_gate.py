import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_repository_public_surface_cleanup_gate,
    validate_repository_public_surface_cleanup_gate,
    write_repository_public_surface_cleanup_gate,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "repository_public_surface_cleanup"
NEXT_ACTION = "Repository push only"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_repository_cleanup_gate_requires_closure_pack_and_preserves_boundaries():
    report = build_repository_public_surface_cleanup_gate(ROOT)
    state = report["campaign_state_after_gate"]

    assert report["status"] == "passed"
    assert report["verdict"] == "accepted_for_repository_push"
    assert report["prerequisite_matrix"]["status"] == "passed"
    assert state["closure_pack_generated"] is True
    assert state["repository_public_surface_cleanup_gate_passed"] is True
    assert state["repository_push_succeeded"] is False
    assert state["tag_created"] is False
    assert state["ci_green"] is False
    assert state["campaign_4_active"] is False
    assert report["next_action_manifest"]["next_safe_action"] == NEXT_ACTION
    assert report["next_action_manifest"]["may_push"] is True
    assert report["next_action_manifest"]["may_tag"] is False


def test_repository_cleanup_gate_generates_inventory_and_safety_reports(tmp_path):
    output = tmp_path / "repo-surface"
    report = write_repository_public_surface_cleanup_gate(ROOT, output)

    assert report["status"] == "passed"
    for name in [
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
        "PUSH_TAG_SAFETY_REPORT.json",
        "validation_report.json",
        "run_manifest.json",
        "checkpoint.json",
        "progress_events.jsonl",
    ]:
        assert (output / name).exists()

    safety = _json(output / "PUSH_TAG_SAFETY_REPORT.json")
    assert safety["push_allowed"] is True
    assert safety["tag_allowed"] is False
    assert safety["ci_check_allowed"] is False


def test_repository_cleanup_gate_renames_public_surface_without_package_rename():
    report = build_repository_public_surface_cleanup_gate(ROOT)
    rename = report["renaming_compatibility_matrix"]

    assert rename["new_public_name"] == "HeiTang Knowledge Workbench"
    assert rename["python_import_namespace"] == "heitang_kb_forge"
    assert rename["python_import_namespace_preserved"] is True
    assert rename["package_distribution_name_changed"] is False
    assert report["gitignore_report"]["status"] == "passed"
    assert report["forbidden_tracked_files_report"]["status"] == "passed"
    assert report["secret_scan_report"]["status"] == "passed"
    assert report["large_file_report"]["status"] == "passed"


def test_repository_cleanup_gate_does_not_delete_push_tag_or_enter_campaign_4(tmp_path):
    output = tmp_path / "repo-surface"
    write_repository_public_surface_cleanup_gate(ROOT, output)
    checkpoint = _json(output / "checkpoint.json")
    deletion = _json(output / "DELETION_CANDIDATE_MANIFEST.json")

    assert deletion["items"] == []
    assert checkpoint["checkpoint_id"] == "repository_public_surface_cleanup_gate_passed"
    assert checkpoint["next_safe_action"] == NEXT_ACTION
    assert checkpoint["repository_push_succeeded"] is False
    assert checkpoint["tag_created"] is False
    assert checkpoint["ci_green"] is False
    assert checkpoint["campaign_4_active"] is False


def test_repository_cleanup_gate_cli_build_and_validate_are_runnable(tmp_path):
    output = tmp_path / "repo-surface"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "repository-public-surface-cleanup-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-repository-public-surface-cleanup-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "status=passed" in build.output
    assert "accepted_for_repository_push" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    assert _json(output / "validation_report.json")["status"] == "passed"


def test_active_repository_cleanup_gate_audit_outputs_validate_when_present():
    run_manifest = AUDIT_DIR / "run_manifest.json"
    if not run_manifest.exists():
        return
    if _json(run_manifest).get("scope") != "REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE":
        return

    validation = validate_repository_public_surface_cleanup_gate(ROOT, AUDIT_DIR)

    assert validation["status"] == "passed"
    assert validation["next_safe_action"] == NEXT_ACTION
    assert validation["repository_public_surface_cleanup_gate_passed"] is True
    assert validation["repository_push_succeeded"] is False
    assert validation["campaign_4_active"] is False
