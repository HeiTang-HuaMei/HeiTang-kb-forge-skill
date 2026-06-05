from pathlib import Path

from heitang_kb_forge.regression.baseline import REGRESSION_BASELINE
from heitang_kb_forge.schemas.regression_schema import RegressionCase


def make_regression_cases(repo_root: Path) -> list[RegressionCase]:
    cases = []
    for version, capability, evidence in REGRESSION_BASELINE:
        status = "pass" if (repo_root / evidence).exists() else "fail"
        cases.append(RegressionCase(version=version, capability=capability, status=status, evidence=evidence))
    return cases

