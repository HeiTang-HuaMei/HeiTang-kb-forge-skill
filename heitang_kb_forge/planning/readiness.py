import json
from pathlib import Path

PLANNING_OUTPUT_FILES = [
    "agent_planning_blueprint.yaml",
    "tool_requirement_map.json",
    "planning_eval_cases.jsonl",
    "planning_risk_report.md",
]


def make_planning_readiness(package: Path) -> tuple[str, dict, list[dict], str]:
    manifest = _read_json(package / "manifest.json")
    risks = _read_jsonl(package / "risk_labels.jsonl")
    agent_type = manifest.get("agent_type") or "generic_agent"
    package_path = str(package).replace("\\", "/")
    blueprint = f"""package: {package_path}
suggested_agent_types:
  - {agent_type}
supported_tasks:
  - answer_grounded_questions
  - summarize_knowledge_package
unsupported_tasks:
  - execute_external_tools
  - update_business_systems
required_tools:
  - knowledge_retrieval
human_confirmation_required:
  - high_risk_answers
risk_notes:
  - {len(risks)} risk labels found
"""
    tool_map = {
        "tasks": [
            {
                "task": "answer_grounded_questions",
                "required_tool_type": "knowledge_retrieval",
                "runtime_required": True,
                "data_dependency": "chunks.jsonl",
                "risk_level": "medium" if risks else "low",
            }
        ]
    }
    eval_cases = [
        {
            "task": "answer_grounded_questions",
            "user_goal": "Ask a question grounded in the package.",
            "expected_plan_steps": ["retrieve_context", "answer_with_citation"],
            "required_citations": True,
            "requires_tool": False,
            "requires_human_review": bool(risks),
        }
    ]
    report = f"# Planning Risk Report\n\n- Risk labels: {len(risks)}\n- Tool execution included: false\n"
    return blueprint, tool_map, eval_cases, report


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
