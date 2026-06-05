def render_validation_report(result: dict) -> str:
    return (
        "# Enhanced Skill Template Validation\n\n"
        f"- Skill type: {result.get('skill_type')}\n"
        f"- Status: {result.get('status')}\n"
        f"- Missing files: {', '.join(result.get('missing_files', [])) or 'None'}\n"
    )
