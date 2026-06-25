from heitang_kb_forge.credential_proxy import validate_credential_proxy_design
from tests.v17_helpers import read_json


def test_credential_proxy_accepts_env_reference_without_value(tmp_path):
    report = validate_credential_proxy_design(
        [
            {
                "provider_id": "openai",
                "credential_env": "OPENAI_API_KEY",
                "endpoint_env": "OPENAI_BASE_URL",
                "model_env": "OPENAI_MODEL",
            }
        ],
        tmp_path,
    )

    persisted = read_json(tmp_path / "credential_proxy_design_report.json")
    assert report.status == "passed"
    assert report.failed_checks == []
    assert persisted["entries"][0]["credential_source"] == "env_ref"
    assert persisted["entries"][0]["inline_credential_present"] is False
    assert persisted["boundary"]["stores_plaintext_credential"] == "forbidden"
    inline_value = "credential" + "-value"
    assert inline_value not in (tmp_path / "credential_proxy_design_report.json").read_text(encoding="utf-8")


def test_credential_proxy_rejects_inline_value(tmp_path):
    report = validate_credential_proxy_design(
        [{"provider_id": "bad", "credential_env": "BAD_PROVIDER_KEY", "inline_credential": "credential" + "-value"}],
        tmp_path,
    )

    persisted_text = (tmp_path / "credential_proxy_design_report.json").read_text(encoding="utf-8")
    assert report.status == "failed"
    assert "bad:inline_credential_forbidden" in report.failed_checks
    assert "credential" + "-value" not in persisted_text


def test_credential_proxy_rejects_missing_env_reference():
    report = validate_credential_proxy_design([{"provider_id": "missing"}])

    assert report.status == "failed"
    assert report.failed_checks == ["missing:missing_credential_env"]
