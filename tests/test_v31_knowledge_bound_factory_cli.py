import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_generate_bound_agent_command_writes_factory_outputs(tmp_path):
    package = _build_package(tmp_path)
    output = tmp_path / "factory"

    result = CliRunner().invoke(
        app,
        [
            "generate-bound-agent",
            "--package",
            str(package),
            "--output",
            str(output),
            "--skill-name",
            "Bound CLI Skill",
            "--agent-name",
            "Bound CLI Agent",
            "--allow-untrusted",
        ],
    )

    assert result.exit_code == 0, result.output
    assert (output / "skill_package" / "SKILL.md").exists()
    assert (output / "agent_package" / "soul.md").exists()
    assert _json(output / "knowledge_bound_factory_manifest.json")["agent_name"] == "Bound CLI Agent"


def _build_package(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "package"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Reviewed v3.1 knowledge-bound factory evidence.", encoding="utf-8")
    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--parser-backend",
            "builtin",
            "--allow-untrusted",
        ],
    )
    assert result.exit_code == 0, result.output
    return output_dir


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
