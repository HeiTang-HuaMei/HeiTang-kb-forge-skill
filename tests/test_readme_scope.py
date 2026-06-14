from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_readme_does_not_overstate_future_capabilities():
    for name in ["README.md", "README.zh-CN.md"]:
        text = (ROOT / name).read_text(encoding="utf-8")
        forbidden = [
            "production-ready",
            "official XHS upload API support",
            "真实 LLM API 已接入",
            "飞书 / 移动端 / 安装端 / iOS 支持",
        ]
        for item in forbidden:
            assert item not in text
        assert "offline-first" in text or "offline" in text or "本地优先" in text
        assert "evidence" in text or "证据" in text

