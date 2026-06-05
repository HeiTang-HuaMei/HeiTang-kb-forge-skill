from heitang_kb_forge.agent_package.generator import generate_agent_package
from heitang_kb_forge.skill.generator import generate_skill_package
from tests.v17_helpers import write_sample_package


def test_agent_package_generator_writes_soul_and_prompt(tmp_path):
    package = write_sample_package(tmp_path / "package")
    skill = tmp_path / "skill"
    output = tmp_path / "agent"
    generate_skill_package(package, skill, "Demo Skill")

    result = generate_agent_package(package, skill, output, "Demo Agent")

    assert result["agent_name"] == "Demo Agent"
    assert (output / "soul.md").exists()
    assert (output / "system_prompt.md").exists()
