import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_provider_readiness_is_offline_and_no_api_keys(tmp_path):
    result = CliRunner().invoke(app, ["provider-readiness", "--workspace", str(tmp_path / "workspace"), "--output", str(tmp_path / "out")])

    assert result.exit_code == 0, result.output
    readiness = json.loads((tmp_path / "out" / "provider_readiness_result.json").read_text(encoding="utf-8"))
    assert readiness["network_required"] is False
    assert readiness["api_keys_stored"] is False

