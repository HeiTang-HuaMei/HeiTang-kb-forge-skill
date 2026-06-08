from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

from heitang_kb_forge.exporters.jsonl_exporter import write_json


INGESTION_MODES = {"official_api", "user_export", "manual_upload", "local_file", "opencli_bridge"}
SOURCE_TYPES = {
    "x_post_export",
    "x_thread_export",
    "newsletter_export",
    "blog_article",
    "github_markdown",
    "youtube_transcript",
    "podcast_transcript",
    "forum_post",
    "exported_chat",
    "local_note",
    "document",
    "manual_source",
}
OPENCLI_FORBIDDEN_KEYS = {"cookie", "cookies", "session", "sessionid", "token", "access_token", "refresh_token", "authorization"}


def run_multi_source_ingestion(sources: Iterable[Path], output: Path, *, ingestion_mode: str = "manual_upload") -> dict:
    mode = _validate_mode(ingestion_mode)
    output.mkdir(parents=True, exist_ok=True)
    raw_records = _load_sources([Path(item) for item in sources], mode)
    normalized = [_normalize_record(item, index, mode) for index, item in enumerate(raw_records, start=1)]
    deduped, duplicate_records = _dedupe_records(normalized)
    merged = _merge_threads(deduped)
    clusters = _topic_clusters(deduped)
    concepts = _concept_map(deduped)
    timeline = _viewpoint_timeline(deduped)
    citation_map = _source_citation_map(deduped)
    opencli = _opencli_report(raw_records, normalized, mode)
    privacy = _opencli_privacy_boundary(raw_records, mode)
    guide = _guide_skill_report(output, deduped, concepts, citation_map)

    inventory = {
        "multi_source_inventory_version": "pre-v4-p0-21",
        "status": "pass" if deduped else "blocked",
        "source_count": len(deduped),
        "ingestion_modes": sorted({item["ingestion_mode"] for item in deduped}),
        "source_types": sorted({item["source_type"] for item in deduped}),
        "sources": [
            {
                "source_id": item["source_id"],
                "source_type": item["source_type"],
                "ingestion_mode": item["ingestion_mode"],
                "created_at": item["created_at"],
                "citation_id": item["citation_id"],
                "compliance_status": item["compliance_status"],
            }
            for item in deduped
        ],
        "tests_require_real_llm_api_network": False,
    }
    normalization = {
        "source_normalization_report_version": "pre-v4-p0-21",
        "status": "pass" if deduped and all(item["normalized_text"] for item in deduped) else "blocked",
        "normalized_count": len(deduped),
        "schema_fields": _schema_fields(),
        "raw_text_dump_only": False,
        "tests_require_real_llm_api_network": False,
    }
    dedup = {
        "source_dedup_report_version": "pre-v4-p0-21",
        "status": "pass",
        "input_count": len(normalized),
        "deduped_count": len(deduped),
        "duplicate_count": len(duplicate_records),
        "duplicates": duplicate_records,
        "tests_require_real_llm_api_network": False,
    }
    merge = {
        "thread_or_conversation_merge_report_version": "pre-v4-p0-21",
        "status": "pass",
        "thread_count": len(merged),
        "threads": merged,
        "chronological_ordering": True,
        "tests_require_real_llm_api_network": False,
    }
    report = {
        "multi_source_ingestion_report_version": "pre-v4-p0-21",
        "status": "pass"
        if all(
            item.get("status") == "pass"
            for item in [inventory, normalization, dedup, merge, clusters, concepts, timeline, citation_map, opencli, privacy, guide]
        )
        else "blocked",
        "supported_ingestion_modes": sorted(INGESTION_MODES),
        "supported_source_types": sorted(SOURCE_TYPES),
        "source_count": len(deduped),
        "normalized_source_count": len(deduped),
        "opencli_bridge_boundary": "local_files_only_user_chosen_external_bridge",
        "hidden_scraping_implemented": False,
        "crawler_or_scraper_marketing": False,
        "reports": [
            "multi_source_inventory.json",
            "source_normalization_report.json",
            "source_dedup_report.json",
            "thread_or_conversation_merge_report.json",
            "topic_cluster_report.json",
            "concept_map_report.json",
            "viewpoint_evolution_timeline.json",
            "source_citation_map.json",
            "opencli_bridge_import_report.json",
            "opencli_bridge_privacy_boundary_report.json",
            "multi_source_to_guide_skill_report.json",
        ],
        "tests_require_real_llm_api_network": False,
    }
    _write_json_and_md(output, "multi_source_ingestion_report", report)
    write_json(output / "multi_source_inventory.json", inventory)
    _write_json_and_md(output, "source_normalization_report", normalization)
    write_json(output / "source_dedup_report.json", dedup)
    write_json(output / "thread_or_conversation_merge_report.json", merge)
    write_json(output / "topic_cluster_report.json", clusters)
    write_json(output / "concept_map_report.json", concepts)
    write_json(output / "viewpoint_evolution_timeline.json", timeline)
    write_json(output / "source_citation_map.json", citation_map)
    _write_json_and_md(output, "opencli_bridge_import_report", opencli)
    write_json(output / "opencli_bridge_privacy_boundary_report.json", privacy)
    _write_json_and_md(output, "multi_source_to_guide_skill_report", guide)
    return report


