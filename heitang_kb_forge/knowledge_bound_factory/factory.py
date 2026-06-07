from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.agent_package import AGENT_PACKAGE_FILES, generate_agent_package
from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.parser_backends.trust_gate import assert_trusted_for_export, read_kb_trust_status
from heitang_kb_forge.skill import SKILL_PACKAGE_FILES, generate_skill_package
from heitang_kb_forge.skill_validation import SKILL_VALIDATION_FILES, validate_skill_package


KNOWLEDGE_BOUND_FACTORY_OUTPUT_FILES = [
    "skill_package/SKILL.md",
    "skill_package/skill_manifest.yaml",
    "skill_package/knowledge_scope.md",
    "agent_package/soul.md",
    "agent_package/system_prompt.md",
    "agent_package/agent_profile.yaml",
    "skill_validation/skill_validation_result.json",
    "knowledge_bound_factory_manifest.json",
    "knowledge_bound_factory_trace.json",
    "knowledge_bound_factory_quality_report.json",
    "knowledge_bound_factory_report.md",
]


def generate_knowledge_bound_agent(
    package: Path,
    output: Path,
    skill_name: str,
    agent_name: str,
    skill_type: str = "generic",
    agent_type: str = "generic",
    allow_untrusted: bool = False,
) -> dict:
    gate = assert_trusted_for_export(package, allow_untrusted=allow_untrusted)
    skill_output = output / "skill_package"
    agent_output = output / "agent_package"
    validation_output = output / "skill_validation"
    skill_result = generate_skill_package(package, skill_output, skill_name, skill_type, generated_by="knowledge_bound_factory")
    validation_result = validate_skill_package(skill_output, package, validation_output)
    agent_result = generate_agent_package(package, skill_output, agent_output, agent_name, agent_type, generated_by="knowledge_bound_factory")

    status = "pass" if validation_result.status in {"pass", "warning"} and not gate["blocked"] else "fail"
    quality = {
        "knowledge_bound_factory_version": "3.1.0-alpha.1",
        "status": status,
        "release_ready": bool(validation_result.release_ready and status == "pass"),
        "kb_trust_status": read_kb_trust_status(package),
        "skill_validation_status": validation_result.status,
        "skill_validation_scores": validation_result.scores,
        "warnings": list(validation_result.warnings) + list(gate["warnings"]),
    }
    manifest = {
        "knowledge_bound_factory_version": "3.1.0-alpha.1",
        "status": status,
        "package": str(package),
        "skill": str(skill_output),
        "agent": str(agent_output),
        "skill_name": skill_result.skill_name,
        "agent_name": agent_result["agent_name"],
        "kb_trust_status": quality["kb_trust_status"],
        "output_files": KNOWLEDGE_BOUND_FACTORY_OUTPUT_FILES,
    }
    trace = {
        "knowledge_bound_factory_trace_version": "3.1.0-alpha.1",
        "steps": [
            {"name": "trust_gate", "status": gate["status"], "kb_trust_status": gate["kb_trust_status"]},
            {"name": "skill_generation", "status": "pass", "files": SKILL_PACKAGE_FILES},
            {"name": "skill_validation", "status": validation_result.status, "files": SKILL_VALIDATION_FILES},
            {"name": "agent_generation", "status": "pass", "files": AGENT_PACKAGE_FILES},
        ],
    }
    output.mkdir(parents=True, exist_ok=True)
    write_json(output / "knowledge_bound_factory_manifest.json", manifest)
    write_json(output / "knowledge_bound_factory_trace.json", trace)
    write_json(output / "knowledge_bound_factory_quality_report.json", quality)
    (output / "knowledge_bound_factory_report.md").write_text(_render_report(manifest, quality), encoding="utf-8")
    return manifest


def _render_report(manifest: dict, quality: dict) -> str:
    warnings = quality["warnings"] or ["none"]
    return "\n".join(
        [
            "# Knowledge-Bound Factory Report",
            "",
            f"Status: {manifest['status']}",
            f"Skill: {manifest['skill_name']}",
            f"Agent: {manifest['agent_name']}",
            f"KB trust status: {manifest['kb_trust_status']}",
            f"Skill validation: {quality['skill_validation_status']}",
            "",
            "## Warnings",
            "",
            *[f"- {warning}" for warning in warnings],
            "",
        ]
    )
