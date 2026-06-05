import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_certify_export_generates_platform_certification(tmp_path):
    skill = tmp_path / "skill"
    export = tmp_path / "export"
    output = tmp_path / "cert"
    skill.mkdir()
    (skill / "SKILL.md").write_text("# Demo Skill", encoding="utf-8")
    export_result = CliRunner().invoke(app, ["export-platform", "--skill", str(skill), "--output", str(export), "--platform", "all"])
    assert export_result.exit_code == 0, export_result.output

    result = CliRunner().invoke(app, ["certify-export", "--export", str(export), "--output", str(output), "--platform", "all"])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "platform_export_certification.json").read_text(encoding="utf-8"))
    assert payload["status"] == "pass"
    assert (output / "platform_certification_findings.jsonl").exists()

