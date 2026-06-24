from heitang_kb_forge.retrieval import run_retrieval_regression


def test_retrieval_regression_passes_for_stable_top_record_and_citation_trace():
    payload = {
        "baseline": {
            "query": "knowledge reliability",
            "records": [{"record_id": "chunk-1", "citation": "source-a.md#chunk=chunk-1"}],
            "citation_trace_count": 1,
        },
        "current": {
            "query": "knowledge reliability",
            "records": [{"record_id": "chunk-1", "citation": "source-a.md#chunk=chunk-1"}],
            "citation_trace_count": 1,
        },
    }

    report = run_retrieval_regression(payload)

    assert report.status == "pass"
    assert report.regression_count == 0
    assert report.top_record_match is True
    assert report.top_citation_match is True


def test_retrieval_regression_reports_changed_top_citation_and_trace_count():
    payload = {
        "baseline": {
            "query": "knowledge reliability",
            "records": [{"record_id": "chunk-1", "citation": "source-a.md#chunk=chunk-1"}],
            "citation_trace_count": 1,
        },
        "current": {
            "query": "knowledge reliability",
            "records": [{"record_id": "chunk-2", "citation": "source-b.md#chunk=chunk-2"}],
            "citation_trace_count": 2,
        },
    }

    report = run_retrieval_regression(payload)

    assert report.status == "regression_found"
    assert report.regression_count == 3
    assert report.regressions == [
        "top_record_changed",
        "top_citation_changed",
        "citation_trace_count_changed",
    ]
