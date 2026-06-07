from pathlib import Path

from tests.final_audit_helpers import load_json, run_audit


ROOT = Path(__file__).resolve().parents[1]


def test_root_repository_surface_is_documented_by_final_audit(tmp_path):
    output, _ = run_audit(tmp_path)

    report = load_json(output, "repository_surface_audit_report.json")
    records = {item["file"]: item for item in report["records"]}
    assert records["README.md"]["classification"] == "essential_root_file"
    assert records["v38_external_absorption_map.json"]["classification"] == "historical_machine_readable_evidence"
    assert records["v39_external_absorption_map.json"]["classification"] == "historical_machine_readable_evidence"


def test_no_untracked_temp_logs_are_expected_at_root():
    noisy_suffixes = {".log", ".patch", ".zip"}
    noisy = [path.name for path in ROOT.iterdir() if path.is_file() and path.suffix.lower() in noisy_suffixes]
    assert noisy == []
