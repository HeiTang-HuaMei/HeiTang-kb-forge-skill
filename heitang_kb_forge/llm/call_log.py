from pathlib import Path
import json


SENSITIVE_KEYS = {"api_key", "authorization", "token", "secret"}


def write_call_log(path: Path, record: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    safe = _sanitize(record)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(safe, ensure_ascii=False) + "\n")


def _sanitize(value):
    if isinstance(value, dict):
        return {
            key: ("[REDACTED]" if key.lower() in SENSITIVE_KEYS else _sanitize(item))
            for key, item in value.items()
        }
    if isinstance(value, list):
        return [_sanitize(item) for item in value]
    return value
