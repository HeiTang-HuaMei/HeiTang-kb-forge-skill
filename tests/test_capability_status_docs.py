from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_capability_status_docs_define_all_levels():
    combined = "\n".join(
        (ROOT / relative).read_text(encoding="utf-8")
        for relative in [
            "docs/项目概览.md",
            "docs/产品定位.md",
            "docs/治理/目标验收矩阵.md",
            "docs/路线图.md",
        ]
    )
    for marker in [
        "Knowledge Package",
        "Document Outputs",
        "Skill Outputs",
        "Agent Creation Package",
        "completed_baseline",
        "not_started",
        "future target",
    ]:
        assert marker in combined
    assert "v2.6" not in combined
    assert "official XHS" not in combined
    assert "SaaS implemented" not in combined

