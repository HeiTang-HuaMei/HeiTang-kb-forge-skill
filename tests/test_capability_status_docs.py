from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_capability_status_docs_define_all_levels():
    for relative in ["docs/CAPABILITY_STATUS.md", "docs/CAPABILITY_STATUS.zh-CN.md"]:
        text = (ROOT / relative).read_text(encoding="utf-8")
        for heading in ["Stable", "Preview", "Experimental", "Roadmap", "Reserved", "Deprecated", "Out of Scope"]:
            assert f"## {heading}" in text
        stable = text.split("## Stable", 1)[1].split("## Preview", 1)[0]
        assert "v2.6" not in stable
        assert "official XHS" not in stable
        assert "SaaS" not in stable

