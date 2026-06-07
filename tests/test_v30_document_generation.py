import json

from heitang_kb_forge.document_generation import DOCUMENT_GENERATION_OUTPUT_FILES, generate_document_outputs
from heitang_kb_forge.exporters.jsonl_exporter import write_json


def test_generate_all_document_formats_and_reports(tmp_path):
    package = _package(tmp_path, trusted=True)
    output = tmp_path / "docs"

    result = generate_document_outputs(
        package,
        output,
        ["md", "docx", "pdf", "pptx"],
        template="default_report",
        grounding_policy="strict_grounded",
        title="Local Evidence Report",
    )

    assert result["status"] == "pass"
    assert set(result["formats"]) == {"md", "docx", "pdf", "pptx"}
    for name in DOCUMENT_GENERATION_OUTPUT_FILES:
        assert (output / name).exists(), name
    generated = (output / "generated.md").read_text(encoding="utf-8")
    assert "## Source Evidence Appendix" in generated
    assert "#chunk=chunk-1" in generated
    trace = _json(output / "document_generation_trace.json")
    quality = _json(output / "document_quality_report.json")
    validation = _json(output / "export_validation_report.json")
    assert trace["source_package"] == str(package)
    assert trace["grounding_policy"] == "strict_grounded"
    assert trace["validation_status"] == "pass"
    assert quality["source_appendix"] == "present"
    assert validation["status"] == "pass"


def test_strict_grounded_blocks_draft_package(tmp_path):
    package = _package(tmp_path, trusted=False)
    output = tmp_path / "blocked"

    try:
        generate_document_outputs(package, output, ["md"], grounding_policy="strict_grounded")
    except ValueError as exc:
        assert "strict_grounded" in str(exc)
    else:
        raise AssertionError("strict_grounded should block draft packages")
    assert not (output / "generated.md").exists()


def test_creative_grounded_allows_draft_with_review_required(tmp_path):
    package = _package(tmp_path, trusted=False)
    output = tmp_path / "creative"

    result = generate_document_outputs(package, output, ["md"], grounding_policy="creative_grounded")

    assert result["status"] == "pass"
    assert result["review_required"] is True
    trace = _json(output / "document_generation_trace.json")
    assert trace["review_required"] is True
    assert "creative_grounded_generation_requires_human_review" in trace["warnings"]


def _package(tmp_path, trusted):
    package = tmp_path / ("trusted" if trusted else "draft")
    package.mkdir()
    write_json(
        package / "manifest.json",
        {
            "domain": "v30",
            "mode": "document_generation",
            "kb_trust_status": "reviewed_knowledge_base" if trusted else "draft_knowledge_package",
        },
    )
    write_json(package / "kb_trust_status.json", {"kb_trust_status": "reviewed_knowledge_base" if trusted else "draft_knowledge_package"})
    write_json(
        package / "trusted_kb_gate.json",
        {
            "status": "pass" if trusted else "fail",
            "blocked": not trusted,
            "kb_trust_status": "reviewed_knowledge_base" if trusted else "draft_knowledge_package",
            "warnings": [] if trusted else ["untrusted_kb_requires_explicit_allow_untrusted"],
        },
    )
    _write_jsonl(
        package / "chunks.jsonl",
        [
            {
                "chunk_id": "chunk-1",
                "source_path": "source.md",
                "title": "Evidence Section",
                "text": "Document generation evidence with cited local facts.",
            }
        ],
    )
    _write_jsonl(
        package / "cards.jsonl",
        [
            {
                "card_id": "card-1",
                "chunk_id": "chunk-1",
                "title": "Evidence Section",
                "summary": "Document generation evidence summary.",
                "citation": "source.md#chunk=chunk-1",
            }
        ],
    )
    return package


def _write_jsonl(path, rows):
    path.write_text("\n".join(json.dumps(row, ensure_ascii=False) for row in rows) + "\n", encoding="utf-8")


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
