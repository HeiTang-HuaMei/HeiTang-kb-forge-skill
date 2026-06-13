import json
import zipfile
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_campaign_1_2_3_closure_pack,
    validate_campaign_1_2_3_closure_pack,
    write_campaign_1_2_3_closure_pack,
)
from heitang_kb_forge.campaign_3_closure.closure_pack import REQUIRED_PACK_FILES
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "campaign_1_2_3_closure_pack"
PACK_PATH = ROOT / "dist" / "HeiTang-Campaign-1-2-3-Integrated-Closure-Pack.zip"
NEXT_ACTION = "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate only"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_closure_pack_requires_integrated_closure_and_inventories_required_files():
    report = build_campaign_1_2_3_closure_pack(ROOT)

    assert report["status"] == "passed"
    assert report["verdict"] == "closure_pack_generated_for_repository_cleanup_gate"
    assert report["prerequisite_matrix"]["status"] == "passed"
    assert report["file_inventory"]["status"] == "passed"
    assert {item["path"] for item in report["file_inventory"]["items"]} == set(REQUIRED_PACK_FILES)


def test_closure_pack_allows_only_repository_cleanup_next(tmp_path):
    output = tmp_path / "closure-pack"
    report = write_campaign_1_2_3_closure_pack(ROOT, output)
    state = report["campaign_state_after_pack"]
    next_action = report["next_action_manifest"]

    assert state["campaign_1_3_integrated_closure_gate_passed"] is True
    assert state["closure_pack_generated"] is True
    assert state["repository_public_surface_cleanup_gate_passed"] is False
    assert state["repository_push_succeeded"] is False
    assert state["tag_created"] is False
    assert state["ci_green"] is False
    assert state["closure_checklist_green"] is False
    assert state["campaign_4_active"] is False
    assert next_action["next_safe_action"] == NEXT_ACTION
    assert next_action["may_run_repository_cleanup"] is True
    assert next_action["may_push"] is False
    assert next_action["may_tag"] is False
    assert next_action["may_check_ci_green"] is False
    assert next_action["may_enter_campaign_4"] is False


def test_closure_pack_zip_contains_only_required_closure_files(tmp_path):
    output = tmp_path / "closure-pack"
    write_campaign_1_2_3_closure_pack(ROOT, output)

    assert PACK_PATH.exists()
    with zipfile.ZipFile(PACK_PATH, "r") as archive:
        names = set(archive.namelist())

    assert set(REQUIRED_PACK_FILES) <= names
    assert "node_modules" not in "/".join(names)
    assert ".venv" not in "/".join(names)
    assert ".heitang_cache" not in "/".join(names)
    assert "_local_dependency_remediation" not in "/".join(names)
    assert not any(name.startswith("build/") for name in names)


def test_closure_pack_writes_required_audit_outputs(tmp_path):
    output = tmp_path / "closure-pack"
    report = write_campaign_1_2_3_closure_pack(ROOT, output)

    assert report["status"] == "passed"
    for name in [
        "run_manifest.json",
        "run_summary.md",
        "closure_pack_manifest.json",
        "closure_pack_file_inventory.json",
        "closure_pack_checksum.json",
        "closure_pack_validation_report.json",
        "checkpoint.json",
        "progress_events.jsonl",
    ]:
        assert (output / name).exists()

    assert _json(output / "run_manifest.json")["scope"] == "CAMPAIGN_1_2_3_CLOSURE_PACK"
    assert _json(output / "checkpoint.json")["checkpoint_id"] == "campaign_1_2_3_closure_pack_generated"
    assert _json(output / "checkpoint.json")["next_safe_action"] == NEXT_ACTION
    assert _json(output / "closure_pack_checksum.json")["sha256"]


def test_closure_pack_fails_closed_when_pack_is_missing(tmp_path):
    output = tmp_path / "closure-pack"
    write_campaign_1_2_3_closure_pack(ROOT, output)
    if PACK_PATH.exists():
        PACK_PATH.unlink()

    validation = validate_campaign_1_2_3_closure_pack(ROOT, output)

    assert validation["status"] == "failed"
    assert f"missing_pack:{PACK_PATH.relative_to(ROOT).as_posix()}" in validation["errors"]


def test_closure_pack_cli_build_and_validate_are_runnable(tmp_path):
    output = tmp_path / "closure-pack"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "generate-campaign-1-2-3-closure-pack",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-campaign-1-2-3-closure-pack",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "status=passed" in build.output
    assert "closure_pack_generated_for_repository_cleanup_gate" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    assert _json(output / "closure_pack_validation_report.json")["status"] == "passed"


def test_active_closure_pack_audit_outputs_validate_when_present():
    run_manifest = AUDIT_DIR / "run_manifest.json"
    if not run_manifest.exists():
        return
    if _json(run_manifest).get("scope") != "CAMPAIGN_1_2_3_CLOSURE_PACK":
        return

    validation = validate_campaign_1_2_3_closure_pack(ROOT, AUDIT_DIR)

    assert validation["status"] == "passed"
    assert validation["next_safe_action"] == NEXT_ACTION
    assert validation["closure_pack_generated"] is True
    assert validation["repository_public_surface_cleanup_gate_passed"] is False
    assert validation["campaign_4_active"] is False
