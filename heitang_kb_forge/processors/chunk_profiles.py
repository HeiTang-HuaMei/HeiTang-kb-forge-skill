from dataclasses import dataclass


@dataclass(frozen=True)
class ChunkProfile:
    name: str
    max_chars: int
    overlap_chars: int
    heading_preservation: bool = True
    table_row_grouping: bool = True
    citation_style: str = "source_chunk"


CHUNK_PROFILES = {
    "default": ChunkProfile("default", 1200, 120),
    "rag_precise": ChunkProfile("rag_precise", 800, 100),
    "long_context": ChunkProfile("long_context", 2000, 160),
    "qa_agent": ChunkProfile("qa_agent", 900, 90),
    "shopping_guide": ChunkProfile("shopping_guide", 700, 80),
    "education_tutor": ChunkProfile("education_tutor", 1000, 120),
}


def get_chunk_profile(name: str) -> ChunkProfile:
    if name not in CHUNK_PROFILES:
        raise ValueError(f"Unsupported chunk profile: {name}")
    return CHUNK_PROFILES[name]
