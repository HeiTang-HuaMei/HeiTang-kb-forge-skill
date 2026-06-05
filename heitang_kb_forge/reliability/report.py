from heitang_kb_forge.schemas.reliability_schema import ReliabilityScore


def render_reliability_report(score: ReliabilityScore) -> str:
    rows = "\n".join(f"| {key} | {value} |" for key, value in score.scores.items())
    warnings = "\n".join(f"- {item}" for item in score.warnings) or "- None"
    return f"""# Reliability Report

- Overall score: {score.overall_score}
- Status: {score.status}
- Release ready: {score.release_ready}

| Dimension | Score |
| --- | --- |
{rows}

## Warnings

{warnings}
"""
