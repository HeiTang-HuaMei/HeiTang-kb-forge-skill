from pathlib import Path
import json
import re


NEGATION_WORDS = {"not", "never", "no", "不能", "不支持", "禁止", "不得"}
POSITIVE_WORDS = {"can", "supports", "allow", "支持", "可以", "允许"}


def detect_conflicts(package: Path) -> dict:
    chunks = _load_jsonl(package / "chunks.jsonl")
    by_key: dict[str, list[dict]] = {}
    for chunk in chunks:
        key = _key(chunk.get("title") or chunk.get("source_path") or "")
        by_key.setdefault(key, []).append(chunk)

    conflicts = []
    for key, items in by_key.items():
        if len(items) < 2:
            continue
        has_negative = any(_has_any(item.get("text", ""), NEGATION_WORDS) for item in items)
        has_positive = any(_has_any(item.get("text", ""), POSITIVE_WORDS) for item in items)
        if has_negative and has_positive:
            conflicts.append({"key": key, "chunk_ids": [item.get("chunk_id") for item in items]})

    return {
        "conflict_report_version": "1.7.0",
        "package": str(package).replace("\\", "/"),
        "conflict_count": len(conflicts),
        "conflicts": conflicts,
        "status": "warning" if conflicts else "pass",
    }


def _load_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _key(value: str) -> str:
    words = re.findall(r"[\w\u4e00-\u9fff]+", value.lower())
    return " ".join(words[:6]) or "package"


def _has_any(value: str, words: set[str]) -> bool:
    low = value.lower()
    return any(word in low for word in words)