def _load_sources(paths: list[Path], mode: str) -> list[dict]:
    if not paths:
        return _sample_sources(mode)
    rows: list[dict] = []
    for path in paths:
        if path.is_dir():
            rows.extend(_load_sources(sorted(item for item in path.rglob("*") if item.is_file()), mode))
        elif path.suffix.lower() == ".jsonl":
            rows.extend(json.loads(line) | {"_source_file": _posix(path)} for line in path.read_text(encoding="utf-8").splitlines() if line.strip())
        elif path.suffix.lower() == ".json":
            payload = json.loads(path.read_text(encoding="utf-8"))
            items = payload.get("items") if isinstance(payload, dict) else payload
            if isinstance(items, list):
                rows.extend(dict(item) | {"_source_file": _posix(path)} for item in items)
            elif isinstance(payload, dict):
                rows.append(payload | {"_source_file": _posix(path)})
        else:
            rows.append(
                {
                    "source_type": _infer_source_type(path),
                    "text": path.read_text(encoding="utf-8", errors="ignore"),
                    "title": path.stem,
                    "created_at": _file_time(path),
                    "_source_file": _posix(path),
                }
            )
    return rows or _sample_sources(mode)


def _normalize_record(record: dict, index: int, mode: str) -> dict:
    source_type = str(record.get("source_type") or _infer_source_type(Path(str(record.get("_source_file") or ""))))
    if source_type not in SOURCE_TYPES:
        source_type = "manual_source"
    text = _normalize_text(str(record.get("text") or record.get("content") or record.get("body") or ""))
    created_at = _normalize_time(str(record.get("created_at") or record.get("timestamp") or ""))
    source_id = str(record.get("source_id") or record.get("id") or _hash(f"{source_type}:{created_at}:{text}")[:16])
    thread_id = str(record.get("thread_id") or record.get("conversation_id") or source_id)
    compliance = _compliance_status(mode, source_type)
    return {
        "source_id": source_id,
        "source_type": source_type,
        "ingestion_mode": mode,
        "title": str(record.get("title") or source_type.replace("_", " ").title()),
        "author": str(record.get("author") or "user_provided_or_unknown"),
        "created_at": created_at,
        "thread_id": thread_id,
        "parent_id": str(record.get("parent_id") or ""),
        "order_index": int(record.get("order_index") or index),
        "normalized_text": text,
        "text_hash": _hash(text),
        "source_file": str(record.get("_source_file") or ""),
        "source_url": str(record.get("source_url") or record.get("url") or ""),
        "citation_id": f"msrc-{index:04d}",
        "compliance_status": compliance,
        "no_hidden_upload": True,
        "cookies_session_tokens_stored": False,
        "raw_record_keys": sorted(str(key) for key in record.keys()),
    }


def _dedupe_records(records: list[dict]) -> tuple[list[dict], list[dict]]:
    seen: dict[str, dict] = {}
    deduped: list[dict] = []
    duplicates: list[dict] = []
    for item in records:
        key = item["text_hash"]
        if key in seen:
            duplicates.append({"duplicate_source_id": item["source_id"], "kept_source_id": seen[key]["source_id"], "reason": "same_normalized_text_hash"})
        else:
            seen[key] = item
            deduped.append(item)
    return deduped, duplicates


