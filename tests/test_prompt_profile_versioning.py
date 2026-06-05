import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_prompt_profile_versioning_writes_versions_and_hashes(tmp_path):
    workspace = tmp_path / "workspace"
    workspace.mkdir()
    (workspace / "profile.yaml").write_text("rules:\n  - be concise\n", encoding="utf-8")

    result = CliRunner().invoke(app, ["prompt-profile-versioning", "--workspace", str(workspace), "--output", str(tmp_path / "out")])

    assert result.exit_code == 0, result.output
    versions = json.loads((tmp_path / "out" / "prompt_profile_versions.json").read_text(encoding="utf-8"))
    assert versions["profiles"][0]["profile_id"] == "profile"
    assert (tmp_path / "out" / "prompt_profile_hashes.json").exists()

