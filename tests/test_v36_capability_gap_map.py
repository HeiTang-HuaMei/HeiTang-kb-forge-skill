import json
from heitang_kb_forge.audit.capability_gap import capability_gap_map


def _report() -> dict:
    return capability_gap_map()


def test_capability_gap_map_parses_and_has_required_fields():
    report = _report()
    required = {
        "capability",
        "status",
        "current_files",
        "current_tests",
        "missing_tests",
        "target_version",
        "priority",
        "implementation_notes",
        "benchmark_reference",
        "deterministic_local_implementation_path",
        "optional_llm_assisted_enhancement_path",
        "offline_fallback",
        "tests_require_real_llm_api_network",
        "llm_dependency_policy",
    }

    assert report["capability_gap_map_version"] == "3.6.0-alpha.1"
    assert report["network_required_for_tests"] is False
    for item in report["capabilities"]:
        assert required.issubset(item)
        assert item["tests_require_real_llm_api_network"] is False
        assert "optional assistive layer" in item["llm_dependency_policy"]


def test_claim_verification_and_contradiction_detection_are_s_level_gaps():
    report = _report()
    by_capability = {item["capability"]: item for item in report["capabilities"]}

    assert "claim_verification" in by_capability
    assert "contradiction_detection" in by_capability
    assert by_capability["claim_verification"]["target_version"] == "v3.8"
    assert by_capability["claim_verification"]["priority"] == "P0"
    assert by_capability["contradiction_detection"]["target_version"] == "v3.8"
    assert by_capability["contradiction_detection"]["priority"] == "P0"
    assert "claim_verification" in report["s_level_capabilities"]


def test_target_version_mapping_includes_v38_and_v43_verification_governance():
    report = _report()

    assert report["target_version_mapping"]["v3.8"] == "RAG Retrieval Quality & Evaluation"
    assert report["target_version_mapping"]["v4.3"] == "Local Governance & Lifecycle Management"


def test_local_pdf_parser_capabilities_are_mapped():
    report = _report()
    by_capability = {item["capability"]: item for item in report["capabilities"]}

    for capability in [
        "local_pdf_to_markdown",
        "pdf_token_reduction",
        "parser_backend_selection",
        "scanned_pdf_detection",
        "ocr_backend_routing",
        "complex_layout_parsing",
        "parser_confidence_report",
        "no_cloud_upload_guarantee",
    ]:
        assert capability in by_capability

    assert by_capability["local_pdf_to_markdown"]["target_version"] == "v3.9"
    assert by_capability["pdf_token_reduction"]["target_version"] == "v3.9"
    assert "LiteDoc" in by_capability["local_pdf_to_markdown"]["benchmark_reference"]


def test_no_ui_repo_dependency_in_capability_map():
    assert "kb-forge-skill-ui" not in json.dumps(_report())
