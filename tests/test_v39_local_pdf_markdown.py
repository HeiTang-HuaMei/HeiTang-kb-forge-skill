from heitang_kb_forge.document_parsing import write_document_parsing_outputs
from tests.v39_helpers import read_json


def test_local_pdf_markdown_report_generated_without_cloud(tmp_path):
    pdf = tmp_path / "sample.pdf"
    pdf.write_bytes(b"%PDF-1.4\n(Hello local PDF evidence)\n%%EOF")
    output = tmp_path / "out"

    write_document_parsing_outputs(pdf, output)

    report = read_json(output / "local_pdf_markdown_report.json")
    assert report["no_cloud_upload"] is True
    assert report["raw_pdf_sent_to_llm"] is False
    assert report["tests_require_real_llm_api_network"] is False
    assert (output / "sample.md").exists()
