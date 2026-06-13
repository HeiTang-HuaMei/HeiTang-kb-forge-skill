import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.external_sources import (
    clear_authenticated_browser_session,
    pause_authenticated_browser_session,
    read_visible_browser_source,
    resume_authenticated_browser_session,
    start_authenticated_browser_session,
    validate_authenticated_browser_session,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _jsonl(path: Path) -> list[dict]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def _start(output: Path, *, ttl_seconds: int = 1800) -> dict:
    return start_authenticated_browser_session(
        output,
        source_url="https://example.com/account/visible-note",
        title="Visible account note",
        user_consent=True,
        ttl_seconds=ttl_seconds,
        started_at="2026-06-13T00:00:00+00:00",
    )


def test_authorized_session_and_visible_content_generate_traceable_evidence(tmp_path):
    session = _start(tmp_path)
    result = read_visible_browser_source(
        tmp_path,
        visible_text="This paragraph is currently visible to the signed-in user.",
        captured_at="2026-06-13T00:01:00+00:00",
    )
    validation = validate_authenticated_browser_session(tmp_path)
    consent = _json(tmp_path / "user_consent_record.json")
    rows = _jsonl(tmp_path / "visible_content_extract.jsonl")
    trace = _json(tmp_path / "auth_source_trace.json")
    evidence = _json(tmp_path / "authenticated_source_evidence_map.json")

    assert session["status"] == "user_authorized_session"
    assert result["status"] == "visible_content_readable"
    assert validation["status"] == "passed"
    assert consent["consent_scope"] == "read_current_visible_page_content_only"
    assert consent["cookie_material_collected"] is False
    assert consent["plaintext_credentials_persisted"] is False
    assert rows[0]["source_type"] == "authenticated_browser_visible_content"
    assert rows[0]["integration_mode"] == "user_authorized_visible_content"
    assert rows[0]["visibility_scope"] == "current_user_visible_content_only"
    assert rows[0]["source_url"] == "https://example.com/account/visible-note"
    assert rows[0]["content_hash"]
    assert rows[0]["backlink"] == rows[0]["source_url"]
    assert trace["sources"][0]["evidence_id"] == rows[0]["evidence_id"]
    assert trace["browser_automation_integrated"] is False
    assert trace["cookie_accessed"] is False
    assert evidence["evidence"][0]["content_hash"] == rows[0]["content_hash"]
    assert evidence["knowledge_verification_engine_complete"] is False


def test_partial_visible_content_is_structured_and_not_overclaimed(tmp_path):
    _start(tmp_path)
    result = read_visible_browser_source(
        tmp_path,
        visible_text="Only the currently rendered excerpt is available.",
        partial=True,
        captured_at="2026-06-13T00:02:00+00:00",
    )
    row = _jsonl(tmp_path / "visible_content_extract.jsonl")[0]

    assert result["status"] == "visible_content_partial"
    assert row["status"] == "visible_content_partial"
    assert row["confidence"] == 0.85
    assert row["ocr_text"] == ""
    assert row["visual_summary"] == ""


def test_missing_consent_is_permission_denied_without_content_capture(tmp_path):
    session = start_authenticated_browser_session(
        tmp_path,
        source_url="https://example.com/private",
        title="Private page",
        user_consent=False,
        started_at="2026-06-13T00:00:00+00:00",
    )
    result = read_visible_browser_source(
        tmp_path,
        visible_text="Must not be stored.",
        captured_at="2026-06-13T00:01:00+00:00",
    )

    assert session["status"] == "permission_denied"
    assert result["status"] == "permission_denied"
    assert _jsonl(tmp_path / "visible_content_extract.jsonl") == []
    assert "Must not be stored" not in (
        tmp_path / "browser_session.json"
    ).read_text(encoding="utf-8")


def test_empty_visible_content_routes_to_manual_evidence(tmp_path):
    _start(tmp_path)
    result = read_visible_browser_source(
        tmp_path,
        visible_text=" ",
        captured_at="2026-06-13T00:01:00+00:00",
    )

    assert result["status"] == "manual_evidence_required"
    assert result["failure_reason"]
    assert "Manual Evidence Upload" in result["repair_suggestion"]
    assert _jsonl(tmp_path / "visible_content_extract.jsonl") == []


def test_expired_session_is_structured_and_isolated(tmp_path):
    _start(tmp_path, ttl_seconds=30)
    result = read_visible_browser_source(
        tmp_path,
        visible_text="Late visible content.",
        captured_at="2026-06-13T00:01:00+00:00",
    )

    assert result["status"] == "session_expired"
    assert result["repair_suggestion"] == "Start a new user-authorized session."
    assert _jsonl(tmp_path / "visible_content_extract.jsonl") == []


def test_pause_resume_revoke_and_clear_session_lifecycle(tmp_path):
    _start(tmp_path)
    paused = pause_authenticated_browser_session(
        tmp_path, paused_at="2026-06-13T00:01:00+00:00"
    )
    blocked = read_visible_browser_source(
        tmp_path,
        visible_text="Blocked while paused.",
        captured_at="2026-06-13T00:02:00+00:00",
    )
    resumed = resume_authenticated_browser_session(
        tmp_path, resumed_at="2026-06-13T00:03:00+00:00"
    )
    accepted = read_visible_browser_source(
        tmp_path,
        visible_text="Accepted after resume.",
        captured_at="2026-06-13T00:04:00+00:00",
    )
    cleared = clear_authenticated_browser_session(
        tmp_path, cleared_at="2026-06-13T00:05:00+00:00"
    )
    after_clear = read_visible_browser_source(
        tmp_path,
        visible_text="Must not be captured after revoke.",
        captured_at="2026-06-13T00:06:00+00:00",
    )

    assert paused["paused"] is True
    assert blocked["status"] == "permission_denied"
    assert resumed["status"] == "user_authorized_session"
    assert accepted["status"] == "visible_content_readable"
    assert cleared["status"] == "user_cancelled"
    assert cleared["revoked"] is True
    assert after_clear["status"] == "permission_denied"
    assert _json(tmp_path / "user_consent_record.json")["consent_status"] == "revoked"


def test_secret_or_cookie_material_is_blocked_and_not_persisted(tmp_path):
    _start(tmp_path)
    secret = "cookie = session-super-secret-value"
    result = read_visible_browser_source(
        tmp_path,
        visible_text=secret,
        captured_at="2026-06-13T00:01:00+00:00",
    )
    all_text = "\n".join(path.read_text(encoding="utf-8") for path in tmp_path.iterdir())

    assert result["status"] == "permission_denied"
    assert "suspected cookie" in result["failure_reason"]
    assert secret not in all_text
    assert _jsonl(tmp_path / "visible_content_extract.jsonl") == []


def test_runtime_boundaries_do_not_claim_campaign_4_5_or_browser_automation(tmp_path):
    _start(tmp_path)
    read_visible_browser_source(
        tmp_path,
        visible_text="Visible source boundary evidence.",
        captured_at="2026-06-13T00:01:00+00:00",
    )
    session = _json(tmp_path / "browser_session.json")
    validation = validate_authenticated_browser_session(tmp_path)
    manifest = _json(tmp_path / "run_manifest.json")

    assert session["runtime_boundary"]["browser_automation_integrated"] is False
    assert session["runtime_boundary"]["cookie_import_integrated"] is False
    assert session["runtime_boundary"]["campaign_4_active"] is False
    assert session["runtime_boundary"]["campaign_5_active"] is False
    assert session["runtime_boundary"]["local_core_bridge_complete"] is False
    assert session["runtime_boundary"]["bridge_execution_accepted"] is False
    assert validation["supplement_3_0_complete"] is False
    assert manifest["decision_qualifier"] == "authenticated_browser_visible_content_connector_alpha"
    assert manifest["next_business_item"].startswith(
        "Campaign 3 Supplement 3.0 P1 Video-to-Knowledge"
    )


def test_cli_start_read_validate_and_clear_are_runnable(tmp_path):
    runner = CliRunner()
    output = tmp_path / "session"

    start = runner.invoke(
        app,
        [
            "start-authenticated-browser-session",
            "--output",
            str(output),
            "--source-url",
            "https://example.com/visible",
            "--title",
            "Visible page",
            "--consent",
        ],
    )
    read = runner.invoke(
        app,
        [
            "read-visible-browser-source",
            "--session",
            str(output),
            "--text",
            "User-authorized visible page body.",
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-authenticated-browser-session",
            "--library",
            str(output),
            "--output",
            str(output),
        ],
    )
    clear = runner.invoke(
        app,
        ["clear-authenticated-browser-session", "--session", str(output)],
    )

    assert start.exit_code == 0, start.output
    assert read.exit_code == 0, read.output
    assert validate.exit_code == 0, validate.output
    assert clear.exit_code == 0, clear.output
    assert "user_cancelled" in clear.output


def test_invalid_url_credentials_and_shell_behavior_are_absent(tmp_path):
    session = start_authenticated_browser_session(
        tmp_path,
        source_url="https://user:password@example.com/private",
        title="Unsafe URL",
        user_consent=True,
    )
    source = (
        Path(__file__).resolve().parents[1]
        / "heitang_kb_forge"
        / "external_sources"
        / "authenticated_browser.py"
    ).read_text(encoding="utf-8").lower()

    assert session["status"] == "auth_required"
    assert "credentials are forbidden" in session["failure_reason"]
    for forbidden in ["subprocess.", "os.system", "powershell", "cmd.exe", "bash -c"]:
        assert forbidden not in source
