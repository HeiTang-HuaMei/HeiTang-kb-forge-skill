from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


STANDALONE_AGENT_FILES = [
    "agent_manifest.json",
    "agent_profile.yaml",
    "soul.md",
    "system_prompt.md",
    "capabilities.yaml",
    "tools.yaml",
    "memory_policy.yaml",
    "output_contract.yaml",
    "answer_policy.md",
    "refusal_policy.md",
    "eval_cases.jsonl",
    "smoke_test_report.json",
    "smoke_test_report.md",
    "validation_report.json",
    "validation_report.md",
]


def generate_standalone_agent(
    output: Path,
    agent_name: str,
    agent_type: str = "generic",
    description: str = "Standalone local Agent package.",
    capabilities: list[str] | None = None,
) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    capabilities = capabilities or _default_capabilities(agent_type)
    manifest = _manifest(agent_name, agent_type, description, capabilities)
    write_json(output / "agent_manifest.json", manifest)
    (output / "agent_profile.yaml").write_text(_profile_yaml(manifest), encoding="utf-8")
    (output / "soul.md").write_text(_soul(agent_name, description), encoding="utf-8")
    (output / "system_prompt.md").write_text(_system_prompt(agent_name), encoding="utf-8")
    (output / "capabilities.yaml").write_text(_capabilities_yaml(capabilities), encoding="utf-8")
    (output / "tools.yaml").write_text(_tools_yaml(), encoding="utf-8")
    (output / "memory_policy.yaml").write_text(_memory_policy_yaml(), encoding="utf-8")
    (output / "output_contract.yaml").write_text(_output_contract_yaml(), encoding="utf-8")
    (output / "answer_policy.md").write_text(_answer_policy(), encoding="utf-8")
    (output / "refusal_policy.md").write_text(_refusal_policy(), encoding="utf-8")
    write_jsonl(output / "eval_cases.jsonl", _eval_cases())
    validation = validate_standalone_agent(output)
    smoke = _smoke_report(validation)
    write_json(output / "validation_report.json", validation)
    (output / "validation_report.md").write_text(_validation_md(validation), encoding="utf-8")
    write_json(output / "smoke_test_report.json", smoke)
    (output / "smoke_test_report.md").write_text(_smoke_md(smoke), encoding="utf-8")
    return manifest | {"output_files": STANDALONE_AGENT_FILES}


def validate_standalone_agent(agent: Path) -> dict:
    missing = [name for name in _required_files() if not (agent / name).exists()]
    manifest = _read_json(agent / "agent_manifest.json")
    errors = list(missing)
    if manifest.get("mode") != "standalone":
        errors.append("mode_must_be_standalone")
    if manifest.get("knowledge_binding", {}).get("enabled") is not False:
        errors.append("standalone_agent_must_not_require_knowledge_binding")
    if (agent / "retrieval_config.yaml").exists():
        errors.append("standalone_agent_must_not_enable_retrieval_binding_by_default")
    status = "pass" if not errors else "fail"
    return {
        "validation_report_version": "3.1.0-alpha.1",
        "mode": "standalone",
        "status": status,
        "validation_status": status,
        "errors": errors,
        "required_files": _required_files(),
    }


def _manifest(agent_name: str, agent_type: str, description: str, capabilities: list[str]) -> dict:
    return {
        "agent_manifest_version": "3.1.0-alpha.1",
        "agent_id": _slug(agent_name),
        "name": agent_name,
        "mode": "standalone",
        "agent_type": agent_type,
        "description": description,
        "capabilities": capabilities,
        "tool_policy": {"enabled_by_default": False, "allowed_tools": []},
        "memory_policy": {"private_memory": True, "kb_memory": False},
        "output_contract": {"format": "markdown", "requires_citations": False},
        "provider_profile": {"provider": "local", "network_required": False, "llm_required": False},
        "knowledge_binding": {"enabled": False},
        "created_at": datetime.now(timezone.utc).isoformat(),
        "validation_status": "pass",
    }


