import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_ui_full_operation_readiness_is_contract_viewer_only():
    report = json.loads((PROOF / "ui_full_operation_readiness_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "blocked"
    assert report["classification"] == "partial_desktop_core_bridge_contract"
    assert report["ui_repo_modified"] is True
    assert report["ui_repo_modified_by_core_audit"] is False
    assert report["ui_worktree_status"] == "dirty_existing_uncommitted_changes"
    assert report["operations"]["file_selection"] == "not_implemented"
    assert report["operations"]["kb_build"] == "bridge_contract_tested_not_page_wired"
    assert report["gate_decision"] == "blocks_v4_if_v4_is_local_workbench_rc"
    assert "full user-operable local Workbench" in report["must_not_claim"]
