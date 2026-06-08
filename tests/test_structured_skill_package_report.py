from tests.structured_skill_helpers import make_structured_skill, read_json


def test_structured_skill_package_report_requires_real_structure(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    report = read_json(skill / "structured_skill_package_report.json")

    assert report["status"] == "pass"
    assert report["required_files_present"] is True
    assert report["missing_required_files"] == []
    assert report["structured_directories"]["skills"] is True
    assert (skill / "BOOK_OVERVIEW.md").exists()
    assert (skill / "INDEX.md").exists()
