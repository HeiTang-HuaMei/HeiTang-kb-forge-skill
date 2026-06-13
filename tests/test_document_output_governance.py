import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"
AUDITS = ROOT / "docs" / "audits"
MANIFEST_PATH = AUDITS / "AUDIT_MANIFEST.json"
INDEX_PATH = AUDITS / "AUDIT_INDEX.md"
POLICY_PATH = GOVERNANCE / "DOCUMENT_OUTPUT_GOVERNANCE_POLICY.md"
GITIGNORE_PATH = ROOT / ".gitignore"
VALIDATION_MANIFEST_PATH = ROOT / "docs" / "testing" / "VALIDATION_GATE_MANIFEST.json"


def _manifest() -> dict:
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def test_document_output_governance_files_exist():
    assert POLICY_PATH.exists()
    assert MANIFEST_PATH.exists()
    assert INDEX_PATH.exists()


def test_policy_defines_document_classes_and_retention_rules():
    text = POLICY_PATH.read_text(encoding="utf-8")

    for marker in [
        "Product docs",
        "Governance rules",
        "Contracts and schemas",
        "Audit evidence",
        "Runtime logs and caches",
        "artifacts/audits/latest/",
        "Keep the newest 3 runs only",
        "Keep 7 days",
        "Keep 3 days unless promoted",
        "not committed by default",
        "run_manifest.json",
        "run_summary.md",
    ]:
        assert marker in text


def test_audit_manifest_has_required_fields_for_each_run():
    manifest = _manifest()

    assert manifest["schema_version"] == "audit_manifest.v1"
    assert manifest["default_evidence_root"] == "artifacts/audits"
    assert manifest["docs_audits_role"] == "index_and_promoted_summaries_only"
    assert manifest["retention_policy"]["latest_keep_runs"] == 3
    assert manifest["retention_policy"]["daily_keep_days"] == 7
    assert manifest["retention_policy"]["failed_debug_keep_days"] == 3

    required = {
        "run_id",
        "type",
        "scope",
        "status",
        "evidence_dir",
        "retention",
        "keep_in_git",
        "run_manifest",
        "run_summary",
        "summary",
    }
    for run in manifest["runs"]:
        assert required <= set(run)
        assert run["run_id"].strip()
        assert run["summary"].strip()
        assert run["retention"] in {"latest", "daily", "failed-debug", "milestone", "release"}
        if run["retention"] in {"milestone", "release"}:
            assert run["keep_in_git"] is True
            assert run["run_summary"].endswith((".md", ".markdown"))


def test_audit_index_links_manifest_and_promoted_runs():
    manifest = _manifest()
    text = INDEX_PATH.read_text(encoding="utf-8")

    assert "AUDIT_MANIFEST.json" in text
    assert "artifacts/audits/latest/<run_id>/" in text
    for run in manifest["runs"]:
        assert run["run_id"] in text


def test_runtime_logs_progress_events_and_caches_are_gitignored():
    ignore = GITIGNORE_PATH.read_text(encoding="utf-8")

    for pattern in [
        "*.log",
        "*.jsonl",
        "progress_events.jsonl",
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


def test_milestone_and_release_manifest_entries_have_summary_entrypoints():
    for run in _manifest()["runs"]:
        if run["retention"] not in {"milestone", "release"}:
            continue
        assert run["run_manifest"].endswith(".json")
        assert run["run_summary"].endswith((".md", ".markdown"))
        assert run["summary"]


def test_validation_gate_manifest_includes_document_output_governance():
    manifest = json.loads(VALIDATION_MANIFEST_PATH.read_text(encoding="utf-8"))
    governance_rule = next(rule for rule in manifest["impact_rules"] if rule["name"] == "test_governance")

    assert "tests/test_document_output_governance.py" in governance_rule["patterns"]
    assert any(
        "tests/test_document_output_governance.py" in gate["command"]
        for gate in manifest["gates"]
        if gate["name"] == "core_fast_test_governance"
    )
