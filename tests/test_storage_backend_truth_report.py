from tests.v4_2_baseline_evidence import load_baseline_report



def test_storage_backend_truth_report_marks_byo_cloud_needs_live_acceptance():
    report = load_baseline_report("storage_backend_truth_report.json")

    assert report["status"] == "needs_review"
    assert report["tests_require_real_llm_api_network"] is False
    assert report["storage_backends"]["local_workspace"] == "implemented_default"
    assert report["storage_backends"]["byo_cloud"] == "implemented_needs_live_acceptance"
    assert report["no_platform_hosted_user_data"] is True
    assert report["destructive_cleanup_default"] is False
