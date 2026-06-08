from heitang_kb_forge.pre_v4_p0 import run_security_completion

from tests.p0_helpers import read_json


def test_malicious_skill_import_risk_report_requires_local_review(tmp_path):
    (tmp_path / ".gitignore").write_text("_local_acceptance_inputs/\n_local_acceptance_outputs/\n_local_acceptance_config/\n", encoding="utf-8")
    output = tmp_path / "out"

    run_security_completion(tmp_path, output)
    report = read_json(output / "malicious_skill_import_risk_report.json")

    assert report["status"] == "pass"
    assert "path_traversal" in report["malicious_skill_import_risks"]
    assert report["default_action"] == "local_static_review_before_import"
