import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.processors.chunk_profiles import get_chunk_profile


def test_chunk_profile_rejects_unknown_profile():
    try:
        get_chunk_profile("unknown")
    except ValueError as exc:
        assert "Unsupported chunk profile" in str(exc)
    else:
        raise AssertionError("Expected unsupported profile to fail")


def test_build_records_chunk_profile(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Chunk profile fixture " * 100, encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output), "--chunk-profile", "rag_precise"])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["chunk_profile"] == "rag_precise"
