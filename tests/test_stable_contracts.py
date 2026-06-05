from heitang_kb_forge.contracts.stable_checker import run_stable_check
from heitang_kb_forge.workspace.initializer import init_portable_workspace


def test_stable_check_includes_extension_readiness(tmp_path):
    workspace = tmp_path / "workspace"
    init_portable_workspace(workspace)

    result, report = run_stable_check(workspace)

    assert result.status in {"pass", "warning"}
    assert "master_skill_learning" in result.extension_readiness
    assert result.extension_readiness["master_skill_learning"] == "not_enabled"
    assert "platform_distribution" in result.extension_readiness
    assert "Extension Readiness" in report
    assert (workspace / "stable_check_result.json").exists()
    assert (workspace / "stable_check_report.md").exists()
