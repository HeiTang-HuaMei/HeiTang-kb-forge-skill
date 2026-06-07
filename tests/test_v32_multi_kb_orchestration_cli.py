import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.exporters.jsonl_exporter import write_json


def test_orchestrate_multi_kb_command_writes_outputs(tmp_path):
    first = _package(tmp_path, "alpha", "Refund policy evidence.")
    second = _package(tmp_path, "beta", "Install policy evidence.")
    output = tmp_path / "orchestration"

    result = CliRunner().invoke(
        app,
        [
            "orchestrate-multi-kb",
            "--packages",
            f"{first},{second}",
            "--output",
            str(output),
            "--query",
            "policy",
        ],
    )

    assert result.exit_code == 0, result.output
    assert _json(output / "multi_kb_orchestration_manifest.json")["package_count"] == 2
    assert (output / "multi_kb_orchestration_trace.json").exists()


def _package(tmp_path, package_id, text):
    package = tmp_path / package_id
    package.mkdir()
    write_json(package / "manifest.json", {"package_id": package_id})
    (package / "chunks.jsonl").write_text(json.dumps({"chunk_id": "c1", "text": text}) + "\n", encoding="utf-8")
    return package


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
