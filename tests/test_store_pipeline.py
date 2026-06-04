import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_store_config_pipeline_imports_and_exports_index(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    db_path = tmp_path / "kb_forge_workspace.db"
    config_path = tmp_path / "store.pipeline.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Store pipeline fixture.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
domain: product
store:
  enabled: true
  db_path: {db_path.as_posix()}
  import_package: true
  export_index: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert (output_dir / "store_manifest.json").exists()
    assert (output_dir / "store_package_index.jsonl").exists()
    manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"]: stage for stage in manifest["stages"]}
    assert stages["local_store_export_index"]["status"] == "success"
