import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.parser_backends import release_hardening, surya_adapter


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def _missing_surya(monkeypatch):
    monkeypatch.setattr(surya_adapter.shutil, "which", lambda name: None)
    monkeypatch.setattr(release_hardening.shutil, "which", lambda name: None)


def _present_surya(monkeypatch):
    monkeypatch.setattr(
        surya_adapter.shutil,
        "which",
        lambda name: name if name in {"surya_ocr", "llama-server"} else None,
    )
    monkeypatch.setattr(
        release_hardening.shutil,
        "which",
        lambda name: name if name in {"surya_ocr", "llama-server"} else None,
    )


def test_check_surya_backend_keeps_benchmark_needs_strengthening_decision(tmp_path, monkeypatch):
    _missing_surya(monkeypatch)
    output = tmp_path / "check"
    model_cache = tmp_path / "surya_cache"

    result = CliRunner().invoke(
        app,
        ["check-surya-backend", "--output", str(output), "--model-cache", str(model_cache)],
    )

    assert result.exit_code == 0, result.output
    payload = _json(output / "surya_integration_decision_report.json")
    assert payload["decision"] == "needs_strengthening"
    assert payload["current_environment_status"] == "blocked_by_dependency"
    assert payload["dependency_status"] == "missing"
    assert payload["capabilities"]["benchmark_adapter"] is True
    assert payload["capabilities"]["primary_parser"] is False
    assert payload["capabilities"]["requires_inference_backend"] == "vllm_or_llama_cpp"
    assert payload["capabilities"]["runtime_invocation_blocked_until_strengthened"] is True
    remediation = _json(output / "surya_dependency_remediation_report.json")
    assert remediation["adapter_name"] == "surya"
    assert remediation["missing_dependencies"] == ["surya_ocr", "vllm_or_llama_server"]
    assert remediation["install_attempted"] is False
    assert remediation["final_decision"] == "needs_strengthening"
    assert remediation["new_cache_path"] == str(model_cache.resolve())
    ui_note = _json(output / "surya_ui_impact_note.json")
    assert ui_note["ui_status"] == "needs_strengthening"
    assert ui_note["model_cache_path"] == str(model_cache.resolve())
    assert ui_note["web_execution_enabled"] is False
    assert (output / "surya_integration_decision_report.md").exists()
    assert (output / "surya_dependency_remediation_report.md").exists()
    assert (output / "surya_ui_impact_note.md").exists()


def test_smoke_surya_backend_never_invokes_runtime_even_if_dependencies_exist(tmp_path, monkeypatch):
    calls = []

    def fail_if_called(self, path, command):
        calls.append((path, command))
        raise AssertionError("Surya benchmark runtime should stay blocked until strengthened.")

    _present_surya(monkeypatch)
    monkeypatch.setattr(surya_adapter.SuryaParserBackend, "parse_source", fail_if_called)
    output = tmp_path / "smoke"

    result = CliRunner().invoke(app, ["smoke-surya-backend", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "surya_smoke_report.json")
    result_payload = payload["adapter_smoke_report"]["result"]
    assert calls == []
    assert payload["status"] == "blocked"
    assert payload["adapter_smoke_report"]["status"] == "skipped"
    assert result_payload["status"] == "skipped"
    assert {error["code"] for error in result_payload["errors"]} == {"adapter_not_integrated"}
    assert payload["benchmark_adapter"] is True
    assert payload["primary_parser_promotion_blocked"] is True
    remediation = _json(output / "surya_dependency_remediation_report.json")
    assert remediation["post_install_smoke_result"] == "blocked"
    assert remediation["final_decision"] == "needs_strengthening"
    assert (output / "surya_smoke_report.md").exists()
    assert (output / "surya_integration_decision_report.json").exists()


def test_surya_registry_contract_never_marks_primary_runtime_ready(monkeypatch):
    _present_surya(monkeypatch)

    check = release_hardening.inspect_backend_status("surya")

    assert check["status"] == "disabled"
    assert check["capability_contract"]["integration_decision"] == "needs_strengthening"
    assert check["capability_contract"]["runtime_status"] == "disabled"
    assert check["backend"]["workbench_state"] == ["needs_strengthening", "reference_benchmark"]
