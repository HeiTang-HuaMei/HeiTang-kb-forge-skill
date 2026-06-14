import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _tracked_files() -> set[str]:
    result = subprocess.run(["git", "ls-files"], cwd=ROOT, text=True, capture_output=True, check=True)
    return set(result.stdout.splitlines())


def test_campaign_1_acceptance_is_preserved_as_concise_v4_2_summary():
    text = (ROOT / "docs" / "治理" / "Campaign_1_3_总结.md").read_text(encoding="utf-8")
    matrix = (ROOT / "docs" / "治理" / "Campaign_1_3_能力矩阵.md").read_text(encoding="utf-8")

    assert "文档导入与知识包构建" in text
    assert "Document Outputs" in matrix
    assert "Markdown / DOCX / PDF / PPTX" in matrix
    assert "optional OCR / advanced parser 是 dependency-gated" in (
        ROOT / "docs" / "测试与验收.md"
    ).read_text(encoding="utf-8")


def test_pre_v4_2_backend_acceptance_audit_pile_is_removed_from_tracked_main():
    tracked = _tracked_files()

    assert "artifacts/audits/backend_remediation_acceptance_review/backend_remediation_acceptance_matrix.json" not in tracked
    assert "artifacts/audits/backend_remediation_acceptance_review/run_summary.md" not in tracked
    assert not any(path.startswith("artifacts/audits/backend_remediation_acceptance_review/") for path in tracked)
