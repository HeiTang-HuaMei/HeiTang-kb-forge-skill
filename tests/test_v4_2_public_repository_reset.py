import re
import shutil
import subprocess
from pathlib import Path

from tests.legacy_public_reset_evidence import ensure_legacy_public_reset_evidence


ROOT = Path(__file__).resolve().parents[1]


ROOT_ALLOWLIST = {
    ".env.example",
    ".gitattributes",
    ".github",
    ".gitignore",
    "AGENTS.md",
    "CHANGELOG.md",
    "LICENSE",
    "README.md",
    "README.zh-CN.md",
    "SKILL.md",
    "assets",
    "desktop",
    "docs",
    "examples",
    "heitang_kb_forge",
    "packaging",
    "provider_config.example.yaml",
    "pyproject.toml",
    "scripts",
    "skill.json",
    "tests",
}

REQUIRED_CHINESE_DOCS = {
    "项目概览.md",
    "快速开始.md",
    "使用指南.md",
    "产品定位.md",
    "系统架构.md",
    "知识供应链架构.md",
    "Skill与Agent生成说明.md",
    "路线图.md",
    "测试与验收.md",
    "发布流程.md",
}

REQUIRED_GOVERNANCE_DOCS = {
    "当前运行状态.md",
    "标签命名策略.md",
    "Campaign_1_3_总结.md",
    "Campaign_1_3_能力矩阵.md",
    "Campaign_1_3_外部项目集成审查.md",
    "历史版本说明.md",
    "仓库结构规范.md",
    "归档说明.md",
    "v4.2主分支清理清单.md",
    "4.2之前版本残留清理映射表.md",
}


