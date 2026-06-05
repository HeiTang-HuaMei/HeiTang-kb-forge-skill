from heitang_kb_forge.skill_templates import render_enhanced_skill_template


def test_skill_template_rendering_writes_required_files(tmp_path):
    result = render_enhanced_skill_template(tmp_path, "education_tutor_skill")

    assert result["status"] == "passed"
    assert (tmp_path / "TASKS.md").exists()
    assert (tmp_path / "INPUT_OUTPUT.md").exists()
    assert (tmp_path / "skill_validation_result.json").exists()

