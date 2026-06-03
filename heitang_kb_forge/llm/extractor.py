from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

from heitang_kb_forge.llm.cache import LLMCache
from heitang_kb_forge.llm.fake_provider import FakeProvider
from heitang_kb_forge.llm.prompt_profile import render_prompt_profile_context
from heitang_kb_forge.llm.provider import LLMProvider, ProviderResponse
from heitang_kb_forge.schemas.chunk_schema import Chunk
from heitang_kb_forge.schemas.prompt_profile_schema import PromptProfile

EXTRACTION_TYPES = ["cards", "qa_pairs", "glossary", "frameworks", "case_cards", "metrics"]
OUTPUT_FILES = {
    "cards": "llm_cards.jsonl",
    "qa_pairs": "llm_qa_pairs.jsonl",
    "glossary": "llm_glossary.jsonl",
    "frameworks": "frameworks.jsonl",
    "case_cards": "case_cards.jsonl",
    "metrics": "metrics.jsonl",
}


@dataclass
class LLMOptions:
    enabled: bool = False
    provider: str = "fake"
    model: str = "fake-model"
    cache: bool = True
    strict: bool = False
    prompt_profile_path: Path | None = None
    prompt_profile: PromptProfile | None = None
    prompt_profile_hash: str | None = None


@dataclass
class LLMExtractionResult:
    outputs: dict[str, list[dict]] = field(default_factory=lambda: {name: [] for name in OUTPUT_FILES})
    warnings: list[str] = field(default_factory=list)
    output_files: list[str] = field(default_factory=lambda: list(OUTPUT_FILES.values()))


def create_provider(provider_name: str, model_name: str) -> LLMProvider:
    if provider_name == "fake":
        return FakeProvider(model_name=model_name)
    if provider_name == "fake-fail":
        return FakeProvider(model_name=model_name, fail=True)
    raise ValueError(f"Unsupported LLM provider: {provider_name}")


def extract_llm_assets(
    chunks: list[Chunk],
    options: LLMOptions,
    provider: LLMProvider | None = None,
    cache: LLMCache | None = None,
) -> LLMExtractionResult:
    result = LLMExtractionResult()
    if not options.enabled:
        return result

    provider = provider or create_provider(options.provider, options.model)
    cache = cache or LLMCache()

    for chunk in chunks:
        for extraction_type in EXTRACTION_TYPES:
            cache_key = cache.make_key(
                provider.provider_name,
                provider.model_name,
                extraction_type,
                chunk.chunk_id,
                chunk.text,
                options.prompt_profile_hash,
            )
            try:
                response_payload = cache.get(cache_key) if options.cache else None
                if response_payload is None:
                    response = provider.generate_json(_prompt(chunk, extraction_type, options.prompt_profile), extraction_type)
                    response_payload = _response_to_cache_payload(response)
                    if options.cache:
                        cache.set(cache_key, response_payload)
                result.outputs[extraction_type].extend(
                    _records_from_payload(response_payload, chunk, extraction_type, cache_key, options)
                )
            except Exception as exc:
                message = f"LLM {extraction_type} extraction failed for chunk {chunk.chunk_id}: {exc}"
                if options.strict:
                    raise RuntimeError(message) from exc
                result.warnings.append(message)

    return result


def _prompt(chunk: Chunk, extraction_type: str, prompt_profile: PromptProfile | None = None) -> str:
    profile_context = render_prompt_profile_context(prompt_profile)
    return f"""Extract {extraction_type} as JSON.
Return an object with an items array. Use only the chunk text. Return an empty items array if information is insufficient.
Do not invent facts that are not present in the source chunk. Preserve source grounding and citation.
{profile_context}
Source path: {chunk.source_path}
Chunk ID: {chunk.chunk_id}
Chunk text:
{chunk.text}
"""


def _response_to_cache_payload(response: ProviderResponse) -> dict:
    return {
        "payload": response.payload,
        "provider_name": response.provider_name,
        "model_name": response.model_name,
        "token_usage": response.token_usage,
        "latency_ms": response.latency_ms,
        "error": response.error,
    }


def _records_from_payload(
    response_payload: dict,
    chunk: Chunk,
    extraction_type: str,
    cache_key: str,
    options: LLMOptions,
) -> list[dict]:
    generated_at = datetime.now(timezone.utc).isoformat()
    payload = response_payload.get("payload", {})
    items = payload.get("items", []) if isinstance(payload, dict) else []
    records = []
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            continue
        record = {
            "llm_id": f"{extraction_type}_{chunk.chunk_id}_{index}",
            "extraction_type": extraction_type,
            "source_path": chunk.source_path,
            "chunk_id": chunk.chunk_id,
            "citation": f"{chunk.source_path}#chunk={chunk.chunk_id}",
            "llm_provider": response_payload["provider_name"],
            "llm_model": response_payload["model_name"],
            "confidence": item.get("confidence", 0.8),
            "token_usage": response_payload["token_usage"],
            "cache_key": cache_key,
            "prompt_profile": options.prompt_profile.profile_name if options.prompt_profile else None,
            "prompt_profile_hash": options.prompt_profile_hash,
            "generated_at": generated_at,
        }
        record.update(item)
        records.append(record)
    return records
