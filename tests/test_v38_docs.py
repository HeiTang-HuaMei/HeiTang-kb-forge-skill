from pathlib import Path


def test_v38_docs_exist_and_reference_external_absorption_map():
    docs = [
        Path("docs/V38_RAG_RETRIEVAL_QUALITY_EVALUATION.md"),
        Path("docs/V38_RAG_RETRIEVAL_QUALITY_EVALUATION.zh-CN.md"),
        Path("docs/V38_EXTERNAL_ABSORPTION_MAP.md"),
        Path("docs/V38_EXTERNAL_ABSORPTION_MAP.zh-CN.md"),
    ]

    for path in docs:
        assert path.exists()
        text = path.read_text(encoding="utf-8")
        assert "External" in text or "外部" in text
        assert "v38_external_absorption_map.json" in text
        assert "network" in text.lower() or "网络" in text


def test_v38_docs_state_no_external_code_prompt_copying():
    text = Path("docs/V38_EXTERNAL_ABSORPTION_MAP.md").read_text(encoding="utf-8")

    assert "No external code, prompts, or datasets are copied" in text
    assert "no real LLM/API" in text
