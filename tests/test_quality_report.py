import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.processors.quality import make_quality_report
from heitang_kb_forge.schemas.card_schema import KnowledgeCard
from heitang_kb_forge.schemas.chunk_schema import Chunk
from heitang_kb_forge.schemas.qa_schema import QAPair


def test_build_writes_quality_report_and_ingest_summary(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "quality.md").write_text("# Quality\n\nAPI 会员系统 improves traceability.", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--domain",
            "education",
            "--mode",
            "teaching",
        ],
    )

    assert result.exit_code == 0, result.output
    quality_report = json.loads((output_dir / "quality_report.json").read_text(encoding="utf-8"))
    for field in [
        "quality_version",
        "generated_at",
        "source_count",
        "chunk_count",
        "card_count",
        "qa_count",
        "glossary_count",
        "empty_chunk_count",
        "empty_card_count",
        "empty_qa_count",
        "duplicate_card_count",
        "duplicate_qa_count",
        "duplicate_glossary_count",
        "citation_coverage",
        "source_path_coverage",
        "warnings",
        "quality_score",
        "quality_level",
    ]:
        assert field in quality_report
    assert quality_report["chunk_count"] >= 1
    assert quality_report["card_count"] >= 1
    assert quality_report["qa_count"] >= 1
    assert isinstance(quality_report["quality_score"], int)
    assert quality_report["quality_level"] in {"excellent", "good", "fair", "poor"}

    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["quality_report_file"] == "quality_report.json"
    assert "quality_report.json" in manifest["files"]

    report = (output_dir / "ingest_report.md").read_text(encoding="utf-8")
    assert "## Quality Summary" in report
    assert "Quality score" in report
    assert "Quality level" in report


def test_quality_report_counts_empty_duplicate_and_coverage_stats():
    chunks = [
        _chunk("a", "Same text", "source.md"),
        _chunk("b", "   ", ""),
    ]
    cards = [
        _card("a", "Title", "Summary", "source.md", "source.md#chunk=a"),
        _card("b", "Title", "Summary", "source.md", None),
        _card("c", "", "Summary", "", None),
    ]
    qa_pairs = [
        _qa("a", "Question?", "Answer", "source.md", "source.md#chunk=a"),
        _qa("b", "Question?", "Answer", "source.md", None),
        _qa("c", "", "Answer", "", None),
    ]
    glossary = [
        {"term": "API", "definition": "Term", "source_path": "source.md", "citation": "source.md#chunk=a"},
        {"term": "api", "definition": "Term", "source_path": "source.md"},
    ]

    quality_report = make_quality_report(1, chunks, cards, qa_pairs, glossary)

    assert quality_report["empty_chunk_count"] == 1
    assert quality_report["empty_card_count"] == 1
    assert quality_report["empty_qa_count"] == 1
    assert quality_report["duplicate_card_count"] == 1
    assert quality_report["duplicate_qa_count"] == 1
    assert quality_report["duplicate_glossary_count"] == 1
    assert quality_report["citation_coverage"] < 1
    assert quality_report["source_path_coverage"] < 1
    assert quality_report["quality_score"] < 100


def _chunk(chunk_id, text, source_path):
    return Chunk(
        chunk_id=chunk_id,
        source_path=source_path,
        source_type="md",
        domain="education",
        mode="teaching",
        title="Title",
        text=text,
        order=0,
        char_count=max(len(text), 1),
    )


def _card(chunk_id, title, summary, source_path, citation):
    return KnowledgeCard(
        card_id=f"card_{chunk_id}",
        chunk_id=chunk_id,
        title=title,
        summary=summary,
        source_path=source_path,
        domain="education",
        mode="teaching",
        citation=citation,
    )


def _qa(chunk_id, question, answer, source_path, citation):
    return QAPair.model_construct(
        qa_id=f"qa_{chunk_id}",
        chunk_id=chunk_id,
        question=question,
        answer=answer,
        source_path=source_path,
        domain="education",
        mode="teaching",
        citation=citation,
    )
