from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_release_checklist_documents_required_gate_inputs():
    text = (ROOT / "docs" / "发布流程.md").read_text(encoding="utf-8") + "\n" + (
        ROOT / "docs" / "测试与验收.md"
    ).read_text(encoding="utf-8")
    for item in ["python -m pytest", "Quickstart", "Release Check", "git diff --check"]:
        assert item in text
    assert "GitHub Release" in text
    assert "不创建稳定" in text

