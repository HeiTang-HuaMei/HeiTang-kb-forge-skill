import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.video_skill_template_metadata import (
    build_video_skill_template_metadata,
    validate_video_skill_template_metadata,
)


def test_video_skill_template_metadata_is_verified_reference_only(tmp_path):
    output = tmp_path / "metadata"

    result = build_video_skill_template_metadata(output)

    assert result["section"] == "5.11"
    assert result["status"] == "passed"
    assert result["integration_decision"] == "reference_only"
    assert result["integration_mode"] == "verified_video_skill_template_metadata"
    source = result["source_verification"]
    assert source["repository_head"] == "e06c7c63a766d623004a2807881c30685ce517af"
    assert source["license_spdx"] == "MIT"
    assert source["repository_cloned"] is False
    assert source["external_code_copied"] is False
    assert source["external_prompt_text_copied"] is False
    assert source["external_skill_file_copied"] is False
    assert result["local_metadata_contract"]["prompt_body_included"] is False
    assert result["local_metadata_contract"]["generated_media_included"] is False
    assert result["ui_contract"]["local_ready"] is True
    assert result["ui_contract"]["ready"] is False
    assert result["ui_contract"]["executable_action"] is False
    assert (output / "video_skill_template_metadata.json").exists()
    assert (output / "provider_boundary.json").exists()
    assert (output / "video_skill_template_validation_report.json").exists()


def test_video_skill_template_metadata_preserves_unverified_provider_boundary(tmp_path):
    output = tmp_path / "metadata"
    result = build_video_skill_template_metadata(output)
    provider = result["provider_boundary"]

    assert provider["official_documentation_discovered"] is True
    assert provider["direct_document_access_status"] == "network_timeout"
    assert provider["exact_api_contract_verified"] is False
    assert provider["pricing_contract_verified"] is False
    assert provider["api_key_required"] is True
    assert provider["network_required"] is True
    assert provider["paid_service_boundary"] is True
    assert provider["provider_call_executed"] is False
    assert provider["api_key_collected"] is False
    assert provider["credential_persisted"] is False
    assert provider["provider_adapter_integrated"] is False
    assert provider["video_generation_runtime"] is False


def test_video_skill_template_metadata_validation_rejects_executable_claim(tmp_path):
    output = tmp_path / "metadata"
    build_video_skill_template_metadata(output)
    metadata_path = output / "video_skill_template_metadata.json"
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    metadata["ui_contract"]["executable_action"] = True
    metadata_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    result = validate_video_skill_template_metadata(output)

    assert result["status"] == "failed"
    assert "executable_action_must_be_false" in result["boundary_errors"]


def test_video_skill_template_metadata_cli_builds_and_validates(tmp_path):
    library = tmp_path / "library"
    validation = tmp_path / "validation"
    runner = CliRunner()

    build = runner.invoke(
        app,
        ["build-video-skill-template-metadata", "--output", str(library)],
    )
    validate = runner.invoke(
        app,
        [
            "validate-video-skill-template-metadata",
            "--library",
            str(library),
            "--output",
            str(validation),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "decision=reference_only" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    report = json.loads(
        (validation / "video_skill_template_validation_report.json").read_text(
            encoding="utf-8"
        )
    )
    assert report["status"] == "passed"
