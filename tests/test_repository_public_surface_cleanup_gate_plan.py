from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"
PLAN = GOVERNANCE / "REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md"
PLAN_LOCK = GOVERNANCE / "PLAN_SEQUENCE_LOCK.md"
CLOSURE_POLICY = GOVERNANCE / "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md"
STAGE_POLICY = GOVERNANCE / "CAMPAIGN_STAGE_GATE_POLICY.md"
MATRIX = GOVERNANCE / "TARGET_ACCEPTANCE_MATRIX.md"
GITIGNORE = ROOT / ".gitignore"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_repository_public_surface_gate_is_future_only_and_after_closure_pack():
    combined = "\n".join([_read(PLAN), _read(PLAN_LOCK), _read(CLOSURE_POLICY), _read(STAGE_POLICY)])

    for marker in [
        "registered now as a future gate only",
        "This gate must not run early",
        "Closure Pack generated",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate",
        "repository push",
        "tag creation",
        "CI green verification",
        "Campaign 4 Goal-Oriented Product UI Workbench Entry Gate",
    ]:
        assert marker in combined

    locked_order = (
        "Closure Pack generation\n"
        "10. Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate\n"
        "11. Repository push\n"
        "12. Tag creation"
    )
    assert locked_order in combined


def test_repository_public_surface_gate_requires_inventory_before_cleanup():
    plan = _read(PLAN)

    for marker in [
        "The first action is read-only inventory",
        "Do not delete, move, rename, push, tag, or run CI as part of the inventory step",
        "file_inventory.json",
        "git_status_snapshot.txt",
        "tracked_files.txt",
        "untracked_files.txt",
        "large_file_report.json",
        "root_surface_report.json",
        "docs_surface_report.json",
        "artifacts_surface_report.json",
        "Deletion candidates require a manifest entry",
    ]:
        assert marker in plan


def test_repository_public_surface_gate_classifies_files_and_preserves_import_namespace():
    plan = _read(PLAN)

    for marker in [
        "active_docs",
        "milestone_evidence",
        "legacy_root_reports",
        "temporary_current_run",
        "obsolete_duplicate_docs",
        "Old public name: HeiTang KB Forge Skill",
        "New public name: HeiTang Knowledge Workbench",
        "Keep `heitang_kb_forge` import namespace",
        "Do not hard rename the Python package",
    ]:
        assert marker in plan


def test_repository_public_surface_gate_blocks_forbidden_tracked_files_before_push():
    combined = "\n".join([_read(PLAN), _read(CLOSURE_POLICY), _read(STAGE_POLICY)])

    for marker in [
        "Push may run only after",
        "no forbidden tracked files",
        "secrets",
        "tokens",
        "cookies",
        "credentials",
        "large runtime binaries",
        "Tag creation may run only after repository push succeeds",
        "CI/CL verification may run only after tag creation",
    ]:
        assert marker in combined


def test_repository_public_surface_gate_required_gitignore_entries_are_present():
    gitignore = _read(GITIGNORE)

    for marker in [
        "_local_dependency_remediation/",
        ".heitang_cache/",
        "repo_surface_audit_pack/",
        "repo_surface_audit_pack.zip",
        "repo_tracked_snapshot.zip",
        "artifacts/audits/current_run/",
        "artifacts/audits/latest/",
        "tmp/",
        "tmp_*/",
        ".cache/",
        ".pytest_cache/",
        ".coverage",
        "coverage/",
        ".venv/",
        "node_modules/",
        ".dart_tool/",
        "build/",
        "dist/",
        "__pycache__/",
        ".env",
        ".env.*",
        "!.env.example",
        "provider_config.yaml",
        "local_provider_config.yaml",
        "*.secret",
        "*.token",
        "*.cookie",
        "credentials.*",
    ]:
        assert marker in gitignore


def test_repository_public_surface_gate_is_not_campaign_4_or_release():
    combined = "\n".join([_read(PLAN), _read(PLAN_LOCK), _read(MATRIX)])

    for marker in [
        "Repository cleanup is not final release",
        "Rename is not commercial release",
        "Push is not release complete",
        "Tag is not EXE ready",
        "CI green is not Campaign 4 complete",
        "Campaign 4 must not start before CI green",
        "Current Campaign 3 Supplement 4.0 implementation work does not execute repository cleanup, rename, push, tag, or CI verification",
        "Campaign 3 Supplement 4.0 Knowledge-to-Skill Template Generator implementation",
    ]:
        assert marker in combined
