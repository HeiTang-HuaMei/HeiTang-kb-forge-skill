from tests.multi_source_helpers import make_multi_source_run, read_json


def test_opencli_bridge_import_is_local_user_responsibility_boundary(tmp_path):
    output = make_multi_source_run(tmp_path)

    report = read_json(output / "opencli_bridge_import_report.json")

    assert report["status"] == "pass"
    assert report["ingestion_mode"] == "opencli_bridge"
    assert report["opencli_is_optional_external_user_chosen_bridge"] is True
    assert report["heitang_controls_platform_login_or_scraping"] is False
    assert report["imports_local_files_or_manifests_only"] is True
    assert report["compliance_status"] == "user_responsibility_required"
    assert report["hidden_scraping_implemented"] is False
    assert report["forbidden_cookie_session_token_keys"] == []
