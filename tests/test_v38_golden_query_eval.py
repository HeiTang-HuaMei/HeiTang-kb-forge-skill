from heitang_kb_forge.retrieval.eval import run_golden_query_eval


def test_golden_query_eval_parses_fixtures():
    recall_trace = {"variant_traces": [{"results": [{"retrieval_id": "chunk_0"}]}]}
    failure_report = {"should_refuse": True}

    report = run_golden_query_eval(None, recall_trace, failure_report)

    assert report["case_count"] >= 1
    assert "recall_at_k" in report
    assert report["refusal_case_pass"] is True
    assert report["validation_case_pass"] is True
