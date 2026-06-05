import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_platform_upload_check_never_allows_real_upload(tmp_path):
    export = tmp_path / "export"
    check = tmp_path / "check"
    export.mkdir()
    for file_name in ["platform_manifest.json", "platform_upload_check_result.json", "platform_upload_check_report.md", "mock_publish_result.json", "install_guide.md", "upload_guide.md"]:
        (export / file_name).write_text("{}", encoding="utf-8")

    result = CliRunner().invoke(app, ["platform-upload-check", "--export", str(export), "--output", str(check), "--platform", "generic"])

    assert result.exit_code == 0, result.output
    payload = json.loads((check / "platform_upload_check_result.json").read_text(encoding="utf-8"))
    assert payload["real_upload_allowed"] is False