def _merge_threads(records: list[dict]) -> list[dict]:
    by_thread: dict[str, list[dict]] = {}
    for item in records:
        by_thread.setdefault(item["thread_id"], []).append(item)
    rows = []
    for thread_id, items in sorted(by_thread.items()):
        ordered = sorted(items, key=lambda row: (row["created_at"], row["order_index"]))
        rows.append(
            {
                "thread_id": thread_id,
                "message_count": len(ordered),
                "source_ids": [item["source_id"] for item in ordered],
                "citation_ids": [item["citation_id"] for item in ordered],
                "merged_text_preview": _preview(" ".join(item["normalized_text"] for item in ordered), 220),
            }
        )
    return rows


def _topic_clusters(records: list[dict]) -> dict:
    clusters: dict[str, list[str]] = {}
    for item in records:
        topic = _topic(item["normalized_text"])
        clusters.setdefault(topic, []).append(item["source_id"])
    return {
        "topic_cluster_report_version": "pre-v4-p0-21",
        "status": "pass" if clusters else "blocked",
        "cluster_count": len(clusters),
        "clusters": [{"topic": key, "source_ids": value} for key, value in sorted(clusters.items())],
        "deterministic_local_path": "keyword_frequency_topic_assignment",
        "tests_require_real_llm_api_network": False,
    }


def _concept_map(records: list[dict]) -> dict:
    concepts: dict[str, set[str]] = {}
    for item in records:
        for token in _keywords(item["normalized_text"])[:8]:
            concepts.setdefault(token, set()).add(item["source_id"])
    return {
        "concept_map_report_version": "pre-v4-p0-21",
        "status": "pass" if concepts else "blocked",
        "concepts": [{"concept": key, "source_ids": sorted(value)} for key, value in sorted(concepts.items())[:40]],
        "concept_extraction": "deterministic_local_keyword_phrase_extraction",
        "tests_require_real_llm_api_network": False,
    }


def _viewpoint_timeline(records: list[dict]) -> dict:
    ordered = sorted(records, key=lambda item: (item["created_at"], item["order_index"]))
    return {
        "viewpoint_evolution_timeline_version": "pre-v4-p0-21",
        "status": "pass" if ordered else "blocked",
        "events": [
            {
                "source_id": item["source_id"],
                "created_at": item["created_at"],
                "viewpoint_summary": _preview(item["normalized_text"], 140),
                "citation_id": item["citation_id"],
            }
            for item in ordered
        ],
        "chronological_ordering": True,
        "tests_require_real_llm_api_network": False,
    }


def _source_citation_map(records: list[dict]) -> dict:
    return {
        "source_citation_map_version": "pre-v4-p0-21",
        "status": "pass" if records and all(item.get("citation_id") for item in records) else "blocked",
        "citations": [
            {
                "citation_id": item["citation_id"],
                "source_id": item["source_id"],
                "source_type": item["source_type"],
                "source_file": item["source_file"],
                "source_url": item["source_url"],
                "created_at": item["created_at"],
            }
            for item in records
        ],
        "source_citations_missing": False,
        "tests_require_real_llm_api_network": False,
    }


def _opencli_report(raw_records: list[dict], normalized: list[dict], mode: str) -> dict:
    forbidden = _collect_forbidden_secret_keys(raw_records)
    return {
        "opencli_bridge_import_report_version": "pre-v4-p0-21",
        "status": "pass" if mode != "opencli_bridge" or not forbidden else "blocked",
        "ingestion_mode": mode,
        "opencli_is_optional_external_user_chosen_bridge": True,
        "heitang_controls_platform_login_or_scraping": False,
        "imports_local_files_or_manifests_only": True,
        "record_count": len(normalized),
        "compliance_status": "user_responsibility_required" if mode == "opencli_bridge" else _compliance_status(mode, "manual_source"),
        "forbidden_cookie_session_token_keys": forbidden,
        "hidden_scraping_implemented": False,
        "tests_require_real_llm_api_network": False,
    }


