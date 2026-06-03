from heitang_kb_forge.schemas.embedding_schema import EmbeddingRecord
from heitang_kb_forge.schemas.vector_schema import VectorStoreManifest, VectorStoreRecord
from heitang_kb_forge.vector.adapter import validate_vector_store
from heitang_kb_forge.vector.local_json_store import make_local_json_records

VECTOR_OUTPUT_FILES = ["vector_store_records.jsonl", "vector_store_manifest.json"]


def make_vector_export(embeddings: list[EmbeddingRecord], store: str) -> tuple[list[VectorStoreRecord], dict]:
    validate_vector_store(store)
    records = make_local_json_records(embeddings, store)
    manifest = VectorStoreManifest(store=store, total_records=len(records)).model_dump(mode="json")
    return records, manifest
