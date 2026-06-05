from heitang_kb_forge.agent_package.profile import make_agent_profile
from heitang_kb_forge.skill.generator import generate_skill_package
from tests.v17_helpers import write_sample_package


def test_agent_profile_references_skill_and_package(tmp_path):
    package = write_sample_package(tmp_path / "package")
    skill = tmp_path / "skill"
    generate_skill_package(package, skill, "Demo Skill")

    profile = make_agent_profile(package, skill, "Demo Agent", "generic")

    assert profile.source_skill_id == "demo-skill"
    assert profile.source_package_id == "package"
