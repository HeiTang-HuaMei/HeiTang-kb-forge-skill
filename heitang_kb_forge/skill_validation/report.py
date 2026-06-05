from heitang_kb_forge.schemas.skill_validation_schema import SkillValidationResult


def render_skill_validation_report(result: SkillValidationResult) -> str:
    score_rows = "\n".join(f"| {key} | {value} |" for key, value in result.scores.items())
    warnings = "\n".join(f"- {warning}" for warning in result.warnings) or "- None"
    errors = "\n".join(f"- {error}" for error in result.errors) or "- None"
    return f"""# Skill Validation Report

- Skill ID: {result.skill_id}
- Status: {result.status}
- Release ready: {result.release_ready}

## Scores

| Dimension | Score |
| --- | --- |
{score_rows}

## Warnings

{warnings}

## Errors

{errors}
"""
