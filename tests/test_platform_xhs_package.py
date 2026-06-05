import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_xhs_platform_export_is_mock_only(tmp_path):
    skill = tmp_path / "skill"
    output = tmp_path / "xhs_export"
    skill.mkdir()
    (skill / "SKILL.md").write_text("# XHS Demo Skill", encoding="utf-8")

    result = CliRunner().invoke(app, ["export-platform", "--skill", str(skill), "--output", str(output), "--platform", "xhs"])

    assert result.exit_code == 0, result.output
    assert (output / "xhs_skill_package" / "SKILL.md").exists()
    xhs_manifest = json.loads((output / "xhs_skill_manifest.json").read_text(encoding="utf-8"))
    assert xhs_manifest["real_account_used"] is False
    assert xhs_manifest["automatic_note_publish"] is False
    assert (output / "platform_policy.md").exists()
    assert (output / "violation_risk_checklist.md").exists()

