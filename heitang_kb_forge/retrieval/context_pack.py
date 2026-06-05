from pathlib import Path

from heitang_kb_forge.retrieval.ranker import rank_records


def make_context_pack(package: Path, records: list[dict], query: str, top_k: int = 5) -> tuple[dict, str]:
    selected = rank_records(records, query, top_k)
    pack = {
        "context_pack_version": "1.7.0",
        "package": str(package).replace("\\", "/"),
        "query": query,
        "selected_count": len(selected),
        "records": selected,
    }
    md = ["# Context Pack", "", f"- Query: {query}", f"- Selected records: {len(selected)}", ""]
    for item in selected:
        md.extend(
            [
                f"## {item.get('retrieval_id')}",
                "",
                f"- Asset type: {item.get('asset_type')}",
                f"- Citation: {item.get('citation') or '-'}",
                "",
                item.get("text", "")[:1000],
                "",
            ]
        )
    return pack, "\n".join(md)
