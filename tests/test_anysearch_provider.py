import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.external_retrieval import (
    check_anysearch_provider,
    run_anysearch_retrieval,
    smoke_anysearch_provider,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _success_transport(endpoint, headers, payload, timeout_seconds, proxy_url):
    assert endpoint == "https://api.anysearch.com/mcp"
    assert "Authorization" not in headers
    assert payload["method"] == "tools/call"
    assert payload["params"]["name"] == "search"
    assert timeout_seconds == 30
    assert proxy_url is None
    return {
        "jsonrpc": "2.0",
        "id": 1,
        "result": {
            "content": [
                {
                    "type": "text",
                    "text": (
                        "## Search Results (2 results, 12ms)\n\n"
                        "### 1. Source Trace Guide\n"
                        "- **URL**: https://example.test/source-trace\n"
                        "- Preserve source attribution and freshness metadata.\n\n"
                        "### 2. Retrieval Verification\n"
                        "- **URL**: https://example.test/verification\n"
                        "- Verify retrieved claims against cited sources.\n"
                    ),
                }
            ]
        },
    }


def test_anysearch_check_supports_anonymous_mode_without_persisting_secrets(tmp_path):
    result = check_anysearch_provider(tmp_path)

    assert result["status"] == "passed"
    assert result["runtime_status"] == "available_anonymous"
    assert result["api_key_optional"] is True
    assert result["api_key_configured"] is False
    assert result["secrets_persisted"] is False
    assert _json(tmp_path / "anysearch_provider_check.json") == result


def test_anysearch_smoke_normalizes_sources_and_source_trace(tmp_path):
    result = smoke_anysearch_provider(
        tmp_path,
        allow_network=True,
        query="source trace",
        transport=_success_transport,
    )

    assert result["status"] == "passed"
    assert result["runtime_status"] == "available"
    assert result["smoke_status"] == "passed"
    assert result["anonymous_mode"] is True
    assert result["result_count"] == 2
    assert result["sources"][0]["title"] == "Source Trace Guide"
    assert result["sources"][0]["url"] == "https://example.test/source-trace"
    trace = _json(tmp_path / "source_trace.json")
    assert trace["source_count"] == 2
    assert trace["sources"] == result["sources"]


def test_anysearch_disabled_and_network_not_allowed_are_structured_skips(tmp_path):
    config = tmp_path / "disabled.json"
    config.write_text(json.dumps({"enabled": False}), encoding="utf-8")

    disabled = smoke_anysearch_provider(tmp_path / "disabled", config_path=config, allow_network=True)
    offline = smoke_anysearch_provider(tmp_path / "offline", allow_network=False)

    assert disabled["status"] == "skipped"
    assert disabled["runtime_status"] == "disabled"
    assert disabled["smoke_status"] == "skipped_disabled"
    assert disabled["network_called"] is False
    assert offline["status"] == "skipped"
    assert offline["smoke_status"] == "skipped_network_not_allowed"
    assert offline["network_called"] is False


def test_anysearch_proxy_failure_is_not_reported_as_ready(tmp_path):
    config = tmp_path / "proxy.json"
    config.write_text(json.dumps({"proxy_url": "https://proxy.example.test:8443"}), encoding="utf-8")

    def failing_transport(*_args):
        raise RuntimeError("proxy authentication failed")

    result = smoke_anysearch_provider(
        tmp_path / "out",
        config_path=config,
        allow_network=True,
        transport=failing_transport,
    )

    assert result["status"] == "failed"
    assert result["runtime_status"] == "unavailable"
    assert result["smoke_status"] == "failed"
    assert result["error_code"] == "proxy_error"
    assert "proxy" in result["repair_suggestion"].lower()


def test_anysearch_api_key_is_environment_only_and_redacted_from_reports(tmp_path, monkeypatch):
    monkeypatch.setenv("ANYSEARCH_API_KEY", "secret-anysearch-key")
    captured = {}

    def transport(endpoint, headers, payload, timeout_seconds, proxy_url):
        captured["authorization"] = headers["Authorization"]
        return _success_transport(
            endpoint,
            {key: value for key, value in headers.items() if key != "Authorization"},
            payload,
            timeout_seconds,
            proxy_url,
        )

    result = run_anysearch_retrieval(
        tmp_path,
        query="fresh evidence",
        allow_network=True,
        transport=transport,
    )
    serialized = json.dumps(result)

    assert captured["authorization"] == "Bearer secret-anysearch-key"
    assert result["api_key_configured"] is True
    assert result["anonymous_mode"] is False
    assert result["secrets_persisted"] is False
    assert "secret-anysearch-key" not in serialized
    assert "secret-anysearch-key" not in (tmp_path / "anysearch_retrieval_result.json").read_text(encoding="utf-8")


def test_anysearch_config_rejects_inline_secret(tmp_path):
    config = tmp_path / "unsafe.json"
    config.write_text(json.dumps({"api_key": "do-not-store-this"}), encoding="utf-8")

    result = check_anysearch_provider(tmp_path / "out", config)
    serialized = json.dumps(result)

    assert result["status"] == "failed"
    assert result["runtime_status"] == "invalid_config"
    assert "inline_secret_not_allowed:api_key" in result["validation_errors"]
    assert "do-not-store-this" not in serialized


def test_anysearch_cli_commands_write_structured_outputs(tmp_path):
    runner = CliRunner()
    check_output = tmp_path / "check"
    smoke_output = tmp_path / "smoke"

    check = runner.invoke(app, ["check-anysearch-provider", "--output", str(check_output)])
    smoke = runner.invoke(app, ["smoke-anysearch-provider", "--output", str(smoke_output)])

    assert check.exit_code == 0, check.output
    assert smoke.exit_code == 0, smoke.output
    assert _json(check_output / "anysearch_provider_check.json")["runtime_status"] == "available_anonymous"
    assert _json(smoke_output / "anysearch_provider_smoke.json")["smoke_status"] == "skipped_network_not_allowed"
