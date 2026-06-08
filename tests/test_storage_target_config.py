from heitang_kb_forge.pre_v4_p0 import run_storage_completion

from tests.p0_helpers import read_json


def test_storage_target_config_marks_external_targets_explicit_only(tmp_path):
    run_storage_completion(tmp_path)
    report = read_json(tmp_path / "storage_target_config_report.json")

    assert report["status"] == "pass"
    assert report["default_storage_backend"] == "local_workspace"
    assert "local_db" in report["supported_targets"]
    assert "byo_cloud" in report["supported_targets"]
    assert report["external_targets_require_explicit_config"] is True
