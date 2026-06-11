import json

import pytest
from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.skill_suite import build_skill_suite, export_skill_pack
from tests.p0_helpers import write_json
from tests.test_skill_suite_build import _candidate_plan_payload


def _read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def test_export_skill_pack_cli_copies_only_allowed_files(tmp_path):
    suite = _make_suite(tmp_path)
    (suite / "secret.txt").write_text("must not leave source suite", encoding="utf-8")
    output = tmp_path / "pack"

    result = CliRunner().invoke(
        app, ["export-skill-pack", "--suite", str(suite), "--out", str(output)]
    )

    assert result.exit_code == 0, result.output
    manifest = _read_json(output / "skill_pack_manifest.json")
    quality = _read_json(output / "description_trigger_quality_report.json")
    boundary = _read_json(output / "allowed_files_boundary_report.json")
    assert manifest["status"] == "packaging_ready"
    assert manifest["manifest_file"] == "skill_pack_manifest.json"
    assert set(manifest["files"]) == set(manifest["file_hashes"])
    assert manifest["description_trigger_quality_status"] == "pass"
    assert manifest["allowed_files_boundary_status"] == "pass"
    assert manifest["suite_validation_status"] == "deferred_to_slice_8"
    assert manifest["installability_check_status"] == "deferred_to_slice_8"
    assert manifest["anthropic_skill_creator_integration"] == {
        "integration_level": "L3_contract_absorbed+partial_L4_packaging_governance_fused",
        "anthropic_platform_binding": False,
        "claude_skills_runtime": False,
        "account_or_upload_required": False,
        "provider_api_required": False,
    }
    assert quality["status"] == "pass"
    assert boundary["status"] == "pass"
    assert "secret.txt" in boundary["excluded_files"]
    assert not (output / "secret.txt").exists()
    assert len(list(output.glob("skills/*/*/SKILL.md"))) == 2
    assert "Installability: deferred_to_slice_8" in result.output


def test_export_skill_pack_blocks_invalid_description_or_trigger(tmp_path):
    suite = _make_suite(tmp_path)
    skill_path = next(suite.glob("skills/*/*/SKILL.md"))
    skill_path.write_text(
        "---\nname: Broken\ndescription: TODO\n---\n\n# Broken\n",
        encoding="utf-8",
    )

    with pytest.raises(ValueError, match="description/trigger quality failed"):
        export_skill_pack(suite, tmp_path / "pack")


def test_export_skill_pack_rejects_unsafe_manifest_path_and_nonempty_output(
    tmp_path,
):
    suite = _make_suite(tmp_path)
    manifest = _read_json(suite / "suite.json")
    manifest["skills"][0]["path"] = "../outside/SKILL.md"
    write_json(suite / "suite.json", manifest)

    with pytest.raises(ValueError, match="unsafe manifest path"):
        export_skill_pack(suite, tmp_path / "unsafe_pack")

    suite = _make_suite(tmp_path / "second")
    output = tmp_path / "nonempty"
    output.mkdir()
    (output / "stale.txt").write_text("stale", encoding="utf-8")

    with pytest.raises(ValueError, match="must be empty"):
        export_skill_pack(suite, output)


def _make_suite(tmp_path):
    plan = tmp_path / "plan"
    plan.mkdir(parents=True)
    write_json(plan / "skill_candidates.json", _candidate_plan_payload())
    suite = tmp_path / "suite"
    build_skill_suite(plan, suite)
    return suite
