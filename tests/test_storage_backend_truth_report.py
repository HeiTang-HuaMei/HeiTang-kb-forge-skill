import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_storage_backend_truth_report_marks_byo_cloud_needs_live_acceptance():
    report = json.loads((PROOF / "storage_backend_truth_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "needs_review"
    assert report["tests_require_real_llm_api_network"] is False
    assert report["storage_backends"]["local_workspace"] == "implemented_default"
    assert report["storage_backends"]["byo_cloud"] == "implemented_needs_live_acceptance"
    assert report["no_platform_hosted_user_data"] is True
    assert report["destructive_cleanup_default"] is False
