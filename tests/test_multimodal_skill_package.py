import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.multimodal_skill_package import (
    write_multimodal_skill_package,
    write_multimodal_skill_validation,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _jsonl(path: Path) -> list[dict]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8-sig").splitlines()
        if line.strip()
    ]


def _write_multimodal_package(package: Path) -> None:
    package.mkdir(parents=True)
    (package / "manifest.json").write_text(
        json.dumps(
            {
                "package_id": "pkg_multimodal_fixture",
                "source_count": 1,
                "multimodal_status": "completed",
            }
        ),
        encoding="utf-8",
    )
    assets = [
        {
            "asset_id": "asset_chart",
            "asset_type": "chart",
            "source_file": "slides/demo.pptx",
            "description": "A dashboard chart with visible trend and labels.",
            "extracted_text": "Trend rises from Q1 to Q2.",
            "confidence": "low",
            "review_required": True,
        }
    ]
    (package / "multimodal_assets.jsonl").write_text(
        "\n".join(json.dumps(asset) for asset in assets) + "\n",
        encoding="utf-8",
    )
    (package / "multimodal_evidence_map.json").write_text(
        json.dumps({"assets": {"asset_chart": {"source_file": "slides/demo.pptx"}}}),
        encoding="utf-8",
    )


def test_multimodal_skill_package_outputs_state_cards_keyframes_and_boundaries(tmp_path):
    package = tmp_path / "knowledge_package"
    output = tmp_path / "mm_skill"
    _write_multimodal_package(package)

    result = write_multimodal_skill_package(
        package,
        output,
        skill_name="Visual Evidence Skill",
    )
    manifest = _json(output / "multimodal_skill_manifest.json")
    state_cards = _jsonl(output / "visual_state_cards.jsonl")
    keyframes = _jsonl(output / "keyframe_index.jsonl")
    branch_policy = _json(output / "branch_loading_policy.json")
    preview = _json(output / "multimodal_skill_preview.json")

    assert result["status"] == "passed"
    assert manifest["project_source"] == "mmskills"
    assert manifest["integration_mode"] == "schema_package_reference"
    assert manifest["mmskills_runtime_integrated"] is False
    assert manifest["mmskills_code_copied"] is False
    assert manifest["mmskills_repository_cloned"] is False
    assert manifest["llm_required"] is False
    assert manifest["network_required"] is False
    assert manifest["external_runtime_required"] is False
    assert state_cards
    assert keyframes
    assert branch_policy["direct_load_allowed"] is False
    assert branch_policy["branch_loaded_preview"] is True
    assert preview["ui_action_available"] is False
    assert preview["runtime_execution_claimed"] is False
    assert (output / "SKILL.md").exists()


def test_multimodal_skill_package_validation_rejects_runtime_boundary_drift(tmp_path):
    package = tmp_path / "knowledge_package"
    output = tmp_path / "mm_skill"
    validation = tmp_path / "validation"
    _write_multimodal_package(package)
    write_multimodal_skill_package(package, output)

    manifest_path = output / "multimodal_skill_manifest.json"
    manifest = _json(manifest_path)
    manifest["mmskills_runtime_integrated"] = True
    manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

    result = write_multimodal_skill_validation(output, validation)

    assert result["status"] == "failed"
    assert "runtime_boundary_violation" in result["blockers"]
    assert (validation / "multimodal_skill_validation_report.json").exists()


def test_multimodal_skill_package_cli_build_and_validate(tmp_path):
    package = tmp_path / "knowledge_package"
    output = tmp_path / "mm_skill"
    validation = tmp_path / "validation"
    _write_multimodal_package(package)

    build = CliRunner().invoke(
        app,
        [
            "build-multimodal-skill-package",
            "--source-package",
            str(package),
            "--output",
            str(output),
            "--skill-name",
            "Visual Evidence Skill",
        ],
    )

    assert build.exit_code == 0, build.output
    validate = CliRunner().invoke(
        app,
        [
            "validate-multimodal-skill-package",
            "--package",
            str(output),
            "--output",
            str(validation),
        ],
    )

    assert validate.exit_code == 0, validate.output
    report = _json(validation / "multimodal_skill_validation_report.json")
    assert report["status"] == "passed"
    assert report["external_code_copied"] is False
    assert report["final_target_not_downgraded"] is True
    assert report["not_goal_complete"] is True
