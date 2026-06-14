from tests.v4_2_baseline_evidence import load_baseline_report



def test_ui_full_operation_after_core_p0_records_validation_and_blocker():
    report = load_baseline_report("ui_full_operation_acceptance_after_core_p0.json")

    assert report["status"] == "blocked"
    assert report["classification"] == "partial_desktop_core_bridge_contract"
    assert report["ui_repo_modified"] is True
    assert report["ui_repo_modified_by_core_audit"] is False
    assert report["ui_worktree_status"] == "dirty_existing_uncommitted_changes"
    assert report["ui_validation_scope"] == "current_dirty_worktree_contract_viewer_and_desktop_core_bridge_contract"
    assert report["validation"]["flutter_analyze"] == "pass"
    assert report["validation"]["flutter_test"] == "pass"
    assert report["validation"]["flutter_build_web"] == "pass"
    assert report["validation"]["flutter_build_windows"] == "pass"
    assert report["validation"]["ui_contract_tests"] == "pass"
    assert report["validation"]["core_bridge_tests"] == "pass"
    assert report["operations"]["kb_build"] == "bridge_contract_tested_not_page_wired"
    assert report["operations"]["llm_api_provider_settings"] == "not_implemented"
    assert report["p1_blockers"][0]["id"] == "ui_page_workflows_not_wired_to_core_bridge"
    assert report["p1_blockers"][0]["blocks_v4_if_v4_is_local_workbench_rc"] is True
    assert "full user-operable local Workbench" in report["must_not_claim"]
    assert report["worktree_evidence"]["core_audit_modified_ui_source"] is False


def test_existing_ui_readiness_report_is_not_misleading_after_ui_validation():
    report = load_baseline_report("ui_full_operation_readiness_report.json")

    assert report["status"] == "blocked"
    assert report["validation"]["flutter_analyze"] == "pass"
    assert report["classification"] == "partial_desktop_core_bridge_contract"
    assert report["gate_decision"] == "blocks_v4_if_v4_is_local_workbench_rc"
    assert report["ui_repo_modified_by_core_audit"] is False
