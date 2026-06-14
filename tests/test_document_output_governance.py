import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
POLICY_PATH = ROOT / "docs" / "测试与验收.md"
PRODUCT_PATH = ROOT / "docs" / "产品定位.md"
GITIGNORE_PATH = ROOT / ".gitignore"


def _tracked_files() -> set[str]:
    result = subprocess.run(["git", "ls-files"], cwd=ROOT, text=True, capture_output=True, check=True)
    return set(result.stdout.splitlines())


def test_document_output_governance_files_exist():
    assert POLICY_PATH.exists()
    assert PRODUCT_PATH.exists()


def test_policy_defines_document_classes_and_retention_rules():
    text = POLICY_PATH.read_text(encoding="utf-8")

    for marker in [
        "Product docs",
        "Governance rules",
        "Contracts and schemas",
        "Audit evidence",
        "Runtime logs and caches",
        "artifacts/audits/latest/",
        "newest 3 runs",
        "Keep 7 days",
        "Keep 3 days unless promoted",
        "not committed by default",
        "run_manifest.json",
        "run_summary.md",
    ]:
        assert marker in text


def test_public_main_does_not_track_audit_manifest_or_index_piles():
    tracked = _tracked_files()
    assert "docs/audits/AUDIT_MANIFEST.json" not in tracked
    assert "docs/audits/AUDIT_INDEX.md" not in tracked
    assert not any(path.startswith("docs/audits/") for path in tracked)
    assert not any(path.startswith("artifacts/") for path in tracked)


def test_runtime_logs_progress_events_and_caches_are_gitignored():
    ignore = GITIGNORE_PATH.read_text(encoding="utf-8")

    for pattern in [
        "*.log",
        "*.jsonl",
        "progress_events.jsonl",
        "artifacts/",
        "artifacts/audits/latest/",
        "artifacts/audits/daily/",
        "_runtime_cache/",
        "_local_dependency_remediation/*/.venv/",
        "_local_dependency_remediation/*/model_cache/",
        ".codex/retry_log.jsonl",
        ".codex/recovery_checkpoint.json",
    ]:
        assert pattern in ignore


def test_artifacts_latest_has_at_most_three_runs_when_present():
    latest = ROOT / "artifacts" / "audits" / "latest"
    if not latest.exists():
        return

    runs = [path for path in latest.iterdir() if path.is_dir()]
    assert len(runs) <= 3
    for run in runs:
        assert (run / "run_manifest.json").exists()
        assert (run / "run_summary.md").exists()


def test_document_outputs_are_product_surface_not_audit_side_effect():
    text = PRODUCT_PATH.read_text(encoding="utf-8")
    for marker in [
        "Document Outputs：Markdown / DOCX / PDF / PPTX",
        "正式产品能力",
        "不是审计报告副产物",
        "不被 Skill Outputs 覆盖",
    ]:
        assert marker in text


def test_test_governance_lives_in_python_tests_after_public_reset():
    tracked = _tracked_files()
    assert "tests/test_document_output_governance.py" in tracked
    assert "docs/testing/VALIDATION_GATE_MANIFEST.json" not in tracked
