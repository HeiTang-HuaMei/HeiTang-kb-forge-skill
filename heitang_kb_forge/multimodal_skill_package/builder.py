from __future__ import annotations

import json
from datetime import datetime, timezone
from hashlib import sha256
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


MULTIMODAL_SKILL_PACKAGE_FILES = [
    "multimodal_skill_manifest.json",
    "SKILL.md",
    "visual_state_cards.jsonl",
    "keyframe_schema.json",
    "keyframe_index.jsonl",
    "branch_loading_policy.json",
    "multimodal_skill_preview.json",
    "multimodal_skill_package_report.md",
]


def build_multimodal_skill_package(
    source_package: Path,
    *,
    skill_name: str = "HeiTang Multimodal Skill",
    now: datetime | None = None,
) -> dict[str, Any]:
    source_package = Path(source_package)
    if not source_package.exists():
        raise FileNotFoundError(f"source package does not exist: {source_package}")
    if not source_package.is_dir():
        raise NotADirectoryError(f"source package must be a directory: {source_package}")

    generated_at = (now or datetime.now(timezone.utc)).astimezone(timezone.utc).isoformat()
    manifest = _read_json(source_package / "manifest.json", default={})
    multimodal_assets = _read_jsonl(source_package / "multimodal_assets.jsonl")
    evidence_map = _read_json(source_package / "multimodal_evidence_map.json", default={})
    fallback_chunks = _read_jsonl(source_package / "chunks.jsonl")
    state_cards = _state_cards(multimodal_assets, fallback_chunks)
    keyframes = _keyframe_index(state_cards)
    package_id = _package_id(skill_name, manifest, state_cards)
    validation = _validation_summary(state_cards, keyframes)
    mm_source_status = "available" if multimodal_assets else "text_fallback"

    skill_manifest = {
        "schema_version": "multimodal_skill_package_manifest.v1",
        "package_id": package_id,
        "skill_name": skill_name,
        "project_source": "mmskills",
        "integration_mode": "schema_package_reference",
        "source_package": str(source_package).replace("\\", "/"),
        "source_package_id": manifest.get("package_id"),
        "generated_at": generated_at,
        "runtime_state_card_count": len(state_cards),
        "keyframe_count": len(keyframes),
        "multimodal_asset_count": len(multimodal_assets),
        "source_status": mm_source_status,
        "mmskills_runtime_integrated": False,
        "mmskills_code_copied": False,
        "mmskills_repository_cloned": False,
        "llm_required": False,
        "network_required": False,
        "external_runtime_required": False,
        "raw_demo_trajectories_stored": False,
        "output_files": MULTIMODAL_SKILL_PACKAGE_FILES,
        "validation_status": validation["status"],
        "final_target_not_downgraded": True,
        "remaining_gap": "This is a local Multimodal Skill Package contract and preview. It does not integrate the MMSkills repository, OSWorld runtime, branch-loaded agent runtime, full UI workflow, Full Gate, EXE, or release.",
        "next_required_e2e_step": "Finish Section 5 item 5.5 MMSkills integration decision and UI impact evidence, then continue only to Section 5 item 5.6 skill-prompt-generator.",
        "not_goal_complete": True,
    }
    keyframe_schema = {
        "schema_version": "multimodal_keyframe_schema.v1",
        "allowed_views": ["full_frame", "focus_crop", "before", "after"],
        "required_fields": [
            "keyframe_id",
            "state_card_id",
            "asset_id",
            "view",
            "source_file",
            "visible_cues",
            "verification_cue",
        ],
        "raw_demo_storage_allowed": False,
        "external_runtime_required": False,
    }
    branch_policy = {
        "schema_version": "branch_loading_policy.v1",
        "status": "ready_for_preview",
        "direct_load_allowed": False,
        "branch_loaded_preview": True,
        "max_state_cards_per_request": 3,
        "loads_raw_images_by_default": False,
        "requires_live_gui_runtime": False,
        "policy_reason": "Keep the main agent context small and load only selected visual state references.",
    }
    preview = {
        "schema_version": "multimodal_skill_preview.v1",
        "status": "passed" if state_cards else "warning",
        "skill_name": skill_name,
        "source_status": mm_source_status,
        "state_card_preview": state_cards[:3],
        "keyframe_preview": keyframes[:3],
        "evidence_map_present": bool(evidence_map),
        "ui_pages": ["Template Library", "Artifact Management"],
        "ui_action_available": False,
        "runtime_execution_claimed": False,
    }
    return {
        "manifest": skill_manifest,
        "skill_md": _render_skill_md(skill_manifest, state_cards),
        "visual_state_cards": state_cards,
        "keyframe_schema": keyframe_schema,
        "keyframe_index": keyframes,
        "branch_loading_policy": branch_policy,
        "preview": preview,
        "validation": validation,
        "report_md": _render_report(skill_manifest, validation),
    }


