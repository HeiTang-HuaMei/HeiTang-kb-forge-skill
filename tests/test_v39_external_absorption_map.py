from pathlib import Path

from heitang_kb_forge.workspace_storage.external_absorption import build_v39_external_absorption_map, write_v39_external_absorption_map
from tests.v39_helpers import read_json


MANDATORY = {
    "local_workspace_registry",
    "package_registry",
    "skill_registry",
    "agent_registry",
    "memory_registry",
    "document_registry",
    "index_registry",
    "storage_usage_report",
    "content_hash_dedup",
    "cleanup_plan",
    "retention_policy",
    "archive_plan",
    "memory_lifecycle",
    "memory_compaction_plan",
    "token_budget_policy",
    "local_pdf_to_markdown_preprocessing",
    "parser_backend_selection",
    "parser_backend_benchmark",
    "pdf_token_reduction_report",
    "no_cloud_upload_guarantee",
}


def test_v39_external_absorption_map_has_all_capabilities(tmp_path):
    write_v39_external_absorption_map(tmp_path)
    payload = read_json(tmp_path / "v39_external_absorption_map.json")
    capabilities = {item["capability"] for item in payload["capabilities"]}
    assert MANDATORY == capabilities
    for item in payload["capabilities"]:
        assert item["benchmark_references"]
        assert item["decision"] in {"absorb", "inspire", "reject", "future", "needs_manual_review"}
        assert item["local_deterministic_implementation"]
        assert item["optional_llm_assist_path"]
        assert item["offline_fallback"]
        assert item["tests_require_real_llm_api_network"] is False
        assert "external code" in item["what_not_to_copy"]
    assert payload["no_copy_policy"]["external_code_copied"] is False


def test_checked_in_root_absorption_map_matches_contract():
    payload = read_json(Path("v39_external_absorption_map.json"))
    expected = build_v39_external_absorption_map()
    assert {item["capability"] for item in payload["capabilities"]} == {item["capability"] for item in expected["capabilities"]}
