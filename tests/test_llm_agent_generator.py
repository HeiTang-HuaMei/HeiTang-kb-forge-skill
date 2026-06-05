from heitang_kb_forge.llm.agent_package_generator import generate_llm_agent_package
from heitang_kb_forge.llm.provider import ProviderSettings
from heitang_kb_forge.skill.generator import generate_skill_package
from tests.v17_helpers import write_sample_package


def test_llm_agent_generator_fallback_without_openai_config(tmp_path):
    package = write_sample_package(tmp_path / "package")
    skill = tmp_path / "skill"
    output = tmp_path / "agent"
    generate_skill_package(package, skill, "Demo Skill")

    mode, report = generate_llm_agent_package(
        package,
        skill,
        output,
        "Demo Agent",
        "generic",
        ProviderSettings(provider="openai_compatible", model="test"),
        True,
    )

    assert mode == "hybrid"
    assert report.fallback is True
    assert "llm_agent_generation_report.md" in [path.name for path in output.iterdir()]
