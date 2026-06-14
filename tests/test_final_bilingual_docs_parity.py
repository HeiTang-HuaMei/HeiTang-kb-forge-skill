from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_readme_and_core_docs_are_bilingually_aligned():
    pairs = [
        ("README.md", "README.zh-CN.md"),
    ]
    for english, chinese in pairs:
        english_text = (ROOT / english).read_text(encoding="utf-8")
        chinese_text = (ROOT / chinese).read_text(encoding="utf-8")
        for marker in ["4.2.0", "v4.2", "LLM"]:
            assert marker in english_text
            assert marker in chinese_text

    public_docs = "\n".join(path.read_text(encoding="utf-8") for path in (ROOT / "docs").glob("*.md"))
    for marker in ["Knowledge Package", "Document Outputs", "Skill Outputs", "Agent Creation Package"]:
        assert marker in public_docs
