import hashlib
import re

from heitang_kb_forge.schemas.card_schema import KnowledgeCard
from heitang_kb_forge.schemas.chunk_schema import Chunk
from heitang_kb_forge.schemas.qa_schema import QAPair


def make_cards(chunks: list[Chunk]) -> list[KnowledgeCard]:
    cards: list[KnowledgeCard] = []
    seen: set[tuple[str, str]] = set()
    for chunk in chunks:
        summary = _first_sentence(chunk.text)
        title = _clean_title(chunk.title or summary[:48])
        if not title or not summary:
            continue
        dedupe_key = (_normalize_for_dedupe(title), _normalize_for_dedupe(summary))
        if dedupe_key in seen:
            continue
        seen.add(dedupe_key)
        card_type = _infer_card_type(chunk.text)
        cards.append(
            KnowledgeCard(
                card_id=_stable_id("card", f"{title}:{summary}"),
                chunk_id=chunk.chunk_id,
                title=title,
                summary=summary,
                source_path=chunk.source_path,
                domain=chunk.domain,
                mode=chunk.mode,
                card_type=card_type,
                tags=_extract_tags(chunk.text, card_type),
                citation=_citation(chunk),
            )
        )
    return cards


def make_qa_pairs(chunks: list[Chunk]) -> list[QAPair]:
    pairs: list[QAPair] = []
    seen: set[tuple[str, str]] = set()
    for chunk in chunks:
        answer = _first_sentence(chunk.text)
        if not answer:
            continue
        qa_type = _infer_qa_type(chunk.text)
        question = _make_question(chunk, qa_type)
        if not question:
            continue
        dedupe_key = (_normalize_for_dedupe(question), _normalize_for_dedupe(answer))
        if dedupe_key in seen:
            continue
        seen.add(dedupe_key)
        pairs.append(
            QAPair(
                qa_id=_stable_id("qa", f"{question}:{answer}"),
                chunk_id=chunk.chunk_id,
                question=question,
                answer=answer,
                source_path=chunk.source_path,
                domain=chunk.domain,
                mode=chunk.mode,
                qa_type=qa_type,
                citation=_citation(chunk),
            )
        )
    return pairs


def make_glossary(chunks: list[Chunk]) -> list[dict[str, str | None]]:
    terms: dict[str, dict[str, str | None]] = {}
    for chunk in chunks:
        for term in _extract_term_candidates(chunk.text):
            key = _normalize_for_dedupe(term)
            terms.setdefault(
                key,
                {
                    "term": term,
                    "definition": f"Term candidate detected in {chunk.source_path}",
                    "source_path": chunk.source_path,
                    "chunk_id": chunk.chunk_id,
                    "citation": _citation(chunk),
                },
            )
    return [terms[key] for key in sorted(terms)]


def _first_sentence(text: str) -> str:
    normalized = " ".join(text.split())
    match = re.search(r"(.+?[。.!?])(?:\s|$)", normalized)
    return (match.group(1) if match else normalized[:220]).strip()


def _clean_title(title: str | None) -> str:
    if not title:
        return ""
    return title.strip().lstrip("#").strip()[:120]


def _normalize_for_dedupe(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip().casefold()


def _infer_card_type(text: str) -> str:
    lowered = text.casefold()
    if re.search(r"\b(example|case|案例|示例)\b", lowered):
        return "example"
    if re.search(r"\b(metric|kpi|formula|rate|指标|公式|口径)\b", lowered):
        return "metric"
    if re.search(r"\b(step|process|workflow|流程|步骤|方法)\b", lowered):
        return "process"
    if re.search(r"\b(rule|policy|must|should|原则|规则|必须)\b", lowered):
        return "rule"
    return "concept"


def _infer_qa_type(text: str) -> str:
    lowered = text.casefold()
    if re.search(r"\b(how|step|process|workflow|如何|步骤|流程)\b", lowered):
        return "how_to"
    if re.search(r"\b(compare|versus|vs|difference|对比|区别)\b", lowered):
        return "comparison"
    if re.search(r"\b(why|explain|reason|原因|解释)\b", lowered):
        return "explanation"
    return "factual"


def _make_question(chunk: Chunk, qa_type: str) -> str:
    title = _clean_title(chunk.title) or _question_subject(chunk.text)
    if not title:
        return ""
    if qa_type == "how_to":
        return f"How does {title} work?"
    if qa_type == "comparison":
        return f"What comparison does {title} describe?"
    if qa_type == "explanation":
        return f"Why is {title} important?"
    return f"What should readers know about {title}?"


def _question_subject(text: str) -> str:
    first = _first_sentence(text)
    return re.sub(r"[:：。.!?]+$", "", first[:80]).strip()


def _extract_tags(text: str, card_type: str) -> list[str]:
    tags = [card_type]
    for term in _extract_term_candidates(text)[:4]:
        normalized = _normalize_for_dedupe(term)
        if normalized not in {_normalize_for_dedupe(tag) for tag in tags}:
            tags.append(term)
    return tags


def _extract_term_candidates(text: str) -> list[str]:
    candidates = re.findall(r"\b[A-Z][A-Za-z0-9_-]{2,}\b", text)
    candidates.extend(re.findall(r"[\u4e00-\u9fff]{2,}(?:系统|流程|规则|指标|模型|框架|策略|方案|方法|知识库|资料包|术语)", text))
    candidates.extend(re.findall(r"(?:系统|流程|规则|指标|模型|框架|策略|方案|方法|知识库|资料包|术语)[\u4e00-\u9fff]{0,6}", text))

    terms: list[str] = []
    seen: set[str] = set()
    for candidate in candidates:
        term = candidate.strip(" \t\r\n,.!?;:，。！？；：、（）()[]{}")
        key = _normalize_for_dedupe(term)
        if key in seen or not _is_meaningful_term(term):
            continue
        seen.add(key)
        terms.append(term)
    return terms


def _is_meaningful_term(term: str) -> bool:
    if len(term) < 2:
        return False
    if re.fullmatch(r"[\W_]+", term):
        return False
    if re.fullmatch(r"\d+", term):
        return False
    stop_words = {
        "the",
        "and",
        "for",
        "with",
        "this",
        "that",
        "from",
        "系统",
        "流程",
        "规则",
        "指标",
        "方案",
        "方法",
    }
    return _normalize_for_dedupe(term) not in stop_words


def _citation(chunk: Chunk) -> str:
    return f"{chunk.source_path}#chunk={chunk.chunk_id}"


def _stable_id(prefix: str, value: str) -> str:
    digest = hashlib.sha256(f"{prefix}:{value}".encode("utf-8")).hexdigest()[:24]
    return f"{prefix}_{digest}"
