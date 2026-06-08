from heitang_kb_forge.pre_v4_p0 import run_security_completion

from tests.p0_helpers import read_json


def test_secret_redaction_completion_covers_llm_vector_and_storage(tmp_path):
    (tmp_path / ".gitignore").write_text("_local_acceptance_inputs/\n_local_acceptance_outputs/\n_local_acceptance_config/\n", encoding="utf-8")
    output = tmp_path / "out"

    run_security_completion(tmp_path, output)
    report = read_json(output / "secret_redaction_completion_report.json")

    assert report["status"] == "pass"
    assert report["llm_key_redaction"] is True
    assert report["vector_db_credential_redaction"] is True
    assert report["byo_storage_credential_redaction"] is True
    assert report["committed_secret_hits"] == []
