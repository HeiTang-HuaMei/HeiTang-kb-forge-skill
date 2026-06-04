from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_docs_describe_skill_first_architecture_and_agent_integrations():
    text = "\n".join(
        (ROOT / path).read_text(encoding="utf-8")
        for path in [
            "README.md",
            "README.zh-CN.md",
            "docs/ARCHITECTURE.md",
            "docs/DESKTOP_APP_GUIDE.md",
            "docs/UI_INFORMATION_ARCHITECTURE.md",
            "docs/ROADMAP.md",
        ]
    )
    assert "Skill-first" in text
    assert "presentation layer" in text
    assert "OpenClaw" in text
    assert "Claude Code" in text
    assert "Codex" in text
    assert "Desktop UI is the core product engine" not in text


def test_standard_agent_friendly_output_contract_is_documented():
    architecture = (ROOT / "docs" / "ARCHITECTURE.md").read_text(encoding="utf-8")
    for name in [
        "chunks.jsonl",
        "cards.jsonl",
        "qa_pairs.jsonl",
        "glossary.jsonl",
        "manifest.json",
        "quality_report.json",
        "ingest_report.md",
        "rag_manifest.json",
        "embedding_input.jsonl",
        "retrieval_metadata.jsonl",
        "agent_profile.yaml",
        "retrieval_config.yaml",
        "tools.yaml",
        "eval_cases.jsonl",
        "quality_gate_report.json",
        "package_validation_report.json",
        "publish_manifest.json",
    ]:
        assert name in architecture
