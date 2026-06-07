import json

import pytest

from heitang_kb_forge.retrieval.query_planning import build_retrieval_plan, write_query_planning_outputs


REQUIRED_PLAN_FIELDS = {
    "original_query",
    "normalized_query",
    "rewritten_query",
    "rewrite_reason",
    "expanded_terms",
    "subqueries",
    "query_variants",
    "fanout_policy",
    "retrieval_purpose",
    "target_kbs",
    "retrieval_mode",
    "top_k",
    "filters",
    "citation_required",
    "refusal_policy",
    "confidence_threshold",
    "route_reason",
    "deterministic_local_path",
    "optional_llm_assist_path",
    "offline_fallback",
    "tests_require_real_llm_api_network",
}


def test_answering_retrieval_plan_contains_required_contract_fields(tmp_path):
    package = tmp_path / "package"
    package.mkdir()

    plan = build_retrieval_plan("pricing revenue", package=package, purpose="answering", top_k=7)

    assert REQUIRED_PLAN_FIELDS.issubset(plan)
    assert plan["retrieval_purpose"] == "answering"
    assert plan["retrieval_mode"].startswith("answering_")
    assert plan["target_kbs"] == [str(package).replace("\\", "/")]
    assert plan["top_k"] == 7
    assert plan["citation_required"] is True
    assert plan["refusal_policy"]["mode"] == "answering"
    assert plan["tests_require_real_llm_api_network"] is False


def test_validation_retrieval_plan_is_separate_and_does_not_claim_v38_features():
    plan = build_retrieval_plan("check pricing freshness", purpose="validation", citation_required=False)

    assert plan["retrieval_purpose"] == "validation"
    assert plan["retrieval_mode"].startswith("validation_")
    assert plan["citation_required"] is False
    assert plan["refusal_policy"]["mode"] == "validation_only"
    assert plan["refusal_policy"]["external_retrieval"] == "not_implemented_in_v3_7"
    assert plan["refusal_policy"]["claim_verification"] == "deferred_to_v3_8"
    assert "answering" not in plan["retrieval_mode"]


def test_invalid_retrieval_purpose_has_stable_business_error():
    with pytest.raises(ValueError, match="retrieval purpose must be one of"):
        build_retrieval_plan("pricing", purpose="external")


def test_write_query_planning_outputs_writes_trace_and_reports(tmp_path):
    plan = build_retrieval_plan("compare pricing and revenue", purpose="answering", max_rewrites=4)
    result = write_query_planning_outputs(tmp_path, plan)

    assert result["status"] == "pass"
    for name in [
        "query_rewrite_report.json",
        "query_rewrite_trace.json",
        "retrieval_plan.json",
        "retrieval_plan_report.md",
    ]:
        assert (tmp_path / name).exists()
    assert json.loads((tmp_path / "retrieval_plan.json").read_text(encoding="utf-8"))["subqueries"]
    trace = json.loads((tmp_path / "query_rewrite_trace.json").read_text(encoding="utf-8"))
    assert [step["name"] for step in trace["steps"]] == [
        "normalize_query",
        "rewrite_query",
        "expand_query",
        "decompose_query",
        "generate_query_variants",
        "build_retrieval_plan",
    ]
    assert "Purpose: answering" in (tmp_path / "retrieval_plan_report.md").read_text(encoding="utf-8")
