from pathlib import Path

from .catalog import get_template
from .report import render_validation_report
from .validator import validate_enhanced_skill
from heitang_kb_forge.exporters.jsonl_exporter import write_json


def render_enhanced_skill_template(output: Path, skill_type: str) -> dict:
    template = get_template(skill_type)
    output.mkdir(parents=True, exist_ok=True)
    files = {
        "TASKS.md": _list_doc("Tasks", template.tasks),
        "INPUT_OUTPUT.md": _list_doc("Inputs", template.inputs) + "\n" + _list_doc("Outputs", template.outputs),
        "FAILURE_MODES.md": _list_doc("Failure Modes", template.failure_modes),
        "SAFE_REFUSAL.md": "# Safe Refusal\n\nRefuse requests that are unsupported by the knowledge package.\n",
        "EVIDENCE_USAGE.md": "# Evidence Usage\n\nUse source-linked evidence and cite chunk or source references when available.\n",
        "OPERATION_GUIDE.md": "# Operation Guide\n\nRun locally, inspect outputs, and validate before release.\n",
        "RELEASE_CHECKLIST.md": "# Release Checklist\n\n- Evidence reviewed\n- Boundary rules present\n- Validation passed\n",
    }
    for file_name, content in files.items():
        (output / file_name).write_text(content, encoding="utf-8")
    result = validate_enhanced_skill(output, template.skill_type)
    write_json(output / "skill_validation_result.json", result)
    (output / "skill_validation_report.md").write_text(render_validation_report(result), encoding="utf-8")
    return result


def _list_doc(title: str, items: list[str]) -> str:
    return f"# {title}\n\n" + "\n".join(f"- {item}" for item in items) + "\n"
