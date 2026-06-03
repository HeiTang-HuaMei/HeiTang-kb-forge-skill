from heitang_kb_forge.llm.cache import LLMCache
from heitang_kb_forge.llm.extractor import LLMOptions, extract_llm_assets
from heitang_kb_forge.llm.fake_provider import FakeProvider
from heitang_kb_forge.schemas.chunk_schema import Chunk


def test_llm_extractor_generates_metadata_for_fake_provider(tmp_path):
    chunk = _chunk("chunk-a", "KB Forge LLM Fixture explains structured extraction.")
    cache = LLMCache(tmp_path / "cache")

    result = extract_llm_assets([chunk], LLMOptions(enabled=True), provider=FakeProvider(), cache=cache)

    record = result.outputs["cards"][0]
    assert record["source_path"] == "source.md"
    assert record["chunk_id"] == "chunk-a"
    assert record["citation"] == "source.md#chunk=chunk-a"
    assert record["llm_provider"] == "fake"
    assert record["llm_model"] == "fake-model"
    assert record["confidence"] == 0.8
    assert record["token_usage"] == {"input_tokens": 32, "output_tokens": 16}
    assert record["cache_key"]
    assert record["generated_at"]


def test_llm_cache_hit_does_not_call_provider_again(tmp_path):
    chunk = _chunk("chunk-a", "KB Forge LLM cache fixture.")
    cache = LLMCache(tmp_path / "cache")
    provider = FakeProvider()

    first = extract_llm_assets([chunk], LLMOptions(enabled=True), provider=provider, cache=cache)
    second = extract_llm_assets([chunk], LLMOptions(enabled=True), provider=provider, cache=cache)

    assert provider.call_count == 6
    assert first.outputs["cards"][0]["cache_key"] == second.outputs["cards"][0]["cache_key"]


def _chunk(chunk_id, text):
    return Chunk(
        chunk_id=chunk_id,
        source_path="source.md",
        source_type="md",
        domain="education",
        mode="teaching",
        title="Source",
        text=text,
        order=0,
        char_count=len(text),
    )
