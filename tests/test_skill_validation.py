from heitang_kb_forge.skill.generator import generate_skill_package
from heitang_kb_forge.skill_validation.evaluator import validate_skill_package
from tests.v17_helpers import read_json, write_sample_package


def test_validate_skill_generates_release_ready_result(tmp_path):
    package = write_sample_package(tmp_path / "package")
    skill = tmp_path / "skill"
    output = tmp_path / "validation"
    generate_skill_package(package, skill, "Demo Skill")

    result = validate_skill_package(skill, package, output)

    assert result.release_ready is True
    assert read_json(output / "skill_validation_result.json")["status"] == "pass"
