from heitang_kb_forge.schemas.regression_schema import RegressionCase, RegressionResult


def render_regression_report(result: RegressionResult, cases: list[RegressionCase]) -> str:
    rows = "\n".join(f"| {case.version} | {case.capability} | {case.status} | {case.evidence} |" for case in cases)
    return f"""# Regression Check Report

- Status: {result.status}
- Covered versions: {', '.join(result.covered_versions)}
- Cases: {result.case_count}
- Failed: {result.failed_count}
- Warnings: {result.warning_count}

| Version | Capability | Status | Evidence |
| --- | --- | --- | --- |
{rows}
"""

