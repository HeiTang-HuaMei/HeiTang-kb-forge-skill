from heitang_kb_forge.pre_v4_p0 import run_security_completion


def test_pre_v4_security_completion_requires_ignored_acceptance_paths(tmp_path):
    (tmp_path / ".gitignore").write_text(
        "_local_acceptance_inputs/\n_local_acceptance_outputs/\n_local_acceptance_config/\n",
        encoding="utf-8",
    )

    report = run_security_completion(tmp_path, tmp_path / "out")

    assert report["status"] == "pass"
    assert report["api_key_redaction"] is True
    assert report["local_env_script_ignored"] is True
    assert report["raw_input_ignored"] is True
    assert report["extracted_chunks_ignored"] is True
