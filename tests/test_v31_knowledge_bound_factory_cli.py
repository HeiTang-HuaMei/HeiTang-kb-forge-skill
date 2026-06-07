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


def test_generate_agent_standalone_mode_does_not_require_kb(tmp_path):
    output = tmp_path / "standalone_agent"

    result = CliRunner().invoke(
        app,
        [
            "generate-agent",
            "--mode",
            "standalone",
            "--output",
            str(output),
            "--agent-name",
            "Standalone CLI Agent",
            "--agent-type",
            "planning",
        ],
    )

    assert result.exit_code == 0, result.output
    manifest = _json(output / "agent_manifest.json")
    assert manifest["mode"] == "standalone"
    assert manifest["knowledge_binding"]["enabled"] is False
    assert (output / "capabilities.yaml").exists()
    assert (output / "memory_policy.yaml").exists()
    assert not (output / "retrieval_config.yaml").exists()


def test_generate_agent_kb_bound_mode_requires_package_and_skill(tmp_path):
    result = CliRunner().invoke(app, ["generate-agent", "--mode", "kb_bound", "--output", str(tmp_path / "agent")])

    assert result.exit_code != 0
    assert "--package and --skill" in result.output


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
