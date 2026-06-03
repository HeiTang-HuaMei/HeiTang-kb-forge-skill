import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_build_knowledge_graph_export_writes_entities_and_manifest(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Product metric process fixture for knowledge graph export.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output), "--knowledge-graph-export"])

    assert result.exit_code == 0, result.output
    assert (output / "entities.jsonl").exists()
    assert (output / "relations.jsonl").exists()
    manifest = json.loads((output / "knowledge_graph_manifest.json").read_text(encoding="utf-8"))
    assert "entity_count" in manifest
