from pathlib import Path


def test_v16_bilingual_docs_exist_and_cover_contract_and_multimodal():
    docs = [
        "docs/MULTIMODAL_KNOWLEDGE_ASSETS.md",
        "docs/MULTIMODAL_KNOWLEDGE_ASSETS.zh-CN.md",
        "docs/PACKAGE_CONTRACT_V2.md",
        "docs/PACKAGE_CONTRACT_V2.zh-CN.md",
        "docs/VERSION_TRACEABILITY.md",
        "docs/VERSION_TRACEABILITY.zh-CN.md",
        "docs/PROGRESS_AND_OBSERVABILITY.zh-CN.md",
        "docs/LARGE_FILE_PERFORMANCE.zh-CN.md",
        "docs/OCR_SETUP.zh-CN.md",
        "docs/ROADMAP.zh-CN.md",
        "docs/ARCHITECTURE.zh-CN.md",
        "docs/QUICKSTART.zh-CN.md",
        "docs/TROUBLESHOOTING.zh-CN.md",
    ]
    for doc in docs:
        assert Path(doc).exists(), doc

    changelog = Path("CHANGELOG.md").read_text(encoding="utf-8")
    quickstart_zh = Path("docs/QUICKSTART.zh-CN.md").read_text(encoding="utf-8")
    assert "## v1.6" in changelog
    assert "multimodal_assets.jsonl" in changelog
    assert "check-contract" in changelog
    assert "v1.6" in quickstart_zh
    assert "multimodal_assets.jsonl" in quickstart_zh
    assert "check-contract" in quickstart_zh
