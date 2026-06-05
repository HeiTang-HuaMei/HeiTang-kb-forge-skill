import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_validate_golden_samples_generates_validation(tmp_path):
    root = tmp_path / "golden"
    output = tmp_path / "golden_output"
    for name in [
        "minimal_knowledge_package",
        "knowledge_package",
        "skill_package",
        "derived_skill_package",
        "agent_package",
        "workspace",
        "platform_export_mock",
        "platform_exports",
    ]:
        (root / name).mkdir(parents=True)

    result = CliRunner().invoke(app, ["validate-golden-samples", "--workspace", str(root), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "golden_sample_validation.json").read_text(encoding="utf-8"))
    assert payload["status"] == "pass"
    assert payload["sample_count"] >= 9
    assert (output / "golden_sample_diff.json").exists()
