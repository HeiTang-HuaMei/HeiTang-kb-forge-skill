from datetime import datetime, timezone
import re

from pydantic import BaseModel

from heitang_kb_forge.schemas.card_schema import KnowledgeCard
from heitang_kb_forge.schemas.chunk_schema import Chunk
from heitang_kb_forge.schemas.qa_schema import QAPair


def make_quality_report(
    source_count: int,
    chunks: list[Chunk],
    cards: list[KnowledgeCard],
    qa_pairs: list[QAPair],
    glossary: list[dict],
) -> dict[str, object]:
    empty_chunk_count = sum(1 for chunk in chunks if not chunk.text.strip())
    empty_card_count = sum(1 for card in cards if not card.title.strip() or not card.summary.strip())
    empty_qa_count = sum(1 for pair in qa_pairs if not pair.question.strip() or not pair.answer.strip())
    duplicate_card_count = _duplicate_count(cards, lambda card: f"{card.title} {card.summary}")
    duplicate_qa_count = _duplicate_count(qa_pairs, lambda pair: f"{pair.question} {pair.answer}")
    duplicate_glossary_count = _duplicate_count(glossary, lambda item: str(item.get("term", "")))
    citation_coverage = _coverage([*cards, *qa_pairs, *glossary], "citation")
    source_path_coverage = _coverage([*chunks, *cards, *qa_pairs, *glossary], "source_path")
    warnings = _quality_warnings(
        chunks,
        cards,
        qa_pairs,
        glossary,
        empty_chunk_count,
        empty_card_count,
        empty_qa_count,
        duplicate_card_count,
        duplicate_qa_count,
        duplicate_glossary_count,
        citation_coverage,
        source_path_coverage,
    )
    quality_score = _quality_score(
        chunks,
        cards,
        qa_pairs,
        glossary,
        empty_chunk_count,
        empty_card_count,
        empty_qa_count,
        duplicate_card_count,
        duplicate_qa_count,
        duplicate_glossary_count,
        citation_coverage,
        source_path_coverage,
    )

    return {
        "quality_version": "0.3.1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_count": source_count,
        "chunk_count": len(chunks),
        "card_count": len(cards),
        "qa_count": len(qa_pairs),
        "glossary_count": len(glossary),
        "empty_chunk_count": empty_chunk_count,
        "empty_card_count": empty_card_count,
        "empty_qa_count": empty_qa_count,
        "duplicate_card_count": duplicate_card_count,
        "duplicate_qa_count": duplicate_qa_count,
        "duplicate_glossary_count": duplicate_glossary_count,
        "citation_coverage": citation_coverage,
        "source_path_coverage": source_path_coverage,
        "warnings": warnings,
        "quality_score": quality_score,
        "quality_level": _quality_level(quality_score),
    }


def _duplicate_count(items, key_fn) -> int:
    keys = [_normalize(key_fn(item)) for item in items if _normalize(key_fn(item))]
    return len(keys) - len(set(keys))


def _coverage(items, field: str) -> float:
    if not items:
        return 1.0
    present = 0
    for item in items:
        value = getattr(item, field, None) if isinstance(item, BaseModel) else item.get(field)
        if isinstance(value, str) and value.strip():
            present += 1
    return round(present / len(items), 4)


def _quality_score(
    chunks,
    cards,
    qa_pairs,
    glossary,
    empty_chunk_count,
    empty_card_count,
    empty_qa_count,
    duplicate_card_count,
    duplicate_qa_count,
    duplicate_glossary_count,
    citation_coverage,
    source_path_coverage,
) -> int:
    score = 100
    score -= (empty_chunk_count + empty_card_count + empty_qa_count) * 5
    score -= (duplicate_card_count + duplicate_qa_count + duplicate_glossary_count) * 3
    score -= int((1 - citation_coverage) * 20)
    score -= int((1 - source_path_coverage) * 20)
    for asset in [chunks, cards, qa_pairs, glossary]:
        if not asset:
            score -= 10
    return max(0, min(100, score))


def _quality_level(score: int) -> str:
    if score >= 90:
        return "excellent"
    if score >= 75:
        return "good"
    if score >= 60:
        return "fair"
    return "poor"


def _quality_warnings(
    chunks,
    cards,
    qa_pairs,
    glossary,
    empty_chunk_count,
    empty_card_count,
    empty_qa_count,
    duplicate_card_count,
    duplicate_qa_count,
    duplicate_glossary_count,
    citation_coverage,
    source_path_coverage,
) -> list[str]:
    warnings: list[str] = []
    for label, asset in [("chunks", chunks), ("cards", cards), ("qa_pairs", qa_pairs), ("glossary", glossary)]:
        if not asset:
            warnings.append(f"No {label} generated")
    if empty_chunk_count or empty_card_count or empty_qa_count:
        warnings.append("Empty content detected")
    if duplicate_card_count or duplicate_qa_count or duplicate_glossary_count:
        warnings.append("Duplicate asset content detected")
    if citation_coverage < 1:
        warnings.append("Citation coverage is incomplete")
    if source_path_coverage < 1:
        warnings.append("Source path coverage is incomplete")
    return warnings


def _normalize(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip().casefold()
