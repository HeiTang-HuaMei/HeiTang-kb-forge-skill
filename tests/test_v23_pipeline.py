import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v23_pipeline_reports_batch_governance_stages(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    config = tmp_path / "v23.yaml"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("v23 pipeline fixture.", encoding="utf-8")
    config.write_text(
        f"""
task: batch
input: {input_dir.as_posix()}
output: {output.as_posix()}
batch:
  retry_failed: false
package_lineage:
  enabled: true
curation:
  enabled: true
update_impact:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"]: stage for stage in manifest["stages"]}
    assert stages["batch_job_manifest"]["status"] == "success"
    assert stages["batch_item_status"]["status"] == "success"
    assert stages["batch_quality_summary"]["status"] == "success"
    assert stages["package_version_graph"]["status"] == "success"
    assert stages["curated_package_generation_v23"]["status"] == "success"
    assert stages["update_impact_analysis"]["status"] == "success"

