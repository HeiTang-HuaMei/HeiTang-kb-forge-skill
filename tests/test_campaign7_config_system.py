import json

from typer.testing import CliRunner

from heitang_kb_forge.campaign7_config_system import (
    CAMPAIGN7_CONFIG_SECTIONS,
    CAMPAIGN7_STATUS,
    run_campaign7_acceptance,
)
from heitang_kb_forge.campaign7_config_system.runtime import (
    resolve_config_profile,
    validate_config_profile,
)
from heitang_kb_forge.cli import app


def _read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def test_campaign7_acceptance_covers_required_configuration_lifecycle(tmp_path):
    output = tmp_path / "campaign7"

    report = run_campaign7_acceptance(output)

    assert report["status"] == "pass"
    assert report["final_status"] == CAMPAIGN7_STATUS
    assert report["config_sections"] == CAMPAIGN7_CONFIG_SECTIONS
    assert report["precedence"] == ["default", "workspace", "user", "env"]
    assert report["provider_runtime_reimplemented"] is False
    assert report["agent_runtime_reimplemented"] is False
    assert report["arbitrary_shell_allowed"] is False
    assert report["computer_use_runtime_enabled"] is False
    assert report["secret_plaintext_written"] is False
    assert report["ui_settings_binding_status"] == "enabled_real"

    status_matrix = _read_json(output / "campaign7_status_matrix.json")
    degraded = _read_json(output / "campaign7_degraded_mode_matrix.json")
    security = _read_json(output / "campaign7_security_boundary_report.json")
    diagnostics = _read_json(output / "diagnostics" / "campaign7_config_diagnostics_report.json")
    migration = _read_json(output / "migration" / "campaign7_config_migration_report.json")
    rollback = _read_json(output / "rollback" / "campaign7_config_rollback_report.json")
    import_export = _read_json(output / "import_export" / "campaign7_config_import_export_report.json")

    assert status_matrix["status"] == "pass"
    assert degraded["status"] == "pass"
    assert security["status"] == "pass"
    assert diagnostics["status"] == "pass"
    assert migration["status"] == "pass"
    assert migration["backward_compatible"] is True
    assert rollback["status"] == "pass"
    assert import_export["status"] == "pass"
    assert import_export["secret_plaintext_exported"] is False
    assert {item["capability"] for item in status_matrix["items"]} >= {
        "unified_config_schema",
        "provider_profile_persistence",
        "agent_profile_persistence",
        "tool_adapter_config_persistence",
        "skill_rag_workspace_binding_config",
        "override_precedence",
        "env_only_secret_injection",
        "masked_ui_secret_display",
        "config_validation",
        "config_migration",
        "config_rollback",
        "config_diagnostics",
        "config_import_export",
        "degraded_status_mapping",
        "ui_settings_binding",
    }


def test_campaign7_precedence_and_secret_redaction_are_real(tmp_path):
    default = tmp_path / "default.json"
    workspace = tmp_path / "workspace.json"
    user = tmp_path / "user.json"
    default.write_text(
        json.dumps(
            {
                "schema_version": "campaign7.config.v1",
                "provider_profiles": {
                    "profiles": [
                        {
                            "profile_id": "default",
                            "provider_type": "official_openai",
                            "base_url_env": "HEITANG_LLM_BASE_URL",
                            "model": "default-model",
                            "api_key_env": "HEITANG_LLM_API_KEY",
                        }
                    ]
                },
                "agent_profiles": {"profiles": [{"agent_profile_id": "agent_default"}]},
                "tool_adapters": {"adapters": [{"adapter_id": "provider_runtime"}]},
                "skills": {"bindings": [{"skill_id": "default_skill"}]},
                "rag": {"knowledge_base_id": "kb_default", "status": "available"},
                "workspace": {"workspace_id": "default_workspace", "status": "available"},
                "ui_settings": {"ui_state": "enabled_real", "masked_secret_display": "sk-************"},
                "runtime_reuse": {
                    "provider_runtime": "accepted_env_only_provider_runtime",
                    "agent_runtime": "campaign6_agent_runtime",
                },
                "permission_policy": {
                    "arbitrary_shell_allowed": False,
                    "computer_use_runtime_enabled": False,
                },
                "status_mapping": {
                    "available": "enabled_real",
                    "degraded": "enabled_real_with_warning",
                    "unavailable": "disabled_boundary",
                    "disabled": "disabled_boundary",
                },
            }
        ),
        encoding="utf-8",
    )
    workspace.write_text(json.dumps({"workspace": {"workspace_id": "workspace_layer"}}), encoding="utf-8")
    user.write_text(json.dumps({"ui_settings": {"theme": "dark"}}), encoding="utf-8")

    resolved = resolve_config_profile(
        default,
        workspace_profile=workspace,
        user_profile=user,
        env={
            "HEITANG_LLM_PROVIDER": "official_openai",
            "HEITANG_LLM_MODEL": "env-model",
            "HEITANG_LLM_BASE_URL": "https://example.invalid/v1",
            "HEITANG_LLM_API_KEY": "campaign7-redaction-sentinel",
        },
    )
    validation = validate_config_profile(resolved)

    assert validation["status"] == "pass"
    assert resolved["provider_profiles"]["profiles"][0]["model"] == "env-model"
    assert resolved["workspace"]["workspace_id"] == "workspace_layer"
    assert resolved["ui_settings"]["theme"] == "dark"
    assert resolved["field_provenance"]["provider_profiles.profiles"] == "env"
    assert "campaign7-redaction-sentinel" not in json.dumps(resolved)
    assert resolved["provider_profiles"]["profiles"][0]["api_key_env"] == "HEITANG_LLM_API_KEY"


def test_campaign7_cli_command_writes_acceptance_outputs(tmp_path):
    output = tmp_path / "campaign7_cli"

    result = CliRunner().invoke(app, ["campaign7-configuration-system-acceptance", "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert _read_json(output / "campaign7_acceptance_report.json")["status"] == "pass"
    assert (output / "campaign7_status_matrix.json").exists()