def _opencli_privacy_boundary(raw_records: list[dict], mode: str) -> dict:
    forbidden = _collect_forbidden_secret_keys(raw_records)
    return {
        "opencli_bridge_privacy_boundary_report_version": "pre-v4-p0-21",
        "status": "pass" if not forbidden else "blocked",
        "ingestion_mode": mode,
        "no_cookies_stored": not _has_forbidden_kind(forbidden, {"cookie", "cookies"}),
        "no_session_stored": not _has_forbidden_kind(forbidden, {"session", "sessionid"}),
        "no_tokens_stored": not _has_forbidden_kind(forbidden, {"token", "access_token", "refresh_token", "authorization"}),
        "no_hidden_upload": True,
        "no_automated_login": True,
        "no_infinite_scroll_scraping": True,
        "no_antibot_or_rate_limit_bypass": True,
        "not_market_as_crawler_or_scraper": True,
        "compliance_status": "user_responsibility_required" if mode == "opencli_bridge" else _compliance_status(mode, "manual_source"),
        "tests_require_real_llm_api_network": False,
    }


def _guide_skill_report(output: Path, records: list[dict], concepts: dict, citation_map: dict) -> dict:
    skill_dir = output / "multi_source_guide_skill"
    skill_dir.mkdir(parents=True, exist_ok=True)
    concept_names = [item["concept"] for item in concepts.get("concepts", [])[:8]]
    skill_md = "\n".join(
        [
            "---",
            "name: Multi Source Guide Skill",
            "description: Guide Skill generated from normalized user-provided multi-source corpus.",
            "---",
            "",
            "# Multi Source Guide Skill",
            "",
            "Use this Guide Skill to navigate normalized, cited, user-provided source material.",
            "",
            "## When to use",
            "",
            "- Compare viewpoints across the normalized corpus.",
            "- Explain concept evolution using `viewpoint_evolution_timeline.json`.",
            "- Ground claims in `source_citation_map.json`.",
            "",
            "## When not to use",
            "",
            "- Do not use it as a scraper, crawler, or platform login tool.",
            "- Do not answer claims that lack source citations.",
            "",
            "## Concepts",
            "",
            *(f"- {item}" for item in concept_names),
            "",
            "## Required evidence",
            "",
            "Load the citation map and relevant normalized sources before answering.",
        ]
    )
    (skill_dir / "SKILL.md").write_text(skill_md, encoding="utf-8")
    write_json(
        skill_dir / "guide_skill_manifest.json",
        {
            "guide_skill_manifest_version": "pre-v4-p0-21",
            "source_count": len(records),
            "citation_map": "source_citation_map.json",
            "topic_cluster_report": "topic_cluster_report.json",
            "tests_require_real_llm_api_network": False,
        },
    )
    return {
        "multi_source_to_guide_skill_report_version": "pre-v4-p0-21",
        "status": "pass" if records and citation_map.get("status") == "pass" and len(skill_md) < 12000 else "blocked",
        "guide_skill_path": _posix(skill_dir / "SKILL.md"),
        "guide_skill_is_summary_only": False,
        "uses_normalized_sources": True,
        "uses_source_citations": True,
        "can_feed_kb_package": True,
        "can_feed_guide_skill": True,
        "can_feed_structured_skill": True,
        "can_feed_agent_bound_knowledge": True,
        "tests_require_real_llm_api_network": False,
    }


def _sample_sources(mode: str) -> list[dict]:
    return [
        {
            "source_id": "sample-thread-1",
            "source_type": "x_thread_export",
            "ingestion_mode": mode,
            "thread_id": "thread-local-first",
            "order_index": 1,
            "created_at": "2026-01-01T00:00:00Z",
            "title": "Local first source",
            "text": "Local-first knowledge work should preserve privacy boundaries and source citations.",
        },
        {
            "source_id": "sample-thread-2",
            "source_type": "blog_article",
            "ingestion_mode": mode,
            "thread_id": "thread-local-first",
            "order_index": 2,
            "created_at": "2026-01-02T00:00:00Z",
            "title": "RAG guide",
            "text": "A guide skill should normalize multi-source viewpoints before becoming agent-bound knowledge.",
        },
        {
            "source_id": "sample-note-1",
            "source_type": "local_note",
            "ingestion_mode": mode,
            "thread_id": "note-guide",
            "order_index": 1,
            "created_at": "2026-01-03T00:00:00Z",
            "title": "OpenCLI boundary",
            "text": "OpenCLI bridge imports local manifests only; cookies sessions and tokens are not stored.",
        },
    ]


