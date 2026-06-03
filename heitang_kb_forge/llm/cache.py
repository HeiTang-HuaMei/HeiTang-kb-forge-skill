import hashlib
import json
from pathlib import Path


PROMPT_VERSION = "v0.5.0"


class LLMCache:
    def __init__(self, root: Path = Path(".heitang_cache") / "llm") -> None:
        self.root = root

    def make_key(
        self,
        provider: str,
        model: str,
        extraction_type: str,
        chunk_id: str,
        text: str,
        prompt_profile_hash: str | None = None,
    ) -> str:
        parts = [
            provider,
            model,
            PROMPT_VERSION,
            extraction_type,
            chunk_id,
            hashlib.sha256(text.encode("utf-8")).hexdigest(),
        ]
        if prompt_profile_hash:
            parts.append(prompt_profile_hash)
        payload = "|".join(parts)
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()

    def get(self, cache_key: str) -> dict | None:
        path = self._path(cache_key)
        if not path.exists():
            return None
        return json.loads(path.read_text(encoding="utf-8"))

    def set(self, cache_key: str, payload: dict) -> None:
        path = self._path(cache_key)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    def _path(self, cache_key: str) -> Path:
        return self.root / f"{cache_key}.json"
