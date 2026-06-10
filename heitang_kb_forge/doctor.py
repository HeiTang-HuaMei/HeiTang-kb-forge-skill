from __future__ import annotations

import importlib.util
import json
import shutil
import sqlite3
import subprocess
import sys
from pathlib import Path
from typing import Any


def run_doctor(output: Path) -> tuple[dict[str, Any], str]:
    output.mkdir(parents=True, exist_ok=True)
    checks = [
        _python_version_check(),
        _package_import_check(),
        _cli_import_check(),
        _quickstart_input_check(),
        _optional_import_check("pdfplumber", "Install with: python -m pip install -e \".[pdf-table]\""),
        _optional_import_check("pypdfium2", "Install with: python -m pip install -e \".[ocr]\""),
        _optional_import_check("pytesseract", "Install with: python -m pip install -e \".[ocr]\""),
        _optional_import_check("PIL", "Install with: python -m pip install -e \".[ocr]\""),
        _sqlite_check(),
        _write_permission_check(output),
        _version_alignment_check(),
        _doc_exists_check("capability_status_exists", Path("docs/CAPABILITY_STATUS.md")),
        _doc_exists_check("version_matrix_exists", Path("docs/VERSION_MATRIX.md")),
        _doc_exists_check("release_checklist_exists", Path("docs/RELEASE_CHECKLIST.md")),
        _check("mock_provider_available", "pass", "Mock provider is available for offline tests.", "", required=True),
        _check("network_not_required", "pass", "Base doctor does not require network access.", "", required=True),
    ]
    tesseract_check, language_check = _tesseract_checks()
    checks.append(tesseract_check)
    checks.append(language_check)
    required_failures = [check for check in checks if check["required"] and check["status"] == "fail"]
    optional_warnings = [check for check in checks if not check["required"] and check["status"] != "pass"]
    status = "fail" if required_failures else "warning" if optional_warnings else "pass"
    report = {
        "doctor_version": "1.6.1",
        "status": status,
        "checks": checks,
        "summary": {
            "required_passed": sum(1 for check in checks if check["required"] and check["status"] == "pass"),
            "optional_warnings": len(optional_warnings),
            "failures": len(required_failures),
        },
        "install_hints": {
            "base": "python -m pip install -e .",
            "dev": "python -m pip install -e \".[dev]\"",
            "ocr_pdf_table": "python -m pip install -e \".[ocr,pdf-table]\"",
            "all": "python -m pip install -e \".[all]\"",
        },
    }
    return report, _render_markdown(report)


def _python_version_check() -> dict[str, Any]:
    ok = sys.version_info >= (3, 11)
    return _check(
        "python_version",
        "pass" if ok else "fail",
        f"Python {sys.version.split()[0]}",
        "Use Python 3.11 or newer.",
        required=True,
    )


def _package_import_check() -> dict[str, Any]:
    try:
        import heitang_kb_forge  # noqa: F401

        return _check("package_import", "pass", "heitang_kb_forge imports successfully.", "", required=True)
    except Exception as exc:
        return _check("package_import", "fail", str(exc), "Run: python -m pip install -e .", required=True)


def _cli_import_check() -> dict[str, Any]:
    try:
        from heitang_kb_forge.cli import app  # noqa: F401

        return _check("cli_availability", "pass", "CLI app imports successfully.", "", required=True)
    except Exception as exc:
        return _check("cli_availability", "fail", str(exc), "Check installation and dependencies.", required=True)


def _quickstart_input_check() -> dict[str, Any]:
    path = Path("examples/quickstart/input")
    return _check(
        "examples_quickstart_input_exists",
        "pass" if path.exists() else "fail",
        str(path),
        "Restore examples/quickstart/input.",
        required=True,
    )


