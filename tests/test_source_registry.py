import json

from heitang_kb_forge.lifecycle.source_registry import make_source_registry


def test_source_registry_records_stable_source_metadata(tmp_path):
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    source = input_dir / "lesson.md"
    source.write_text("Lifecycle source registry fixture", encoding="utf-8")

    registry = make_source_registry(input_dir, [source])
    payload = registry.model_dump(mode="json")

    assert payload["source_count"] == 1
    record = payload["sources"][0]
    assert record["relative_path"] == "lesson.md"
    assert record["extension"] == ".md"
    assert record["content_hash"]
    assert json.dumps(payload)
