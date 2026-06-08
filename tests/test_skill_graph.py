from tests.structured_skill_helpers import make_structured_skill, read_json


def test_skill_graph_has_required_relation_types(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    graph = read_json(skill / "skill_graph.json")
    report = read_json(skill / "skill_graph_report.json")

    assert graph["status"] == "pass"
    assert graph["dependency"]
    assert graph["contrast"]
    assert graph["composition"]
    assert graph["conflict"]
    assert report["relation_types"]["dependency"] >= 1
