from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_current_docs_cover_package_contract_without_legacy_v16_docs():
    text = "\n".join(
        (ROOT / path).read_text(encoding="utf-8")
        for path in ["README.md", "docs/项目概览.md", "docs/使用指南.md", "docs/知识供应链架构.md"]
    )

    for name in ["manifest.json", "chunks.jsonl", "quality_report.json", "ingest_report.md"]:
        assert name in text
    assert "Knowledge Package" in text
    assert "source trace" in text
