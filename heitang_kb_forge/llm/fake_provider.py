import re

from heitang_kb_forge.llm.provider import ProviderResponse


class FakeProvider:
    provider_name = "fake"

    def __init__(self, model_name: str = "fake-model", fail: bool = False) -> None:
        self.model_name = model_name
        self.fail = fail
        self.call_count = 0

    def generate_json(self, prompt: str, schema_name: str) -> ProviderResponse:
        self.call_count += 1
        if self.fail:
            raise RuntimeError("Fake LLM provider failed")
        chunk_text = _extract_prompt_value(prompt, "Chunk text")
        title = _short_text(chunk_text)
        payload = _payload(schema_name, title, chunk_text)
        return ProviderResponse(
            payload=payload,
            provider_name=self.provider_name,
            model_name=self.model_name,
            token_usage={"input_tokens": 32, "output_tokens": 16},
            latency_ms=1,
        )


def _payload(schema_name: str, title: str, chunk_text: str) -> dict:
    if schema_name == "cards":
        return {"items": [{"title": title, "summary": chunk_text[:160], "confidence": 0.8}]}
    if schema_name == "qa_pairs":
        return {"items": [{"question": f"What is {title}?", "answer": chunk_text[:160], "confidence": 0.8}]}
    if schema_name == "glossary":
        return {"items": [{"term": title, "definition": chunk_text[:160], "confidence": 0.8}]}
    if schema_name == "frameworks":
        return {"items": [{"name": title, "summary": chunk_text[:160], "confidence": 0.8}]}
    if schema_name == "case_cards":
        return {"items": [{"title": title, "case_summary": chunk_text[:160], "confidence": 0.8}]}
    if schema_name == "metrics":
        return {"items": [{"name": title, "definition": chunk_text[:160], "confidence": 0.8}]}
    return {"items": []}


def _extract_prompt_value(prompt: str, label: str) -> str:
    match = re.search(rf"{re.escape(label)}:\n(.+)", prompt, flags=re.DOTALL)
    return match.group(1).strip() if match else prompt.strip()


def _short_text(value: str) -> str:
    words = re.findall(r"[\w\u4e00-\u9fff]+", value)
    return " ".join(words[:6]) or "LLM extracted item"
