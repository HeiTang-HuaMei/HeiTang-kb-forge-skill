import json

import pytest

from heitang_kb_forge.skill_reverse_fusion import reverse_and_fuse_skills


def test_reverse_and_fuse_skills_writes_profiles_plan_and_fused_skill(tmp_path):
    first = _skill(tmp_path, "first", "Use this skill to answer pricing questions with evidence.")
    second = _skill(tmp_path, "second", "Use this skill to retrieve renewal evidence.")
    output = tmp_path / "fusion"

    result = reverse_and_fuse_skills([first, second], output, "Commercial Fused Skill")

    assert result["status"] == "pass"
    assert (output / "fused_skill" / "SKILL.md").exists()
    assert _json(output / "skill_fusion_plan.json")["source_skill_count"] == 2
    assert _json(output / "skill_reverse_fusion_quality_report.json")["review_required"] is True
    assert (output / "skill_reverse_fusion_report.md").exists()


def test_reverse_and_fuse_skills_requires_skill_md(tmp_path):
    skill = tmp_path / "broken"
    skill.mkdir()

    with pytest.raises(FileNotFoundError):
        reverse_and_fuse_skills([skill], tmp_path / "fusion")


def _skill(tmp_path, name, body):
    skill = tmp_path / name
    skill.mkdir()
    (skill / "SKILL.md").write_text(f"# {name}\n\n{body}\n", encoding="utf-8")
    (skill / "boundary_rules.md").write_text("Do not answer outside evidence scope.\n", encoding="utf-8")
    (skill / "evidence_policy.md").write_text("Use citation and source evidence.\n", encoding="utf-8")
    return skill


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
