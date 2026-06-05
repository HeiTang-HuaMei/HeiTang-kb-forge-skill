import json
from pathlib import Path


def write_sample_package(path: Path, text: str = "HeiTang evidence package supports governance retrieval.") -> Path:
    path.mkdir(parents=True, exist_ok=True)
    chunk = {
        "chunk_id": "chunk_1",
        "source_path": "input/sample.md",
        "source_type": "md",
        "domain": "education",
        "mode": "teaching",
        "title": "HeiTang Evidence",
        "text": text,
        "order": 0,
        "char_count": len(text),
        "metadata": {},
    }
    card = {
        "card_id": "card_1",
        "chunk_id": "chunk_1",
        "title": "HeiTang Evidence",
        "summary": text,
        "source_path": "input/sample.md",
        "domain": "education",
        "mode": "teaching",
        "citation": "input/sample.md#chunk=chunk_1",
    }
    qa = {
        "qa_id": "qa_1",
        "chunk_id": "chunk_1",
        "question": "What does HeiTang support?",
        "answer": text,
        "source_path": "input/sample.md",
        "domain": "education",
        "mode": "teaching",
        "citation": "input/sample.md#chunk=chunk_1",
    }
    glossary = {
        "term": "HeiTang",
        "definition": text,
        "source_path": "input/sample.md",
        "chunk_id": "chunk_1",
        "citation": "input/sample.md#chunk=chunk_1",
    }
    _write_jsonl(path / "chunks.jsonl", [chunk])
    _write_jsonl(path / "cards.jsonl", [card])
    _write_jsonl(path / "qa_pairs.jsonl", [qa])
    _write_jsonl(path / "glossary.jsonl", [glossary])
    _write_json(path / "manifest.json", {"generated_at": "2026-06-05T00:00:00+00:00", "files": []})
    _write_json(path / "quality_report.json", {"quality_score": 90, "quality_level": "excellent"})
    (path / "ingest_report.md").write_text("# Report\n", encoding="utf-8")
    return path


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def read_jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _write_json(path: Path, payload: dict) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")


def _write_jsonl(path: Path, records: list[dict]) -> None:
    path.write_text("\n".join(json.dumps(record, ensure_ascii=False) for record in records) + "\n", encoding="utf-8")
