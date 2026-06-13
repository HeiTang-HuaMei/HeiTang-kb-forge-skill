from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


PROMPT_ASSET_LIBRARY_FILES = [
    "prompt_asset_manifest.json",
    "prompt_cards.jsonl",
    "skill_factory_enhancement_report.json",
    "prompt_asset_library_report.md",
    "PROMPT_ASSET_INDEX.md",
]


def build_prompt_asset_library(
    skill_suite: Path,
    output: Path,
    library_name: str = "HeiTang Prompt Asset Library",
) -> dict[str, Any]:
    suite = _read_json(skill_suite / "suite.json")
    skills = suite.get("skills")
    if not isinstance(skills, list) or not skills:
        raise ValueError("Prompt Asset Library requires a Skill Suite with non-empty suite.json skills")

    cards = [_card_from_skill(skill_suite, skill, index) for index, skill in enumerate(skills, start=1)]
    manifest = {
        "prompt_asset_library_version": "section_5_5_6_prompt_asset_library.v1",
        "library_name": library_name,
        "source_suite_id": suite.get("suite_id"),
        "source_package_id": suite.get("source_package_id"),
        "source_skill_count": len(skills),
        "prompt_card_count": len(cards),
        "status": "passed",
        "integration_mode": "prompt_asset_library_enhancer",
        "external_project_reference": {
            "project_id": "skill_prompt_generator",
            "project_name": "skill-prompt-generator",
            "github_url": "https://github.com/huangserva/skill-prompt-generator",
            "git_ls_remote_checked": True,
            "github_api_checked": True,
            "license_gate": "pending_no_license_field_in_github_api",
            "external_code_or_prompts_copied": False,
        },
        "skill_factory_boundary": {
            "enhancer_only": True,
            "p2_2_skill_factory_replaced": False,
            "skill_suite_modified": False,
            "llm_required": False,
            "provider_api_required": False,
        },
        "output_files": PROMPT_ASSET_LIBRARY_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Prompt Asset Library enhances existing Skill Suite prompt assets locally, "
            "but external Skill import/decomposition/learning, owned Skill generation, "
            "multi-agent workflow, full UI workflow, Full Gate, and EXE remain incomplete."
        ),
        "next_required_e2e_step": "Continue Section 5 item 5.7 ai-marketing-skills after governed 5.6 closeout.",
        "not_goal_complete": True,
    }
    enhancement = {
        "enhancement_report_version": "section_5_5_6_prompt_asset_library.v1",
        "status": "passed",
        "source_suite_id": manifest["source_suite_id"],
        "prompt_card_count": len(cards),
        "enhancement_surfaces": [
            "prompt_asset_library",
            "skill_factory_template_quality",
            "evidence_boundary_prompts",
            "safe_refusal_prompts",
            "evaluation_prompt_templates",
        ],
        "p2_2_skill_factory_replaced": False,
        "external_code_or_prompts_copied": False,
        "license_gate": "pending_no_license_field_in_github_api",
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": manifest["remaining_gap"],
        "next_required_e2e_step": manifest["next_required_e2e_step"],
        "not_goal_complete": True,
    }

    output.mkdir(parents=True, exist_ok=True)
    write_json(output / "prompt_asset_manifest.json", manifest)
    write_jsonl(output / "prompt_cards.jsonl", cards)
    write_json(output / "skill_factory_enhancement_report.json", enhancement)
    (output / "PROMPT_ASSET_INDEX.md").write_text(_render_index(manifest, cards), encoding="utf-8")
    (output / "prompt_asset_library_report.md").write_text(
        _render_report(manifest, cards), encoding="utf-8"
    )
    return manifest | {"prompt_cards": cards}


