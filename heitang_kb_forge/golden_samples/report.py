from heitang_kb_forge.schemas.golden_sample_schema import GoldenSampleValidation


def render_golden_sample_report(result: GoldenSampleValidation) -> str:
    rows = "\n".join(f"| {sample.sample_id} | {sample.status} | {sample.path} |" for sample in result.samples)
    return f"""# Golden Sample Validation Report

- Status: {result.status}
- Samples: {result.sample_count}
- Passed: {result.passed}
- Failed: {result.failed}

| Sample | Status | Path |
| --- | --- | --- |
{rows}
"""

