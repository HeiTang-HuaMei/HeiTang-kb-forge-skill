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

    readme = Path("README.md").read_text(encoding="utf-8")
    zh_readme = Path("README.zh-CN.md").read_text(encoding="utf-8")
    assert "v1.6 Real-world Ingestion Closure" in readme
    assert "multimodal_assets.jsonl" in readme
    assert "check-contract" in readme
    assert "v1.6 真实资料接入收口" in zh_readme
    assert "multimodal_assets.jsonl" in zh_readme
    assert "check-contract" in zh_readme