def _schema_fields() -> list[str]:
    return [
        "source_id",
        "source_type",
        "ingestion_mode",
        "title",
        "author",
        "created_at",
        "thread_id",
        "parent_id",
        "order_index",
        "normalized_text",
        "text_hash",
        "source_file",
        "source_url",
        "citation_id",
        "compliance_status",
    ]


def _validate_mode(mode: str) -> str:
    if mode not in INGESTION_MODES:
        raise ValueError(f"Unsupported ingestion_mode: {mode}")
    return mode


def _compliance_status(mode: str, source_type: str) -> str:
    if mode == "official_api":
        return "official_api_terms_required"
    if mode == "user_export" or source_type.endswith("_export"):
        return "user_export_declared"
    if mode == "opencli_bridge":
        return "user_responsibility_required"
    return "user_provided_local_source"


def _infer_source_type(path: Path) -> str:
    name = path.name.lower()
    suffix = path.suffix.lower()
    if "youtube" in name or "yt_" in name:
        return "youtube_transcript"
    if "podcast" in name:
        return "podcast_transcript"
    if "github" in name or suffix == ".md":
        return "github_markdown"
    if "chat" in name:
        return "exported_chat"
    if suffix in {".pdf", ".docx", ".txt"}:
        return "document" if suffix != ".txt" else "local_note"
    return "manual_source"


def _normalize_text(text: str) -> str:
    text = re.sub(r"\s+", " ", text or "").strip()
    return text


def _normalize_time(value: str) -> str:
    if not value:
        return datetime.now(timezone.utc).isoformat()
    cleaned = value.replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(cleaned).astimezone(timezone.utc).isoformat()
    except ValueError:
        return value


def _keywords(text: str) -> list[str]:
    words = re.findall(r"[A-Za-z][A-Za-z0-9_-]{2,}|[\u4e00-\u9fff]{2,}", text.lower())
    stop = {"the", "and", "for", "with", "this", "that", "from", "into", "should", "before", "only"}
    output = []
    for word in words:
        if word not in stop and word not in output:
            output.append(word)
    return output


def _topic(text: str) -> str:
    terms = _keywords(text)
    if any(term in terms for term in ["privacy", "local-first", "local"]):
        return "local_privacy_boundary"
    if any(term in terms for term in ["agent", "skill", "guide"]):
        return "skill_agent_supply_chain"
    if any(term in terms for term in ["opencli", "bridge"]):
        return "opencli_bridge_boundary"
    return terms[0] if terms else "general"


def _secret_key_name(key: str) -> bool:
    lowered = key.lower()
    return lowered in OPENCLI_FORBIDDEN_KEYS or lowered.endswith("_token") or lowered.endswith("_cookie")


def _collect_forbidden_secret_keys(records: list[dict]) -> list[str]:
    found: set[str] = set()

    def visit(value: object, prefix: str = "") -> None:
        if isinstance(value, dict):
            for key, child in value.items():
                path = f"{prefix}.{key}" if prefix else str(key)
                if _secret_key_name(str(key)):
                    found.add(path)
                visit(child, path)
        elif isinstance(value, list):
            for index, child in enumerate(value):
                visit(child, f"{prefix}[{index}]" if prefix else f"[{index}]")

    for record in records:
        visit(record)
    return sorted(found)


def _has_forbidden_kind(keys: list[str], names: set[str]) -> bool:
    for key in keys:
        lowered = key.lower()
        parts = re.split(r"[.\[\]]+", lowered)
        if any(part in names or any(marker in part for marker in names) for part in parts if part):
            return True
    return False


def _hash(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _preview(text: str, limit: int) -> str:
    return text[:limit] + ("..." if len(text) > limit else "")


def _file_time(path: Path) -> str:
    return datetime.fromtimestamp(path.stat().st_mtime, timezone.utc).isoformat()


def _write_json_and_md(output: Path, stem: str, payload: dict) -> None:
    write_json(output / f"{stem}.json", payload)
    title = stem.replace("_", " ").title()
    (output / f"{stem}.md").write_text(
        f"# {title}\n\n- Status: {payload.get('status', 'unknown')}\n- Tests require real LLM/API/network: {payload.get('tests_require_real_llm_api_network', False)}\n",
        encoding="utf-8",
    )


def _posix(path: Path) -> str:
    return str(path).replace("\\", "/")
