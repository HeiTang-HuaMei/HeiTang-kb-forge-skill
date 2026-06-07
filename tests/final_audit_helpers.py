from __future__ import annotations

import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.final_audit import FINAL_AUDIT_OUTPUT_FILES, run_final_pre_v4_audit


def run_audit(tmp_path: Path, *, core_validation: dict | None = None, ui_validation: dict | None = None, ci_status: dict | None = None) -> tuple[Path, dict]:
    output = tmp_path / "final_audit"
    result = run_final_pre_v4_audit(
        Path.cwd(),
        output,
        _ui_repo(),
        core_validation=core_validation,
        ui_validation=ui_validation,
        ci_status=ci_status,
    )
    return output, result


def run_audit_cli(tmp_path: Path) -> tuple[Path, object]:
    output = tmp_path / "final_audit_cli"
    args = ["final-pre-v4-audit", "--core-repo", str(Path.cwd()), "--output", str(output)]
    ui = _ui_repo()
    if ui.exists():
        args.extend(["--ui-repo", str(ui)])
    result = CliRunner().invoke(app, args)
    return output, result


def load_json(output: Path, name: str) -> dict:
    return json.loads((output / name).read_text(encoding="utf-8"))


def assert_required_outputs(output: Path) -> None:
    for name in FINAL_AUDIT_OUTPUT_FILES:
        path = output / name
        assert path.exists(), name
        assert path.stat().st_size > 0, name


def _ui_repo() -> Path:
    return Path.cwd().parent / "kb-forge-skill-ui"
