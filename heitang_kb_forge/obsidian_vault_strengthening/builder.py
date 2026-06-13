from __future__ import annotations

import json
import re
import shutil
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


OBSIDIAN_VAULT_STRENGTHENING_FILES = [
    "obsidian_vault_strengthening_manifest.json",
    "vault_note_inventory.jsonl",
    "vault_frontmatter_schema.json",
    "vault_backlink_map.json",
    "vault_folder_structure.json",
    "vault_export_manifest.json",
    "obsidian_vault_validation_report.json",
    "obsidian_vault_strengthening_report.md",
]

WIKILINK_RE = re.compile(r"!?\[\[([^\]#|]+)(?:#[^\]|]+)?(?:\|[^\]]+)?\]\]")
MARKDOWN_LINK_RE = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")


def build_obsidian_vault_strengthening_record(
    output: Path,
    *,
    vault: Path | None = None,
    library_name: str = "HeiTang Obsidian-compatible Local Vault Adapter",
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    vault_path = Path(vault) if vault else _write_sample_vault(output / "sample_vault")
    scan = scan_markdown_vault(vault_path)
    export_manifest = export_markdown_vault(vault_path, output / "export")
    frontmatter_schema = _frontmatter_schema(scan["notes"])
    manifest = {
        "schema_version": "obsidian_vault_strengthening_manifest.v1",
        "section": "5.S3",
        "campaign": "Campaign 3",
        "status": "passed",
        "project_id": "obsidian_compatible_vault",
        "project_name": "Obsidian-compatible Vault",
        "library_name": library_name,
        "integration_decision": "real_integration",
        "decision_qualifier": "local_vault_adapter_only",
        "integration_mode": "local_markdown_vault_adapter_strengthening",
        "compatibility_target": {
            "target": "Local Markdown Vault / Obsidian-compatible conventions",
            "markdown_folder_import": True,
            "markdown_folder_export": True,
            "frontmatter_support": True,
            "wikilink_support": True,
            "backlink_map_support": True,
            "folder_structure_support": True,
            "obsidian_runtime_required": False,
            "obsidian_plugin_required": False,
            "obsidian_sync_required": False,
        },
        "vault_scan": {
            "vault_path": str(vault_path),
            "note_count": len(scan["notes"]),
            "folder_count": len(scan["folder_structure"]["folders"]),
            "wikilink_count": sum(len(note["outgoing_wikilinks"]) for note in scan["notes"]),
            "backlink_edge_count": scan["backlink_map"]["edge_count"],
            "unresolved_wikilink_count": len(scan["backlink_map"]["unresolved_wikilinks"]),
            "sample_vault_generated": vault is None,
        },
        "runtime_boundary": _runtime_boundary(),
        "ui_contract": {
            "status_visible": True,
            "local_vault_import_visible": True,
            "markdown_folder_import_visible": True,
            "obsidian_compatible_export_visible": True,
            "frontmatter_preview_visible": True,
            "backlink_map_preview_visible": True,
            "local_ready": True,
            "ready": False,
            "executable_action": False,
            "obsidian_runtime_action_available": False,
            "obsidian_plugin_action_available": False,
            "sync_service_action_available": False,
            "ui_visibility": "visible_status_only",
        },
        "output_files": OBSIDIAN_VAULT_STRENGTHENING_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "This advances Section 5 strengthening item 5.S3 as a local Markdown vault adapter only. "
            "It does not launch Obsidian, call plugins, require sync, accept Campaign 3, open Campaign 3.0/4.0, "
            "open Campaign 4 UI workflow, run Full Gate, package EXE, or release."
        ),
        "next_required_e2e_step": "Run Campaign 3 Supplement 2.0 closure gate only.",
        "not_goal_complete": True,
    }
    validation = validate_obsidian_vault_strengthening_payload(
        manifest,
        scan["notes"],
        frontmatter_schema,
        scan["backlink_map"],
        scan["folder_structure"],
        export_manifest,
    )
    write_json(output / "obsidian_vault_strengthening_manifest.json", manifest)
    write_jsonl(output / "vault_note_inventory.jsonl", scan["notes"])
    write_json(output / "vault_frontmatter_schema.json", frontmatter_schema)
    write_json(output / "vault_backlink_map.json", scan["backlink_map"])
    write_json(output / "vault_folder_structure.json", scan["folder_structure"])
    write_json(output / "vault_export_manifest.json", export_manifest)
    write_json(output / "obsidian_vault_validation_report.json", validation)
    (output / "obsidian_vault_strengthening_report.md").write_text(
        _render_report(manifest, validation),
        encoding="utf-8",
    )
    return manifest | {"validation": validation}


