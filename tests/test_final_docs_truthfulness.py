import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_readme_current_status_is_not_stale():
    english = (ROOT / "README.md").read_text(encoding="utf-8")
    chinese = (ROOT / "README.zh-CN.md").read_text(encoding="utf-8")

    assert "Current Core package version: `4.1.0`" in english
    assert "当前 Core package 版本：`4.1.0`" in chinese
    assert "Current version: `2.9.0-alpha.1`" not in english
    assert "当前版本：`2.9.0-alpha.1`" not in chinese
    assert "Current stable release: `v4.0.0`" in english
    assert "Current release candidate line: `v4.1.0`" in english
    assert "当前 stable release：`v4.0.0`" in chinese
    assert "当前 release candidate line：`v4.1.0`" in chinese
    assert "Parser/OCR" in english
    assert "Parser/OCR" in chinese


def test_docs_do_not_claim_forbidden_future_features_as_implemented():
    forbidden_patterns = [r"BYO cloud[^\n.]{0,120}fully implemented", r"SaaS[^\n.]{0,120}implemented", r"platform-hosted user data[^\n.]{0,120}default"]
    allowed_negations = ["not claim", "do not claim", "not implemented", "not released", "尚未发布", "不是当前默认实现"]
    for path in (ROOT / "docs").glob("*.md"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for pattern in forbidden_patterns:
            for match in re.finditer(pattern, text, flags=re.IGNORECASE):
                window = text[max(0, match.start() - 80) : match.end() + 80].lower()
                assert any(phrase in window for phrase in allowed_negations), f"{path}: {match.group(0)}"


def test_local_privacy_security_states_required_boundaries():
    text = (ROOT / "docs" / "LOCAL_PRIVACY_SECURITY.md").read_text(encoding="utf-8")
    for phrase in ["Local-first default", "No platform-hosted user data", "LLM optional only", "No hidden upload", "BYO cloud"]:
        assert phrase in text
