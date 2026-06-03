import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.processors.extractor import make_cards, make_glossary, make_qa_pairs
from heitang_kb_forge.schemas.chunk_schema import Chunk


def test_cards_are_deduplicated_and_keep_source_linkage():
    chunks = [
        _chunk("a", "Concept Alpha is important.", title="Concept Alpha"),
        _chunk("b", "Concept Alpha is important.", title="Concept Alpha"),
        _chunk("c", " ", title=""),
    ]

    cards = make_cards(chunks)

    assert len(cards) == 1
    assert cards[0].chunk_id == "a"
    assert cards[0].source_path == "source.md"
    assert cards[0].citation == "source.md#chunk=a"
    assert cards[0].card_type == "concept"
    assert cards[0].title
    assert cards[0].summary


def test_qa_pairs_are_deduplicated_and_keep_source_linkage():
    chunks = [
        _chunk("a", "The process has three steps.", title="Process Alpha"),
        _chunk("b", "The process has three steps.", title="Process Alpha"),
        _chunk("c", " ", title=""),
    ]

    pairs = make_qa_pairs(chunks)

    assert len(pairs) == 1
    assert pairs[0].chunk_id == "a"
    assert pairs[0].source_path == "source.md"
    assert pairs[0].citation == "source.md#chunk=a"
    assert pairs[0].qa_type == "how_to"
    assert pairs[0].question
    assert pairs[0].answer
    assert pairs[0].answer in chunks[0].text


def test_glossary_extracts_english_and_chinese_terms_with_filters():
    chunks = [
        _chunk("a", "API API 123 !!! 会员系统 and 知识库流程 support agents."),
    ]

    glossary = make_glossary(chunks)
    terms = {item["term"]: item for item in glossary}

    assert "API" in terms
    assert "会员系统" in terms
    assert "知识库流程" in terms
    assert "123" not in terms
    assert "!!!" not in terms
    assert list(terms).count("API") == 1
    assert terms["API"]["source_path"] == "source.md"
    assert terms["API"]["chunk_id"] == "a"
    assert terms["API"]["citation"] == "source.md#chunk=a"


def test_build_outputs_have_no_empty_or_duplicate_quality_records(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "quality.md").write_text(
        "# Quality Concept\n\nAPI 会员系统 is important.\n\nAPI 会员系统 is important.",
        encoding="utf-8",
    )

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
    cards = _read_jsonl(output_dir / "cards.jsonl")
    qa_pairs = _read_jsonl(output_dir / "qa_pairs.jsonl")
    glossary = _read_jsonl(output_dir / "glossary.jsonl")

    assert all(card["title"] and card["summary"] for card in cards)
    assert all(pair["question"] and pair["answer"] for pair in qa_pairs)
    assert len({(card["title"].casefold(), card["summary"].casefold()) for card in cards}) == len(cards)
    assert len({(pair["question"].casefold(), pair["answer"].casefold()) for pair in qa_pairs}) == len(qa_pairs)
    assert len({item["term"].casefold() for item in glossary}) == len(glossary)
    assert all("chunk_id" in item and "source_path" in item and "citation" in item for item in glossary)


def _chunk(chunk_id, text, title="Title"):
    return Chunk(
        chunk_id=chunk_id,
        source_path="source.md",
        source_type="md",
        domain="education",
        mode="teaching",
        title=title,
        text=text,
        order=0,
        char_count=max(len(text), 1),
    )


def _read_jsonl(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]
