from tests.structured_skill_helpers import make_structured_skill, read_json


def test_structured_skill_package_outputs_required_files_and_compact_entrypoint(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    for name in [
        "SKILL.md",
        "skill_manifest.json",
        "skill_index.json",
        "source_inventory.json",
        "evidence_map.json",
        "safety_boundary.md",
        "usage_examples.md",
        "install_instructions.md",
        "extraction_trace.json",
        "skill_quality_report.json",
    ]:
        assert (skill / name).exists(), name
    text = (skill / "SKILL.md").read_text(encoding="utf-8")
    assert len(text) < 12000
    assert "Source loading policy" in text
    assert "Do not load all chapters" in text
    completion = read_json(skill / "structured_skill_package_completion_report.json")
    assert completion["status"] == "pass"
    assert completion["real_structured_skill_package_generated"] is True
