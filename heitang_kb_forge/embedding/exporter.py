import hashlib

from heitang_kb_forge.embedding.fake_provider import FakeEmbeddingProvider
from heitang_kb_forge.embedding.openai_compatible_provider import OpenAICompatibleEmbeddingProvider
from heitang_kb_forge.embedding.provider import EmbeddingProvider
from heitang_kb_forge.schemas.embedding_schema import EmbeddingManifest, EmbeddingRecord

EMBEDDING_OUTPUT_FILES = ["embeddings.jsonl", "embedding_manifest.json"]


def create_embedding_provider(provider: str, model: str) -> EmbeddingProvider:
    if provider == "fake":
        return FakeEmbeddingProvider(model)
    if provider == "openai-compatible":
        return OpenAICompatibleEmbeddingProvider(model)
    raise ValueError(f"Unsupported embedding provider: {provider}")


def make_embeddings(records: list, provider_name: str, model: str) -> tuple[list[EmbeddingRecord], dict]:
    provider = create_embedding_provider(provider_name, model)
    embeddings: list[EmbeddingRecord] = []
    dimensions = 0
    for record in records:
        text = str(getattr(record, "text", "")).strip()
        response = provider.embed(text)
        dimensions = response.dimensions
        embeddings.append(
            EmbeddingRecord(
                embedding_id=record.embedding_id,
                text_hash=hashlib.sha256(text.encode("utf-8")).hexdigest(),
                vector=response.vector,
                dimensions=response.dimensions,
                provider=response.provider,
                model=response.model,
                source_asset_type=record.asset_type,
                source_path=record.source_path,
                chunk_id=record.chunk_id,
                citation=record.citation,
            )
        )
    manifest = EmbeddingManifest(
        provider=provider_name,
        model=model,
        dimensions=dimensions,
        total_records=len(embeddings),
    ).model_dump(mode="json")
    return embeddings, manifest
