import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from tests.p0_helpers import make_p0_package


def _read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def test_book_to_skill_cli_generates_structured_package_from_existing_kb(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "book_skill"

    result = CliRunner().invoke(
        app,
        [
            "book-to-skill",
            "--package",
            str(package),
            "--output",
            str(output),
            "--skill-name",
            "Structured Demo Skill",
            "--target",
            "codex",
        ],
    )

    assert result.exit_code == 0, result.output
    assert (output / "SKILL.md").exists()
    assert (output / "on_demand_load_manifest.json").exists()
    assert (output / "skill_agent_kb_compatibility_report.json").exists()
    assert "Validation: pass" in result.output


def test_book_to_skill_cli_generates_structured_package_from_readme_input(tmp_path):
    readme = tmp_path / "README.md"
    readme.write_text(
        "# README Operations Playbook\n\n"
        "## Principles\n\n"
        "Use local evidence, keep scope narrow, and cite generated chunks.\n\n"
        "## Workflow\n\n"
        "1. Ingest the README.\n"
        "2. Generate a standard Skill.\n"
        "3. Validate installability and governance evidence.\n",
        encoding="utf-8",
    )
    output = tmp_path / "readme_skill"

    result = CliRunner().invoke(
        app,
        [
            "book-to-skill",
            "--input",
            str(readme),
            "--output",
            str(output),
            "--skill-name",
            "README Operations Skill",
            "--target",
            "codex",
        ],
    )

    knowledge_package = output / "knowledge_package"
    skill_package = output / "skill_package"
    validation_output = output / "skill_validation"

    assert result.exit_code == 0, result.output
    assert (knowledge_package / "manifest.json").exists()
    assert (knowledge_package / "chunks.jsonl").exists()
    assert (skill_package / "SKILL.md").exists()
    assert (skill_package / "skill_installability_report.json").exists()
    assert (skill_package / "skill_governance_report.json").exists()
    assert (validation_output / "structured_skill_validation_result.json").exists()

    governance = _read_json(skill_package / "skill_governance_report.json")
    assert governance["status"] == "pass"
    assert governance["checks"]["generation"]["status"] == "pass"
    assert governance["checks"]["validation"]["status"] == "pass"
    assert governance["checks"]["installability"]["status"] == "pass"
    assert governance["ui_contract"]["ready_for_workbench_display"] is True
    assert governance["tests_require_real_llm_api_network"] is False
    assert "diff_baseline_not_provided" in governance["warnings"]
    assert "Validation: pass" in result.output


def test_book_to_skill_cli_requires_input_or_package(tmp_path):
    result = CliRunner().invoke(app, ["book-to-skill", "--output", str(tmp_path / "out")])

    assert result.exit_code != 0
    assert "--input or --package is required" in result.output
