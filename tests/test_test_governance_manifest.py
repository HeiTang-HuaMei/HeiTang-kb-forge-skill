from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_pytest_markers_remain_declared_for_gate_selection():
    pyproject = (ROOT / "pyproject.toml").read_text(encoding="utf-8")
    for marker in ["fast", "medium", "full", "docs_truth", "parser_backend", "release", "ui_contract", "slow"]:
        assert f"{marker}:" in pyproject


def test_v4_2_validation_commands_are_documented_in_public_surface():
    text = (ROOT / "docs" / "测试与验收.md").read_text(encoding="utf-8")

    for command in [
        "python -m pytest tests/test_v4_2_public_repository_reset.py -q",
        "python -m pytest -q",
        "python -m json.tool .\\skill.json",
        "git diff --check",
    ]:
        assert command in text


def test_public_reset_hard_tests_cover_required_cleanup_policies():
    test_text = (ROOT / "tests" / "test_v4_2_public_repository_reset.py").read_text(encoding="utf-8")

    for check in [
        "test_root_public_surface_is_allowlisted_and_within_budget",
        "test_root_json_files_are_only_skill_json",
        "test_no_tracked_current_run_latest_or_audit_piles",
        "test_no_pre_v4_2_residue_in_public_root",
        "test_docs_use_chinese_public_filename_structure",
        "test_cleanup_mapping_table_covers_required_actions",
    ]:
        assert check in test_text


def test_legacy_validation_manifest_is_removed_from_public_main():
    tracked = _tracked_files()
    assert "docs/testing/VALIDATION_GATE_MANIFEST.json" not in tracked
    assert "docs/testing/VALIDATION_STRATEGY.md" not in tracked


def _tracked_files() -> set[str]:
    import subprocess

    result = subprocess.run(["git", "ls-files"], cwd=ROOT, text=True, capture_output=True, check=True)
    return set(result.stdout.splitlines())
