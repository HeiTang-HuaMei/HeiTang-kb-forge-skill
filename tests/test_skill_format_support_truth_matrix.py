from tests.structured_skill_helpers import make_structured_skill, read_json


def test_skill_format_support_truth_matrix_does_not_overclaim_unsupported_formats(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    matrix = read_json(skill / "skill_format_support_truth_matrix.json")
    by_format = {item["format"]: item for item in matrix["formats"]}

    assert matrix["status"] == "pass"
    assert by_format["pdf"]["status"] in {"implemented_tested", "implemented_needs_live_or_optional_dependency"}
    assert by_format["docx"]["status"] == "implemented_tested"
    assert by_format["epub"]["status"] == "implemented_tested"
    assert by_format["rtf"]["status"] == "unsupported_with_reason"
    assert by_format["mobi"]["status"] == "unsupported_with_reason"
    assert by_format["eml"]["status"] == "unsupported_with_reason"
    assert all(item["overclaimed"] is False for item in matrix["formats"])
