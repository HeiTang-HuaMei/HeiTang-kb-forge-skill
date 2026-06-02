from kb_forge.processors.validator import validate_chunks


def test_validator_detects_empty_chunk():
    warnings = validate_chunks(
        [
            {
                "chunk_id": "a",
                "source_path": "x.md",
                "source_type": "md",
                "domain": "education",
                "mode": "teaching",
                "text": "",
                "order": 0,
                "char_count": 0,
            }
        ]
    )

    assert any("empty" in warning for warning in warnings)


def test_validator_detects_duplicate_text():
    base = {
        "source_path": "x.md",
        "source_type": "md",
        "domain": "education",
        "mode": "teaching",
        "text": "same text",
        "char_count": 9,
    }
    warnings = validate_chunks([{**base, "chunk_id": "a", "order": 0}, {**base, "chunk_id": "b", "order": 1}])

    assert any("duplicate" in warning for warning in warnings)


def test_validator_detects_missing_fields():
    warnings = validate_chunks([{"chunk_id": "a", "text": "content"}])

    assert any("missing fields" in warning for warning in warnings)
