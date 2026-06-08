import io
import json
import urllib.error
from pathlib import Path

from heitang_kb_forge.llm.provider_profiles import ProviderProfile, load_provider_profiles, run_provider_profile_acceptance
from heitang_kb_forge.pre_v4_p0 import run_live_llm_acceptance
from tests.p0_helpers import make_p0_package, read_json
from heitang_kb_forge.pre_v4_p0 import run_pre_v4_p0_completion


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")
PROFILE_TYPES = {"official_openai", "official_vendor", "openai_compatible_proxy", "local_model", "custom_http"}


class FakeResponse:
    def __init__(self, body: bytes = b'{"ok":true}', status: int = 200) -> None:
        self.body = body
        self.status = status

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False

    def read(self, *_args):
        return self.body


def test_provider_profile_loader_supports_all_user_configured_types_and_redacts_keys(tmp_path):
    payload = {
        "provider_profiles": [
            {"profile_id": "openai", "provider_type": "official_openai", "base_url": "https://api.openai.example/v1", "model": "m", "api_key": "redaction-token-openai"},
            {"profile_id": "vendor", "provider_type": "official_vendor", "base_url": "https://vendor.example/v1", "model": "m", "api_key": "redaction-token-vendor"},
            {"profile_id": "proxy", "provider_type": "openai_compatible_proxy", "base_url": "https://proxy.example/v1", "model": "m", "api_key": "redaction-token-proxy"},
            {"profile_id": "local", "provider_type": "local_model", "base_url": "http://127.0.0.1:11434/v1", "model": "m", "network_required": False},
            {"profile_id": "custom", "provider_type": "custom_http", "base_url": "https://custom.example/v1", "model": "m", "api_key": "redaction-token-custom"},
        ]
    }
    profile_file = tmp_path / "profiles.json"
    profile_file.write_text(json.dumps(payload), encoding="utf-8")

    profiles, metadata = load_provider_profiles(profile_file=profile_file)
    report = run_provider_profile_acceptance(profiles, acceptance_enabled=False)
    serialized = json.dumps(report)

    assert {item.provider_type for item in profiles} == {
        "official_openai",
        "official_vendor",
        "openai_compatible_proxy",
        "local_model",
        "custom_http",
    }
    assert metadata["official_openai_only"] is False
    assert metadata["bundled_or_recommended_unofficial_proxy"] is False
    assert metadata["openai_compatible_proxy_equivalent_to_official_openai"] is False
    assert "redaction-token" not in serialized
    proxy = next(item for item in report["provider_profiles"] if item["provider_type"] == "openai_compatible_proxy")
    assert proxy["third_party_proxy_not_equivalent_to_official_api"] is True
    assert "not bundled, recommended, or equivalent" in proxy["privacy_notice"]


def test_provider_capability_detection_hits_required_endpoints_without_leaking_key():
    urls = []

    def fake_urlopen(request, timeout):
        urls.append(request.full_url)
        return FakeResponse()

    report = run_provider_profile_acceptance(
        [
            ProviderProfile(
                profile_id="custom",
                provider_type="custom_http",
                base_url="https://provider.example/v1",
                model="model",
                api_key="redaction-token",
                wire_api={"chat_completions": True, "responses": True, "embeddings": True},
            )
        ],
        acceptance_enabled=True,
        timeout_sec=1,
        urlopen=fake_urlopen,
    )
    serialized = json.dumps(report)

    assert report["status"] == "pass"
    assert urls == [
        "https://provider.example/v1/models",
        "https://provider.example/v1/chat/completions",
        "https://provider.example/v1/responses",
        "https://provider.example/v1/embeddings",
    ]
    assert "redaction-token" not in serialized
    assert report["provider_profiles"][0]["capability_detection"]["responses"]["status"] == "pass"


def test_openai_compatible_proxy_502_blocks_live_gate_but_not_offline_core():
    def fake_urlopen(request, timeout):
        raise urllib.error.HTTPError(
            request.full_url,
            502,
            "Bad Gateway",
            hdrs=None,
            fp=io.BytesIO(b"proxy bad gateway"),
        )

    report = run_provider_profile_acceptance(
        [
            ProviderProfile(
                profile_id="user_proxy",
                provider_type="openai_compatible_proxy",
                base_url="https://proxy.example/v1",
                model="model",
                api_key="redaction-token",
                wire_api={"chat_completions": True, "responses": True},
            )
        ],
        acceptance_enabled=True,
        timeout_sec=1,
        urlopen=fake_urlopen,
    )

    assert report["status"] == "blocked_with_reason"
    assert report["core_usable_without_llm"] is True
    assert report["provider_profiles"][0]["last_error_class"] == "provider_http_error_502"
    assert any("Switch provider profile" in item for item in report["suggestions"])


