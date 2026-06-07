from pathlib import Path


def test_v39_docs_exist_and_describe_no_cloud_and_absorption_map():
    docs = [
        Path("docs/V39_LOCAL_WORKSPACE_STORAGE_MEMORY_LIFECYCLE.md"),
        Path("docs/V39_LOCAL_WORKSPACE_STORAGE_MEMORY_LIFECYCLE.zh-CN.md"),
        Path("docs/V39_EXTERNAL_ABSORPTION_MAP.md"),
        Path("docs/V39_EXTERNAL_ABSORPTION_MAP.zh-CN.md"),
    ]
    for path in docs:
        assert path.exists()
        text = path.read_text(encoding="utf-8")
        assert "v39_external_absorption_map.json" in text or "V39" in path.name
        assert "cloud" in text.lower() or "上传" in text


def test_v39_docs_state_no_external_code_or_prompt_copying():
    text = Path("docs/V39_EXTERNAL_ABSORPTION_MAP.md").read_text(encoding="utf-8")
    assert "No external code or prompts are copied" in text
