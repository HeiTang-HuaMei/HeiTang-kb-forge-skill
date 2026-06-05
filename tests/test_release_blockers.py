import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_release_blockers_detects_critical_boundary_blocker(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "release_blockers"
    workspace.mkdir()
    (workspace / "manifest.json").write_text("{}", encoding="utf-8")
    (workspace / "xhs.md").write_text("XHS upload package.", encoding="utf-8")

    result = CliRunner().invoke(app, ["release-blockers", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "release_blockers.json").read_text(encoding="utf-8"))
    assert payload["critical_count"] >= 1
    assert payload["release_ready"] is False
    assert (output / "release_blocker_findings.jsonl").exists()

