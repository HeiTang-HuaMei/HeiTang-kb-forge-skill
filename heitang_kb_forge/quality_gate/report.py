from heitang_kb_forge.schemas.quality_gate_schema import QualityGateFinding, QualityGateResult


def render_quality_gate_report(result: QualityGateResult) -> str:
    gates = "\n".join(f"| {name} | {status} |" for name, status in result.gates.items())
    blockers = "\n".join(f"- {item}" for item in result.blockers) or "- None"
    warnings = "\n".join(f"- {item}" for item in result.warnings) or "- None"
    recommendations = "\n".join(f"- {item}" for item in result.recommendations) or "- None"
    return f"""# Release Quality Gate Report

## Summary

- Status: {result.status}
- Release ready: {result.release_ready}
- Overall score: {result.overall_score}

## Gates

| Gate | Status |
| --- | --- |
{gates}

## Blockers

{blockers}

## Warnings

{warnings}

## Recommendations

{recommendations}
"""


def scorecard(result: QualityGateResult) -> dict:
    return {"overall_score": result.overall_score, "release_ready": result.release_ready, "gates": result.gates}


def finding_rows(findings: list[QualityGateFinding]) -> list[dict]:
    return [finding.model_dump(mode="json") for finding in findings]

