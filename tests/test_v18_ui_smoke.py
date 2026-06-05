from heitang_kb_forge.skill.generator import generate_skill_package
from heitang_kb_forge.skill_validation.evaluator import validate_skill_package
from heitang_kb_forge.agent_package.generator import generate_agent_package
from heitang_kb_forge.web.app import load_package_summary
from tests.v17_helpers import write_sample_package


def test_web_summary_loads_v18_skill_and_agent_files(tmp_path):
    package = write_sample_package(tmp_path / "package")
    skill = package / "skill_package"
    validation = package / "skill_validation"
    agent = package / "agent_package"
    generate_skill_package(package, skill, "Demo Skill")
    validate_skill_package(skill, package, validation)
    generate_agent_package(package, skill, agent, "Demo Agent")

    summary = load_package_summary(package)

    assert "skill_package/SKILL.md" in summary
    assert "skill_validation/skill_validation_report.md" in summary
    assert "agent_package/soul.md" in summary
