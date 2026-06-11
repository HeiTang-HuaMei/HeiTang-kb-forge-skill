import json

import pytest
from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.skill_suite import build_skill_suite, plan_skill_suite
from tests.p0_helpers import write_json


def _read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def test_build_skill_suite_cli_writes_hierarchy_routing_and_graph(tmp_path):
    methodology = tmp_path / "methodology"
    methodology.mkdir()
    write_json(
        methodology / "methodology_map.json",
        {
            "methodology_map_version": "v4.2-p2.2-1",
            "source_package_id": "pkg-suite",
            "source_evidence": ["window_plan", "window_function", "window_atomic"],
            "methodology_modules": [
                _module("plan", "Plan Operations", "window_plan", workflows=2),
                _module("function", "Execute Operations", "window_function", workflows=1),
                _module("atomic", "Check One Rule", "window_atomic", workflows=0),
            ],
        },
    )
    plan = tmp_path / "plan"
    plan_skill_suite(methodology, plan)
    output = tmp_path / "suite"

    result = CliRunner().invoke(
        app, ["build-skill-suite", "--plan", str(plan), "--out", str(output)]
    )

    assert result.exit_code == 0, result.output
    suite = _read_json(output / "suite.json")
    graph = _read_json(output / "DEPENDENCY_GRAPH.json")
    hierarchy = _read_json(output / "SKILL_HIERARCHY.json")
    assert suite["skill_count"] == 3
    assert suite["hierarchy_counts"] == {
        "planning": 1,
        "functional": 1,
        "atomic": 1,
    }
    assert hierarchy["planning"]
    assert hierarchy["functional"]
    assert hierarchy["atomic"]
    assert len(graph["nodes"]) == 3
    assert len(graph["edges"]) == 2
    assert graph["missing_dependencies"] == []
    assert graph["cycle_detected"] is False
    assert (output / "ROUTING.md").read_text(encoding="utf-8").count("->") == 3
    assert (output / "skills" / "planning").is_dir()
    assert (output / "skills" / "functional").is_dir()
    assert (output / "skills" / "atomic").is_dir()
    assert len(list(output.glob("skills/*/*/SKILL.md"))) == 3
    assert suite["skillx_integration"]["integration_level"] == "L3_contract_absorbed+L4_capability_fused"
    assert suite["skillx_integration"]["runtime_integration"] == "none"
    assert "Skills: 3 | Status: ready" in result.output


def test_build_skill_suite_reports_duplicate_and_trigger_conflict(tmp_path):
    plan = tmp_path / "plan"
    plan.mkdir()
    payload = _candidate_plan_payload()
    duplicate = dict(payload["candidates"][1])
    duplicate["candidate_id"] = "candidate_duplicate"
    duplicate["title"] = payload["candidates"][0]["title"]
    duplicate["skill_contract"] = dict(duplicate["skill_contract"])
    duplicate["skill_contract"]["trigger"] = payload["candidates"][0]["skill_contract"][
        "trigger"
    ]
    duplicate["skill_contract"]["purpose"] = "A conflicting purpose."
    payload["candidates"].append(duplicate)
    payload["candidate_count"] = 3
    write_json(plan / "skill_candidates.json", payload)

    result = build_skill_suite(plan, tmp_path / "suite")

    assert result["status"] == "review_required"
    assert result["duplicate_skill_groups"]
    assert result["conflict_skill_pairs"]


def test_build_skill_suite_rejects_missing_dependency_and_cycle(tmp_path):
    plan = tmp_path / "plan"
    plan.mkdir()
    missing = _candidate_plan_payload()
    missing["candidates"][1]["dependency_draft"] = ["candidate_missing"]
    write_json(plan / "skill_candidates.json", missing)

    with pytest.raises(ValueError, match="missing dependencies"):
        build_skill_suite(plan, tmp_path / "missing_suite")

    cycle = _candidate_plan_payload()
    cycle["candidates"][0]["dependency_draft"] = ["candidate_function"]
    cycle["candidates"][1]["dependency_draft"] = ["candidate_plan"]
    write_json(plan / "skill_candidates.json", cycle)

    with pytest.raises(ValueError, match="contains a cycle"):
        build_skill_suite(plan, tmp_path / "cycle_suite")


def test_build_skill_suite_rejects_duplicate_or_unsafe_candidate_ids(tmp_path):
    plan = tmp_path / "plan"
    plan.mkdir()
    duplicate = _candidate_plan_payload()
    duplicate["candidates"][1]["candidate_id"] = "candidate_plan"
    write_json(plan / "skill_candidates.json", duplicate)

    with pytest.raises(ValueError, match="must be unique"):
        build_skill_suite(plan, tmp_path / "duplicate_suite")

    unsafe = _candidate_plan_payload()
    unsafe["candidates"][1]["candidate_id"] = "../escape"
    write_json(plan / "skill_candidates.json", unsafe)

    with pytest.raises(ValueError, match="unsafe path values"):
        build_skill_suite(plan, tmp_path / "unsafe_suite")


def _candidate_plan_payload():
    return {
        "skill_candidate_schema_version": "v4.2-p2.2-1",
        "source_package_id": "pkg-suite",
        "source_methodology_version": "v4.2-p2.2-1",
        "candidate_count": 2,
        "candidates": [
            _candidate("candidate_plan", "Plan Operations", "planning", []),
            _candidate(
                "candidate_function",
                "Execute Operations",
                "functional",
                ["candidate_plan"],
            ),
        ],
        "rejected_claims": [],
        "unsupported_claim_count": 0,
        "evidence_trace_preserved": True,
        "anything2skill_integration": {
            "integration_level": "L3_contract_absorbed+L4_capability_fused",
            "runtime_integration": "none",
            "provider_api_required": False,
        },
        "tests_require_real_llm_api_network": False,
    }


def _candidate(candidate_id, title, skill_type, dependencies):
    return {
        "candidate_id": candidate_id,
        "title": title,
        "provisional_skill_type": skill_type,
        "source_methodology_module": f"module_{candidate_id}",
        "supporting_evidence": [f"window_{candidate_id}"],
        "confidence": 0.9,
        "risk_flags": [],
        "status": "ready",
        "skill_contract": {
            "purpose": f"Purpose for {title}.",
            "trigger": f"Use when {title} is required.",
            "inputs": ["task"],
            "outputs": ["result"],
            "workflow_steps": [f"Apply {title}."],
            "constraints": ["Use evidence."],
            "failure_modes": [],
        },
        "merge_split_recommendation": {
            "action": "keep",
            "reason": "Focused responsibility.",
        },
        "dependency_draft": dependencies,
    }


def _module(module_id, title, evidence, workflows):
    return {
        "module_id": module_id,
        "title": title,
        "concepts": [
            {
                "item_id": f"{module_id}_concept",
                "statement": title,
                "source_evidence": [evidence],
                "confidence": 0.9,
                "risk_flags": [],
            }
        ],
        "principles": [],
        "decision_rules": [],
        "workflows": [
            {
                "item_id": f"{module_id}_workflow_{index}",
                "statement": f"Workflow step {index}",
                "source_evidence": [evidence],
                "confidence": 0.9,
                "risk_flags": [],
            }
            for index in range(workflows)
        ],
        "anti_patterns": [],
        "constraints": [],
        "applicability_boundary": [],
        "failure_modes": [],
        "risk_flags": [],
    }
