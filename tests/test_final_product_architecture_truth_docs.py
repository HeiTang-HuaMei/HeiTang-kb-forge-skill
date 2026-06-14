from pathlib import Path


ROOT = Path.cwd()


def test_v4_2_product_truth_docs_are_concise_and_auditable():
    text = "\n".join(
        (ROOT / path).read_text(encoding="utf-8")
        for path in [
            "docs/产品定位.md",
            "docs/系统架构.md",
            "docs/测试与验收.md",
            "docs/治理/Campaign_1_3_总结.md",
            "docs/治理/Campaign_1_3_能力矩阵.md",
        ]
    )

    for phrase in [
        "Knowledge Package",
        "Document Outputs",
        "Markdown / DOCX / PDF / PPTX",
        "Skill Template",
        "Skill Suite",
        "Agent Creation Package",
    ]:
        assert phrase in text


def test_final_product_truth_docs_do_not_overclaim_blocked_capabilities():
    text = "\n".join(
        (ROOT / path).read_text(encoding="utf-8")
        for path in [
            "README.md",
            "README.zh-CN.md",
            "docs/产品定位.md",
            "docs/治理/当前运行状态.md",
        ]
    )

    for phrase in [
        "Campaign 4 UI 未启动",
        "Campaign 5 未启动",
        "Redis / Vector DB",
        "future target",
        "Agent Runtime ready",
    ]:
        assert phrase in text
    assert "不把 UI handoff 写成 Campaign 4 UI 完成" in text
    assert "不把 Bridge handoff 写成 Campaign 5 Bridge 完成" in text


def test_readmes_link_to_current_chinese_product_surface():
    english = (ROOT / "README.md").read_text(encoding="utf-8")
    chinese = (ROOT / "README.zh-CN.md").read_text(encoding="utf-8")

    assert "docs/项目概览.md" in english
    assert "docs/产品定位.md" in english
    assert "docs/项目概览.md" in chinese
    assert "docs/产品定位.md" in chinese
