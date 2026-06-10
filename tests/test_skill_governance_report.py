from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.skill import run_skill_governance_report
from tests.structured_skill_helpers import make_structured_skill, read_json


def test_skill_governance_report_summarizes_structured_skill_evidence(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    report = run_skill_governance_report(skill)

    assert report["status"] == "pass"
    assert report["checks"]["generation"]["status"] == "pass"
    assert report["checks"]["validation"]["status"] == "pass"
    assert report["checks"]["installability"]["status"] == "pass"
    assert report["checks"]["privacy_boundary"]["status"] == "pass"
    assert report["checks"]["kb_agent_compatibility"]["status"] == "pass"
    assert report["checks"]["diff_comparison"]["status"] == "not_run"
    assert "diff_baseline_not_provided" in report["warnings"]
    assert (skill / "skill_governance_report.json").exists()
    assert (skill / "skill_governance_report.md").exists()


def test_skill_governance_report_cli_accepts_diff_baseline(tmp_path):
    old_root = tmp_path / "old"
    new_root = tmp_path / "new"
    old_root.mkdir()
    new_root.mkdir()
    _, old_skill = make_structured_skill(old_root)
    _, new_skill = make_structured_skill(new_root)
    (new_skill / "cheatsheet.md").write_text("# Cheatsheet\n\n- changed\n", encoding="utf-8")
    output = tmp_path / "governance"

    result = CliRunner().invoke(
        app,
        [
            "skill-governance-report",
            "--skill",
            str(new_skill),
            "--old-skill",
            str(old_skill),
            "--output",
            str(output),
        ],
    )

    assert result.exit_code == 0, result.output
    report = read_json(output / "skill_governance_report.json")
    assert report["checks"]["diff_comparison"]["status"] == "pass"
    assert report["checks"]["diff_comparison"]["changed_file_count"] >= 1
    assert report["release_ready"] is True
    assert "Status: pass" in result.output
