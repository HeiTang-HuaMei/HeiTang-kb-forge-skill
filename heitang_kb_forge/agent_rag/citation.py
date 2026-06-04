def make_citation(source_path: str, chunk_id: str) -> str:
    return f"{source_path}#chunk={chunk_id}"


def make_citation_trace(records: list[dict]) -> dict:
    return {
        "citation_trace_version": "1.5.0",
        "citations": [
            {
                "embedding_id": record["embedding_id"],
                "source_path": record["source_path"],
                "chunk_id": record["chunk_id"],
                "citation": record["citation"],
            }
            for record in records
        ],
    }
