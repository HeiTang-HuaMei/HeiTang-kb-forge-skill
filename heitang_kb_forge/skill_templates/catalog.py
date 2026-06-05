from heitang_kb_forge.schemas.skill_template_schema import SkillTemplate

SUPPORTED_SKILL_TYPES = [
    "qa_skill",
    "content_skill",
    "product_manager_skill",
    "shopping_guide_skill",
    "education_tutor_skill",
    "novel_writing_skill",
    "customer_service_skill",
    "enterprise_kb_skill",
    "xiaohongshu_content_skill",
    "longform_writing_skill",
    "official_account_writing_skill",
]


def get_template(skill_type: str) -> SkillTemplate:
    normalized = skill_type if skill_type in SUPPORTED_SKILL_TYPES else "qa_skill"
    title = normalized.replace("_", " ").title()
    return SkillTemplate(
        skill_type=normalized,
        title=title,
        tasks=[
            "Answer using the provided knowledge package.",
            "Preserve citations and evidence boundaries.",
            "Refuse unsupported requests clearly.",
        ],
        inputs=["User question", "Knowledge package files", "Optional domain context"],
        outputs=["Grounded answer", "Citation list", "Boundary note when needed"],
        failure_modes=["Missing evidence", "Out-of-scope question", "Conflicting source content"],
    )
