from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_docs_describe_skill_first_architecture_and_agent_integrations():
    text = "\n".join(
        (ROOT / path).read_text(encoding="utf-8")
        for path in [
            "README.md",
            "README.zh-CN.md",
            "docs/Skill与Agent生成说明.md",
            "docs/系统架构.md",
        ]
    )
    assert "Skill" in text
    assert "presentation layer" in text or "表现层" in text
    assert "Agent Creation Package" in text
    assert "Campaign 4 UI" in text
    assert "Campaign 4 UI 完成" not in text


def test_standard_agent_friendly_output_contract_is_documented():
    text = (ROOT / "docs" / "Skill与Agent生成说明.md").read_text(encoding="utf-8")
    for name in [
        "manifest.json",
        "quality_report.json",
        "agent_profile",
        "retrieval",
        "evaluation",
    ]:
        assert name in text
