from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.agent_rag.retriever import retrieve_from_package, retrieve_from_store
from heitang_kb_forge.agent_tools.registry import get_agent_tool


def invoke_tool(name: str, input_file: Path) -> tuple[dict, dict]:
    get_agent_tool(name)
    payload = json.loads(input_file.read_text(encoding="utf-8"))
    if name == "retrieve_knowledge":
        query = payload["query"]
        top_k = int(payload.get("top_k", 5))
        if payload.get("store"):
            records, trace, citation_trace = retrieve_from_store(Path(payload["store"]), query, top_k)
        else:
            records, trace, citation_trace = retrieve_from_package(Path(payload["package"]), query, top_k)
        result = {
            "tool": name,
            "status": "success",
            "records": [record.model_dump(mode="json") for record in records],
            "citation_trace": citation_trace,
        }
        return result, _trace(name, payload, "success", trace)
    return {"tool": name, "status": "not_implemented"}, _trace(name, payload, "not_implemented", {})


def _trace(name: str, payload: dict, status: str, details: dict) -> dict:
    return {
        "tool_execution_trace_version": "1.6.0",
        "tool": name,
        "status": status,
        "input_keys": sorted(payload.keys()),
        "details": details,
    }
