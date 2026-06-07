from heitang_kb_forge.document_parsing import write_document_parsing_outputs
from tests.v39_helpers import read_json


def test_no_cloud_upload_report_generated_and_no_network_required(tmp_path):
    source = tmp_path / "lesson.md"
    source.write_text("# Lesson", encoding="utf-8")
    output = tmp_path / "out"

    write_document_parsing_outputs(source, output)

    report = read_json(output / "no_cloud_upload_report.json")
    assert report["local_only_processing_path"] is True
    assert report["no_external_api_calls"] is True
    assert report["real_llm_dependency"] is False
    assert report["tests_require_network"] is False
