import json

import pytest
from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.methodology import extract_methodology
from heitang_kb_forge.schemas.skill_suite_schema import SkillCandidatePlan
from heitang_kb_forge.skill_suite import plan_skill_suite
from tests.p0_helpers import make_p0_package, write_json, write_jsonl


def _read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def test_plan_skill_suite_cli_builds_evidence_supported_candidates(tmp_path):
    package = make_p0_package(tmp_path)
    write_jsonl(
        package / "chunks.jsonl",
        [
            {
                "chunk_id": "c0",
                "source_path": "operations.md",
                "title": "Evidence-led Operations",
                "text": (
                    "Use local evidence and prefer narrow scope. "
                    "When evidence is missing, request review. "
                    "First inspect the source. Then apply the decision rule."
                ),
                "metadata": {"parse_confidence": 0.92},
            }
        ],
    )
    methodology = tmp_path / "methodology"
    extract_methodology(package, methodology)
    output = tmp_path / "skill_plan"

    result = CliRunner().invoke(
        app,
        ["plan-skill-suite", "--methodology", str(methodology), "--out", str(output)],
    )

    assert result.exit_code == 0, result.output
    assert set(path.name for path in output.iterdir()) == {
        "skill_candidates.json",
        "skill_plan.json",
        "dependency_draft.json",
        "candidate_planning_report.md",
    }
    plan = SkillCandidatePlan.model_validate(_read_json(output / "skill_candidates.json"))
    candidate = plan.candidates[0]
    assert plan.candidate_count == 1
    assert candidate.provisional_skill_type == "planning"
    assert candidate.supporting_evidence == ["window_001"]
    assert candidate.confidence == 0.92
    assert candidate.status == "ready"
    assert candidate.skill_contract.workflow_steps
    assert candidate.merge_split_recommendation.action == "keep"
    assert plan.anything2skill_integration["integration_level"] == "L3_contract_absorbed+L4_capability_fused"
    assert plan.anything2skill_integration["runtime_integration"] == "none"
    assert plan.anything2skill_integration["provider_api_required"] is False
    assert "Candidates: 1" in result.output


def test_plan_skill_suite_excludes_unsupported_claims(tmp_path):
    methodology = tmp_path / "methodology"
    methodology.mkdir()
    write_json(
        methodology / "methodology_map.json",
        {
            "methodology_map_version": "v4.2-p2.2-1",
            "source_package_id": "pkg-test",
            "source_evidence": ["window_001"],
            "methodology_modules": [
                {
                    "module_id": "module_001",
                    "title": "Review Boundary",
                    "concepts": [
                        {
                            "item_id": "supported",
                            "statement": "Review Boundary",
                            "source_evidence": ["window_001"],
                            "confidence": 0.9,
                            "risk_flags": [],
                        }
                    ],
                    "principles": [
                        {
                            "item_id": "unsupported",
                            "statement": "Call an external provider automatically.",
                            "source_evidence": ["window_missing"],
                            "confidence": 0.9,
                            "risk_flags": [],
                        }
                    ],
                    "decision_rules": [],
                    "workflows": [],
                    "anti_patterns": [],
                    "constraints": [],
                    "applicability_boundary": [],
                    "failure_modes": [],
                    "risk_flags": [],
                }
            ],
        },
    )

    result = plan_skill_suite(methodology, tmp_path / "skill_plan")

    assert result["candidate_count"] == 1
    assert result["unsupported_claim_count"] == 1
    assert result["rejected_claims"][0]["claim_id"] == "unsupported"
    assert "unsupported_claims_excluded" in result["candidates"][0]["risk_flags"]
    assert (
        "Call an external provider automatically."
        not in result["candidates"][0]["skill_contract"]["purpose"]
    )


def test_plan_skill_suite_requires_evidence_supported_candidate(tmp_path):
    methodology = tmp_path / "methodology"
    methodology.mkdir()
    write_json(
        methodology / "methodology_map.json",
        {
            "methodology_map_version": "v4.2-p2.2-1",
            "source_package_id": "pkg-test",
            "source_evidence": [],
            "methodology_modules": [
                {
                    "module_id": "module_001",
                    "title": "Unsupported",
                    "concepts": [
                        {
                            "item_id": "unsupported",
                            "statement": "Unsupported claim",
                            "source_evidence": [],
                            "confidence": 0.9,
                        }
                    ],
                }
            ],
        },
    )

    with pytest.raises(ValueError, match="No evidence-supported Skill candidates"):
        plan_skill_suite(methodology, tmp_path / "skill_plan")


def test_plan_skill_suite_builds_provisional_dependency_draft(tmp_path):
    methodology = tmp_path / "methodology"
    methodology.mkdir()
    write_json(
        methodology / "methodology_map.json",
        {
            "methodology_map_version": "v4.2-p2.2-1",
            "source_package_id": "pkg-test",
            "source_evidence": ["window_001", "window_002", "window_003"],
            "methodology_modules": [
                _module("module_plan", "Plan Work", "window_001", workflows=2),
                _module("module_function", "Execute Work", "window_002", workflows=1),
                _module("module_atomic", "Check One Rule", "window_003", workflows=0),
            ],
        },
    )

    result = plan_skill_suite(methodology, tmp_path / "skill_plan")
    candidates = {item["provisional_skill_type"]: item for item in result["candidates"]}

    assert candidates["planning"]["dependency_draft"] == []
    assert candidates["functional"]["dependency_draft"] == [
        candidates["planning"]["candidate_id"]
    ]
    assert candidates["atomic"]["dependency_draft"] == [
        candidates["functional"]["candidate_id"]
    ]


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