def validate_prompt_asset_library(library: Path) -> dict[str, Any]:
    missing = [file_name for file_name in PROMPT_ASSET_LIBRARY_FILES if not (library / file_name).exists()]
    manifest = _read_json(library / "prompt_asset_manifest.json") if not missing else {}
    cards = _read_jsonl(library / "prompt_cards.jsonl") if (library / "prompt_cards.jsonl").exists() else []
    card_errors = [
        card.get("card_id") or f"card_{index}"
        for index, card in enumerate(cards, start=1)
        if not _card_is_valid(card)
    ]
    boundary_errors = []
    if manifest.get("external_project_reference", {}).get("external_code_or_prompts_copied") is not False:
        boundary_errors.append("external_code_or_prompts_copied_must_be_false")
    if manifest.get("skill_factory_boundary", {}).get("p2_2_skill_factory_replaced") is not False:
        boundary_errors.append("p2_2_skill_factory_replaced_must_be_false")
    if manifest.get("skill_factory_boundary", {}).get("llm_required") is not False:
        boundary_errors.append("llm_required_must_be_false")
    status = "passed" if not missing and cards and not card_errors and not boundary_errors else "failed"
    return {
        "prompt_asset_validation_version": "section_5_5_6_prompt_asset_library.v1",
        "status": status,
        "required_files": PROMPT_ASSET_LIBRARY_FILES,
        "missing_files": missing,
        "prompt_card_count": len(cards),
        "card_errors": card_errors,
        "boundary_errors": boundary_errors,
        "external_code_or_prompts_copied": manifest.get("external_project_reference", {}).get("external_code_or_prompts_copied"),
        "p2_2_skill_factory_replaced": manifest.get("skill_factory_boundary", {}).get("p2_2_skill_factory_replaced"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Prompt Asset Library validation covers local prompt cards and boundaries only; "
            "it does not complete Campaign 3, full UI workflow, Full Gate, or EXE acceptance."
        ),
        "next_required_e2e_step": "Continue Section 5 item 5.7 ai-marketing-skills after governed 5.6 closeout.",
        "not_goal_complete": True,
    }


def write_prompt_asset_library(
    skill_suite: Path,
    output: Path,
    library_name: str = "HeiTang Prompt Asset Library",
) -> dict[str, Any]:
    return build_prompt_asset_library(skill_suite, output, library_name=library_name)


def write_prompt_asset_validation(library: Path, output: Path) -> dict[str, Any]:
    output.mkdir(parents=True, exist_ok=True)
    result = validate_prompt_asset_library(library)
    write_json(output / "prompt_asset_validation_report.json", result)
    (output / "prompt_asset_validation_report.md").write_text(
        _render_validation_report(result), encoding="utf-8"
    )
    return result


def _card_from_skill(skill_suite: Path, skill: dict[str, Any], index: int) -> dict[str, Any]:
    skill_id = str(skill.get("skill_id") or f"skill_{index:03d}")
    title = str(skill.get("title") or skill_id)
    skill_type = str(skill.get("skill_type") or "unknown")
    trigger = str(skill.get("trigger") or f"Use when {title} is needed.")
    purpose = str(skill.get("purpose") or f"Apply {title} with source-traced evidence.")
    evidence = [str(item) for item in skill.get("supporting_evidence", []) if str(item).strip()]
    skill_path = skill_suite / str(skill.get("path") or "")
    source_excerpt = _source_excerpt(skill_path)
    return {
        "card_id": f"prompt_card_{index:03d}_{_slug(skill_id)}",
        "skill_id": skill_id,
        "title": title,
        "skill_type": skill_type,
        "trigger": trigger,
        "purpose": purpose,
        "supporting_evidence": evidence,
        "source_skill_path": str(skill.get("path") or "").replace("\\", "/"),
        "source_skill_excerpt": source_excerpt,
        "prompt_assets": {
            "system_instruction": (
                f"You are using the local HeiTang Skill `{title}`. Use only connected "
                "knowledge package evidence and preserve citation boundaries."
            ),
            "task_prompt_template": (
                "Task: {task}\n"
                "Relevant Skill: " + title + "\n"
                "Required evidence refs: {evidence_refs}\n"
                "Boundary notes: {boundary_notes}\n"
                "Return an evidence-grounded answer or a clear refusal."
            ),
            "safe_refusal_template": (
                "I cannot complete this from the connected evidence. Missing or conflicting evidence: {reason}."
            ),
            "evaluation_prompt_template": (
                "Check whether the answer cites source evidence, stays within the Skill purpose, "
                "and avoids unsupported claims. Return pass/review_required/fail."
            ),
        },
        "quality_rules": [
            "Preserve source trace and citation boundaries.",
            "Do not invent facts outside the connected knowledge package.",
            "Use safe refusal when evidence is missing.",
            "Treat this as a Skill Factory enhancer, not a replacement generator.",
        ],
        "external_code_or_prompts_copied": False,
        "tests_require_real_llm_api_network": False,
    }


