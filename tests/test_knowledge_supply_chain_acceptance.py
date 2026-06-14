import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _tracked_files() -> set[str]:
    result = subprocess.run(["git", "ls-files"], cwd=ROOT, text=True, capture_output=True, check=True)
    return set(result.stdout.splitlines())


def test_campaign_2_knowledge_supply_chain_is_preserved_as_v4_2_product_boundary():
    summary = (ROOT / "docs" / "治理" / "Campaign_1_3_总结.md").read_text(encoding="utf-8")
    matrix = (ROOT / "docs" / "治理" / "Campaign_1_3_能力矩阵.md").read_text(encoding="utf-8")

    for marker in [
        "文档导入与知识包构建",
        "source trace / evidence map",
        "检索、验证和质量报告",
    ]:
        assert marker in summary
    for marker in [
        "Knowledge Package 构建",
        "Source Trace / Evidence Map",
        "Retrieval / Verification",
    ]:
        assert marker in matrix


def test_pre_v4_2_knowledge_supply_chain_audit_pile_is_removed_from_tracked_main():
    tracked = _tracked_files()

    assert "artifacts/audits/knowledge_supply_chain_acceptance_review/campaign_2_acceptance_matrix.json" not in tracked
    assert "artifacts/audits/knowledge_supply_chain_acceptance_review/run_summary.md" not in tracked
    assert not any(path.startswith("artifacts/audits/knowledge_supply_chain_acceptance_review/") for path in tracked)
