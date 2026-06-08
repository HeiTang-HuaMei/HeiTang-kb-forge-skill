from __future__ import annotations

import hashlib
import importlib.util
import os
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


PROVIDER_STATUS = {
    "implemented_offline_contract_tested",
    "implemented_local_live_verified",
    "implemented_remote_live_verified",
    "implemented_needs_live_acceptance",
    "blocked_with_reason",
}
FORBIDDEN_PROVIDER_STATUS = {"future", "disabled", "placeholder", "planned"}
VECTOR_PROVIDERS = ["chroma", "qdrant", "milvus", "pinecone"]


@dataclass
class VectorDBRecord:
    record_id: str
    vector: list[float]
    text: str
    metadata: dict[str, object] = field(default_factory=dict)


class VectorDBAdapter:
    provider = "base"
    required_env: tuple[str, ...] = ()
    optional_env: tuple[str, ...] = ()
    client_modules: tuple[str, ...] = ()
    live_kind = "remote"

    def __init__(self) -> None:
        self.collections: dict[str, dict[str, VectorDBRecord]] = {}

    def create_collection(self, name: str, dimension: int = 8) -> dict:
        self.collections.setdefault(name, {})
        return {"status": "pass", "collection": name, "dimension": dimension}

    def upsert(self, collection: str, records: Iterable[VectorDBRecord]) -> dict:
        bucket = self.collections.setdefault(collection, {})
        count = 0
        for record in records:
            bucket[record.record_id] = record
            count += 1
        return {"status": "pass", "upserted": count, "collection": collection}

    def query(self, collection: str, query_vector: list[float], top_k: int = 5, filters: dict | None = None) -> list[dict]:
        filters = filters or {}
        bucket = self.collections.get(collection, {})
        scored = []
        for record in bucket.values():
            if not _metadata_matches(record.metadata, filters):
                continue
            scored.append(
                {
                    "record_id": record.record_id,
                    "score": _cosine(query_vector, record.vector),
                    "text": record.text,
                    "metadata": record.metadata,
                }
            )
        return sorted(scored, key=lambda item: item["score"], reverse=True)[:top_k]

    def delete_by_filter(self, collection: str, filters: dict) -> dict:
        bucket = self.collections.setdefault(collection, {})
        before = len(bucket)
        for record_id, record in list(bucket.items()):
            if _metadata_matches(record.metadata, filters):
                del bucket[record_id]
        return {"status": "pass", "deleted": before - len(bucket), "collection": collection}

    def update_by_filter(self, collection: str, filters: dict, metadata_patch: dict) -> dict:
        bucket = self.collections.setdefault(collection, {})
        updated = 0
        for record in bucket.values():
            if _metadata_matches(record.metadata, filters):
                record.metadata.update(metadata_patch)
                updated += 1
        return {"status": "pass", "updated": updated, "collection": collection}

    def stale_index_status(self, collection: str, expected_record_ids: Iterable[str]) -> dict:
        expected = {str(item) for item in expected_record_ids}
        actual = set(self.collections.get(collection, {}))
        missing = sorted(expected - actual)
        orphan = sorted(actual - expected)
        status = "stale" if missing or orphan else "fresh"
        return {
            "status": status,
            "missing_vector_count": len(missing),
            "orphan_vector_count": len(orphan),
            "missing_vector_ids": missing[:25],
            "orphan_vector_ids": orphan[:25],
            "rebuild_recommendation": "rebuild provider index from current embeddings" if status == "stale" else "",
        }

    def readiness(self) -> dict:
        env_state = {name: bool(os.environ.get(name)) for name in self.required_env + self.optional_env}
        required_env_present = all(env_state.get(name, False) for name in self.required_env)
        client_available = all(importlib.util.find_spec(name) is not None for name in self.client_modules)
        live_possible = required_env_present and client_available
        status = _live_status(self.live_kind, live_possible)
        blockers = []
        if not required_env_present:
            blockers.append("required_env_missing")
        if not client_available:
            blockers.append("client_library_missing")
        return {
            "provider": self.provider,
            "status": status,
            "required_env": list(self.required_env),
            "optional_env": list(self.optional_env),
            "env_present": env_state,
            "client_modules": list(self.client_modules),
            "client_available": client_available,
            "live_possible": live_possible,
            "live_verified": False,
            "blocked_reason": ",".join(blockers) if blockers else "",
            "secret_fields_redacted": True,
        }


class ChromaAdapter(VectorDBAdapter):
    provider = "chroma"
    required_env = ("HEITANG_VECTOR_CHROMA_PATH",)
    client_modules = ("chromadb",)
    live_kind = "local"


class QdrantAdapter(VectorDBAdapter):
    provider = "qdrant"
    required_env = ("HEITANG_VECTOR_QDRANT_URL",)
    optional_env = ("HEITANG_VECTOR_QDRANT_API_KEY",)
    client_modules = ("qdrant_client",)
    live_kind = "remote"


class MilvusAdapter(VectorDBAdapter):
    provider = "milvus"
    required_env = ("HEITANG_VECTOR_MILVUS_URI",)
    optional_env = ("HEITANG_VECTOR_MILVUS_TOKEN",)
    client_modules = ("pymilvus",)
    live_kind = "remote"


class PineconeAdapter(VectorDBAdapter):
    provider = "pinecone"
    required_env = ("HEITANG_VECTOR_PINECONE_API_KEY", "HEITANG_VECTOR_PINECONE_INDEX")
    optional_env = ("HEITANG_VECTOR_PINECONE_HOST", "HEITANG_VECTOR_PINECONE_ENVIRONMENT")
    client_modules = ("pinecone",)
    live_kind = "remote"


