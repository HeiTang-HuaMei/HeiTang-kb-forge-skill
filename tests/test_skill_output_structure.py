from tests.structured_skill_helpers import make_structured_skill, read_json


def test_skill_output_structure_has_loadable_directories(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    report = read_json(skill / "skill_output_structure_report.json")

    assert report["status"] == "pass"
    assert report["required_files_present"] is True
    for dirname in ["chapters", "concepts", "frameworks", "techniques", "patterns", "anti_patterns"]:
        assert report["structured_directories"][dirname] is True
        assert any((skill / dirname).iterdir())
