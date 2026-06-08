import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


CURRENT_DOCS = [
    "docs/DOCS_INDEX.md",
    "docs/DOCS_INDEX.zh-CN.md",
    "docs/DOCUMENTATION_GOVERNANCE.md",
    "docs/DOCUMENTATION_GOVERNANCE.zh-CN.md",
    "docs/00_overview/CURRENT_TRUTH.md",
    "docs/00_overview/CURRENT_TRUTH.zh-CN.md",
    "docs/00_overview/CAPABILITY_MATRIX.md",
    "docs/00_overview/CAPABILITY_MATRIX.zh-CN.md",
    "docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.md",
    "docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.zh-CN.md",
    "docs/10_roadmap/P1_UI_CORE_PARITY.md",
    "docs/10_roadmap/P1_UI_CORE_PARITY.zh-CN.md",
    "docs/10_roadmap/P2_PRODUCTIZATION.md",
    "docs/10_roadmap/P2_PRODUCTIZATION.zh-CN.md",
    "docs/VERSION_MATRIX.md",
    "docs/VERSION_MATRIX.zh-CN.md",
    "docs/USER_MANUAL.md",
    "docs/USER_MANUAL.zh-CN.md",
    "docs/COMMAND_REFERENCE.md",
    "docs/COMMAND_REFERENCE.zh-CN.md",
    "docs/AGENT_INTEGRATION.md",
    "docs/AGENT_TOOL_INTERFACE_GUIDE.md",
    "docs/MCP_READINESS_GUIDE.md",
    "docs/ICON_GUIDELINES.md",
    "docs/OUTPUT_REPORT_GUIDE.md",
    "docs/OUTPUT_REPORT_GUIDE.zh-CN.md",
    "docs/GOLDEN_DEMO_GUIDE.md",
    "docs/GOLDEN_DEMO_GUIDE.zh-CN.md",
    "docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md",
    "docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md",
    "docs/ROADMAP.md",
    "docs/ROADMAP.zh-CN.md",
    "docs/RELEASE_NOTES.md",
    "docs/RELEASE_NOTES.zh-CN.md",
    "docs/LOCAL_PRIVACY_SECURITY.md",
    "docs/LOCAL_PRIVACY_SECURITY.zh-CN.md",
    "docs/RELEASE_CHECKLIST.md",
    "docs/RELEASE_CHECKLIST.zh-CN.md",
    "docs/CAPABILITY_STATUS.md",
    "docs/CAPABILITY_STATUS.zh-CN.md",
    "docs/ARCHITECTURE.md",
    "docs/ARCHITECTURE.zh-CN.md",
    "docs/TROUBLESHOOTING.md",
    "docs/TROUBLESHOOTING.zh-CN.md",
]


def test_required_documentation_structure_exists():
    for relative in CURRENT_DOCS:
        path = ROOT / relative
        assert path.exists(), relative
        assert path.stat().st_size > 0, relative


def test_readme_and_docs_index_local_links_exist():
    for relative in ["README.md", "README.zh-CN.md", "docs/DOCS_INDEX.md", "docs/DOCS_INDEX.zh-CN.md"]:
        _assert_local_markdown_links_exist(ROOT / relative)


def test_old_process_docs_are_not_kept_as_top_level_docs():
    forbidden = [
        "docs/V310_LOCAL_AGENT_RUNTIME_MOTHER_CHILD.md",
        "docs/V312_PRODUCT_HARDENING_LOCAL_RELEASE_READINESS.md",
        "docs/WORKBENCH_VERSION_PLAN.md",
        "docs/IMPLEMENTATION_CHECKPOINTS.md",
        "docs/ARCHITECTURE_GAP_AUDIT.md",
        "docs/EXTERNAL_PROJECT_BENCHMARK.md",
        "docs/CAPABILITY_GAP_MAP.md",
        "docs/EXTERNAL_FUSION_PLAN.md",
    ]
    for relative in forbidden:
        assert not (ROOT / relative).exists(), relative


def test_root_public_surface_is_slimmed_to_current_gate_files():
    forbidden_root = [
        "architecture_gap_audit_report.json",
        "external_project_benchmark_report.json",
        "capability_gap_map.json",
        "external_fusion_plan.json",
        "repository_surface_audit_report.json",
    ]
    for relative in forbidden_root:
        assert not (ROOT / relative).exists(), relative
    assert (ROOT / "final_v4_rc_gate_report.json").exists()
    assert (ROOT / "v4_rc_final_gate_report.json").exists()
    assert (ROOT / "v310_external_absorption_map.json").exists()
    assert (ROOT / "v38_external_absorption_map.json").exists()
    assert (ROOT / "v39_external_absorption_map.json").exists()
    assert (ROOT / "v312_external_absorption_map.json").exists()
    assert (ROOT / "docs" / "audits" / "local_acceptance" / "pre_v4_p0_after_live_llm").exists()


def test_parser_backend_strategy_tracks_external_candidates_without_overclaiming():
    for relative in [
        "docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.md",
        "docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.zh-CN.md",
        "docs/00_overview/CAPABILITY_MATRIX.md",
        "docs/00_overview/CAPABILITY_MATRIX.zh-CN.md",
        "docs/ROADMAP.md",
        "docs/ROADMAP.zh-CN.md",
    ]:
        text = (ROOT / relative).read_text(encoding="utf-8")
        assert "OpenDataLoader" in text
        assert "PaddleOCR" in text
        assert "MinerU" in text
        assert "PDF -> Markdown/JSON/RAG-ready" in text
        assert "OCR + document understanding pipeline" in text
        assert "external backend candidate" in text
        assert "planned adapter" in text
        assert "verified internal parser" in text or "已验证的 internal parser" in text
        assert "bounded best-effort OCR" in text
        assert "PDF token reduction" in text

    strategy = (
        (ROOT / "docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.md").read_text(encoding="utf-8")
        + "\n"
        + (ROOT / "docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.zh-CN.md").read_text(encoding="utf-8")
    )
    for forbidden in ["supported", "integrated", "已支持", "已集成"]:
        assert forbidden not in strategy


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
