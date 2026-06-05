import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_mock_publish_does_not_call_external_platform(tmp_path):
    export = tmp_path / "export"
    output = tmp_path / "publish"
    export.mkdir()

    result = CliRunner().invoke(app, ["mock-publish", "--export", str(export), "--platform", "openclaw", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "mock_publish_result.json").read_text(encoding="utf-8"))
    assert payload["real_upload_performed"] is False
    assert payload["external_platform_called"] is False
    assert payload["network_call_performed"] is False
    assert payload["xhs_account_used"] is False
    assert payload["automatic_note_publish"] is False
