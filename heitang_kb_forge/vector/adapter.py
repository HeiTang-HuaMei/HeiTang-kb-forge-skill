SUPPORTED_LOCAL_STORES = {"local_json", "fake"}
PLANNED_STORES = {"faiss", "chroma", "qdrant", "milvus"}


def validate_vector_store(store: str) -> None:
    if store in SUPPORTED_LOCAL_STORES:
        return
    if store in PLANNED_STORES:
        raise RuntimeError(f"Vector store '{store}' is configured but real write is not implemented in v0.9.0")
    raise ValueError(f"Unsupported vector store: {store}")
