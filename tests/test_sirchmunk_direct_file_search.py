import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli_runtime import app
from heitang_kb_forge.external_retrieval import (
    build_sirchmunk_direct_file_search,
    validate_sirchmunk_direct_file_search,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_sirchmunk_direct_file_search_is_local_bounded_and_embedding_free(tmp_path):
    workspace = tmp_path / "workspace"
    workspace.mkdir()
    (workspace / "notes.md").write_text(
        "# Search notes\nSirchmunk inspires direct file search without vector DB.",
        encoding="utf-8",
    )
    (workspace / "other.txt").write_text("unrelated", encoding="utf-8")
    output = tmp_path / "out"

    result = build_sirchmunk_direct_file_search(
        output,
        workspace=workspace,
        query="direct vector",
    )
    validation = validate_sirchmunk_direct_file_search(output)
    manifest = _json(output / "sirchmunk_direct_file_search_manifest.json")
    results = [
        json.loads(line)
        for line in (output / "direct_file_search_results.jsonl").read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]

    assert result["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []
    assert manifest["section"] == "5.14"
    assert manifest["project_id"] == "sirchmunk"
    assert manifest["integration_decision"] == "real_integration"
    assert manifest["integration_mode"] == "bounded_direct_file_search_provider"
    assert manifest["source_verification"]["repository_url"] == "https://github.com/modelscope/sirchmunk"
    assert manifest["source_verification"]["repository_head"] == (
        "1e07ec11953673b601959fc82563e8264b9d5c6a"
    )
    assert manifest["source_verification"]["latest_release"] == "v0.0.7"
    assert manifest["source_verification"]["license_spdx"] == "Apache-2.0"
    assert manifest["source_verification"]["repository_cloned"] is False
    assert manifest["runtime_boundary"]["sirchmunk_runtime_integrated"] is False
    assert manifest["runtime_boundary"]["embedding_required"] is False
    assert manifest["runtime_boundary"]["vector_database_required"] is False
    assert manifest["runtime_boundary"]["network_required"] is False
    assert manifest["runtime_boundary"]["llm_required"] is False
    assert manifest["runtime_boundary"]["external_source_ingestion_implemented"] is False
    assert manifest["security_boundary"]["path_boundary_enforced"] is True
    assert manifest["search_summary"]["result_count"] == 1
    assert results[0]["relative_path"] == "notes.md"
    assert results[0]["score"] >= 2


def test_sirchmunk_direct_file_search_blocks_paths_outside_workspace(tmp_path):
    workspace = tmp_path / "workspace"
    outside = tmp_path / "outside"
    workspace.mkdir()
    outside.mkdir()
    (outside / "secret.txt").write_text("direct vector", encoding="utf-8")

    result = build_sirchmunk_direct_file_search(
        tmp_path / "out",
        workspace=workspace,
        query="direct",
        include_paths=[outside],
    )

    assert result["status"] == "failed"
    assert result["error_code"] == "path_outside_workspace"
    assert result["not_goal_complete"] is True


def test_sirchmunk_validation_rejects_runtime_boundary_drift(tmp_path):
    workspace = tmp_path / "workspace"
    workspace.mkdir()
    (workspace / "notes.md").write_text("direct file search", encoding="utf-8")
    output = tmp_path / "out"
    build_sirchmunk_direct_file_search(output, workspace=workspace, query="direct")
    manifest_path = output / "sirchmunk_direct_file_search_manifest.json"
    manifest = _json(manifest_path)
    manifest["runtime_boundary"]["vector_database_required"] = True
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    result = validate_sirchmunk_direct_file_search(output)

    assert result["status"] == "failed"
    assert "vector_database_required_must_be_false" in result["boundary_errors"]


def test_sirchmunk_cli_build_and_validate(tmp_path):
    workspace = tmp_path / "workspace"
    workspace.mkdir()
    (workspace / "notes.md").write_text("direct file search", encoding="utf-8")
    library = tmp_path / "library"
    validation = tmp_path / "validation"
    runner = CliRunner()

    build_result = runner.invoke(
        app,
        [
            "build-sirchmunk-direct-file-search",
            "--workspace",
            str(workspace),
            "--query",
            "direct",
            "--output",
            str(library),
        ],
    )
    validate_result = runner.invoke(
        app,
        [
            "validate-sirchmunk-direct-file-search",
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
    assert _json(validation / "sirchmunk_direct_file_search_validation_report.json")["status"] == "passed"
