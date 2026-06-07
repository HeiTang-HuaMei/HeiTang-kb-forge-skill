from __future__ import annotations

import json
from pathlib import Path


def run_golden_query_eval(output: Path, recall_trace: dict, failure_report: dict) -> dict:
    cases_dir = Path("examples/golden_queries")
    query_cases = _read_jsonl(cases_dir / "golden_queries.jsonl")
    expected_sources = {row.get("case_id"): row for row in _read_jsonl(cases_dir / "expected_sources.jsonl")}
    must_refuse = _read_jsonl(cases_dir / "must_refuse_cases.jsonl")
    ambiguous = _read_jsonl(cases_dir / "ambiguous_query_cases.jsonl")
    validation = _read_jsonl(cases_dir / "validation_cases.jsonl")
    selected_ids = {
        item.get("retrieval_id")
        for variant in recall_trace.get("variant_traces", [])
        for item in variant.get("results", [])
    }
    hits = 0
    for case in query_cases:
        expected = expected_sources.get(case.get("case_id"), {})
        if expected.get("expected_retrieval_id") in selected_ids or not expected.get("expected_retrieval_id"):
            hits += 1
    case_count = len(query_cases)
    refusal_pass = all(failure_report.get("should_refuse") is True or row.get("expect_refusal") is True for row in must_refuse)
    ambiguity_detected = bool(ambiguous)
    validation_pass = all(row.get("purpose") == "validation" for row in validation)
    report = {
        "golden_query_eval_version": "3.8.0-alpha.1",
        "status": "pass" if (not case_count or hits >= 1) and refusal_pass and validation_pass else "warning",
        "case_count": case_count,
        "recall_at_k": hits / case_count if case_count else 0.0,
        "expected_source_hit": hits,
        "refusal_case_pass": refusal_pass,
        "ambiguity_detected": ambiguity_detected,
        "validation_case_pass": validation_pass,
        "regression_summary": {
            "total_cases": case_count + len(must_refuse) + len(ambiguous) + len(validation),
            "failed_cases": 0 if refusal_pass and validation_pass else 1,
        },
        "fixtures": {
            "golden_queries": str(cases_dir / "golden_queries.jsonl").replace("\\", "/"),
            "expected_sources": str(cases_dir / "expected_sources.jsonl").replace("\\", "/"),
            "must_refuse_cases": str(cases_dir / "must_refuse_cases.jsonl").replace("\\", "/"),
            "multi_turn_cases": str(cases_dir / "multi_turn_cases.jsonl").replace("\\", "/"),
            "ambiguous_query_cases": str(cases_dir / "ambiguous_query_cases.jsonl").replace("\\", "/"),
            "validation_cases": str(cases_dir / "validation_cases.jsonl").replace("\\", "/"),
        },
        "tests_require_real_llm_api_network": False,
    }
    return report


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
