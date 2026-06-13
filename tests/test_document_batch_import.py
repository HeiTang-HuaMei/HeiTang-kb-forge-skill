import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def test_preflight_documents_writes_inventory_preflight_and_recommendations(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "preflight"
    input_dir.mkdir()
    (input_dir / "001_plain.md").write_text("Markdown fixture", encoding="utf-8")
    (input_dir / "002_scan.pdf").write_bytes(b"%PDF scanned fixture")
    (input_dir / "003_table.xlsx").write_bytes(b"fake xlsx fixture")
    (input_dir / "004_unsupported.xyz").write_text("Unsupported", encoding="utf-8")

    result = CliRunner().invoke(app, ["preflight-documents", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    inventory = _json(output / "document_inventory.json")
    preflight = _json(output / "document_preflight.json")
    recommendations = _json(output / "backend_recommendation.json")
    unsupported = _json(output / "unsupported_file_report.json")
    file_type = _json(output / "file_type_report.json")

    assert inventory["total_files"] == 4
    assert inventory["ready_count"] == 3
    assert inventory["unsupported_count"] == 1
    assert len(preflight["files"]) == 4
    assert len(recommendations["recommendations"]) == 4
    rows = {row["relative_path"]: row for row in preflight["files"]}
    recs = {row["relative_path"]: row for row in recommendations["recommendations"]}
    assert rows["002_scan.pdf"]["needs_ocr"] is True
    assert rows["003_table.xlsx"]["contains_tables"] is True
    assert recs["001_plain.md"]["selected_backend"] == "builtin"
    assert recs["002_scan.pdf"]["selected_backend"] == "paddleocr"
    assert recs["003_table.xlsx"]["selected_backend"] == "builtin"
    assert recs["003_table.xlsx"]["reason"] == "table_document_builtin_parser"
    assert recs["004_unsupported.xyz"]["recommendation_status"] == "unsupported"
    assert unsupported["unsupported_count"] == 1
    assert file_type["counts_by_file_type"]["unsupported"] == 1
    assert (output / "preflight_report.md").exists()
    assert (output / "unsupported_file_report.md").exists()
    assert not (output / "batch_import_report.json").exists()


def test_batch_import_documents_isolates_unsupported_and_duplicate_files(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "batch"
    input_dir.mkdir()
    (input_dir / "001_text.txt").write_text("Duplicate payload", encoding="utf-8")
    (input_dir / "002_copy.txt").write_text("Duplicate payload", encoding="utf-8")
    (input_dir / "003_complex_table.pdf").write_bytes(b"%PDF table fixture")
    (input_dir / "004_unsupported.bin").write_bytes(b"unsupported")

    result = CliRunner().invoke(app, ["batch-import-documents", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    report = _json(output / "batch_import_report.json")
    inventory = _json(output / "document_inventory.json")
    recommendations = _json(output / "backend_recommendation.json")

    assert report["status"] == "completed_with_issues"
    assert report["total_files"] == 4
    assert report["imported_count"] == 3
    assert report["failed_count"] == 1
    assert report["unsupported_count"] == 1
    assert report["duplicate_count"] == 1
    assert report["single_file_failure_isolated"] is True
    assert report["llm_required"] is False
    items = {item["relative_path"]: item for item in report["items"]}
    assert items["001_text.txt"]["status"] == "imported"
    assert items["002_copy.txt"]["status"] == "duplicate"
    assert items["002_copy.txt"]["duplicate_of"] == "001_text.txt"
    assert items["004_unsupported.bin"]["status"] == "unsupported"
    assert items["004_unsupported.bin"]["error"] == "unsupported_file_extension"
    inv = {item["relative_path"]: item for item in inventory["files"]}
    assert inv["002_copy.txt"]["duplicate_of"] == "001_text.txt"
    recs = {item["relative_path"]: item for item in recommendations["recommendations"]}
    assert recs["003_complex_table.pdf"]["selected_backend"] == "mineru"
    assert recs["003_complex_table.pdf"]["review_required"] is True
    assert (output / "batch_import_report.md").exists()
    assert (output / "batch_import_log.jsonl").exists()
    assert len((output / "batch_import_log.jsonl").read_text(encoding="utf-8").splitlines()) == 4
