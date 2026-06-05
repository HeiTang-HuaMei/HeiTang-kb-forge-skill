import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v23_config_generates_batch_and_governance_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    config = tmp_path / "v23.yaml"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("v23 config fixture.", encoding="utf-8")
    config.write_text(
        f"""
task: batch
input: {input_dir.as_posix()}
output: {output.as_posix()}
batch:
  profile: production
  retry_failed: true
  resume_batch: true
package_lineage:
  enabled: true
curation:
  enabled: true
  build_curated_package: true
update_impact:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    assert (output / "batch_job_manifest.json").exists()
    assert (output / "batch_item_status.jsonl").exists()
    assert (output / "package_version_graph.json").exists()
    assert (output / "curated_package" / "governance_decisions.jsonl").exists()
    assert (output / "impacted_skills.json").exists()
    assert (output / "impacted_agents.json").exists()
    assert json.loads((output / "batch_quality_summary.json").read_text(encoding="utf-8"))["failed_source_count"] == 0

