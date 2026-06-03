from collections import Counter

from pydantic import ValidationError

from heitang_kb_forge.schemas.chunk_schema import Chunk


REQUIRED_CHUNK_FIELDS = {"chunk_id", "source_path", "source_type", "domain", "mode", "text", "order", "char_count"}


def validate_chunks(chunks: list[Chunk | dict]) -> list[str]:
    warnings: list[str] = []
    seen_text: Counter[str] = Counter()

    for index, item in enumerate(chunks):
        data = item.model_dump() if isinstance(item, Chunk) else item
        missing = sorted(field for field in REQUIRED_CHUNK_FIELDS if field not in data or data[field] in (None, ""))
        if missing:
            warnings.append(f"chunk[{index}] missing fields: {', '.join(missing)}")

        text = str(data.get("text", ""))
        if not text.strip():
            warnings.append(f"chunk[{index}] is empty")
        else:
            seen_text[text.strip()] += 1

        try:
            Chunk.model_validate(data)
        except ValidationError as exc:
            warnings.append(f"chunk[{index}] schema error: {exc.errors()[0]['msg']}")

    for text, count in seen_text.items():
        if count > 1:
            preview = text[:60].replace("\n", " ")
            warnings.append(f"duplicate chunk text detected {count} times: {preview}")

    return warnings
