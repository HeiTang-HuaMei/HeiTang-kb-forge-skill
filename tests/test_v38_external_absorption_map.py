from heitang_kb_forge.retrieval.external_absorption import build_v38_external_absorption_map, write_v38_external_absorption_map

from tests.v38_helpers import read_json


REQUIRED_FIELDS = {
    "capability",
    "benchmark_references",
    "external_project_or_pattern",
    "decision",
    "reason",
    "what_to_absorb",
    "what_not_to_copy",
    "local_deterministic_implementation",
    "optional_llm_assist_path",
    "offline_fallback",
    "tests_require_real_llm_api_network",
    "implementation_files",
    "tests",
    "reports_or_traces",
    "contract_impact",
    "ui_impact",
    "risk_level",
    "completion_status",
}

MANDATORY = {
    "multi_query_recall",
    "candidate_merge_dedup",
    "deterministic_rerank",
    "evidence_selection",
    "retrieval_failure_diagnostics",
    "explainable_refusal_support",
    "golden_query_evaluation",
    "claim_extraction",
    "local_verification_retrieval",
    "source_cross_check",
    "contradiction_detection",
    "freshness_verification",
    "knowledge_accuracy_scoring",
    "verification_retrieval_trace",
}


def test_v38_external_absorption_map_json_exists_and_has_all_capabilities(tmp_path):
    write_v38_external_absorption_map(tmp_path)

    payload = read_json(tmp_path / "v38_external_absorption_map.json")
    records = {item["capability"]: item for item in payload["capabilities"]}
    assert MANDATORY == set(records)
    assert payload["no_copy_policy"]["external_code_copied"] is False
    assert payload["no_copy_policy"]["external_prompts_copied"] is False
    for item in records.values():
        assert REQUIRED_FIELDS.issubset(item)
        assert item["benchmark_references"] or item["decision"] == "needs_manual_review"
        assert item["decision"]
        assert item["local_deterministic_implementation"]
        assert item["optional_llm_assist_path"]
        assert item["offline_fallback"]
        assert item["tests_require_real_llm_api_network"] is False


def test_absorption_map_builder_claims_no_external_copying():
    payload = build_v38_external_absorption_map()

    assert all("external code" in item["what_not_to_copy"] for item in payload["capabilities"])
    assert payload["no_copy_policy"]["network_required_for_tests"] is False
    assert payload["no_copy_policy"]["real_llm_api_required_for_tests"] is False


def test_generated_absorption_map_matches_v38_contract(tmp_path):
    write_v38_external_absorption_map(tmp_path)
    payload = read_json(tmp_path / "v38_external_absorption_map.json")
    records = {item["capability"]: item for item in payload["capabilities"]}

    assert MANDATORY == set(records)
    assert payload["no_copy_policy"]["external_code_copied"] is False
    assert payload["no_copy_policy"]["external_prompts_copied"] is False
    assert all(REQUIRED_FIELDS.issubset(item) for item in records.values())
    assert all(item["tests_require_real_llm_api_network"] is False for item in records.values())
