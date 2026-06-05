import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_doctor_command_writes_reports_without_requiring_ocr_system_deps(tmp_path):
    output = tmp_path / "doctor"

    result = CliRunner().invoke(app, ["doctor", "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert (output / "doctor_report.json").exists()
    assert (output / "doctor_result.json").exists()
    assert (output / "doctor_report.md").exists()
    report = json.loads((output / "doctor_report.json").read_text(encoding="utf-8"))
    assert report["status"] in {"pass", "warning"}
    assert any(check["name"] == "tesseract_binary" for check in report["checks"])
    assert any(check["name"] == "version_alignment" for check in report["checks"])
    assert any(check["name"] == "capability_status_exists" for check in report["checks"])
    assert any(check["status"] == "warning" for check in report["checks"]) or report["status"] == "pass"
