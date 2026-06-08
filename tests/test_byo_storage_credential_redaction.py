from heitang_kb_forge.pre_v4_p0 import run_storage_completion

from tests.p0_helpers import read_json


def test_byo_storage_credential_redaction_uses_env_references_only(tmp_path):
    run_storage_completion(tmp_path)
    report = read_json(tmp_path / "byo_storage_credential_redaction_report.json")

    assert report["status"] == "pass"
    assert report["credential_values_written"] is False
    assert report["env_reference_only"] is True
