import hashlib
import re

from heitang_kb_forge.schemas.card_schema import KnowledgeCard
from heitang_kb_forge.schemas.chunk_schema import Chunk
from heitang_kb_forge.schemas.qa_schema import QAPair


def make_cards(chunks: list[Chunk]) -> list[KnowledgeCard]:
    cards: list[KnowledgeCard] = []
    for chunk in chunks:
        summary = _first_sentence(chunk.text)
        title = chunk.title or summary[:48]
        cards.append(
            KnowledgeCard(
                card_id=_stable_id("card", chunk.chunk_id),
                chunk_id=chunk.chunk_id,
                title=title,
                summary=summary,
                source_path=chunk.source_path,
                domain=chunk.domain,
                mode=chunk.mode,
            )
        )
    return cards


def make_qa_pairs(chunks: list[Chunk]) -> list[QAPair]:
    pairs: list[QAPair] = []
    for chunk in chunks:
        title = chunk.title or "this knowledge chunk"
        answer = _first_sentence(chunk.text)
        pairs.append(
            QAPair(
                qa_id=_stable_id("qa", chunk.chunk_id),
                chunk_id=chunk.chunk_id,
                question=f"What is the key idea of {title}?",
                answer=answer,
                source_path=chunk.source_path,
                domain=chunk.domain,
                mode=chunk.mode,
            )
        )
    return pairs


def make_glossary(chunks: list[Chunk]) -> list[dict[str, str]]:
    terms: dict[str, str] = {}
    for chunk in chunks:
        for term in re.findall(r"\b[A-Z][A-Za-z0-9_-]{2,}\b", chunk.text):
            terms.setdefault(term, f"Term detected in {chunk.source_path}")
    return [{"term": term, "definition": definition} for term, definition in sorted(terms.items())]


def _first_sentence(text: str) -> str:
    normalized = " ".join(text.split())
    match = re.search(r"(.+?[。.!?])(?:\s|$)", normalized)
    return (match.group(1) if match else normalized[:220]).strip()


def _stable_id(prefix: str, value: str) -> str:
    digest = hashlib.sha256(f"{prefix}:{value}".encode("utf-8")).hexdigest()[:24]
    return f"{prefix}_{digest}"
