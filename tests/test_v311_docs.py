from pathlib import Path


def test_v311_docs_exist_and_cover_boundaries():
    for path in [
        Path("docs/V311_GOLDEN_DEMO_ACCEPTANCE_SMOKE.md"),
        Path("docs/V311_GOLDEN_DEMO_ACCEPTANCE_SMOKE.zh-CN.md"),
    ]:
        text = path.read_text(encoding="utf-8")
        assert "Golden Demo" in text or "黄金演示" in text
        assert "LLM" in text
        assert "network" in text or "网络" in text
        assert "artifact openability" in text or "产物可打开性" in text