def _tracked_files() -> list[str]:
    result = subprocess.run(
        ["git", "-c", "core.quotePath=false", "ls-files"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=True,
    )
    stdout = result.stdout or ""
    return [line.strip() for line in stdout.splitlines() if line.strip()]


def test_root_public_surface_is_allowlisted_and_within_budget():
    tracked_roots = {path.split("/", 1)[0] for path in _tracked_files()}
    unexpected = sorted(tracked_roots - ROOT_ALLOWLIST)
    assert unexpected == []

    visible_root = [
        path.name
        for path in ROOT.iterdir()
        if path.is_file() and path.name != ".git" and not path.name.startswith(".") and not _is_ignored(path)
    ]
    assert len(visible_root) <= 15


def test_root_json_files_are_only_skill_json():
    root_json = [path for path in _tracked_files() if "/" not in path and path.endswith(".json")]
    assert root_json == ["skill.json"]


def test_no_tracked_current_run_latest_or_audit_piles():
    tracked = _tracked_files()
    forbidden_prefixes = (
        "artifacts/",
        "docs/audits/",
        ".agents/",
    )
    forbidden_fragments = (
        "/current_run/",
        "/latest/",
    )
    assert [path for path in tracked if path.startswith(forbidden_prefixes)] == []
    assert [path for path in tracked if any(fragment in path for fragment in forbidden_fragments)] == []


def test_no_pre_v4_2_residue_in_public_root():
    forbidden_patterns = [
        r"^final_.*\.json$",
        r"^.*_gate_report\.json$",
        r"^.*_fix_log\.json$",
        r"^v\d+_external_absorption_map\.json$",
        r"^v4_rc_.*\.json$",
    ]
    tracked_root = [path for path in _tracked_files() if "/" not in path]
    offenders = [
        path
        for path in tracked_root
        if any(re.match(pattern, path) for pattern in forbidden_patterns)
    ]
    assert offenders == []


def test_docs_use_chinese_public_filename_structure():
    docs = {path.name for path in (ROOT / "docs").glob("*.md")}
    governance = {path.name for path in (ROOT / "docs" / "治理").glob("*.md")}

    assert REQUIRED_CHINESE_DOCS <= docs
    assert REQUIRED_GOVERNANCE_DOCS <= governance

    removed_dirs = [
        "00_overview",
        "03_core_capabilities",
        "10_roadmap",
        "audits",
        "bridge",
        "governance",
        "product",
        "roadmap",
        "testing",
    ]
    tracked = set(_tracked_files())
    for dirname in removed_dirs:
        assert not any(path.startswith(f"docs/{dirname}/") for path in tracked)


def test_cleanup_mapping_table_covers_required_actions():
    mapping = ROOT / "docs" / "治理" / "4.2之前版本残留清理映射表.md"
    text = mapping.read_text(encoding="utf-8")
    for column in [
        "old_path",
        "action",
        "reason",
        "reference_update_required",
        "safe_to_remove_from_main",
    ]:
        assert column in text
    for required in [
        "final_fix_log.json",
        "final_v4_rc_gate_report.json",
        "docs/audits/**",
        "artifacts/**",
        "docs/*.md old English docs",
    ]:
        assert required in text


def test_readme_links_point_to_existing_public_files():
    for name in ["README.md", "README.zh-CN.md"]:
        text = (ROOT / name).read_text(encoding="utf-8")
        for match in re.finditer(r"\[[^\]]+\]\(([^)]+)\)", text):
            target = match.group(1).split("#", 1)[0]
            if not target or "://" in target or target.startswith("mailto:"):
                continue
            assert (ROOT / target).exists(), f"{name} -> {target}"


def test_gitignore_blocks_runtime_audit_and_dependency_residue():
    text = (ROOT / ".gitignore").read_text(encoding="utf-8")
    for entry in [
        "artifacts/",
        "docs/audits/",
        "_local_dependency_remediation/",
        ".heitang_cache/",
        "repo_surface_audit_pack/",
        "tmp/",
        "build/",
        "dist/",
        ".venv/",
        "node_modules/",
    ]:
        assert entry in text


def test_legacy_public_reset_evidence_self_bootstraps_from_clean_checkout(tmp_path):
    clean_root = tmp_path / "clean-main"
    clean_root.mkdir()
    for path in _tracked_files():
        source = ROOT / path
        target = clean_root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)

    subprocess.run(["git", "init", "-q"], cwd=clean_root, text=True, capture_output=True, check=True)
    subprocess.run(["git", "add", "-A"], cwd=clean_root, text=True, capture_output=True, check=True)

    legacy_paths = [
        "artifacts",
        "docs/audits",
        "docs/governance",
        "docs/testing",
        "docs/product",
        "docs/bridge",
        "docs/roadmap",
        ".agents",
    ]
    for rel in legacy_paths:
        path = clean_root / rel
        if path.exists():
            if path.is_dir():
                shutil.rmtree(path)
            else:
                path.unlink()

    ensure_legacy_public_reset_evidence(clean_root)

    required = [
        "artifacts/audits/campaign_3_final_consistency/run_manifest.json",
        "artifacts/audits/campaign_1_2_3_closure_pack/run_manifest.json",
        "artifacts/audits/repository_public_surface_cleanup/run_manifest.json",
        "docs/audits/p1_real_workflow_v1/p1_real_workflow_v1_report.json",
        "docs/audits/p1_real_workflow_v2/p1_real_workflow_v2_report.json",
        "docs/audits/p1_final_gate_rerun/p1_final_gate_report.json",
        "docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json",
        "docs/audits/p2_1_parser_ocr_backends/parser_backend_matrix.json",
        "docs/governance/PLAN_SEQUENCE_LOCK.md",
        "docs/testing/VALIDATION_GATE_MANIFEST.json",
    ]
    for rel in required:
        assert (clean_root / rel).exists(), rel

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
        cwd=clean_root,
        text=True,
        capture_output=True,
        check=True,
    )
    assert (result.stdout or "").strip() == ""


def _is_ignored(path: Path) -> bool:
    result = subprocess.run(
        ["git", "check-ignore", "-q", str(path.relative_to(ROOT))],
        cwd=ROOT,
        text=True,
    )
    return result.returncode == 0
