from heitang_kb_forge.pre_v4_p0 import run_security_completion

from tests.p0_helpers import read_json


def test_unsafe_cleanup_prevention_report_keeps_destructive_cleanup_off_by_default(tmp_path):
    (tmp_path / ".gitignore").write_text("_local_acceptance_inputs/\n_local_acceptance_outputs/\n_local_acceptance_config/\n", encoding="utf-8")
    output = tmp_path / "out"

    run_security_completion(tmp_path, output)
    report = read_json(output / "unsafe_cleanup_prevention_report.json")

    assert report["status"] == "pass"
    assert report["destructive_cleanup_default"] is False
    assert report["cleanup_is_recommendation_only"] is True
