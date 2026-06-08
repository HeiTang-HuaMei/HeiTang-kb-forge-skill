import json

from heitang_kb_forge.multi_source_ingestion import run_multi_source_ingestion
from tests.multi_source_helpers import make_multi_source_run, read_json


def test_opencli_bridge_privacy_boundary_stores_no_cookies_sessions_or_tokens(tmp_path):
    output = make_multi_source_run(tmp_path)

    report = read_json(output / "opencli_bridge_privacy_boundary_report.json")

    assert report["status"] == "pass"
    assert report["no_cookies_stored"] is True
    assert report["no_session_stored"] is True
    assert report["no_tokens_stored"] is True
    assert report["no_hidden_upload"] is True
    assert report["no_automated_login"] is True
    assert report["no_infinite_scroll_scraping"] is True
    assert report["no_antibot_or_rate_limit_bypass"] is True
    assert report["not_market_as_crawler_or_scraper"] is True


def test_opencli_bridge_privacy_boundary_blocks_nested_cookie_session_token_keys(tmp_path):
    source = tmp_path / "unsafe_manifest.json"
    source.write_text(
        json.dumps(
            {
                "items": [
                    {
                        "source_id": "unsafe-1",
                        "source_type": "manual_source",
                        "text": "This local manifest tries to include platform credentials.",
                        "headers": {"authorization": "Bearer secret"},
                        "browser": {"cookies": "do-not-store"},
                        "auth": {"access_token": "do-not-store"},
                    }
                ]
            }
        ),
        encoding="utf-8",
    )
    output = tmp_path / "out"

    report = run_multi_source_ingestion([source], output, ingestion_mode="opencli_bridge")
    privacy = read_json(output / "opencli_bridge_privacy_boundary_report.json")
    opencli = read_json(output / "opencli_bridge_import_report.json")

    assert report["status"] == "blocked"
    assert privacy["status"] == "blocked"
    assert privacy["no_cookies_stored"] is False
    assert privacy["no_tokens_stored"] is False
    assert opencli["status"] == "blocked"
    assert "headers.authorization" in opencli["forbidden_cookie_session_token_keys"]
    assert "browser.cookies" in opencli["forbidden_cookie_session_token_keys"]
    assert "auth.access_token" in opencli["forbidden_cookie_session_token_keys"]
