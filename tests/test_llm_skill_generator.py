from heitang_kb_forge.llm.provider import ProviderSettings
from heitang_kb_forge.llm.skill_generator import generate_llm_skill_package
from tests.v17_helpers import write_sample_package


def test_llm_skill_generator_mock_marks_llm_assisted(tmp_path):
    package = write_sample_package(tmp_path / "package")
    output = tmp_path / "skill"

    mode, report = generate_llm_skill_package(package, output, "Demo Skill", "generic", ProviderSettings(), True)

    assert mode == "llm_assisted"
    assert report.enabled is True
    assert (output / "llm_skill_generation_report.md").exists()