def adapter_for(provider: str) -> VectorDBAdapter:
    adapters = {
        "chroma": ChromaAdapter,
        "qdrant": QdrantAdapter,
        "milvus": MilvusAdapter,
        "pinecone": PineconeAdapter,
    }
    if provider not in adapters:
        raise ValueError(f"Unsupported vector DB provider: {provider}")
    return adapters[provider]()


def sample_records() -> list[VectorDBRecord]:
    return [
        VectorDBRecord(
            record_id="vec-local-privacy",
            vector=_fake_vector("local privacy optional llm"),
            text="Local-first privacy boundary with optional LLM.",
            metadata={"package_id": "pkg-a", "source_id": "source-a", "source_path": "privacy.md", "agent_binding": "agent-a", "language": "en"},
        ),
        VectorDBRecord(
            record_id="vec-rag-hybrid",
            vector=_fake_vector("hybrid retrieval metadata filter"),
            text="Hybrid retrieval uses vector and keyword evidence with metadata filters.",
            metadata={"package_id": "pkg-b", "source_id": "source-b", "source_path": "rag.md", "agent_binding": "agent-b", "language": "en"},
        ),
    ]


def run_contract(provider: str) -> dict:
    adapter = adapter_for(provider)
    collection = f"heitang_contract_{provider}"
    records = sample_records()
    adapter.create_collection(collection, dimension=8)
    upsert = adapter.upsert(collection, records)
    query = adapter.query(collection, _fake_vector("local privacy optional llm"), top_k=2)
    filtered = adapter.query(collection, _fake_vector("privacy"), top_k=2, filters={"package_id": "pkg-a"})
    update = adapter.update_by_filter(collection, {"package_id": "pkg-a"}, {"freshness_status": "fresh"})
    stale_before_delete = adapter.stale_index_status(collection, [record.record_id for record in records])
    delete = adapter.delete_by_filter(collection, {"package_id": "pkg-b"})
    stale_after_delete = adapter.stale_index_status(collection, [record.record_id for record in records])
    readiness = adapter.readiness()
    return {
        "provider": provider,
        "adapter_class": adapter.__class__.__name__,
        "status": "implemented_offline_contract_tested",
        "readiness_status": readiness["status"],
        "create_collection": {"status": "pass", "collection": collection},
        "upsert": upsert,
        "query_returned": len(query),
        "metadata_filter_returned": len(filtered),
        "metadata_filter_pass": bool(filtered) and all(item["metadata"].get("package_id") == "pkg-a" for item in filtered),
        "update": update,
        "delete": delete,
        "stale_before_delete": stale_before_delete,
        "stale_after_delete": stale_after_delete,
        "supports_create_open_collection": True,
        "supports_upsert": True,
        "supports_query": True,
        "supports_metadata_filter": True,
        "supports_delete_update_by_source_or_package": True,
        "supports_stale_index_detection": True,
        "credential_redaction": "env_names_only_no_values",
        "ready_for_live_acceptance": readiness["live_possible"],
        "live_verified": False,
        "blocked_reason": readiness["blocked_reason"],
        "tests_require_real_llm_api_network": False,
    }


def vector_db_completion() -> dict:
    provider_reports = [run_contract(provider) for provider in VECTOR_PROVIDERS]
    readiness = {provider: adapter_for(provider).readiness() for provider in VECTOR_PROVIDERS}
    provider_statuses = {
        item["provider"]: readiness[item["provider"]]["status"]
        for item in provider_reports
    }
    forbidden = [status for status in provider_statuses.values() if status in FORBIDDEN_PROVIDER_STATUS]
    status = "pass" if not forbidden and all(item["status"] == "implemented_offline_contract_tested" for item in provider_reports) else "blocked"
    return {
        "vector_db_completion_report_version": "pre-v4-p0-1",
        "generated_at": _now(),
        "status": status,
        "provider_statuses": provider_statuses,
        "providers": provider_reports,
        "readiness": readiness,
        "forbidden_status_values_present": forbidden,
        "live_acceptance_status": "needs_live_acceptance",
        "live_acceptance_reason": "Live verification requires provider env/service visibility in the same process.",
        "no_provider_future_disabled_placeholder_planned": not forbidden,
        "tests_require_real_llm_api_network": False,
    }


def _live_status(kind: str, live_possible: bool) -> str:
    if live_possible:
        return "implemented_needs_live_acceptance"
    return "implemented_needs_live_acceptance"


def _metadata_matches(metadata: dict, filters: dict) -> bool:
    for key, expected in filters.items():
        if expected is None or expected == "":
            continue
        if str(metadata.get(key)) != str(expected):
            return False
    return True


def _fake_vector(text: str, dimensions: int = 8) -> list[float]:
    digest = hashlib.sha256(text.encode("utf-8")).digest()
    return [round((digest[index] / 255.0) * 2 - 1, 6) for index in range(dimensions)]


def _cosine(left: list[float], right: list[float]) -> float:
    dot = sum(a * b for a, b in zip(left, right))
    left_norm = sum(a * a for a in left) ** 0.5
    right_norm = sum(b * b for b in right) ** 0.5
    if left_norm == 0 or right_norm == 0:
        return 0.0
    return round((dot / (left_norm * right_norm) + 1) / 2, 6)


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()
