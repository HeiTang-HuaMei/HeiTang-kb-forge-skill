from heitang_kb_forge.pre_v4_p0 import run_storage_completion

from tests.p0_helpers import read_json


def test_no_hidden_upload_runtime_report_has_no_upload_paths(tmp_path):
    run_storage_completion(tmp_path)
    report = read_json(tmp_path / "no_hidden_upload_runtime_report.json")

    assert report["status"] == "pass"
    assert report["hidden_upload_runtime_paths"] == []
    assert report["network_disabled_by_default"] is True
