from heitang_kb_forge.skill.rules import make_rule_files


def test_skill_rules_include_boundary_and_citation_policy():
    rules = make_rule_files()

    assert "citation_rules.md" in rules
    assert "Do not invent citations" in rules["citation_rules.md"]
    assert "outside" in rules["boundary_rules.md"]