def write_multimodal_skill_package(
    source_package: Path,
    output: Path,
    *,
    skill_name: str = "HeiTang Multimodal Skill",
    now: datetime | None = None,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    payload = build_multimodal_skill_package(source_package, skill_name=skill_name, now=now)
    write_json(output / "multimodal_skill_manifest.json", payload["manifest"])
    (output / "SKILL.md").write_text(payload["skill_md"], encoding="utf-8")
    write_jsonl(output / "visual_state_cards.jsonl", payload["visual_state_cards"])
    write_json(output / "keyframe_schema.json", payload["keyframe_schema"])
    write_jsonl(output / "keyframe_index.jsonl", payload["keyframe_index"])
    write_json(output / "branch_loading_policy.json", payload["branch_loading_policy"])
    write_json(output / "multimodal_skill_preview.json", payload["preview"])
    (output / "multimodal_skill_package_report.md").write_text(
        payload["report_md"],
        encoding="utf-8",
    )
    return {
        "status": payload["manifest"]["validation_status"],
        "output": str(output),
        "output_files": MULTIMODAL_SKILL_PACKAGE_FILES,
        **payload,
    }


def validate_multimodal_skill_package(package: Path) -> dict[str, Any]:
    package = Path(package)
    missing = [name for name in MULTIMODAL_SKILL_PACKAGE_FILES if not (package / name).is_file()]
    manifest = _read_json(package / "multimodal_skill_manifest.json", default={})
    state_cards = _read_jsonl(package / "visual_state_cards.jsonl")
    keyframes = _read_jsonl(package / "keyframe_index.jsonl")
    branch_policy = _read_json(package / "branch_loading_policy.json", default={})
    blockers = []
    if missing:
        blockers.append("missing_required_files")
    if manifest.get("mmskills_runtime_integrated") is not False:
        blockers.append("runtime_boundary_violation")
    if manifest.get("mmskills_code_copied") is not False:
        blockers.append("external_code_boundary_violation")
    if branch_policy.get("direct_load_allowed") is not False:
        blockers.append("direct_load_not_allowed")
    if not state_cards:
        blockers.append("missing_visual_state_cards")
    if not keyframes:
        blockers.append("missing_keyframe_index")
    return {
        "schema_version": "multimodal_skill_validation.v1",
        "status": "passed" if not blockers else "failed",
        "package": str(package).replace("\\", "/"),
        "missing_files": missing,
        "blockers": blockers,
        "state_card_count": len(state_cards),
        "keyframe_count": len(keyframes),
        "runtime_integrated": manifest.get("mmskills_runtime_integrated"),
        "external_code_copied": manifest.get("mmskills_code_copied"),
        "ui_action_available": False,
        "final_target_not_downgraded": True,
        "remaining_gap": "Validation proves the local multimodal skill package contract only, not MMSkills runtime execution, Campaign 3 acceptance, UI completion, Full Gate, EXE, or release.",
        "next_required_e2e_step": "Continue Section 5 in order after the MMSkills decision is recorded.",
        "not_goal_complete": True,
    }


def write_multimodal_skill_validation(package: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_multimodal_skill_package(package)
    write_json(output / "multimodal_skill_validation_report.json", result)
    (output / "multimodal_skill_validation_report.md").write_text(
        _render_validation_report(result),
        encoding="utf-8",
    )
    return result


def _state_cards(multimodal_assets: list[dict[str, Any]], chunks: list[dict[str, Any]]) -> list[dict[str, Any]]:
    if multimodal_assets:
        rows = multimodal_assets
    else:
        rows = [
            {
                "asset_id": str(chunk.get("chunk_id") or f"chunk_{index}"),
                "asset_type": "textual_visual_placeholder",
                "source_file": str(chunk.get("source_path") or ""),
                "description": str(chunk.get("title") or "Text-derived state"),
                "extracted_text": str(chunk.get("text") or "")[:300],
                "confidence": "medium" if chunk.get("source_path") else "low",
                "review_required": True,
            }
            for index, chunk in enumerate(chunks[:5], start=1)
            if chunk.get("text") or chunk.get("title")
        ]
    cards = []
    for index, asset in enumerate(rows, start=1):
        source_file = str(asset.get("source_file") or "")
        description = str(asset.get("description") or asset.get("extracted_text") or "Visual state reference").strip()
        visible_cues = _visible_cues(asset)
        card_id = f"state_card_{index:03d}"
        cards.append(
            {
                "state_card_id": card_id,
                "asset_id": str(asset.get("asset_id") or card_id),
                "state_name": _state_name(description, index),
                "when_to_use": f"Use when the user task depends on visual or layout evidence from {source_file or 'the source package'}.",
                "when_not_to_use": "Do not use as proof of live GUI state, external runtime execution, or raw demonstration replay.",
                "visible_cues": visible_cues,
                "verification_cue": "Verify against source trace, cited package evidence, and current user context before acting.",
                "source_file": source_file,
                "confidence": str(asset.get("confidence") or "low"),
                "review_required": bool(asset.get("review_required", True)),
            }
        )
    return cards


def _keyframe_index(state_cards: list[dict[str, Any]]) -> list[dict[str, Any]]:
    keyframes = []
    for card in state_cards:
        for view in ["full_frame", "focus_crop"]:
            keyframes.append(
                {
                    "keyframe_id": f"{card['state_card_id']}_{view}",
                    "state_card_id": card["state_card_id"],
                    "asset_id": card["asset_id"],
                    "view": view,
                    "source_file": card["source_file"],
                    "visible_cues": card["visible_cues"],
                    "verification_cue": card["verification_cue"],
                    "stored_binary_image": False,
                    "reference_only": True,
                }
            )
    return keyframes


def _validation_summary(state_cards: list[dict[str, Any]], keyframes: list[dict[str, Any]]) -> dict[str, Any]:
    blockers = []
    if not state_cards:
        blockers.append("state_cards_empty")
    if not keyframes:
        blockers.append("keyframes_empty")
    return {
        "schema_version": "multimodal_skill_validation_summary.v1",
        "status": "passed" if not blockers else "failed",
        "blockers": blockers,
        "state_card_count": len(state_cards),
        "keyframe_count": len(keyframes),
        "requires_human_review_count": sum(1 for card in state_cards if card["review_required"]),
    }


def _visible_cues(asset: dict[str, Any]) -> list[str]:
    cues = []
    asset_type = str(asset.get("asset_type") or "visual_asset")
    cues.append(f"asset_type:{asset_type}")
    if asset.get("description"):
        cues.append(str(asset["description"])[:160])
    if asset.get("extracted_text"):
        cues.append(str(asset["extracted_text"])[:160])
    return cues[:3] or ["inspect visible source evidence"]


def _state_name(description: str, index: int) -> str:
    cleaned = " ".join(description.split())
    return cleaned[:60] if cleaned else f"Visual state {index}"


def _package_id(skill_name: str, manifest: dict[str, Any], state_cards: list[dict[str, Any]]) -> str:
    raw = f"{skill_name}:{manifest.get('package_id')}:{len(state_cards)}"
    return "mm_skill_" + sha256(raw.encode("utf-8")).hexdigest()[:16]


def _render_skill_md(manifest: dict[str, Any], state_cards: list[dict[str, Any]]) -> str:
    return f"""---
name: {manifest['skill_name']}
description: Use this skill when a package-grounded task needs multimodal evidence, visual state cards, or keyframe references.
skill_type: multimodal_reference
---

# {manifest['skill_name']}

Generated as a local MMSkills-inspired package contract.

## Trigger

Use when the answer or workflow needs visual evidence from package assets, layout cues, image-like sources, slide context, or state-conditioned references.

## Boundary

- Do not claim live GUI execution.
- Do not claim MMSkills repository runtime integration.
- Do not load raw demonstration trajectories.
- Use `visual_state_cards.jsonl` and `keyframe_index.jsonl` as reference evidence only.

## Runtime State Cards

State cards available: {len(state_cards)}
"""


def _render_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    return f"""# Multimodal Skill Package Report

- Status: {validation['status']}
- Project source: {manifest['project_source']}
- Integration mode: {manifest['integration_mode']}
- MMSkills runtime integrated: {manifest['mmskills_runtime_integrated']}
- MMSkills code copied: {manifest['mmskills_code_copied']}
- Runtime state cards: {manifest['runtime_state_card_count']}
- Keyframes: {manifest['keyframe_count']}
- Multimodal assets: {manifest['multimodal_asset_count']}

This package turns HeiTang package evidence into a multimodal Skill package contract. It is not an MMSkills runtime integration and does not execute GUI/game environments.
"""


def _render_validation_report(result: dict[str, Any]) -> str:
    return f"""# Multimodal Skill Validation Report

- Status: {result['status']}
- State cards: {result['state_card_count']}
- Keyframes: {result['keyframe_count']}
- Runtime integrated: {result['runtime_integrated']}
- External code copied: {result['external_code_copied']}
- Blockers: {', '.join(result['blockers']) if result['blockers'] else 'none'}
"""


def _read_json(path: Path, *, default: Any) -> Any:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8-sig").splitlines()
        if line.strip()
    ]