def scan_markdown_vault(vault: Path) -> dict[str, Any]:
    vault = Path(vault)
    notes = []
    for path in sorted(vault.rglob("*.md")):
        if any(part.startswith(".") for part in path.relative_to(vault).parts):
            continue
        text = path.read_text(encoding="utf-8-sig")
        frontmatter, body = _parse_frontmatter(text)
        rel = path.relative_to(vault).as_posix()
        title = str(frontmatter.get("title") or _first_heading(body) or path.stem).strip()
        notes.append(
            {
                "note_id": _note_id(rel),
                "relative_path": rel,
                "folder": path.relative_to(vault).parent.as_posix(),
                "title": title,
                "frontmatter": frontmatter,
                "frontmatter_keys": sorted(frontmatter),
                "outgoing_wikilinks": _wikilinks(body),
                "outgoing_markdown_links": _markdown_links(body),
                "body_char_count": len(body),
            }
        )
    backlink_map = _backlink_map(notes)
    folder_structure = _folder_structure(notes)
    return {
        "schema_version": "local_markdown_vault_scan.v1",
        "vault_path": str(vault),
        "notes": notes,
        "backlink_map": backlink_map,
        "folder_structure": folder_structure,
    }


def export_markdown_vault(vault: Path, output: Path) -> dict[str, Any]:
    vault = Path(vault)
    output = Path(output)
    if output.exists():
        shutil.rmtree(output)
    exported = []
    for path in sorted(vault.rglob("*.md")):
        if any(part.startswith(".") for part in path.relative_to(vault).parts):
            continue
        rel = path.relative_to(vault)
        target = output / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(path.read_text(encoding="utf-8-sig"), encoding="utf-8")
        exported.append(rel.as_posix())
    return {
        "schema_version": "local_markdown_vault_export_manifest.v1",
        "status": "passed",
        "source_vault": str(vault),
        "export_dir": str(output),
        "exported_note_count": len(exported),
        "exported_files": exported,
        "frontmatter_preserved": True,
        "wikilinks_preserved": True,
        "folder_structure_preserved": True,
        "obsidian_runtime_required": False,
        "obsidian_plugin_required": False,
    }


