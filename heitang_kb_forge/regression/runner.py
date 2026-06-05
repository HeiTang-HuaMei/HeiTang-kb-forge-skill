from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.regression.comparator import make_regression_cases
from heitang_kb_forge.regression.report import render_regression_report
from heitang_kb_forge.schemas.regression_schema import RegressionResult


def run_regression_check(workspace: Path, output: Path, repo_root: Path | None = None) -> RegressionResult:
    output.mkdir(parents=True, exist_ok=True)
    root = repo_root or Path.cwd()
    cases = make_regression_cases(root)
    failed = [case for case in cases if case.status == "fail"]
    result = RegressionResult(
        status="fail" if failed else "pass",
        covered_versions=sorted({case.version for case in cases}),
        case_count=len(cases),
        failed_count=len(failed),
        warning_count=0,
    )
    write_json(output / "regression_result.json", result)
    write_jsonl(output / "regression_cases.jsonl", [case.model_dump(mode="json") for case in cases])
    write_jsonl(output / "regression_failures.jsonl", [case.model_dump(mode="json") for case in failed])
    (output / "regression_report.md").write_text(render_regression_report(result, cases), encoding="utf-8")
    return result