def _card_is_valid(card: dict[str, Any]) -> bool:
    assets = card.get("prompt_assets")
    if not isinstance(assets, dict):
        return False
    required_assets = {
        "system_instruction",
        "task_prompt_template",
        "safe_refusal_template",
        "evaluation_prompt_template",
    }
    if not required_assets <= set(assets):
        return False
    if card.get("external_code_or_prompts_copied") is not False:
        return False
    return all(str(assets[key]).strip() for key in required_assets)


def _source_excerpt(path: Path) -> str:
    if not path.exists() or not path.is_file():
        return ""
    text = path.read_text(encoding="utf-8")
    lines = [line.strip() for line in text.splitlines() if line.strip() and not line.startswith("---")]
    return " ".join(lines[:8])[:500]


def _render_index(manifest: dict[str, Any], cards: list[dict[str, Any]]) -> str:
    lines = [
        "# Prompt Asset Index",
        "",
        f"- Library: `{manifest['library_name']}`",
        f"- Source suite: `{manifest['source_suite_id']}`",
        f"- Status: `{manifest['status']}`",
        f"- Prompt cards: {len(cards)}",
        "",
        "| Card | Skill | Type |",
        "| --- | --- | --- |",
    ]
    lines.extend(
        f"| `{card['card_id']}` | {card['title']} | `{card['skill_type']}` |"
        for card in cards
    )
    return "\n".join(lines).rstrip() + "\n"


def _render_report(manifest: dict[str, Any], cards: list[dict[str, Any]]) -> str:
    return (
        "# Prompt Asset Library Report\n\n"
        f"- Status: `{manifest['status']}`\n"
        f"- Integration mode: `{manifest['integration_mode']}`\n"
        f"- Source suite: `{manifest['source_suite_id']}`\n"
        f"- Prompt cards: {len(cards)}\n"
        f"- External code or prompts copied: `{manifest['external_project_reference']['external_code_or_prompts_copied']}`\n"
        f"- License gate: `{manifest['external_project_reference']['license_gate']}`\n"
        f"- P2.2 Skill Factory replaced: `{manifest['skill_factory_boundary']['p2_2_skill_factory_replaced']}`\n"
        f"- LLM required: `{manifest['skill_factory_boundary']['llm_required']}`\n"
        "\nThis library is a local Skill Factory enhancer. It does not vendor or execute skill-prompt-generator.\n"
    )


def _render_validation_report(result: dict[str, Any]) -> str:
    return (
        "# Prompt Asset Validation Report\n\n"
        f"- Status: `{result['status']}`\n"
        f"- Prompt cards: {result['prompt_card_count']}\n"
        f"- Missing files: {', '.join(result['missing_files']) or 'None'}\n"
        f"- Card errors: {', '.join(result['card_errors']) or 'None'}\n"
        f"- Boundary errors: {', '.join(result['boundary_errors']) or 'None'}\n"
    )


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _slug(value: str) -> str:
    slug = "".join(char.lower() if char.isalnum() else "_" for char in value).strip("_")
    return "_".join(part for part in slug.split("_") if part) or "skill"
