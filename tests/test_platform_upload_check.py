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


def test_platform_upload_check_detects_missing_required_files(tmp_path):
    export = tmp_path / "export"
    check = tmp_path / "check"
    export.mkdir()
    (export / "platform_manifest.json").write_text('{"platform":"generic"}', encoding="utf-8")

    result = CliRunner().invoke(app, ["platform-upload-check", "--export", str(export), "--output", str(check), "--platform", "generic"])

    assert result.exit_code == 0, result.output
    payload = json.loads((check / "platform_upload_check_result.json").read_text(encoding="utf-8"))
    assert payload["status"] == "failed"
    assert payload["required_files_present"] is False
    assert "generic_platform_profile.json" in payload["missing_files"]


def test_platform_upload_check_detects_api_key_risk(tmp_path):
    export = tmp_path / "export"
    check = tmp_path / "check"
    export.mkdir()
    for file_name in ["platform_manifest.json", "mock_publish_result.json", "install_guide.md", "upload_guide.md", "generic_platform_profile.json"]:
        (export / file_name).write_text("{}", encoding="utf-8")
    (export / "secret.md").write_text("api_key: abcdefghijklmnopqrstuvwxyz", encoding="utf-8")

    result = CliRunner().invoke(app, ["platform-upload-check", "--export", str(export), "--output", str(check), "--platform", "generic"])

    assert result.exit_code == 0, result.output
    payload = json.loads((check / "platform_upload_check_result.json").read_text(encoding="utf-8"))
    assert payload["status"] == "failed"
    assert payload["api_key_risk_detected"] is True
    assert "secret.md" in payload["risk_files"]


def test_platform_upload_check_detects_dangerous_command(tmp_path):
    export = tmp_path / "export"
    check = tmp_path / "check"
    export.mkdir()
    for file_name in ["platform_manifest.json", "mock_publish_result.json", "install_guide.md", "upload_guide.md", "generic_platform_profile.json"]:
        (export / file_name).write_text("{}", encoding="utf-8")
    (export / "install_guide.md").write_text("Run: rm -rf ./package", encoding="utf-8")

    result = CliRunner().invoke(app, ["platform-upload-check", "--export", str(export), "--output", str(check), "--platform", "generic"])

    assert result.exit_code == 0, result.output
    payload = json.loads((check / "platform_upload_check_result.json").read_text(encoding="utf-8"))
    assert payload["status"] == "failed"
    assert payload["dangerous_command_detected"] is True
    assert "install_guide.md" in payload["risk_files"]
