from heitang_kb_forge.contracts.report import make_contract_report
from heitang_kb_forge.schemas.package_contract_schema import ContractCheckResult


def test_contract_report_renders_status_and_missing_files():
    report = make_contract_report(ContractCheckResult(status="fail", missing_required_files=["manifest.json"]))

    assert "# Contract Check Report" in report
    assert "Status: fail" in report
    assert "manifest.json" in report
