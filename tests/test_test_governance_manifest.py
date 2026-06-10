import json
from pathlib import Path
from types import SimpleNamespace

from heitang_kb_forge.test_governance import build_validation_plan, load_manifest, select_impact_rules, validate_manifest
from heitang_kb_forge.test_governance import gates


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "docs" / "testing" / "VALIDATION_GATE_MANIFEST.json"


def test_validation_gate_manifest_is_structurally_valid():
    manifest = load_manifest(MANIFEST_PATH)

    assert manifest["release_version"] == "v4.1.1"
    assert validate_manifest(manifest) == []
    assert manifest["reporting_policy"]["never_report_skipped_or_deferred_as_passed"] is True
    assert "passed by default" in manifest["reporting_policy"]["forbidden_skip_reasons"]
    assert "passed" not in manifest["reporting_policy"]["allowed_non_pass_status"]
    assert manifest["post_codex_review_gate"]["required"] is True

    release_gates = {gate["name"]: gate for gate in manifest["gates"] if gate["level"] == "chunked_full"}
    assert set(manifest["release_gate_sequence"]) <= set(release_gates)
    assert all(gate["release_blocking"] is True for gate in release_gates.values())
    assert all(gate["exit_code_required"] is True for gate in release_gates.values())
    assert all(gate["log_path"].startswith("docs/audits/test_engineering/full_gate_logs/") for gate in release_gates.values())


def test_pytest_markers_are_declared_for_gate_selection():
    manifest = load_manifest(MANIFEST_PATH)
    pyproject = (ROOT / "pyproject.toml").read_text(encoding="utf-8")

    for marker in manifest["pytest_markers"]:
        assert f"{marker}:" in pyproject


def test_changed_file_impact_rules_select_development_and_release_gates():
    manifest = load_manifest(MANIFEST_PATH)
    rules = select_impact_rules(["docs/testing/VALIDATION_STRATEGY.md", "pyproject.toml"], manifest)

    assert {rule["name"] for rule in rules} >= {"test_governance", "version_metadata"}

    dev_plan = build_validation_plan(["docs/testing/VALIDATION_STRATEGY.md"], phase="development", manifest=manifest)
    assert {gate["name"] for gate in dev_plan["selected_gates"]} >= {
        "core_fast_test_governance",
        "core_fast_docs_truth",
    }
    assert dev_plan["release_blocking"] is False

    release_plan = build_validation_plan(["docs/testing/VALIDATION_STRATEGY.md"], phase="release", manifest=manifest)
    assert [gate["name"] for gate in release_plan["selected_gates"]] == manifest["release_gate_sequence"]
    assert release_plan["release_blocking"] is True

    doctor_plan = build_validation_plan(["heitang_kb_forge/doctor.py"], phase="development", manifest=manifest)
    assert [gate["name"] for gate in doctor_plan["selected_gates"]] == ["core_fast_doctor_release_readiness"]
    assert "doctor_release_readiness" in doctor_plan["matched_rules"]


def test_unmatched_changes_fall_back_to_governance_gate():
    manifest = load_manifest(MANIFEST_PATH)
    plan = build_validation_plan(["tmp/manual_note.txt"], phase="development", manifest=manifest)

    assert [gate["name"] for gate in plan["selected_gates"]] == manifest["default_gates"]["development"]


def test_test_pruning_register_names_canonical_replacements():
    register = (ROOT / "docs" / "testing" / "TEST_PRUNING_REGISTER.md").read_text(encoding="utf-8")
    zh_register = (ROOT / "docs" / "testing" / "TEST_PRUNING_REGISTER.zh-CN.md").read_text(encoding="utf-8")

    for text in [register, zh_register]:
        assert "canonical" in text.lower()
        assert "exact" in text.lower()
        assert "replacement" in text.lower()
        assert "skipped" in text.lower()
        assert "passed" in text.lower()


def test_validation_report_schema_fields_remain_required():
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))

    assert manifest["reporting_policy"]["required_command_fields"] == [
        "command",
        "exit_code",
        "status",
        "log_path",
        "summary",
    ]


def test_post_codex_review_gate_is_finite_and_release_blocking():
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    review_gate = manifest["post_codex_review_gate"]

    assert set(review_gate["levels"]) == {"light", "medium", "full"}
    assert review_gate["levels"]["light"]["when"] == "after_each_task"
    assert review_gate["levels"]["medium"]["when"] == "after_phase_closure"
    assert review_gate["levels"]["full"]["when"] == "before_tag_or_release"
    assert "v4.1.1 tag" in review_gate["levels"]["full"]["required_before"]
    assert "P3 recorded as non-blocking backlog" in review_gate["stop_conditions"]
    assert "no release-blocking P0/P1/P2" in review_gate["release_rule"]

    for field in ["id", "severity", "surface", "file/path", "evidence", "impact", "recommended_fix", "blocks_release"]:
        assert field in review_gate["issue_schema"]


def test_execute_mode_returns_nonzero_when_any_gate_fails(monkeypatch):
    monkeypatch.setattr(gates, "load_manifest", lambda path: {"release_version": "v4.1.1"})
    monkeypatch.setattr(gates, "build_validation_plan", lambda changed_files, phase, manifest: {"selected_gates": []})
    monkeypatch.setattr(gates, "run_validation_plan", lambda plan, repo_root: {"results": [{"status": "failed"}]})

    assert gates.main(["--execute"]) == 1


def test_run_validation_plan_writes_per_gate_exit_code_and_result(tmp_path, monkeypatch):
    tests_dir = tmp_path / "tests"
    tests_dir.mkdir()
    (tests_dir / "test_fake.py").write_text("def test_fake():\n    assert True\n", encoding="utf-8")
    captured = {}

    def fake_run(command, cwd, shell, text, stdout, stderr):
        captured["command"] = command
        stdout.write("fake gate passed\n")
        return SimpleNamespace(returncode=0)

    monkeypatch.setattr(gates.subprocess, "run", fake_run)
    plan = {
        "selected_gates": [
            {
                "name": "fake_gate",
                "command": "fake command",
                "working_directory": ".",
                "test_file_patterns": ["tests/test_*.py"],
                "log_path": "docs/audits/test_engineering/full_gate_logs/fake_gate.log",
            }
        ]
    }

    result = gates.run_validation_plan(plan, tmp_path)["results"][0]

    exit_code_path = tmp_path / "docs/audits/test_engineering/full_gate_logs/fake_gate.log.exitcode"
    result_path = tmp_path / "docs/audits/test_engineering/full_gate_logs/fake_gate.log.result.json"
    assert exit_code_path.read_text(encoding="utf-8").strip() == "0"
    assert json.loads(result_path.read_text(encoding="utf-8"))["exit_code"] == 0
    assert result["exit_code_path"] == "docs/audits/test_engineering/full_gate_logs/fake_gate.log.exitcode"
    assert captured["command"] == "fake command tests/test_fake.py"
