import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli_runtime import app
from heitang_kb_forge.cross_modal_rag_schema import (
    build_cross_modal_rag_schema_library,
    validate_cross_modal_rag_schema_library,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_cross_modal_rag_schema_preserves_distinct_value_and_runtime_boundaries(tmp_path):
    output = tmp_path / "schema"

    result = build_cross_modal_rag_schema_library(output)
    validation = validate_cross_modal_rag_schema_library(output)
    manifest = _json(output / "cross_modal_rag_manifest.json")
    modalities = _json(output / "modality_registry.json")
    graph = _json(output / "cross_modal_knowledge_graph_schema.json")
    benchmark = _json(output / "benchmark_profile.json")

    assert result["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []
    assert manifest["section"] == "5.12"
    assert manifest["integration_decision"] == "reference_only"
    assert manifest["integration_mode"] == "cross_modal_rag_schema_reference"
    assert manifest["source_verification"]["repository_head"] == (
        "a8538efecc99719538960692745ef0eb90d1a2f9"
    )
    assert manifest["source_verification"]["license_spdx"] == "MIT"
    assert manifest["source_verification"]["repository_cloned"] is False
    assert manifest["runtime_boundary"]["rag_anything_runtime_integrated"] is False
    assert manifest["runtime_boundary"]["lightrag_runtime_integrated"] is False
    assert manifest["runtime_boundary"]["mineru_runtime_executed"] is False
    assert manifest["runtime_boundary"]["llm_or_vlm_required"] is False
    assert manifest["runtime_boundary"]["embedding_required"] is False
    assert manifest["runtime_boundary"]["vector_database_required"] is False
    assert manifest["runtime_boundary"]["existing_rag_main_chain_replaced"] is False
    assert manifest["runtime_boundary"]["external_source_ingestion_implemented"] is False
    assert (
        manifest["runtime_boundary"]["knowledge_to_skill_template_generator_implemented"]
        is False
    )
    assert manifest["ui_contract"]["local_ready"] is True
    assert manifest["ui_contract"]["ready"] is False
    assert manifest["ui_contract"]["executable_action"] is False
    assert {item["modality"] for item in modalities["modalities"]} == {
        "text",
        "image",
        "table",
        "equation",
    }
    assert "cross_modal_supports" in graph["relation_types"]
    assert benchmark["runtime_benchmark_executed"] is False


def test_cross_modal_rag_schema_validation_rejects_runtime_boundary_drift(tmp_path):
    output = tmp_path / "schema"
    build_cross_modal_rag_schema_library(output)
    manifest_path = output / "cross_modal_rag_manifest.json"
    manifest = _json(manifest_path)
    manifest["runtime_boundary"]["rag_anything_runtime_integrated"] = True
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    result = validate_cross_modal_rag_schema_library(output)

    assert result["status"] == "failed"
    assert "rag_anything_runtime_integrated_must_be_false" in result["boundary_errors"]


def test_cross_modal_rag_schema_cli_build_and_validate(tmp_path):
    runner = CliRunner()
    library = tmp_path / "library"
    validation = tmp_path / "validation"

    build_result = runner.invoke(
        app,
        ["build-cross-modal-rag-schema-library", "--output", str(library)],
    )
    validate_result = runner.invoke(
        app,
        [
            "validate-cross-modal-rag-schema-library",
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
    assert _json(validation / "cross_modal_rag_validation_report.json")["status"] == "passed"
