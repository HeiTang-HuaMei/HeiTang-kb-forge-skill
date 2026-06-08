from heitang_kb_forge.pre_v4_p0 import run_security_completion

from tests.p0_helpers import read_json


def test_path_traversal_safety_report_records_workspace_checks(tmp_path):
    (tmp_path / ".gitignore").write_text("_local_acceptance_inputs/\n_local_acceptance_outputs/\n_local_acceptance_config/\n", encoding="utf-8")
    output = tmp_path / "out"

    run_security_completion(tmp_path, output)
    report = read_json(output / "path_traversal_safety_report.json")

    assert report["status"] == "pass"
    assert all(item["status"] == "pass" for item in report["checks"])
