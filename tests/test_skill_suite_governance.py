import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.skill_suite import (
    build_skill_suite,
    check_skill_suite_installability,
    diff_skill_suites,
    export_skill_pack,
    run_skill_suite_governance,
    validate_skill_suite,
)
from tests.p0_helpers import write_json
from tests.test_skill_suite_build import _candidate, _candidate_plan_payload


def _read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def test_suite_validation_installability_governance_and_ready_pack(tmp_path):
    old_suite, new_suite = _make_diff_suites(tmp_path)

    validate_result = CliRunner().invoke(
        app, ["validate-skill-suite", "--suite", str(new_suite)]
    )
    install_result = CliRunner().invoke(
        app, ["check-skill-suite-installability", "--suite", str(new_suite)]
    )
    governance_result = CliRunner().invoke(
        app,
        [
            "skill-suite-governance-report",
            "--suite",
            str(new_suite),
            "--old-suite",
            str(old_suite),
        ],
    )

    assert validate_result.exit_code == 0, validate_result.output
    assert install_result.exit_code == 0, install_result.output
    assert governance_result.exit_code == 0, governance_result.output
    validation = _read_json(new_suite / "suite_validation_report.json")
    installability = _read_json(
        new_suite / "skill_suite_installability_report.json"
    )
    governance = _read_json(new_suite / "skill_suite_governance_report.json")
    diff = _read_json(new_suite / "skill_suite_diff_report.json")
    assert validation["status"] == "pass"
    assert validation["release_ready"] is True
    assert installability["status"] == "pass"
    assert installability["validation_command"].startswith(
        "heitang-kb-forge validate-skill-suite"
    )
    assert governance["status"] == "pass"
    assert governance["release_ready"] is True
    assert governance["checks"]["diff_comparison"]["baseline_provided"] is True
    assert diff["added_skill_ids"] == ["candidate_atomic"]
    assert diff["removed_skill_ids"] == ["candidate_obsolete"]
    assert diff["changed_skills"][0]["skill_id"] == "candidate_function"

    pack = tmp_path / "pack"
    pack_manifest = export_skill_pack(new_suite, pack)
    assert pack_manifest["status"] == "ready"
    assert pack_manifest["suite_validation_status"] == "pass"
    assert pack_manifest["installability_check_status"] == "pass"
    assert pack_manifest["suite_governance_status"] == "pass"
    assert "skill_suite_governance_report.json" in pack_manifest["files"]
    checklist = (pack / "skill_eval_checklist.md").read_text(encoding="utf-8")
    assert "- [x] Suite validation: pass" in checklist
    assert "- [x] Installability check: pass" in checklist
    assert "- [x] Suite governance: pass" in checklist
    assert "Status: pass | Release ready: True" in governance_result.output


def test_suite_validation_blocks_tampered_routing_and_review_suite(tmp_path):
    _, suite = _make_diff_suites(tmp_path)
    (suite / "ROUTING.md").write_text("# Routing Rules\n", encoding="utf-8")

    validation = validate_skill_suite(suite)
    installability = check_skill_suite_installability(
        suite, validation=validation
    )
    governance = run_skill_suite_governance(suite)

    assert validation["status"] == "fail"
    assert any(
        blocker.startswith("routing_missing_skill:")
        for blocker in validation["blockers"]
    )
    assert installability["status"] == "fail"
    assert governance["status"] == "fail"
    assert governance["release_ready"] is False
    assert "diff_baseline_not_provided" in governance["warnings"]


def test_diff_skill_suite_cli_reports_added_removed_changed_and_graph(tmp_path):
    old_suite, new_suite = _make_diff_suites(tmp_path)
    output = tmp_path / "diff"

    result = CliRunner().invoke(
        app,
        [
            "diff-skill-suite",
            "--before",
            str(old_suite),
            "--after",
            str(new_suite),
            "--output",
            str(output),
        ],
    )

    assert result.exit_code == 0, result.output
    report = _read_json(output / "skill_suite_diff_report.json")
    assert report["added_skill_ids"] == ["candidate_atomic"]
    assert report["removed_skill_ids"] == ["candidate_obsolete"]
    assert [item["skill_id"] for item in report["changed_skills"]] == [
        "candidate_function"
    ]
    assert report["routing_changed"] is True
    assert report["dependency_graph_changed"] is True
    assert "Added: 1 | Removed: 1 | Changed: 1" in result.output


def test_validation_and_diff_reject_tampered_manifest_contracts(tmp_path):
    old_suite, new_suite = _make_diff_suites(tmp_path)
    manifest = _read_json(new_suite / "suite.json")
    manifest["skill_count"] = 99
    manifest["hierarchy_counts"]["atomic"] = 99
    write_json(new_suite / "suite.json", manifest)

    validation = validate_skill_suite(new_suite)
    assert "skill_count_manifest_mismatch" in validation["blockers"]
    assert "hierarchy_count_manifest_mismatch" in validation["blockers"]

    manifest["skills"][0]["path"] = "../outside/SKILL.md"
    write_json(new_suite / "suite.json", manifest)
    installability = check_skill_suite_installability(new_suite)
    assert installability["status"] == "fail"
    assert any(
        blocker.startswith("unsafe_skill_path:")
        for blocker in installability["blockers"]
    )

    try:
        diff_skill_suites(old_suite, new_suite, tmp_path / "diff")
    except ValueError as exc:
        assert "unsafe manifest path" in str(exc)
    else:
        raise AssertionError("diff_skill_suites accepted an unsafe Skill path")


def _make_diff_suites(tmp_path):
    old_payload = _candidate_plan_payload()
    old_payload["candidates"].append(
        _candidate(
            "candidate_obsolete",
            "Obsolete Check",
            "atomic",
            ["candidate_function"],
        )
    )
    old_payload["candidate_count"] = 3
    old_plan = tmp_path / "old_plan"
    old_plan.mkdir()
    write_json(old_plan / "skill_candidates.json", old_payload)
    old_suite = tmp_path / "old_suite"
    build_skill_suite(old_plan, old_suite)

    new_payload = _candidate_plan_payload()
    new_payload["candidates"][1]["skill_contract"]["purpose"] = (
        "Execute operations with revised evidence."
    )
    new_payload["candidates"].append(
        _candidate(
            "candidate_atomic",
            "Atomic Check",
            "atomic",
            ["candidate_function"],
        )
    )
    new_payload["candidate_count"] = 3
    new_plan = tmp_path / "new_plan"
    new_plan.mkdir()
    write_json(new_plan / "skill_candidates.json", new_payload)
    new_suite = tmp_path / "new_suite"
    build_skill_suite(new_plan, new_suite)
    return old_suite, new_suite
