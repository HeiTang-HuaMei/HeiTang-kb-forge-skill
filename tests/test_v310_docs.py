from pathlib import Path


def test_v310_docs_exist_and_state_local_only_boundaries():
    docs = [
        Path("docs/V310_LOCAL_AGENT_RUNTIME_MOTHER_CHILD.md"),
        Path("docs/V310_LOCAL_AGENT_RUNTIME_MOTHER_CHILD.zh-CN.md"),
    ]
    for path in docs:
        assert path.exists()
        text = path.read_text(encoding="utf-8")
        assert "run-local-agent" in text
        assert "LLM" in text
        assert "network" in text or "网络" in text
        assert "mother" in text
        assert "child" in text
