import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.external_sources import import_manual_evidence, validate_manual_evidence


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def test_manual_text_import_success_preserves_contract_trace_and_evidence_map(tmp_path):
    report = import_manual_evidence(
        tmp_path,
        copied_text="Copied claim: HeiTang supports traceable manual evidence.",
        title="Manual evidence note",
        source_url="https://example.com/original-note",
        user_note="User copied this from the visible article body.",
    )
    validation = validate_manual_evidence(tmp_path)
    manifest = _json(tmp_path / "manual_evidence_manifest.json")
    blocks = _jsonl(tmp_path / "manual_evidence_blocks.jsonl")
    source_trace = _json(tmp_path / "manual_source_trace.json")
    evidence_map = _json(tmp_path / "manual_evidence_map.json")

    assert report["status"] == "passed"
    assert report["decision_qualifier"] == "manual_evidence_upload_only"
    assert manifest["accepted_count"] == 1
    assert manifest["failed_count"] == 0
    record = manifest["records"][0]
    assert record["evidence_id"]
    assert record["source_type"] == "manual_evidence"
    assert record["manual_input_type"] == "copied_text"
    assert record["title"] == "Manual evidence note"
    assert record["user_provided_source_url"] == "https://example.com/original-note"
    assert record["user_note"] == "User copied this from the visible article body."
    assert record["content_hash"]
    assert record["created_at"]
    assert record["text"].startswith("Copied claim")
    assert record["metadata"]["secret_guard"] == "passed"
    assert record["trace"]["manual_evidence_not_public_fetch"] is True
    assert len(blocks) == 1
    assert blocks[0]["chunk_type"] == "text"
    assert blocks[0]["manual_input_type"] == "copied_text"
    assert blocks[0]["backlink"].startswith("manual_evidence_manifest.json#")
    assert source_trace["source_count"] == 1
    assert evidence_map["evidence_count"] == 1
    assert validation["status"] == "passed"


def test_manual_context_title_url_note_are_preserved(tmp_path):
    import_manual_evidence(
        tmp_path,
        copied_text="Manual source context preservation.",
        title="Visible platform excerpt",
        source_url="https://example.com/platform/item/123",
        user_note="Platform page was partial_readable, user pasted visible text.",
        source_type="manual_platform_supplement",
    )
    manifest = _json(tmp_path / "manual_evidence_manifest.json")
    trace = _json(tmp_path / "manual_source_trace.json")

    record = manifest["records"][0]
    assert record["title"] == "Visible platform excerpt"
    assert record["source_type"] == "manual_platform_supplement"
    assert record["user_provided_source_url"] == "https://example.com/platform/item/123"
    assert "partial_readable" in record["user_note"]
    assert trace["sources"][0]["title"] == "Visible platform excerpt"
    assert trace["sources"][0]["user_provided_source_url"] == "https://example.com/platform/item/123"


def test_manual_content_hash_is_stable_for_same_text(tmp_path):
    first = tmp_path / "first"
    second = tmp_path / "second"
    import_manual_evidence(
        first,
        copied_text="Stable content hash text.",
        title="Hash note",
        imported_at="2026-06-13T00:00:00Z",
    )
    import_manual_evidence(
        second,
        copied_text="Stable   content\nhash text.",
        title="Hash note",
        imported_at="2026-06-13T01:00:00Z",
    )

    assert _json(first / "manual_evidence_manifest.json")["records"][0]["content_hash"] == _json(
        second / "manual_evidence_manifest.json"
    )["records"][0]["content_hash"]


def test_manual_file_metadata_import_does_not_read_or_claim_processing(tmp_path):
    screenshot = tmp_path / "visible-screenshot.png"
    screenshot.write_bytes(b"fake image bytes")

    report = import_manual_evidence(
        tmp_path / "out",
        input_files=[screenshot],
        title="Screenshot from platform note",
        user_note="User supplied screenshot metadata; OCR is later.",
    )
    validation = validate_manual_evidence(tmp_path / "out")
    manifest = _json(tmp_path / "out" / "manual_evidence_manifest.json")
    blocks = _jsonl(tmp_path / "out" / "manual_evidence_blocks.jsonl")
    record = manifest["records"][0]

    assert report["status"] == "passed"
    assert record["manual_input_type"] == "screenshot_metadata"
    assert record["text"] == ""
    assert record["metadata"]["metadata_only"] is True
    assert record["metadata"]["file_content_read"] is False
    assert record["metadata"]["file_system_metadata_read"] is False
    assert record["metadata"]["size_bytes"] is None
    assert record["metadata"]["path_not_persisted"] is True
    assert "path_hash" in record["metadata"]
    assert blocks[0]["chunk_type"] == "layout_block"
    assert blocks[0]["ocr_text"] == ""
    assert blocks[0]["visual_summary"] == ""
    assert validation["visual_ocr_runtime_integrated"] is False
    assert validation["status"] == "passed"


