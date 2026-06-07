from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_readme_and_core_docs_are_bilingually_aligned():
    pairs = [
        ("README.md", "README.zh-CN.md"),
        ("docs/DOCS_INDEX.md", "docs/DOCS_INDEX.zh-CN.md"),
        ("docs/USER_MANUAL.md", "docs/USER_MANUAL.zh-CN.md"),
        ("docs/COMMAND_REFERENCE.md", "docs/COMMAND_REFERENCE.zh-CN.md"),
        ("docs/LOCAL_PRIVACY_SECURITY.md", "docs/LOCAL_PRIVACY_SECURITY.zh-CN.md"),
    ]
    for english, chinese in pairs:
        english_text = (ROOT / english).read_text(encoding="utf-8")
        chinese_text = (ROOT / chinese).read_text(encoding="utf-8")
        for marker in ["3.12.0-alpha.1", "v4.0", "LLM"]:
            assert marker in english_text
            assert marker in chinese_text
