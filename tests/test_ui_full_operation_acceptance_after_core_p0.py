import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_ui_full_operation_after_core_p0_records_validation_and_blocker():
    report = json.loads((PROOF / "ui_full_operation_acceptance_after_core_p0.json").read_text(encoding="utf-8"))

    assert report["status"] == "blocked"
    assert report["classification"] == "contract_viewer_only"
    assert report["ui_repo_modified"] is False
    assert report["validation"]["flutter_analyze"] == "pass"
    assert report["validation"]["flutter_test"] == "pass"
    assert report["validation"]["flutter_build_web"] == "pass"
    assert report["validation"]["flutter_build_windows"] == "pass"
    assert report["validation"]["ui_contract_tests"] == "pass"
    assert report["operations"]["kb_build"] == "contract_only_no_core_execution"
    assert report["operations"]["llm_api_provider_settings"] == "not_implemented"
    assert report["p1_blockers"][0]["id"] == "ui_full_operation_not_implemented"
    assert report["p1_blockers"][0]["blocks_v4_if_v4_is_local_workbench_rc"] is True
    assert "full user-operable local Workbench" in report["must_not_claim"]


def test_existing_ui_readiness_report_is_not_misleading_after_ui_validation():
    report = json.loads((PROOF / "ui_full_operation_readiness_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "blocked"
    assert report["validation"]["flutter_analyze"] == "pass"
    assert report["gate_decision"] == "blocks_v4_if_v4_is_local_workbench_rc"
