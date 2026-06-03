from pydantic import BaseModel


class EntityRecord(BaseModel):
    entity_id: str
    name: str
    entity_type: str
    source_path: str
    chunk_id: str
    citation: str


class RelationRecord(BaseModel):
    relation_id: str
    source_entity_id: str
    target_entity_id: str
    relation_type: str
    source_path: str
    chunk_id: str
    citation: str
