from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_current_docs_cover_v39_workspace_memory_without_legacy_docs():
    text = "\n".join(
        (ROOT / path).read_text(encoding="utf-8")
        for path in ["README.md", "docs/系统架构.md", "docs/产品定位.md"]
    )

    assert "workspace" in text.lower() or "工作区" in text
    assert "local" in text.lower() or "本地" in text
    assert "Redis / Vector DB" in text
    assert "future target" in text
