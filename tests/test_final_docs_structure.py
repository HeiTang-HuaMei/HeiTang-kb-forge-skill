import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

CURRENT_DOCS = [
    "docs/项目概览.md",
    "docs/快速开始.md",
    "docs/使用指南.md",
    "docs/产品定位.md",
    "docs/系统架构.md",
    "docs/知识供应链架构.md",
    "docs/Skill与Agent生成说明.md",
    "docs/路线图.md",
    "docs/测试与验收.md",
    "docs/发布流程.md",
    "docs/治理/当前运行状态.md",
    "docs/治理/标签命名策略.md",
    "docs/治理/Campaign_1_3_总结.md",
    "docs/治理/Campaign_1_3_能力矩阵.md",
    "docs/治理/Campaign_1_3_外部项目集成审查.md",
    "docs/治理/历史版本说明.md",
    "docs/治理/仓库结构规范.md",
    "docs/治理/归档说明.md",
    "docs/治理/v4.2主分支清理清单.md",
    "docs/治理/4.2之前版本残留清理映射表.md",
]


def test_required_documentation_structure_exists():
    for relative in CURRENT_DOCS:
        path = ROOT / relative
        assert path.exists(), relative
        assert path.stat().st_size > 0, relative


def test_readme_local_links_exist():
    for relative in ["README.md", "README.zh-CN.md"]:
        _assert_local_markdown_links_exist(ROOT / relative)


def test_old_public_docs_are_not_kept_as_top_level_docs():
    forbidden = [
        "docs/DOCS_INDEX.md",
        "docs/CURRENT_TRUTH.md",
        "docs/CAPABILITY_MATRIX.md",
        "docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md",
        "docs/AIGC_BOOK_CONTENT_PIPELINE.md",
        "docs/USER_MANUAL.md",
        "docs/VERSION_MATRIX.md",
        "docs/ROADMAP.md",
    ]
    for relative in forbidden:
        assert not (ROOT / relative).exists(), relative


def test_root_public_surface_has_no_old_json_gate_files():
    forbidden_patterns = [
        r"final_.*\.json",
        r".*_gate_report\.json",
        r".*_fix_log\.json",
        r"v\d+_external_absorption_map\.json",
        r"v4_rc_.*\.json",
    ]
    offenders = []
    for path in ROOT.iterdir():
        if not path.is_file():
            continue
        if any(re.fullmatch(pattern, path.name) for pattern in forbidden_patterns):
            offenders.append(path.name)
    assert offenders == []
    assert (ROOT / "skill.json").exists()


def test_product_docs_track_current_boundaries_without_overclaiming():
    combined = "\n".join((ROOT / relative).read_text(encoding="utf-8") for relative in CURRENT_DOCS)
    for phrase in [
        "Knowledge Package",
        "Document Outputs",
        "Markdown / DOCX / PDF / PPTX",
        "Skill Template",
        "Skill Suite",
        "Agent Creation Package",
        "Campaign 4 未启动",
        "Campaign 5 未启动",
    ]:
        assert phrase in combined
    for boundary in [
        "Agent package 不等于 executable runtime",
        "不把 UI handoff 写成 Campaign 4 UI 完成",
        "不把 Bridge handoff 写成 Campaign 5 Bridge 完成",
        "Redis / Vector DB 是 future target",
    ]:
        assert boundary in combined


def _assert_local_markdown_links_exist(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    for match in re.finditer(r"\[[^\]]+\]\(([^)]+)\)", text):
        target = match.group(1)
        if "://" in target or target.startswith("#") or target.startswith("mailto:"):
            continue
        target = target.split("#", 1)[0]
        if not target:
            continue
        resolved = (path.parent / target).resolve()
        assert resolved.exists(), f"{path.relative_to(ROOT)} -> {target}"