def test_live_llm_acceptance_passes_only_when_one_profile_has_valid_live_response(tmp_path, monkeypatch):
    monkeypatch.setenv("HEITANG_LLM_ACCEPTANCE_ENABLED", "true")
    profile_file = tmp_path / "profiles.json"
    profile_file.write_text(
        json.dumps(
            {
                "provider_profiles": [
                    {
                        "profile_id": "working",
                        "provider_type": "official_vendor",
                        "base_url": "https://provider.example/v1",
                        "model": "model",
                        "api_key": "redaction-token",
                        "wire_api": {"chat_completions": True, "responses": True},
                    }
                ]
            }
        ),
        encoding="utf-8",
    )

    def fake_urlopen(request, timeout):
        return FakeResponse()

    monkeypatch.setattr("heitang_kb_forge.llm.provider_profiles.urllib.request.urlopen", fake_urlopen)
    report = run_live_llm_acceptance(tmp_path / "out", profile_file)
    serialized = (tmp_path / "out" / "live_llm_acceptance_report.json").read_text(encoding="utf-8")

    assert report["status"] == "pass"
    assert report["passing_provider_profile_count"] == 1
    assert report["live_gate_pass_requires_one_valid_profile"] is True
    assert "redaction-token" not in serialized


def test_pre_v4_final_gate_uses_provider_profile_success_for_live_llm(tmp_path, monkeypatch):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"
    profile_file = tmp_path / "profiles.json"
    profile_file.write_text(
        json.dumps(
            {
                "provider_profiles": [
                    {
                        "profile_id": "working",
                        "provider_type": "custom_http",
                        "base_url": "https://provider.example/v1",
                        "model": "model",
                        "api_key": "redaction-token",
                        "wire_api": {"chat_completions": True, "responses": True},
                    }
                ]
            }
        ),
        encoding="utf-8",
    )
    monkeypatch.setenv("HEITANG_LLM_ACCEPTANCE_ENABLED", "true")
    monkeypatch.setattr("heitang_kb_forge.llm.provider_profiles.urllib.request.urlopen", lambda request, timeout: FakeResponse())
    (tmp_path / ".gitignore").write_text("_local_acceptance_inputs/\n_local_acceptance_outputs/\n_local_acceptance_config/\n", encoding="utf-8")

    summary = run_pre_v4_p0_completion(tmp_path, package, output, provider_profile_file=profile_file)
    gate = read_json(output / "final_v4_rc_gate_report.json")

    assert "live_llm" not in summary["p0_blockers"]
    assert gate["llm_provider_readiness"]["status"] == "pass"
    assert gate["llm_provider_readiness"]["passing_provider_profile_count"] == 1
    assert gate["llm_provider_readiness"]["official_openai_only"] is False


def test_static_pre_v4_llm_proof_uses_user_configured_provider_profile_design():
    live = json.loads((PROOF / "live_llm_acceptance_report.json").read_text(encoding="utf-8"))
    gate = json.loads((PROOF / "final_v4_rc_gate_report.json").read_text(encoding="utf-8"))
    readiness = json.loads((PROOF / "llm_provider_and_per_agent_api_readiness_report.json").read_text(encoding="utf-8"))
    optional = json.loads((PROOF / "optional_llm_provider_acceptance_report.json").read_text(encoding="utf-8"))

    assert set(live["allowed_provider_types"]) == PROFILE_TYPES
    assert set(readiness["supported_provider_profile_types"]) == PROFILE_TYPES
    assert set(optional["supported_provider_profile_types"]) == PROFILE_TYPES
    for report in [live, readiness, optional, gate["llm_provider_readiness"]]:
        assert report["official_openai_only"] is False
        assert report["openai_compatible_proxy_equivalent_to_official_openai"] is False
        assert report["bundled_or_recommended_unofficial_proxy"] is False
        assert report["live_gate_pass_requires_one_valid_profile"] is True
    assert live["status"] == "blocked_with_reason"
    assert live["passing_provider_profile_count"] == 0
    assert gate["ready_for_v4_rc"] is False
