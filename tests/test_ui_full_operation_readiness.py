import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_ui_full_operation_readiness_is_contract_viewer_only():
    report = json.loads((PROOF / "ui_full_operation_readiness_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "needs_review"
    assert report["classification"] == "contract_viewer_only"
    assert report["ui_repo_modified"] is False
    assert report["operations"]["file_selection"] == "not_proven"
    assert report["operations"]["kb_build"] == "contract_only"
    assert "full user-operable local Workbench" in report["must_not_claim"]
