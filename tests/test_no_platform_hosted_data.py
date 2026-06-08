from heitang_kb_forge.pre_v4_p0 import run_storage_completion

from tests.p0_helpers import read_json


def test_no_platform_hosted_data_report_blocks_saas_default_claim(tmp_path):
    run_storage_completion(tmp_path)
    report = read_json(tmp_path / "no_platform_hosted_data_report.json")

    assert report["status"] == "pass"
    assert report["platform_hosted_user_data_default"] is False
    assert report["no_saas"] is True
