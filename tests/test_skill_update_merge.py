from heitang_kb_forge.skill import diff_structured_skill_packages, generate_skill_package
from tests.p0_helpers import make_p0_package
from tests.structured_skill_helpers import read_json


def test_skill_update_preserves_manual_notes_when_explicitly_requested(tmp_path):
    package = make_p0_package(tmp_path)
    old_skill = tmp_path / "old_skill"
    (old_skill).mkdir()
    (old_skill / "manual_notes.md").write_text("Keep this reviewer note.", encoding="utf-8")
    new_skill = tmp_path / "new_skill"

    generate_skill_package(
        package,
        new_skill,
        "Structured Demo Skill",
        update_existing=old_skill,
        preserve_manual_edits=True,
    )

    report = read_json(new_skill / "skill_update_merge_report.json")
    assert report["manual_custom_notes_preserved"] is True
    assert (new_skill / "manual_notes.md").read_text(encoding="utf-8") == "Keep this reviewer note."


def test_diff_skill_package_reports_stale_changes(tmp_path):
    package = make_p0_package(tmp_path)
    old_skill = tmp_path / "old_skill"
    new_skill = tmp_path / "new_skill"
    generate_skill_package(package, old_skill, "Structured Demo Skill")
    generate_skill_package(package, new_skill, "Structured Demo Skill")
    (new_skill / "concepts" / "core_concepts.md").write_text("# Core Concepts\n\n- changed\n", encoding="utf-8")

    result = diff_structured_skill_packages(old_skill, new_skill, tmp_path / "diff")

    assert result["status"] == "pass"
    assert "concepts/core_concepts.md" in result["changed_files"]
    assert result["stale_skill_detection"] is True
