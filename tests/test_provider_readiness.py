import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_provider_readiness_is_offline_and_no_api_keys(tmp_path):
    result = CliRunner().invoke(app, ["provider-readiness", "--workspace", str(tmp_path / "workspace"), "--output", str(tmp_path / "out")])

    assert result.exit_code == 0, result.output
    readiness = json.loads((tmp_path / "out" / "provider_readiness_result.json").read_text(encoding="utf-8"))
    assert readiness["network_required"] is False
    assert readiness["api_keys_stored"] is False


def test_provider_readiness_accepts_utf8_bom_registry(tmp_path):
    workspace = tmp_path / "workspace"
    registry = workspace / "registries"
    registry.mkdir(parents=True)
    (registry / "provider_registry.json").write_text(
        json.dumps(
            {
                "providers": [
                    {
                        "provider_id": "mock_default",
                        "provider_type": "mock",
                        "status": "disabled",
                    }
                ]
            }
        ),
        encoding="utf-8-sig",
    )

    result = CliRunner().invoke(
        app,
        [
            "provider-readiness",
            "--workspace",
            str(workspace),
            "--output",
            str(tmp_path / "out"),
        ],
    )

    assert result.exit_code == 0, result.output
    readiness = json.loads((tmp_path / "out" / "provider_readiness_result.json").read_text(encoding="utf-8"))
    assert readiness["provider_count"] == 1
    assert readiness["api_keys_stored"] is False

