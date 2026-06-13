import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli_runtime import app
from heitang_kb_forge.obsidian_vault_strengthening import (
    build_obsidian_vault_strengthening_record,
    scan_markdown_vault,
    validate_obsidian_vault_strengthening_record,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_obsidian_vault_strengthening_builds_local_adapter_outputs(tmp_path):
    output = tmp_path / "obsidian"

    result = build_obsidian_vault_strengthening_record(output)
    validation = validate_obsidian_vault_strengthening_record(output)
    manifest = _json(output / "obsidian_vault_strengthening_manifest.json")
    frontmatter = _json(output / "vault_frontmatter_schema.json")
    backlinks = _json(output / "vault_backlink_map.json")
    folders = _json(output / "vault_folder_structure.json")
    export = _json(output / "vault_export_manifest.json")

    assert result["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []
    assert manifest["section"] == "5.S3"
    assert manifest["project_id"] == "obsidian_compatible_vault"
    assert manifest["integration_decision"] == "real_integration"
    assert manifest["decision_qualifier"] == "local_vault_adapter_only"
    assert manifest["integration_mode"] == "local_markdown_vault_adapter_strengthening"
    assert manifest["compatibility_target"]["markdown_folder_import"] is True
    assert manifest["compatibility_target"]["markdown_folder_export"] is True
    assert manifest["compatibility_target"]["frontmatter_support"] is True
    assert manifest["compatibility_target"]["backlink_map_support"] is True
    assert manifest["compatibility_target"]["obsidian_runtime_required"] is False
    assert manifest["compatibility_target"]["obsidian_plugin_required"] is False
    assert manifest["runtime_boundary"]["local_vault_adapter_implemented"] is True
    assert manifest["runtime_boundary"]["obsidian_runtime_integrated"] is False
    assert manifest["runtime_boundary"]["obsidian_plugin_required"] is False
    assert manifest["runtime_boundary"]["obsidian_app_launched"] is False
    assert manifest["runtime_boundary"]["network_required"] is False
    assert manifest["ui_contract"]["local_vault_import_visible"] is True
    assert manifest["ui_contract"]["obsidian_compatible_export_visible"] is True
    assert manifest["ui_contract"]["ready"] is False
    assert manifest["ui_contract"]["executable_action"] is False
    assert {"title", "tags", "owner"} <= set(frontmatter["observed_keys"])
    assert backlinks["edge_count"] >= 1
    assert folders["folder_count"] >= 2
    assert export["exported_note_count"] == manifest["vault_scan"]["note_count"]
    assert export["frontmatter_preserved"] is True
    assert export["wikilinks_preserved"] is True


def test_scan_markdown_vault_reads_frontmatter_wikilinks_and_folders(tmp_path):
    vault = tmp_path / "vault"
    (vault / "A").mkdir(parents=True)
    (vault / "B").mkdir()
    (vault / "A" / "One.md").write_text(
        "---\ntitle: One\ntags: [alpha]\n---\n# One\n\nSee [[B/Two]].\n",
        encoding="utf-8",
    )
    (vault / "B" / "Two.md").write_text(
        "---\ntitle: Two\n---\n# Two\n\nBack to [[One]].\n",
        encoding="utf-8",
    )

    scan = scan_markdown_vault(vault)

    assert len(scan["notes"]) == 2
    assert scan["backlink_map"]["edge_count"] == 2
    assert {folder["folder"] for folder in scan["folder_structure"]["folders"]} == {"A", "B"}
    assert any("title" in note["frontmatter_keys"] for note in scan["notes"])


def test_obsidian_validation_rejects_runtime_drift(tmp_path):
    output = tmp_path / "obsidian"
    build_obsidian_vault_strengthening_record(output)
    manifest_path = output / "obsidian_vault_strengthening_manifest.json"
    manifest = _json(manifest_path)
    manifest["runtime_boundary"]["obsidian_runtime_integrated"] = True
    manifest["runtime_boundary"]["obsidian_plugin_required"] = True
    manifest["ui_contract"]["ready"] = True
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    result = validate_obsidian_vault_strengthening_record(output)

    assert result["status"] == "failed"
    assert "obsidian_runtime_integrated_must_be_false" in result["boundary_errors"]
    assert "obsidian_plugin_required_must_be_false" in result["boundary_errors"]
    assert "ready_must_be_false" in result["boundary_errors"]


def test_obsidian_vault_cli_build_and_validate(tmp_path):
    library = tmp_path / "library"
    validation = tmp_path / "validation"
    runner = CliRunner()

    build_result = runner.invoke(
        app,
        ["build-obsidian-vault-strengthening-record", "--output", str(library)],
    )
    validate_result = runner.invoke(
        app,
        [
            "validate-obsidian-vault-strengthening-record",
            "--library",
            str(library),
            "--output",
            str(validation),
        ],
    )

    assert build_result.exit_code == 0, build_result.output
    assert "status=passed" in build_result.output
    assert validate_result.exit_code == 0, validate_result.output
    assert "status=passed" in validate_result.output
    assert _json(validation / "obsidian_vault_validation_report.json")["status"] == "passed"
