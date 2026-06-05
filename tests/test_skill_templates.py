from heitang_kb_forge.skill_templates.catalog import SUPPORTED_SKILL_TYPES, get_template


def test_skill_template_catalog_contains_required_types():
    assert "qa_skill" in SUPPORTED_SKILL_TYPES
    assert "xiaohongshu_content_skill" in SUPPORTED_SKILL_TYPES
    assert get_template("product_manager_skill").skill_type == "product_manager_skill"

