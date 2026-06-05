from heitang_kb_forge.skill_templates.validator import validate_enhanced_skill


def test_skill_template_validation_reports_missing_files(tmp_path):
    result = validate_enhanced_skill(tmp_path, "qa_skill")

    assert result["status"] == "failed"
    assert "TASKS.md" in result["missing_files"]

