import json
import sys
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def _json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _events(path):
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def test_du_to_kb_to_package_chain_uses_real_subprocess_and_progress(tmp_path):
    source = tmp_path / "source"
    preflight = tmp_path / "preflight"
    du_output = tmp_path / "document_understanding"
    knowledge_base = tmp_path / "knowledge_base"
    knowledge_package = tmp_path / "knowledge_package"
    source.mkdir()
    (source / "guide.md").write_text(
        "# HeiTang Guide\n\nA verifiable knowledge supply chain preserves source lineage.",
        encoding="utf-8",
    )
    (source / "operations.txt").write_text(
        "Progress events make long-running local workflows diagnosable.",
        encoding="utf-8",
    )

    runner = CliRunner()
    preflight_result = runner.invoke(
        app,
        [
            "batch-import-documents",
            "--input",
            str(source),
            "--output",
            str(preflight),
        ],
    )
    assert preflight_result.exit_code == 0, preflight_result.output

    runtime_config = tmp_path / "runtime_config.json"
    repo_root = Path(__file__).resolve().parents[1]
    runtime_config.write_text(
        json.dumps(
            {
                "schema_version": "document_understanding_runtime_config.v1",
                "working_directory": str(repo_root),
                "routes": {".md": "builtin", ".txt": "builtin"},
                "backends": {
                    "builtin": {
                        "python": sys.executable,
                        "working_directory": str(repo_root),
                        "timeout_seconds": 120,
                    }
                },
            }
        ),
        encoding="utf-8",
    )
    du_result = runner.invoke(
        app,
        [
            "run-document-understanding",
            "--input",
            str(source),
            "--preflight",
            str(preflight),
            "--runtime-config",
            str(runtime_config),
            "--output",
            str(du_output),
        ],
    )
    assert du_result.exit_code == 0, du_result.output
    du_manifest = _json(du_output / "document_understanding_manifest.json")
    assert du_manifest["status"] == "completed"
    assert du_manifest["success_count"] == 2
    assert du_manifest["runtime_invoked_count"] == 2
    assert du_manifest["normalized_source_count"] == 2
    assert all(item["executed_backend"] == "builtin" for item in du_manifest["items"])
    assert all(item["runtime_invoked"] is True for item in du_manifest["items"])
    assert _json(du_output / "runtime_configuration_report.json")["secrets_persisted"] is False
    du_stages = [event["stage"] for event in _events(du_output / "progress_events.jsonl")]
    assert du_stages[0] == "document_understanding_started"
    assert "document_understanding_item" in du_stages
    assert du_stages[-1] == "document_understanding_done"

    kb_result = runner.invoke(
        app,
        [
            "build-knowledge-base",
            "--document-understanding",
            str(du_output),
            "--output",
            str(knowledge_base),
        ],
    )
    assert kb_result.exit_code == 0, kb_result.output
    kb_report = _json(knowledge_base / "knowledge_base_build_report.json")
    assert kb_report["status"] == "pass"
    assert kb_report["source_count"] == 2
    assert kb_report["chunk_count"] > 0
    assert kb_report["retrieval_index_count"] > 0
    assert kb_report["document_understanding_backend_counts"] == {"builtin": 2}
    assert (knowledge_base / "document_understanding_lineage.json").exists()
    kb_stages = [event["stage"] for event in _events(knowledge_base / "progress_events.jsonl")]
    assert kb_stages[0] == "knowledge_base_started"
    assert "done" in kb_stages
    assert kb_stages[-1] == "knowledge_base_done"

    package_result = runner.invoke(
        app,
        [
            "build-knowledge-package",
            "--knowledge-base",
            str(knowledge_base),
            "--output",
            str(knowledge_package),
        ],
    )
    assert package_result.exit_code == 0, package_result.output
    package_report = _json(
        knowledge_package / "knowledge_package_build_report.json"
    )
    assert package_report["status"] == "pass"
    assert package_report["standard_files_present"] is True
    assert package_report["target_contract_status"] in {"pass", "warning"}
    assert package_report["artifact_file_count"] > 0
    assert package_report["exe_packaging_proven"] is False
    assert (knowledge_package / "chunks.jsonl").stat().st_size > 0
    assert (knowledge_package / "retrieval_index.jsonl").stat().st_size > 0
    package_stages = [
        event["stage"]
        for event in _events(knowledge_package / "progress_events.jsonl")
    ]
    assert package_stages[0] == "knowledge_package_started"
    assert package_stages[-1] == "knowledge_package_done"


def test_document_understanding_routes_xlsx_to_builtin_runtime(tmp_path):
    source = tmp_path / "source"
    preflight = tmp_path / "preflight"
    du_output = tmp_path / "document_understanding"
    source.mkdir()

    from openpyxl import Workbook

    workbook = Workbook()
    worksheet = workbook.active
    worksheet.title = "Routing"
    worksheet.append(["Claim", "Evidence"])
    worksheet.append(
        [
            "HeiTang table routing must use builtin parser for XLSX.",
            "The normalized output should preserve source lineage.",
        ]
    )
    workbook.save(source / "table_claims.xlsx")

    runner = CliRunner()
    preflight_result = runner.invoke(
        app,
        [
            "batch-import-documents",
            "--input",
            str(source),
            "--output",
            str(preflight),
        ],
    )
    assert preflight_result.exit_code == 0, preflight_result.output
    recommendations = _json(preflight / "backend_recommendation.json")
    xlsx_recommendation = recommendations["recommendations"][0]
    assert xlsx_recommendation["selected_backend"] == "builtin"
    assert xlsx_recommendation["reason"] == "table_document_builtin_parser"

    runtime_config = tmp_path / "runtime_config.json"
    repo_root = Path(__file__).resolve().parents[1]
    runtime_config.write_text(
        json.dumps(
            {
                "schema_version": "document_understanding_runtime_config.v1",
                "working_directory": str(repo_root),
                "routes": {".xlsx": "builtin"},
                "backends": {
                    "builtin": {
                        "python": sys.executable,
                        "working_directory": str(repo_root),
                        "timeout_seconds": 120,
                    }
                },
            }
        ),
        encoding="utf-8",
    )

    du_result = runner.invoke(
        app,
        [
            "run-document-understanding",
            "--input",
            str(source),
            "--preflight",
            str(preflight),
            "--runtime-config",
            str(runtime_config),
            "--output",
            str(du_output),
        ],
    )

    assert du_result.exit_code == 0, du_result.output
    du_manifest = _json(du_output / "document_understanding_manifest.json")
    assert du_manifest["status"] == "completed"
    assert du_manifest["success_count"] == 1
    assert du_manifest["failed_count"] == 0
    item = du_manifest["items"][0]
    assert item["executed_backend"] == "builtin"
    assert item["runtime_invoked"] is True

    records = [
        json.loads(line)
        for line in (du_output / "document_understanding_records.jsonl").read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
    assert records[0]["relative_path"] == "table_claims.xlsx"
    assert records[0]["text_length"] > 0
    normalized_text = Path(records[0]["normalized_path"]).read_text(encoding="utf-8")
    assert "HeiTang table routing must use builtin parser for XLSX" in normalized_text
