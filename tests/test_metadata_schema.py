from heitang_kb_forge.pre_v4_p0 import run_rag_index_completion

from tests.p0_helpers import make_p0_package, read_json


def test_metadata_schema_report_contains_required_fields(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_rag_index_completion(package, output)
    report = read_json(output / "metadata_schema_report.json")

    assert report["status"] == "pass"
    assert "source_id" in report["required_fields"]
    assert "content_hash" in report["required_fields"]
    assert report["metadata_filter_ready"] is True