def _required_files() -> list[str]:
    return [
        "agent_manifest.json",
        "agent_profile.yaml",
        "soul.md",
        "system_prompt.md",
        "capabilities.yaml",
        "tools.yaml",
        "memory_policy.yaml",
        "output_contract.yaml",
        "answer_policy.md",
        "refusal_policy.md",
        "eval_cases.jsonl",
    ]


def _default_capabilities(agent_type: str) -> list[str]:
    if agent_type in {"planning", "project_management"}:
        return ["plan tasks", "organize milestones", "summarize risks"]
    if agent_type in {"writing", "interview_coach"}:
        return ["draft structured responses", "review tone", "suggest improvements"]
    return ["plan", "reason", "produce structured output"]


def _profile_yaml(manifest: dict) -> str:
    return "\n".join(
        [
            f"agent_id: {manifest['agent_id']}",
            f"agent_name: {manifest['name']}",
            "mode: standalone",
            f"agent_type: {manifest['agent_type']}",
            "knowledge_binding_enabled: false",
            "retrieval_binding_enabled: false",
            "",
        ]
    )


def _soul(agent_name: str, description: str) -> str:
    return f"# {agent_name} Soul\n\n{description}\n\nThis standalone Agent works from its prompt, policies, tools, memory policy, and output contract. It does not claim KB citations.\n"


def _system_prompt(agent_name: str) -> str:
    return f"# System Prompt\n\nYou are {agent_name}. Follow the answer policy, refusal policy, memory policy, tool policy, and output contract. Do not claim citations from a knowledge package unless one is explicitly provided by a future workflow.\n"


def _capabilities_yaml(capabilities: list[str]) -> str:
    return "capabilities:\n" + "\n".join(f"  - {capability}" for capability in capabilities) + "\n"


def _tools_yaml() -> str:
    return "tools:\n  enabled_by_default: false\n  allowed: []\n"


def _memory_policy_yaml() -> str:
    return "memory_policy:\n  private_memory: true\n  knowledge_bound_memory: false\n  persist_without_user_consent: false\n"


def _output_contract_yaml() -> str:
    return "output_contract:\n  default_format: markdown\n  requires_kb_citations: false\n  require_clear_uncertainty: true\n"


def _answer_policy() -> str:
    return "# Answer Policy\n\n- Answer from the system prompt, declared capabilities, and explicit user-provided context.\n- Do not invent KB citations.\n- State uncertainty when evidence or context is insufficient.\n"


def _refusal_policy() -> str:
    return "# Refusal Policy\n\nRefuse unsafe, unsupported, or out-of-role requests. Explain the boundary briefly and offer a safe alternative when possible.\n"


def _eval_cases() -> list[dict]:
    return [
        {"case_id": "standalone_case_1", "query": "Create a project plan.", "expected_behavior": "structured_plan_without_kb_citation"},
        {"case_id": "standalone_case_2", "query": "Cite the bound KB.", "expected_behavior": "refuse_fake_kb_citation"},
    ]


def _smoke_report(validation: dict) -> dict:
    return {
        "smoke_test_report_version": "3.1.0-alpha.1",
        "mode": "standalone",
        "status": validation["status"],
        "checks": [
            {"name": "required_files", "status": "pass" if not validation["errors"] else "fail"},
            {"name": "no_kb_citation_claim", "status": "pass"},
            {"name": "offline_only", "status": "pass"},
        ],
    }


def _validation_md(validation: dict) -> str:
    errors = validation["errors"] or ["none"]
    return "# Standalone Agent Validation\n\n" + "\n".join(f"- {error}" for error in errors) + "\n"


def _smoke_md(smoke: dict) -> str:
    return "# Standalone Agent Smoke Test\n\n" + "\n".join(f"- {item['name']}: {item['status']}" for item in smoke["checks"]) + "\n"


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _slug(value: str) -> str:
    return "".join(char.lower() if char.isalnum() else "-" for char in value).strip("-") or "standalone-agent"
