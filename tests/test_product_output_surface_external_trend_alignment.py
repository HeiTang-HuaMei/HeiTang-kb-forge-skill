from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "治理"


def test_four_distinct_product_output_surfaces_are_publicly_registered():
    text = "\n".join(
        (ROOT / path).read_text(encoding="utf-8")
        for path in [
            "docs/项目概览.md",
            "docs/产品定位.md",
            "docs/治理/目标验收矩阵.md",
            "docs/治理/Campaign_1_3_能力矩阵.md",
        ]
    )

    for phrase in [
        "Knowledge Package",
        "Document Outputs",
        "Markdown / DOCX / PDF / PPTX",
        "Skill Outputs",
        "Agent Creation Package",
    ]:
        assert phrase in text


def test_external_reference_queue_is_not_integrated_runtime():
    text = (GOVERNANCE / "Campaign_1_3_外部项目集成审查.md").read_text(encoding="utf-8")

    for project in [
        "andrej-karpathy-skills",
        "Presenton",
        "CodeGraph",
        "Understand Anything",
        "LongLive",
        "claude-plugins-official",
        "pi-mono",
    ]:
        assert project in text
    for phrase in [
        "reference_only",
        "planned_not_active",
        "stopped_or_rejected",
        "不是 runtime 接入",
        "不做 GPU 视频生成",
    ]:
        assert phrase in text


def test_document_outputs_are_not_covered_by_skill_outputs():
    text = (GOVERNANCE / "目标验收矩阵.md").read_text(encoding="utf-8")
    document_index = text.index("Document Outputs")
    skill_index = text.index("Skill Outputs")
    assert document_index < skill_index
    assert "Markdown / DOCX / PDF / PPTX" in text


def test_guard_forbids_campaign_advancement_and_release_actions():
    text = (GOVERNANCE / "当前运行状态.md").read_text(encoding="utf-8")
    assert "不得进入 Campaign 4" in text
    assert "不得创建 GitHub Release" in text
    assert "不得创建稳定 `campaign-1-3-baseline`" in text