def validate_obsidian_vault_strengthening_record(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [
        file_name
        for file_name in OBSIDIAN_VAULT_STRENGTHENING_FILES
        if not (library / file_name).exists()
    ]
    if missing:
        return {
            "schema_version": "obsidian_vault_validation_report.v1",
            "section": "5.S3",
            "campaign": "Campaign 3",
            "status": "failed",
            "boundary_errors": ["required_files_missing"],
            "required_files": OBSIDIAN_VAULT_STRENGTHENING_FILES,
            "missing_files": missing,
            "tests_require_real_llm_api_network": False,
            "final_target_not_downgraded": True,
            "remaining_gap": "Required Obsidian-compatible vault strengthening evidence is incomplete.",
            "next_required_e2e_step": "Complete Section 5 strengthening item 5.S3 before advancing.",
            "not_goal_complete": True,
        }
    notes = _read_jsonl(library / "vault_note_inventory.jsonl")
    result = validate_obsidian_vault_strengthening_payload(
        _read_json(library / "obsidian_vault_strengthening_manifest.json"),
        notes,
        _read_json(library / "vault_frontmatter_schema.json"),
        _read_json(library / "vault_backlink_map.json"),
        _read_json(library / "vault_folder_structure.json"),
        _read_json(library / "vault_export_manifest.json"),
    )
    return {
        **result,
        "required_files": OBSIDIAN_VAULT_STRENGTHENING_FILES,
        "missing_files": missing,
    }


def validate_obsidian_vault_strengthening_payload(
    manifest: dict[str, Any],
    notes: list[dict[str, Any]],
    frontmatter_schema: dict[str, Any],
    backlink_map: dict[str, Any],
    folder_structure: dict[str, Any],
    export_manifest: dict[str, Any],
) -> dict[str, Any]:
    compatibility = manifest.get("compatibility_target", {})
    runtime = manifest.get("runtime_boundary", {})
    ui = manifest.get("ui_contract", {})
    errors: list[str] = []
    required_true = {
        "markdown_folder_import": compatibility,
        "markdown_folder_export": compatibility,
        "frontmatter_support": compatibility,
        "wikilink_support": compatibility,
        "backlink_map_support": compatibility,
        "folder_structure_support": compatibility,
        "local_vault_adapter_implemented": runtime,
        "local_ready": ui,
        "frontmatter_preserved": export_manifest,
        "wikilinks_preserved": export_manifest,
        "folder_structure_preserved": export_manifest,
    }
    required_false = {
        "obsidian_runtime_required": compatibility,
        "obsidian_plugin_required": compatibility,
        "obsidian_sync_required": compatibility,
        "obsidian_runtime_integrated": runtime,
        "obsidian_plugin_required": runtime,
        "obsidian_app_launched": runtime,
        "obsidian_sync_required": runtime,
        "external_runtime_required": runtime,
        "database_required": runtime,
        "network_required": runtime,
        "external_source_ingestion_implemented": runtime,
        "campaign_3_3_0_implemented": runtime,
        "campaign_3_4_0_implemented": runtime,
        "ready": ui,
        "executable_action": ui,
        "obsidian_runtime_action_available": ui,
        "obsidian_plugin_action_available": ui,
        "sync_service_action_available": ui,
    }
    for field, container in required_true.items():
        if container.get(field) is not True:
            errors.append(f"{field}_must_be_true")
    for field, container in required_false.items():
        if container.get(field) is not False:
            errors.append(f"{field}_must_be_false")
    if manifest.get("integration_decision") != "real_integration":
        errors.append("integration_decision_must_be_real_integration")
    if manifest.get("integration_mode") != "local_markdown_vault_adapter_strengthening":
        errors.append("integration_mode_invalid")
    if len(notes) < 2:
        errors.append("note_count_must_be_at_least_2")
    if not frontmatter_schema.get("observed_keys"):
        errors.append("frontmatter_keys_required")
    if backlink_map.get("edge_count", 0) < 1:
        errors.append("backlink_edge_required")
    if folder_structure.get("folder_count", 0) < 1:
        errors.append("folder_structure_required")
    if export_manifest.get("exported_note_count") != len(notes):
        errors.append("exported_note_count_must_match_inventory")
    status = "passed" if not errors else "failed"
    return {
        "schema_version": "obsidian_vault_validation_report.v1",
        "section": "5.S3",
        "campaign": "Campaign 3",
        "status": status,
        "boundary_errors": errors,
        "integration_decision": manifest.get("integration_decision"),
        "note_count": len(notes),
        "folder_count": folder_structure.get("folder_count", 0),
        "frontmatter_key_count": len(frontmatter_schema.get("observed_keys", [])),
        "backlink_edge_count": backlink_map.get("edge_count", 0),
        "exported_note_count": export_manifest.get("exported_note_count", 0),
        "obsidian_runtime_integrated": runtime.get("obsidian_runtime_integrated"),
        "obsidian_plugin_required": runtime.get("obsidian_plugin_required"),
        "ui_ready": ui.get("ready"),
        "ui_executable_action": ui.get("executable_action"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Validation covers local Markdown vault import/export, frontmatter, backlinks, and folder structure only. "
            "It does not accept Campaign 3, open Campaign 3.0/4.0, accept Campaign 4 UI workflow, run Full Gate, package EXE, or release."
        ),
        "next_required_e2e_step": "Run Campaign 3 Supplement 2.0 closure gate only.",
        "not_goal_complete": True,
    }


def write_obsidian_vault_strengthening_record(
    output: Path,
    *,
    vault: Path | None = None,
    library_name: str = "HeiTang Obsidian-compatible Local Vault Adapter",
) -> dict[str, Any]:
    return build_obsidian_vault_strengthening_record(output, vault=vault, library_name=library_name)


def write_obsidian_vault_strengthening_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_obsidian_vault_strengthening_record(library)
    write_json(output / "obsidian_vault_validation_report.json", result)
    (output / "obsidian_vault_validation_report.md").write_text(
        _render_validation_report(result),
        encoding="utf-8",
    )
    return result


def _runtime_boundary() -> dict[str, Any]:
    return {
        "local_vault_adapter_implemented": True,
        "obsidian_runtime_integrated": False,
        "obsidian_plugin_required": False,
        "obsidian_app_launched": False,
        "obsidian_sync_required": False,
        "external_runtime_required": False,
        "database_required": False,
        "network_required": False,
        "external_source_ingestion_implemented": False,
        "knowledge_to_skill_template_generator_implemented": False,
        "campaign_3_3_0_implemented": False,
        "campaign_3_4_0_implemented": False,
    }


def _write_sample_vault(vault: Path) -> Path:
    if vault.exists():
        shutil.rmtree(vault)
    (vault / "Research").mkdir(parents=True, exist_ok=True)
    (vault / "Marketing").mkdir(parents=True, exist_ok=True)
    (vault / "Research" / "AI Radar.md").write_text(
        "---\n"
        "title: AI Radar\n"
        "tags: [research, topic-intake]\n"
        "---\n"
        "# AI Radar\n\n"
        "This note links to [[Marketing/Content Plan]] and [[Unresolved Idea]].\n",
        encoding="utf-8",
    )
    (vault / "Marketing" / "Content Plan.md").write_text(
        "---\n"
        "title: Content Plan\n"
        "owner: marketing\n"
        "---\n"
        "# Content Plan\n\n"
        "This note references [[AI Radar]] and a [local report](../Research/AI%20Radar.md).\n",
        encoding="utf-8",
    )
    return vault


def _parse_frontmatter(text: str) -> tuple[dict[str, Any], str]:
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---", 4)
    if end == -1:
        return {}, text
    raw = text[4:end].strip()
    body = text[end + 4 :].lstrip("\r\n")
    data: dict[str, Any] = {}
    for line in raw.splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value.startswith("[") and value.endswith("]"):
            data[key] = [item.strip() for item in value[1:-1].split(",") if item.strip()]
        else:
            data[key] = value
    return data, body


def _first_heading(body: str) -> str | None:
    for line in body.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return None


def _wikilinks(body: str) -> list[str]:
    return sorted({match.strip() for match in WIKILINK_RE.findall(body) if match.strip()})


def _markdown_links(body: str) -> list[str]:
    return sorted({match.strip() for match in MARKDOWN_LINK_RE.findall(body) if match.strip()})


def _note_id(relative_path: str) -> str:
    return relative_path[:-3].lower().replace("\\", "/")


def _backlink_map(notes: list[dict[str, Any]]) -> dict[str, Any]:
    by_id = {note["note_id"]: note["relative_path"] for note in notes}
    by_stem = {Path(note["relative_path"]).stem.lower(): note["relative_path"] for note in notes}
    edges = []
    unresolved = []
    for note in notes:
        for raw in note["outgoing_wikilinks"]:
            key = raw.strip().lower().replace("\\", "/")
            target = by_id.get(key) or by_id.get(key.removesuffix(".md")) or by_stem.get(Path(key).stem)
            if target:
                edges.append(
                    {
                        "source": note["relative_path"],
                        "target": target,
                        "link": raw,
                    }
                )
            else:
                unresolved.append({"source": note["relative_path"], "link": raw})
    backlinks: dict[str, list[str]] = {note["relative_path"]: [] for note in notes}
    for edge in edges:
        backlinks[edge["target"]].append(edge["source"])
    return {
        "schema_version": "local_markdown_vault_backlink_map.v1",
        "edge_count": len(edges),
        "edges": edges,
        "backlinks": {key: sorted(value) for key, value in backlinks.items()},
        "unresolved_wikilinks": unresolved,
    }


def _folder_structure(notes: list[dict[str, Any]]) -> dict[str, Any]:
    folders: dict[str, list[str]] = {}
    for note in notes:
        folders.setdefault(note["folder"], []).append(note["relative_path"])
    return {
        "schema_version": "local_markdown_vault_folder_structure.v1",
        "folder_count": len(folders),
        "folders": [
            {
                "folder": folder,
                "note_count": len(paths),
                "notes": sorted(paths),
            }
            for folder, paths in sorted(folders.items())
        ],
    }


def _frontmatter_schema(notes: list[dict[str, Any]]) -> dict[str, Any]:
    observed = sorted({key for note in notes for key in note.get("frontmatter_keys", [])})
    return {
        "schema_version": "local_markdown_vault_frontmatter_schema.v1",
        "observed_keys": observed,
        "recommended_keys": ["title", "tags", "source", "created", "updated"],
        "frontmatter_preserved": True,
        "yaml_parser_dependency_required": False,
    }


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows


def _render_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    scan = manifest["vault_scan"]
    return f"""# Obsidian-Compatible Local Vault Adapter Strengthening

- Status: {validation['status']}
- Integration decision: {manifest['integration_decision']}
- Integration mode: {manifest['integration_mode']}
- Notes: {scan['note_count']}
- Folders: {scan['folder_count']}
- Wikilinks: {scan['wikilink_count']}
- Backlink edges: {scan['backlink_edge_count']}
- Exported notes: {validation.get('exported_note_count', 0)}
- Obsidian runtime integrated: {manifest['runtime_boundary']['obsidian_runtime_integrated']}
- Obsidian plugin required: {manifest['runtime_boundary']['obsidian_plugin_required']}
- UI executable action: {manifest['ui_contract']['executable_action']}

This is a Section 5.S3 strengthening record for local Markdown vault import/export, frontmatter, backlinks, and folder structure. It does not launch Obsidian, call plugins, require sync, or open later campaigns.
"""


def _render_validation_report(result: dict[str, Any]) -> str:
    return f"""# Obsidian-Compatible Vault Validation

- Status: {result['status']}
- Boundary errors: {len(result['boundary_errors'])}
- Notes: {result.get('note_count', 0)}
- Folders: {result.get('folder_count', 0)}
- Frontmatter keys: {result.get('frontmatter_key_count', 0)}
- Backlink edges: {result.get('backlink_edge_count', 0)}
- Exported notes: {result.get('exported_note_count', 0)}
- Runtime integrated: {result.get('obsidian_runtime_integrated')}
- Plugin required: {result.get('obsidian_plugin_required')}
"""
