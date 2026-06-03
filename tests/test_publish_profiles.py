import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_publish_profile_generates_publish_package(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    publish = tmp_path / "publish"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Publish profile fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package), "--rag-export", "--downstream-export"]).exit_code == 0

    result = runner.invoke(app, ["publish", "--package", str(package), "--profile", "generic_rag", "--output", str(publish)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((publish / "publish_manifest.json").read_text(encoding="utf-8"))
    assert manifest["remote_publish_performed"] is False
    assert (publish / "export_profile.yaml").exists()
    assert (publish / "publish_package").exists()
