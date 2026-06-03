from collections import Counter
import re

from heitang_kb_forge.schemas.knowledge_graph_schema import EntityRecord, RelationRecord

KNOWLEDGE_GRAPH_OUTPUT_FILES = ["entities.jsonl", "relations.jsonl", "knowledge_graph_manifest.json"]


def make_knowledge_graph(cards: list, glossary: list[dict], llm_outputs: dict | None = None) -> tuple[list[EntityRecord], list[RelationRecord], dict]:
    entities: list[EntityRecord] = []
    seen: set[str] = set()
    for item in glossary:
        term = str(item.get("term", "")).strip()
        citation = str(item.get("citation", "")).strip()
        if not term or not citation:
            continue
        entity_type = _entity_type(term)
        entity_id = _entity_id(term, entity_type)
        if entity_id in seen:
            continue
        seen.add(entity_id)
        entities.append(
            EntityRecord(
                entity_id=entity_id,
                name=term,
                entity_type=entity_type,
                source_path=str(item.get("source_path", "")),
                chunk_id=str(item.get("chunk_id", "")),
                citation=citation,
            )
        )
    for card in cards:
        title = str(card.title).strip()
        if not title or not card.citation:
            continue
        entity_type = _entity_type(title)
        entity_id = _entity_id(title, entity_type)
        if entity_id in seen:
            continue
        seen.add(entity_id)
        entities.append(EntityRecord(entity_id=entity_id, name=title, entity_type=entity_type, source_path=card.source_path, chunk_id=card.chunk_id, citation=card.citation))
    relations = _relations_from_entities(entities)
    counts = Counter(entity.entity_type for entity in entities)
    manifest = {
        "knowledge_graph_version": "1.1.0",
        "entity_count": len(entities),
        "relation_count": len(relations),
        "entity_type_counts": dict(counts),
        "warnings": [],
    }
    return entities, relations, manifest


def _entity_type(name: str) -> str:
    if re.search(r"book|书|教材", name, re.IGNORECASE):
        return "book"
    if re.search(r"author|作者", name, re.IGNORECASE):
        return "author"
    if re.search(r"publisher|出版社", name, re.IGNORECASE):
        return "publisher"
    if re.search(r"rate|score|metric|指标|转化|价格", name, re.IGNORECASE):
        return "metric"
    if re.search(r"process|流程|步骤", name, re.IGNORECASE):
        return "process"
    if re.search(r"product|商品|产品", name, re.IGNORECASE):
        return "product"
    return "concept"


def _entity_id(name: str, entity_type: str) -> str:
    slug = re.sub(r"\W+", "_", name.lower(), flags=re.UNICODE).strip("_")[:48] or "entity"
    return f"{entity_type}_{slug}"


def _relations_from_entities(entities: list[EntityRecord]) -> list[RelationRecord]:
    if len(entities) < 2:
        return []
    first = entities[0]
    return [
        RelationRecord(
            relation_id=f"relation_{index}",
            source_entity_id=first.entity_id,
            target_entity_id=entity.entity_id,
            relation_type="used_for",
            source_path=entity.source_path,
            chunk_id=entity.chunk_id,
            citation=entity.citation,
        )
        for index, entity in enumerate(entities[1:], start=1)
    ]
