from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json


WORKBENCH_CONTRACT_OUTPUT_FILES = [
    "workbench_contract_manifest.json",
    "workbench_navigation_contract.json",
    "workbench_action_contract.json",
    "workbench_asset_contract.json",
    "workbench_status_contract.json",
    "workbench_contract_trace.json",
    "workbench_contract_report.md",
]


def generate_workbench_contracts(core_output: Path, output: Path | None = None, project_name: str = "HeiTang Workbench") -> dict:
    target = output or core_output
    target.mkdir(parents=True, exist_ok=True)
    assets = _assets(core_output)
    navigation = {
        "workbench_navigation_contract_version": "3.4.0-alpha.1",
        "project_name": project_name,
        "views": [
            {"id": "packages", "label": "Knowledge Packages", "asset_types": ["knowledge_package"]},
            {"id": "skills", "label": "Skills", "asset_types": ["skill_package", "fused_skill"]},
            {"id": "agents", "label": "Agents", "asset_types": ["agent_package"]},
            {"id": "reports", "label": "Reports", "asset_types": ["report"]},
        ],
    }
    actions = {
        "workbench_action_contract_version": "3.4.0-alpha.1",
        "actions": [
            {"id": "build_package", "label": "Build Package", "command": "build", "requires": ["input", "output"]},
            {"id": "generate_documents", "label": "Generate Documents", "command": "generate-documents", "requires": ["package", "output"]},
            {"id": "generate_bound_agent", "label": "Generate Bound Agent", "command": "generate-bound-agent", "requires": ["package", "output"]},
            {"id": "orchestrate_multi_kb", "label": "Orchestrate Multi-KB", "command": "orchestrate-multi-kb", "requires": ["packages", "output"]},
            {"id": "reverse_fuse_skills", "label": "Reverse Fuse Skills", "command": "reverse-fuse-skills", "requires": ["skills", "output"]},
        ],
    }
    asset_contract = {"workbench_asset_contract_version": "3.4.0-alpha.1", "assets": assets}
    status = {
        "workbench_status_contract_version": "3.4.0-alpha.1",
        "status": "ready" if assets else "empty",
        "asset_count": len(assets),
        "report_count": len([asset for asset in assets if asset["asset_type"] == "report"]),
    }
    manifest = {
        "workbench_contract_version": "3.4.0-alpha.1",
        "project_name": project_name,
        "core_output": str(core_output).replace("\\", "/"),
        "status": status["status"],
        "output_files": WORKBENCH_CONTRACT_OUTPUT_FILES,
    }
    trace = {
        "workbench_contract_trace_version": "3.4.0-alpha.1",
        "steps": [
            {"name": "scan_core_output", "status": "pass", "asset_count": len(assets)},
            {"name": "write_navigation_contract", "status": "pass"},
            {"name": "write_action_contract", "status": "pass"},
            {"name": "write_status_contract", "status": status["status"]},
        ],
    }
    write_json(target / "workbench_contract_manifest.json", manifest)
    write_json(target / "workbench_navigation_contract.json", navigation)
    write_json(target / "workbench_action_contract.json", actions)
    write_json(target / "workbench_asset_contract.json", asset_contract)
    write_json(target / "workbench_status_contract.json", status)
    write_json(target / "workbench_contract_trace.json", trace)
    (target / "workbench_contract_report.md").write_text(_report(manifest, status), encoding="utf-8")
    return manifest


def _assets(core_output: Path) -> list[dict]:
    candidates = [
        ("manifest.json", "knowledge_package"),
        ("generated_file_report.json", "report"),
        ("knowledge_bound_factory_manifest.json", "report"),
        ("multi_kb_orchestration_manifest.json", "report"),
        ("skill_reverse_fusion_manifest.json", "report"),
        ("skill_package/SKILL.md", "skill_package"),
        ("agent_package/agent_profile.yaml", "agent_package"),
        ("fused_skill/SKILL.md", "fused_skill"),
    ]
    assets = []
    for relative, asset_type in candidates:
        path = core_output / relative
        if path.exists():
            assets.append({"asset_id": relative.replace("/", "_").replace(".", "_"), "asset_type": asset_type, "path": str(path).replace("\\", "/")})
    return assets


def _report(manifest: dict, status: dict) -> str:
    return "\n".join(
        [
            "# Workbench Contract Report",
            "",
            f"Project: {manifest['project_name']}",
            f"Status: {manifest['status']}",
            f"Assets: {status['asset_count']}",
            f"Reports: {status['report_count']}",
            "",
        ]
    )
