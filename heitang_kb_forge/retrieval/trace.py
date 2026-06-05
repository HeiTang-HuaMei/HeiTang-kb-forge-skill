from heitang_kb_forge.schemas.retrieval_schema import RetrievalTrace


def make_retrieval_trace(query: str, route: str, selected: list[dict], warnings: list[str] | None = None) -> RetrievalTrace:
    return RetrievalTrace(
        query=query,
        route=route,
        selected_ids=[item.get("retrieval_id", "") for item in selected],
        warnings=warnings or [],
    )
