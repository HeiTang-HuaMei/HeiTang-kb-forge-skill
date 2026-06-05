from heitang_kb_forge.schemas.release_readiness_schema import ReleaseReadinessResult


def render_release_readiness_report(result: ReleaseReadinessResult) -> str:
    inputs = "\n".join(f"| {name} | {status} |" for name, status in result.inputs.items())
    blockers = "\n".join(f"- {item}" for item in result.critical_blockers) or "- None"
    warnings = "\n".join(f"- {item}" for item in result.warnings) or "- None"
    actions = "\n".join(f"- {item}" for item in result.next_actions) or "- None"
    return f"""# Release Readiness Report

- Status: {result.status}
- Release ready: {result.release_ready}
- Overall score: {result.overall_score}

## Inputs

| Input | Status |
| --- | --- |
{inputs}

## Critical Blockers

{blockers}

## Warnings

{warnings}

## Next Actions

{actions}
"""


def render_release_readiness_checklist(result: ReleaseReadinessResult) -> str:
    return f"""# Release Readiness Checklist

- [x] Quality gate checked: {result.inputs.get('quality_gate')}
- [x] Release blockers checked: {result.inputs.get('release_blockers')}
- [x] Regression checked: {result.inputs.get('regression')}
- [x] Golden samples checked: {result.inputs.get('golden_samples')}
- [x] Export certification checked: {result.inputs.get('export_certification')}
- [x] Compatibility matrix checked: {result.inputs.get('compatibility_matrix')}
- [ ] v2.6 opt-in LLM live smoke evidence checked when available.
- [ ] Runtime compatibility smoke is reserved for v2.7.
- [ ] Feishu / mobile / installer / iOS are reserved for v2.9.
"""