def test_empty_input_is_structured_failure(tmp_path):
    report = import_manual_evidence(
        tmp_path,
        copied_text="   ",
        title="Empty note",
        user_note="User attempted an empty paste.",
    )
    validation = validate_manual_evidence(tmp_path)
    manifest = _json(tmp_path / "manual_evidence_manifest.json")

    assert report["status"] == "failed"
    assert manifest["records"][0]["status"] == "empty_input"
    assert manifest["records"][0]["failure_reason"] == "Manual evidence text is empty."
    assert validation["status"] == "passed"


def test_unsupported_manual_type_is_structured_failure(tmp_path):
    report = import_manual_evidence(
        tmp_path,
        copied_text="Manual text.",
        manual_input_type="platform_fetch_complete",
        title="Unsupported type",
    )
    manifest = _json(tmp_path / "manual_evidence_manifest.json")

    assert report["status"] == "failed"
    assert manifest["records"][0]["status"] == "unsupported_manual_type"
    assert manifest["records"][0]["manual_input_type"] == "platform_fetch_complete"


def test_secret_like_manual_material_is_blocked_and_not_persisted(tmp_path):
    report = import_manual_evidence(
        tmp_path,
        copied_text="api_key = sk-abcdefghijklmnopqrstuvwxyz123456",
        title="Secret paste",
        user_note="User accidentally pasted a key.",
    )
    manifest_text = (tmp_path / "manual_evidence_manifest.json").read_text(encoding="utf-8")
    manifest = json.loads(manifest_text)

    assert report["status"] == "failed"
    assert manifest["records"][0]["status"] == "blocked_for_sensitive_secret"
    assert manifest["records"][0]["text"] == ""
    assert "sk-abcdefghijklmnopqrstuvwxyz123456" not in manifest_text


def test_missing_source_context_is_structured_failure(tmp_path):
    import_manual_evidence(tmp_path, copied_text="Manual text without any context.")
    manifest = _json(tmp_path / "manual_evidence_manifest.json")

    assert manifest["records"][0]["status"] == "missing_source_context"
    assert manifest["records"][0]["failure_reason"].startswith("Manual evidence requires title")


def test_cli_import_and_validate_are_runnable(tmp_path):
    runner = CliRunner()
    output = tmp_path / "manual"
    validation_output = tmp_path / "validation"

    import_result = runner.invoke(
        app,
        [
            "import-manual-evidence",
            "--output",
            str(output),
            "--text",
            "Copied manual text.",
            "--title",
            "Manual bundle",
            "--source-url",
            "https://example.com/source",
            "--user-note",
            "User supplied visible text.",
        ],
    )
    validate_result = runner.invoke(
        app,
        [
            "validate-manual-evidence",
            "--library",
            str(output),
            "--output",
            str(validation_output),
        ],
    )

    assert import_result.exit_code == 0, import_result.output
    assert validate_result.exit_code == 0, validate_result.output
    assert _json(output / "manual_evidence_manifest.json")["status"] == "passed"
    assert _json(validation_output / "manual_evidence_validation_report.json")["status"] == "passed"


def test_manual_evidence_does_not_claim_ocr_browser_opencli_or_platform_fetch(tmp_path):
    import_manual_evidence(
        tmp_path,
        copied_text="Manual evidence only.",
        title="Boundary note",
        user_note="This was pasted manually.",
    )
    manifest = _json(tmp_path / "manual_evidence_manifest.json")
    blocks = _jsonl(tmp_path / "manual_evidence_blocks.jsonl")
    runtime = manifest["runtime_boundary"]
    trace = manifest["records"][0]["trace"]

    assert runtime["visual_ocr_runtime_integrated"] is False
    assert runtime["video_transcription_implemented"] is False
    assert runtime["authenticated_browser_runtime_integrated"] is False
    assert runtime["opencli_expansion_implemented"] is False
    assert runtime["platform_fetch_completed"] is False
    assert trace["manual_evidence_not_ocr_completion"] is True
    assert trace["manual_evidence_not_browser_read"] is True
    assert trace["manual_evidence_not_opencli_result"] is True
    assert trace["manual_evidence_not_public_fetch"] is True
    assert blocks[0]["ocr_text"] == ""
    assert blocks[0]["timestamp_start"] == ""
