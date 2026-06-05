from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_golden_samples_have_minimal_fixed_baseline():
    root = ROOT / "examples" / "golden_samples"
    assert (root / "README.md").exists()
    assert (root / "README.zh-CN.md").exists()
    assert (root / "minimal_knowledge_package").exists()
    assert (root / "platform_export_mock").exists()
    assert "Large-scale stress samples are planned" in (root / "README.md").read_text(encoding="utf-8")

