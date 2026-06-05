import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_generate_skill_enhanced_template_outputs_files(tmp_path):
    package = tmp_path / "package"
    output = tmp_path / "skill"
    package.mkdir()

    result = CliRunner().invoke(app, ["generate-skill", "--package", str(package), "--output", str(output), "--skill-type", "qa_skill", "--enhanced-skill-template"])

    assert result.exit_code == 0, result.output
    for file_name in ["TASKS.md", "INPUT_OUTPUT.md", "FAILURE_MODES.md", "SAFE_REFUSAL.md", "EVIDENCE_USAGE.md", "OPERATION_GUIDE.md", "RELEASE_CHECKLIST.md"]:
        assert (output / file_name).exists()
    assert json.loads((output / "skill_validation_result.json").read_text(encoding="utf-8"))["status"] == "passed"

