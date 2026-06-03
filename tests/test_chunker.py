from heitang_kb_forge.processors.chunker import chunk_text


def test_chunk_ids_are_stable():
    text = "Alpha paragraph.\n\nBeta paragraph."
    first = chunk_text(text, "example.md", "md", "education", "teaching")
    second = chunk_text(text, "example.md", "md", "education", "teaching")

    assert [chunk.chunk_id for chunk in first] == [chunk.chunk_id for chunk in second]


def test_chunker_splits_large_text():
    text = "A" * 80 + "\n\n" + "B" * 80
    chunks = chunk_text(text, "example.txt", "txt", "general", "reference", max_chars=90, overlap_chars=10)

    assert len(chunks) == 2
    assert all(chunk.char_count <= 90 for chunk in chunks)
