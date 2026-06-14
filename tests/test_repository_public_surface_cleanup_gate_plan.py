from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "治理"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_repository_public_surface_reset_has_inventory_and_mapping_before_cleanup():
    inventory = GOVERNANCE / "v4.2主分支清理清单.md"
    mapping = GOVERNANCE / "4.2之前版本残留清理映射表.md"

    assert inventory.exists()
    assert mapping.exists()
    for phrase in ["git status --short", "git ls-tree --name-only HEAD", "git ls-tree -r --name-only HEAD"]:
        assert phrase in _read(inventory)
    for column in ["old_path", "action", "reason", "reference_update_required", "safe_to_remove_from_main"]:
        assert column in _read(mapping)


def test_repository_public_surface_reset_removes_not_archives_old_piles():
    text = _read(GOVERNANCE / "v4.2主分支清理清单.md") + "\n" + _read(GOVERNANCE / "归档说明.md")

    assert "不把旧文件搬进 `docs/archive` 或 `artifacts/archive`" in text
    assert "历史文件通过 Git history 和历史 tag 查询" in text
    assert "删除 main 中 `docs/audits/**` 历史审计堆" in text
    assert "删除 main 中 `artifacts/**` 历史审计堆" in text


def test_repository_public_surface_gate_required_gitignore_entries_are_present():
    gitignore = _read(ROOT / ".gitignore")

    for marker in [
        "artifacts/",
        "docs/audits/",
        "_local_dependency_remediation/",
        ".heitang_cache/",
        "repo_surface_audit_pack/",
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
    text = _read(GOVERNANCE / "当前运行状态.md")
    assert "Campaign 4 active：false" in text
    assert "GitHub Release created：false" in text
    assert "Stable `campaign-1-3-baseline` created：false" in text
