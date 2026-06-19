import json
import subprocess

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def _write_release_workspace_contract(workspace):
    docs = workspace / "docs"
    docs.mkdir()
    governance = docs / "治理"
    governance.mkdir()
    workflows = workspace / ".github" / "workflows"
    workflows.mkdir(parents=True)
    (workspace / "pyproject.toml").write_text('version = "4.2.0"\n', encoding="utf-8")
    (workspace / "skill.json").write_text('{"version":"4.2.0"}', encoding="utf-8")
    (workspace / "README.md").write_text("HeiTang Knowledge Workbench\nv4.2.0\n", encoding="utf-8")
    (workspace / "README.zh-CN.md").write_text("HeiTang Knowledge Workbench\nv4.2.0\n", encoding="utf-8")
    (governance / "目标验收矩阵.md").write_text("v4.2 public main capability baseline\n", encoding="utf-8")
    (governance / "Campaign_1_3_能力矩阵.md").write_text("v4.2 Core capability matrix\n", encoding="utf-8")
    (governance / "历史版本说明.md").write_text("v4.2.0 current Core package version\n", encoding="utf-8")
    (docs / "发布流程.md").write_text("v4.2 release process\n", encoding="utf-8")
    (docs / "测试与验收.md").write_text("v4.2 acceptance checks\n", encoding="utf-8")
    (workflows / "ci.yml").write_text("name: CI\n", encoding="utf-8")
    (workflows / "release-check.yml").write_text("name: Release Check\n", encoding="utf-8")


def _write_passing_release_inputs(output):
    for name in [
        "quality_gate_result.json",
        "release_blockers.json",
        "regression_result.json",
        "golden_sample_validation.json",
        "platform_export_certification.json",
        "compatibility_matrix.json",
    ]:
        (output / name).parent.mkdir(parents=True, exist_ok=True)
        (output / name).write_text('{"status":"pass"}', encoding="utf-8")


def test_release_readiness_summarizes_v25_outputs(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "release"
    workspace.mkdir()
    _write_release_workspace_contract(workspace)
    _write_passing_release_inputs(output)

    result = CliRunner().invoke(app, ["release-readiness", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "release_readiness_result.json").read_text(encoding="utf-8"))
    assert payload["release_ready"] is True
    assert (output / "release_readiness_checklist.md").exists()


def test_release_readiness_uses_v4_2_chinese_docs_without_old_english_docs(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "release"
    workspace.mkdir()
    _write_release_workspace_contract(workspace)
    for old_doc in ["CAPABILITY_STATUS.md", "VERSION_MATRIX.md", "RELEASE_CHECKLIST.md"]:
        assert not (workspace / "docs" / old_doc).exists()
    _write_passing_release_inputs(output)

    result = CliRunner().invoke(app, ["release-readiness", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "release_readiness_result.json").read_text(encoding="utf-8"))
    assert payload["release_ready"] is True
    assert "capability_status_missing" not in payload["critical_blockers"]
    assert "version_matrix_missing" not in payload["critical_blockers"]
    assert "release_checklist_missing" not in payload["critical_blockers"]


def test_release_readiness_forbidden_legacy_paths_remain_untracked():
    allowed_product_baseline = {
        "docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md",
        "docs/product/PRD_V3_2026-06-19.md",
        "docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md",
    }
    result = subprocess.run(
        [
            "git",
            "ls-files",
            "artifacts",
            "docs/audits",
            ".agents",
            "docs/governance",
            "docs/testing",
            "docs/product",
            "docs/bridge",
            "docs/roadmap",
        ],
        text=True,
        capture_output=True,
        check=True,
    )
    tracked = {line.strip() for line in (result.stdout or "").splitlines() if line.strip()}
    assert tracked <= allowed_product_baseline
