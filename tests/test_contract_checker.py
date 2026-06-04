from heitang_kb_forge.contracts.checker import check_package_contract
from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


def test_contract_checker_passes_valid_v2_package(tmp_path):
    _write_minimal_contract_package(tmp_path)

    result = check_package_contract(tmp_path)

    assert result.status == "pass"


def test_contract_checker_fails_missing_required_files(tmp_path):
    result = check_package_contract(tmp_path)

    assert result.status == "fail"
    assert "manifest.json" in result.missing_required_files
    assert "chunks.jsonl" in result.missing_required_files
    assert "evidence_map.json" in result.missing_required_files


def _write_minimal_contract_package(path):
    write_json(
        path / "manifest.json",
        {
            "contract_version": "2.0",
            "package_version": "0.1.0",
            "generated_at": "2026-01-01T00:00:00+00:00",
            "source_count": 1,
            "chunk_count": 1,
            "quality_status": "pass",
            "review_status": "none",
            "progress_status": "not_enabled",
            "ocr_status": "not_enabled",
            "multimodal_status": "not_enabled",
            "rag_status": "not_enabled",
            "agent_template_status": "not_enabled",
        },
    )
    write_jsonl(path / "chunks.jsonl", [{"chunk_id": "chunk_1", "text": "hello"}])
    write_json(path / "evidence_map.json", {"chunks": {}})
    write_json(path / "source_inventory.json", {"sources": []})
    (path / "quality_report.md").write_text("# Quality Report\n", encoding="utf-8")