def _version_alignment_check() -> dict[str, Any]:
    versions = []
    pyproject = Path("pyproject.toml")
    skill_json = Path("skill.json")
    if pyproject.exists():
        for line in pyproject.read_text(encoding="utf-8").splitlines():
            if line.startswith("version = "):
                versions.append(line.split("=", 1)[1].strip().strip('"'))
                break
    if skill_json.exists():
        versions.append(json.loads(skill_json.read_text(encoding="utf-8")).get("version"))
    expected = versions[0] if versions else None
    ok = bool(expected) and all(version == expected for version in versions)
    return _check(
        "version_alignment",
        "pass" if ok else "fail",
        f"Expected aligned project metadata; found {versions}",
        "Align project metadata versions.",
        required=True,
    )


def _doc_exists_check(name: str, path: Path) -> dict[str, Any]:
    return _check(
        name,
        "pass" if path.exists() else "fail",
        str(path),
        f"Create {path}.",
        required=True,
    )


def _optional_import_check(module: str, fix_hint: str) -> dict[str, Any]:
    if importlib.util.find_spec(module):
        return _check(f"optional_dependency_{module}", "pass", f"{module} is installed.", "", required=False)
    return _check(f"optional_dependency_{module}", "warning", f"{module} is not installed.", fix_hint, required=False)


def _sqlite_check() -> dict[str, Any]:
    try:
        sqlite3.connect(":memory:").close()
        return _check("sqlite3_availability", "pass", "sqlite3 is available.", "", required=True)
    except Exception as exc:
        return _check("sqlite3_availability", "fail", str(exc), "Use a Python build with sqlite3 support.", required=True)


def _write_permission_check(output: Path) -> dict[str, Any]:
    try:
        probe = output / ".doctor_write_test"
        probe.write_text("ok", encoding="utf-8")
        probe.unlink()
        return _check("output_write_permission", "pass", f"Can write to {output}.", "", required=True)
    except Exception as exc:
        return _check("output_write_permission", "fail", str(exc), "Choose a writable output path.", required=True)


def _tesseract_checks() -> tuple[dict[str, Any], dict[str, Any]]:
    binary = shutil.which("tesseract")
    if not binary:
        return (
            _check(
                "tesseract_binary",
                "warning",
                "tesseract is not installed or not in PATH.",
                "Install Tesseract OCR and add it to PATH. OCR is optional for base usage.",
                required=False,
            ),
            _check(
                "tesseract_languages",
                "warning",
                "Cannot check languages because tesseract is unavailable.",
                "After installing Tesseract, run: tesseract --list-langs",
                required=False,
            ),
        )
    version = _run_tesseract([binary, "--version"])
    languages = _run_tesseract([binary, "--list-langs"])
    language_status = "pass" if "chi_sim" in languages else "warning"
    language_hint = "" if language_status == "pass" else "Install chi_sim.traineddata for Simplified Chinese OCR."
    return (
        _check("tesseract_binary", "pass", version.splitlines()[0] if version else f"Found {binary}", "", required=False),
        _check("tesseract_languages", language_status, languages.strip() or "No languages reported.", language_hint, required=False),
    )


def _run_tesseract(command: list[str]) -> str:
    try:
        completed = subprocess.run(command, check=False, capture_output=True, text=True, timeout=10)
        return (completed.stdout or completed.stderr or "").strip()
    except Exception as exc:
        return str(exc)


def _check(name: str, status: str, message: str, fix_hint: str, required: bool) -> dict[str, Any]:
    return {"name": name, "status": status, "message": message, "fix_hint": fix_hint, "required": required}


def _render_markdown(report: dict[str, Any]) -> str:
    rows = "\n".join(
        f"| {check['name']} | {check['status']} | {check['required']} | {check['message']} | {check['fix_hint'] or '-'} |"
        for check in report["checks"]
    )
    return f"""# HeiTang KB Forge Doctor Report

## Summary

- Status: {report['status']}
- Required passed: {report['summary']['required_passed']}
- Optional warnings: {report['summary']['optional_warnings']}
- Failures: {report['summary']['failures']}

## Checks

| Check | Status | Required | Message | Fix hint |
| --- | --- | --- | --- | --- |
{rows}

## Install Hints

- Base: `{report['install_hints']['base']}`
- Dev: `{report['install_hints']['dev']}`
- OCR / PDF table: `{report['install_hints']['ocr_pdf_table']}`
- All local extras: `{report['install_hints']['all']}`
"""

