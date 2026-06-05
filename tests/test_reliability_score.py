from heitang_kb_forge.reliability import make_reliability_score
from heitang_kb_forge.workspace.initializer import init_portable_workspace


def test_reliability_score_generates_report(tmp_path):
    workspace = tmp_path / "workspace"
    init_portable_workspace(workspace)

    result, report = make_reliability_score(workspace)

    assert result.overall_score >= 0
    assert result.status in {"pass", "warning", "fail"}
    assert "Reliability Report" in report
    assert (workspace / "reliability_score.json").exists()
    assert (workspace / "reliability_report.md").exists()
