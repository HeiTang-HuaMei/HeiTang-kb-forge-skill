from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_v12_main_docs_include_ops_platform_sections():
    readme = read("README.md")
    readme_zh = read("README.zh-CN.md")
    changelog = read("CHANGELOG.md")
    ops_guide = read("docs/KNOWLEDGE_OPS_GUIDE.md")
    planning_guide = read("docs/AGENT_PLANNING_READINESS_GUIDE.md")

    assert "Knowledge Ops Guide" in readme
    assert "v1.2.0 Knowledge Ops & Governance Platform" in ops_guide
    assert "Workspace / Package Registry" in ops_guide
    assert "Refresh / Staleness Detection" in ops_guide
    assert "Human Review / Curation Loop" in ops_guide
    assert "Agent Planning Readiness Pack" in planning_guide
    assert "heitang-kb-forge workspace init" in ops_guide
    assert "Tool Runtime" in ops_guide
    assert "real business integration" in ops_guide
    assert "permissions" in ops_guide
    assert "SaaS" in ops_guide

    assert "Knowledge Ops Guide" in readme_zh

    assert "v1.2.0" in changelog
    assert "workspace registry" in changelog
    assert "refresh / staleness detection" in changelog
    assert "review / curation loop" in changelog
    assert "Agent Planning Readiness" in changelog


def test_v12_supplementary_docs_exist_and_match_boundaries():
    docs = [
        "docs/KNOWLEDGE_OPS_GUIDE.md",
        "docs/WEB_UI_OPS_GUIDE.md",
        "docs/AGENT_PLANNING_READINESS_GUIDE.md",
    ]

    for doc in docs:
        path = ROOT / doc
        assert path.exists(), f"Missing {doc}"
        text = path.read_text(encoding="utf-8")
        assert "PowerShell" in text
        assert "heitang-kb-forge" in text
        assert "Tool Runtime" in text
        assert "permissions" in text or "权限" in text
        assert "SaaS" in text
        assert "real business integration" in text or "业务系统" in text


def test_knowledge_ops_guide_covers_v12_ops_modules():
    text = read("docs/KNOWLEDGE_OPS_GUIDE.md")

    assert "Workspace / Package Registry" in text
    assert "Refresh / Staleness Detection" in text
    assert "Human Review / Curation Loop" in text
    assert "Evaluation Dashboard Data" in text
    assert "Publish / Export Profiles" in text
    assert "workspace init" in text
    assert "refresh-check" in text
    assert "review-create" in text
    assert "publish" in text


def test_web_ui_ops_guide_covers_optional_extra_and_ops_views():
    text = read("docs/WEB_UI_OPS_GUIDE.md")

    assert "optional" in text.lower()
    assert "pip install -e" in text
    assert "heitang-kb-forge web" in text
    assert "package list" in text
    assert "review queue" in text
    assert "refresh plan" in text
    assert "Streamlit" in text or "streamlit" in text


def test_agent_planning_readiness_guide_covers_outputs_and_non_runtime_boundary():
    text = read("docs/AGENT_PLANNING_READINESS_GUIDE.md")

    assert "Agent Planning Readiness" in text
    assert "not Agent Planning Runtime" in text
    assert "agent_planning_blueprint.yaml" in text
    assert "tool_requirement_map.json" in text
    assert "planning_eval_cases.jsonl" in text
    assert "planning_risk_report.md" in text
    assert "planning-readiness" in text
    assert "does not execute plans" in text
    assert "does not call tools" in text
