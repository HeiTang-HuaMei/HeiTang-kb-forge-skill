import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.live.provider_smoke import run_live_provider_smoke
from heitang_kb_forge.provider_security import default_provider_registry, run_provider_security_audit


REQUIRED_PROVIDER_FIELDS = {
    "provider_id",
    "display_name",
    "region",
    "adapter_type",
    "base_url_env",
    "api_key_env",
    "default_model_env",
    "default_base_url",
    "timeout_seconds",
    "max_retries",
    "supports_streaming",
    "supports_json_mode",
    "supports_vision",
    "supports_embedding",
    "live_smoke_supported",
    "status",
    "docs_url",
    "risk_notes",
}


def test_provider_security_audit_passes_for_env_only_mock_provider(tmp_path):
    workspace = tmp_path / "workspace"
    registry = workspace / "registries"
    output = tmp_path / "out"
    registry.mkdir(parents=True)
    (registry / "provider_registry.json").write_text(
        json.dumps(
            {
                "providers": [
                    {
                        "provider_id": "mock_default",
                        "provider_type": "mock",
                        "api_key_env": "OPENAI_API_KEY",
                        "network_required": False,
                        "enabled": True,
                    }
                ]
            }
        ),
        encoding="utf-8",
    )

    result = run_provider_security_audit(workspace, output)

    assert result["status"] == "pass"
    assert result["stores_real_api_keys"] is False
    assert (output / "provider_security_audit.json").exists()
    assert (output / "provider_security_report.md").exists()
    assert "sk-" not in (output / "provider_security_audit.json").read_text(encoding="utf-8")


def test_provider_security_audit_fails_for_inline_secret(tmp_path):
    workspace = tmp_path / "workspace"
    registry = workspace / "registries"
    output = tmp_path / "out"
    registry.mkdir(parents=True)
    (registry / "provider_registry.json").write_text(
        json.dumps({"providers": [{"provider_id": "bad", "provider_type": "openai", "api_key": "sk-secret-value"}]}),
        encoding="utf-8",
    )

    result = run_provider_security_audit(workspace, output)

    assert result["status"] == "fail"
    assert result["stores_real_api_keys"] is True
    assert result["findings"][0]["severity"] == "critical"


def test_llm_live_smoke_mock_provider_is_callable_without_network(tmp_path):
    output = tmp_path / "live"

    result = run_live_provider_smoke(output, provider="mock", model="mock-model")

    assert result["status"] == "pass"
    assert result["allow_network"] is False
    assert result["llm_callable"] is True
    assert result["api_key_leak_detected"] is False
    assert (output / "llm_live_smoke_result.json").exists()
    assert (output / "llm_live_smoke_report.md").exists()


def test_llm_live_smoke_non_mock_is_warning_without_allow_network(tmp_path, monkeypatch):
    monkeypatch.setenv("LIVE_KEY", "sk-test-secret")
    output = tmp_path / "live"

    result = run_live_provider_smoke(
        output,
        provider="openai_compatible",
        model="model",
        base_url_env="LIVE_URL",
        api_key_env="LIVE_KEY",
        allow_network=False,
    )

    payload = (output / "llm_live_smoke_result.json").read_text(encoding="utf-8")
    report = (output / "llm_live_smoke_report.md").read_text(encoding="utf-8")
    assert result["status"] == "warning"
    assert result["llm_callable"] is False
    assert "sk-test-secret" not in payload
    assert "sk-test-secret" not in report


def test_v26_provider_security_and_live_smoke_cli_outputs(tmp_path):
    workspace = tmp_path / "workspace"
    security_output = tmp_path / "security"
    smoke_output = tmp_path / "smoke"

    runner = CliRunner()
    audit = runner.invoke(app, ["provider-security-audit", "--workspace", str(workspace), "--output", str(security_output)])
    smoke = runner.invoke(app, ["llm-live-smoke", "--output", str(smoke_output), "--provider", "mock"])

    assert audit.exit_code == 0, audit.output
    assert smoke.exit_code == 0, smoke.output
    assert (security_output / "provider_security_audit.json").exists()
    assert (security_output / "provider_security_report.md").exists()
    assert (smoke_output / "llm_live_smoke_result.json").exists()
    assert (smoke_output / "llm_live_smoke_report.md").exists()


def test_v26_builtin_registry_covers_user_configured_provider_profile_types():
    registry = default_provider_registry()
    providers = {item["provider_id"]: item for item in registry["providers"]}

    assert set(providers) == {
        "official_openai",
        "official_vendor",
        "openai_compatible_proxy",
        "local_model",
        "custom_http",
    }
    for provider in providers.values():
        assert REQUIRED_PROVIDER_FIELDS <= set(provider)
        assert provider["api_key_env"]
        assert "api_key" not in provider
        assert provider["provider_profile_template"] is True
        assert provider["recommendation_status"] == "not_a_recommendation"
        assert provider["bundled_unofficial_proxy"] is False
        assert provider["openai_compatible_proxy_equivalent_to_official_openai"] is False


def test_v26_provider_governance_cli_outputs_are_offline_and_redacted(tmp_path):
    runner = CliRunner()
    output = tmp_path / "out"

    commands = [
        ["provider-registry-export", "--output", str(output / "registry")],
        ["provider-config-validate", "--output", str(output / "validate")],
        ["provider-health", "--output", str(output / "health")],
        ["provider-live-smoke", "--output", str(output / "live-smoke")],
        ["provider-fallback-test", "--output", str(output / "fallback"), "--scenario", "rate_limit"],
        [
            "llm-cost-guard",
            "--output",
            str(output / "cost"),
            "--prompt-chars",
            "13000",
            "--output-tokens",
            "5000",
        ],
        ["audit-redaction-check", "--output", str(output / "redaction"), "--sample", "sk-test-secret"],
        ["llm-quality-gate-assist", "--workspace", str(tmp_path), "--output", str(output / "quality"), "--provider", "mock"],
    ]

    for command in commands:
        result = runner.invoke(app, command)
        assert result.exit_code == 0, result.output

    assert (output / "registry" / "provider_registry.json").exists()
    assert (output / "validate" / "provider_config_validate_result.json").exists()
    assert (output / "health" / "provider_health_result.json").exists()
    live_smoke = json.loads((output / "live-smoke" / "provider_live_smoke_result.json").read_text(encoding="utf-8"))
    redaction = json.loads((output / "redaction" / "audit_redaction_check_result.json").read_text(encoding="utf-8"))
    quality = json.loads((output / "quality" / "llm_quality_gate_assist_result.json").read_text(encoding="utf-8"))
    assert live_smoke["network_called"] is False
    assert redaction["secret_leaked"] is False
    assert redaction["redacted_sample"] == "[REDACTED]"
    assert quality["network_called"] is False
