from __future__ import annotations

from heitang_kb_forge.audit.architecture_gap import architecture_gap_audit_report


_CAPABILITY_ALIASES = {
    "claim extraction from a KB package": "claim_extraction",
    "claim-level evidence mapping": "claim_evidence_mapping",
    "external source retrieval for verification": "claim_verification",
    "source cross-checking": "external_source_cross_check",
    "contradiction detection": "contradiction_detection",
    "freshness verification": "freshness_verification",
    "knowledge accuracy scoring": "knowledge_accuracy_scoring",
    "verification retrieval trace": "verification_retrieval_trace",
    "claim verification report": "claim_verification_report",
    "user-facing explanation of claim trust status": "claim_trust_explanation",
    "local PDF to Markdown preprocessing": "local_pdf_to_markdown",
    "token cost reduction report": "pdf_token_reduction",
    "parser backend selection": "parser_backend_selection",
    "scanned PDF detection": "scanned_pdf_detection",
    "OCR backend routing": "ocr_backend_routing",
    "complex layout parser routing": "complex_layout_parsing",
    "parser confidence report": "parser_confidence_report",
    "no-cloud-upload guarantee": "no_cloud_upload_guarantee",
}


def capability_gap_map() -> dict:
    audit = architecture_gap_audit_report()
    capabilities = [_map_item(item) for item in audit["gap_items"]]
    return {
        "capability_gap_map_version": audit["audit_version"],
        "generated_at": audit["generated_at"],
        "network_required_for_tests": False,
        "capabilities": capabilities,
        "target_version_mapping": audit["next_version_recommendations"],
        "s_level_capabilities": [
            "claim_verification",
            "external_source_cross_check",
            "contradiction_detection",
            "freshness_verification",
            "knowledge_accuracy_scoring",
            "verification_retrieval_trace",
        ],
    }


def _map_item(item: dict) -> dict:
    capability = _CAPABILITY_ALIASES.get(item["capability"], _slug(item["capability"]))
    return {
        "capability": capability,
        "display_name": item["capability"],
        "category": item["category"],
        "status": item["status"],
        "current_files": item["evidence_files"],
        "current_tests": item["evidence_tests"],
        "missing_tests": _missing_tests(item),
        "target_version": item["target_version"],
        "priority": item["risk_level"],
        "implementation_notes": item["recommended_fix"],
        "benchmark_reference": _benchmark_reference(capability, item),
        "deterministic_local_implementation_path": item["deterministic_local_implementation_path"],
        "optional_llm_assisted_enhancement_path": item["optional_llm_assisted_enhancement_path"],
        "offline_fallback": item["offline_fallback"],
        "tests_require_real_llm_api_network": item["tests_require_real_llm_api_network"],
        "llm_dependency_policy": item["llm_dependency_policy"],
        "affects_core_contract": item["affects_core_contract"],
        "affects_ui": item["affects_ui"],
        "affects_golden_demo": item["affects_golden_demo"],
    }


def _slug(value: str) -> str:
    return (
        value.lower()
        .replace("/", "_")
        .replace("-", "_")
        .replace(" ", "_")
        .replace("__", "_")
        .strip("_")
    )


def _missing_tests(item: dict) -> list[str]:
    if item["status"] == "exists" and item["evidence_tests"]:
        return []
    return [f"tests for {item['capability']} in {item['target_version']}"]


def _benchmark_reference(capability: str, item: dict) -> list[str]:
    if capability in {
        "query_rewrite",
        "query_expansion",
        "multi_query_generation",
        "retrieval_planning",
        "multi_query_recall",
        "rerank",
        "retrieval_evaluation",
    }:
        return ["LangChain", "LlamaIndex", "Haystack"]
    if capability in {
        "claim_extraction",
        "claim_verification",
        "external_source_cross_check",
        "contradiction_detection",
        "freshness_verification",
        "knowledge_accuracy_scoring",
        "verification_retrieval_trace",
    }:
        return ["RAGAS", "TruLens", "FActScore", "FEVER-style fact verification"]
    if "memory" in capability:
        return ["agentmemory", "rtk", "LangGraph"]
    if capability in {
        "local_pdf_to_markdown",
        "pdf_token_reduction",
        "parser_backend_selection",
        "scanned_pdf_detection",
        "ocr_backend_routing",
        "complex_layout_parsing",
        "parser_confidence_report",
        "no_cloud_upload_guarantee",
    }:
        return ["LiteDoc", "PaddleOCR", "MinerU", "Marker", "Docling"]
    if "workbench" in item["category"].lower():
        return ["Continue", "AutoGen"]
    return []
