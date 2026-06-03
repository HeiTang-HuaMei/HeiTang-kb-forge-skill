from heitang_kb_forge.llm.extractor import LLMOptions
from heitang_kb_forge.llm.quality import make_llm_quality_report


def test_llm_quality_report_counts_records_and_coverage():
    outputs = {
        "cards": [_record("cards", "Title", "Summary")],
        "qa_pairs": [_record("qa_pairs", "Question?", "Answer")],
        "glossary": [_record("glossary", "Term", "Definition")],
        "frameworks": [_record("frameworks", "Framework", "Summary")],
        "case_cards": [_record("case_cards", "Case", "Summary")],
        "metrics": [_record("metrics", "Metric", "Definition")],
    }

    result = make_llm_quality_report(outputs, LLMOptions(enabled=True))

    report = result.report
    assert report.total_llm_records == 6
    assert report.asset_type_counts["cards"] == 1
    assert report.citation_coverage == 1.0
    assert report.source_path_coverage == 1.0
    assert report.chunk_id_coverage == 1.0
    assert report.llm_quality_score == 100
    assert report.llm_quality_level == "excellent"
    assert "LLM Quality Summary" in result.summary
    assert "rule-based proxy evaluation" in result.summary
    assert "No LLM judge" in result.summary
    assert "No network call" in result.summary


def test_llm_quality_report_counts_empty_and_duplicate_outputs():
    duplicate = _record("cards", "Same", "Summary")
    outputs = {
        "cards": [duplicate, duplicate.copy(), {"citation": "", "source_path": "", "chunk_id": ""}],
        "qa_pairs": [],
        "glossary": [],
        "frameworks": [],
        "case_cards": [],
        "metrics": [],
    }

    result = make_llm_quality_report(outputs, LLMOptions(enabled=True))

    report = result.report
    assert report.total_llm_records == 3
    assert report.empty_output_count == 1
    assert report.duplicate_count == 1
    assert report.missing_citation_count == 1
    assert report.llm_quality_score < 100
    assert report.warnings


def _record(asset_type, first, second):
    record = {
        "source_path": "input.md",
        "chunk_id": "chunk-1",
        "citation": "input.md#chunk=chunk-1",
        "confidence": 0.8,
        "token_usage": {"total_tokens": 1},
        "cache_key": "cache",
    }
    if asset_type == "cards":
        record.update({"title": first, "summary": second})
    elif asset_type == "qa_pairs":
        record.update({"question": first, "answer": second})
    elif asset_type == "glossary":
        record.update({"term": first, "definition": second})
    elif asset_type == "case_cards":
        record.update({"title": first, "case_summary": second})
    else:
        record.update({"name": first, "definition": second})
    return record
