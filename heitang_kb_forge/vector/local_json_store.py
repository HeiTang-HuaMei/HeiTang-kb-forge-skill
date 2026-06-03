from heitang_kb_forge.schemas.embedding_schema import EmbeddingRecord
from heitang_kb_forge.schemas.vector_schema import VectorStoreRecord


def make_local_json_records(embeddings: list[EmbeddingRecord], store: str) -> list[VectorStoreRecord]:
    return [
        VectorStoreRecord(
            vector_record_id=f"{store}_{index}",
            embedding_id=record.embedding_id,
            vector=record.vector,
            metadata={
                "source_asset_type": record.source_asset_type,
                "source_path": record.source_path,
                "chunk_id": record.chunk_id,
                "citation": record.citation,
                "provider": record.provider,
                "model": record.model,
                "dimensions": record.dimensions,
            },
            store=store,
        )
        for index, record in enumerate(embeddings)
    ]
