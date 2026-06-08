from heitang_kb_forge.audit.architecture_gap import architecture_gap_audit_report


def _report() -> dict:
    return architecture_gap_audit_report()


def test_architecture_gap_audit_report_parses_and_has_required_shape():
    report = _report()

    assert report["audit_version"] == "3.6.0-alpha.1"
    assert report["current_core_commit"] == "cdfbb0e"
    assert report["ui_repo_dependency"] is False
    assert report["categories"]
    assert report["gap_items"]
    assert {"P0", "P1", "P2"} == set(report["risk_summary"])


def test_every_gap_item_has_status_risk_and_target_version():
    valid_status = {"exists", "partial", "missing", "unknown"}
    valid_risk = {"P0", "P1", "P2"}
    valid_versions = {"v3.7", "v3.8", "v3.9", "v3.10", "v3.11", "v3.12", "v4.0", "v4.3"}

    for item in _report()["gap_items"]:
        assert item["status"] in valid_status
        assert item["risk_level"] in valid_risk
        assert item["target_version"] in valid_versions
        assert isinstance(item["evidence_files"], list)
        assert isinstance(item["evidence_tests"], list)
        assert "recommended_fix" in item
        assert "user_impact" in item
        assert "affects_core_contract" in item
        assert "affects_ui" in item
        assert "affects_golden_demo" in item
        assert item["deterministic_local_implementation_path"]
        assert item["optional_llm_assisted_enhancement_path"]
        assert item["offline_fallback"]
        assert item["tests_require_real_llm_api_network"] is False
        assert "optional assistive layer" in item["llm_dependency_policy"]


def test_query_rewrite_rerank_and_multi_query_are_not_overclaimed():
    items = {item["capability"]: item for item in _report()["gap_items"]}

    assert items["Query Rewrite"]["status"] in {"missing", "partial"}
    assert items["Query Rewrite"]["target_version"] == "v3.7"
    assert items["Rerank"]["status"] in {"missing", "partial"}
    assert items["Rerank"]["target_version"] == "v3.8"
    assert items["Multi-query Generation"]["status"] in {"missing", "partial"}
    assert items["Multi-query Recall"]["status"] in {"missing", "partial"}


def test_external_retrieval_accuracy_verification_category_exists():
    report = _report()
    categories = {category["name"] for category in report["categories"]}
    items = {
        item["capability"]: item
        for item in report["gap_items"]
        if item["category"] == "External Retrieval for Knowledge Accuracy Verification"
    }

    assert "External Retrieval for Knowledge Accuracy Verification" in categories
    assert items["external source retrieval for verification"]["risk_level"] == "P0"
    assert items["external source retrieval for verification"]["target_version"] == "v3.8"
    assert items["contradiction detection"]["status"] == "missing"
    assert items["verification retrieval trace"]["target_version"] == "v3.8"
    assert items["outdated knowledge detection"]["target_version"] == "v4.3"


def test_local_document_parsing_and_pdf_token_reduction_category_exists():
    report = _report()
    categories = {category["name"] for category in report["categories"]}
    items = {
        item["capability"]: item
        for item in report["gap_items"]
        if item["category"] == "Local Document Parsing & PDF Token Reduction"
    }

    assert "Local Document Parsing & PDF Token Reduction" in categories
    assert items["local PDF to Markdown preprocessing"]["status"] in {"missing", "partial"}
    assert items["local PDF to Markdown preprocessing"]["target_version"] == "v3.9"
    assert items["OCR backend routing"]["status"] in {"partial", "exists"}
    assert items["complex layout parser routing"]["status"] in {"partial", "missing"}
    assert items["token cost reduction report"]["target_version"] == "v3.9"
    assert items["no-cloud-upload guarantee"]["status"] == "exists"


def test_v37_mapping_distinguishes_answer_retrieval_from_validation_retrieval():
    report = _report()

    assert report["next_version_recommendations"]["v3.7"] == "Query Rewrite & Retrieval Planning"
    assert any("validation retrieval" in blocker or "verification" in blocker for blocker in report["blockers_before_v3_7"])
