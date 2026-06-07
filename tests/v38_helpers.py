import json
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_jsonl
from heitang_kb_forge.retrieval.query_planning import build_retrieval_plan, write_query_planning_outputs


def make_package(tmp_path: Path) -> Path:
    package = tmp_path / "package"
    package.mkdir()
    chunks = [
        {
            "chunk_id": "c1",
            "source_path": "pricing.md",
            "text": "Pricing is 20 dollars. Revenue is growing. The pricing policy is active in 2026.",
            "metadata": {"date": "2026-01-01", "trusted_source": True},
        },
        {
            "chunk_id": "c2",
            "source_path": "revenue.md",
            "text": "Revenue is growing and margin is stable. The source is fresh.",
            "metadata": {"date": "2026-02-01", "trusted_source": True},
        },
        {
            "chunk_id": "c3",
            "source_path": "old.md",
            "text": "Legacy pricing is 15 dollars. This old note is stale.",
            "metadata": {"date": "2020-01-01", "freshness_status": "stale", "review_required": True},
        },
    ]
    cards = [
        {"chunk_id": "card1", "source_path": "pricing.md", "title": "Pricing", "summary": "Pricing is 20 dollars and is supported by cited source."}
    ]
    qa_pairs = [
        {"chunk_id": "qa1", "source_path": "pricing.md", "question": "What is pricing?", "answer": "Pricing is 20 dollars.", "citation": "pricing.md#chunk=c1"}
    ]
    write_jsonl(package / "chunks.jsonl", chunks)
    write_jsonl(package / "cards.jsonl", cards)
    write_jsonl(package / "qa_pairs.jsonl", qa_pairs)
    write_jsonl(package / "glossary.jsonl", [])
    (package / "manifest.json").write_text(json.dumps({"package_id": "pkg_v38"}, indent=2), encoding="utf-8")
    plan = build_retrieval_plan("compare pricing and revenue", package=package, domain="finance", max_rewrites=5)
    write_query_planning_outputs(package, plan)
    return package


def make_verification_source(tmp_path: Path, text: str | None = None) -> Path:
    source = tmp_path / "verification.jsonl"
    row = {
        "source_id": "verify_pricing",
        "source_path": "verification.md",
        "text": text or "Pricing is 20 dollars. Revenue is growing. The pricing policy is active in 2026.",
        "date": "2026-01-01",
        "trusted_source": True,
    }
    source.write_text(json.dumps(row) + "\n", encoding="utf-8")
    return source


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))
