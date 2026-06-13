import contextlib
import functools
import json
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli_runtime import app
from heitang_kb_forge.external_sources import (
    ingest_generic_web_url,
    validate_generic_web_url_ingestion,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


@contextlib.contextmanager
def _serve(directory: Path):
    handler = functools.partial(SimpleHTTPRequestHandler, directory=str(directory))
    server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        yield f"http://127.0.0.1:{server.server_port}"
    finally:
        server.shutdown()
        thread.join(timeout=5)
        server.server_close()


def test_generic_web_url_ingestion_fetches_public_html_and_builds_traceable_chunks(tmp_path):
    site = tmp_path / "site"
    site.mkdir()
    (site / "index.html").write_text(
        """
        <html lang="en">
          <head>
            <title>Source Trace Guide</title>
            <meta name="author" content="HeiTang Tester">
            <meta property="article:published_time" content="2026-06-13">
            <link rel="canonical" href="/docs/source-trace.html">
          </head>
          <body>
            <nav>navigation should not dominate</nav>
            <main>
              <h1>Source Trace Guide</h1>
              <p>Generic Web URL ingestion preserves source attribution and content hash.</p>
            </main>
          </body>
        </html>
        """,
        encoding="utf-8",
    )
    output = tmp_path / "out"

    with _serve(site) as base_url:
        result = ingest_generic_web_url(
            output,
            url=f"{base_url}/index.html",
            retrieved_at="2026-06-13T00:00:00+08:00",
        )

    validation = validate_generic_web_url_ingestion(output)
    manifest = _json(output / "link_ingestion_report.json")
    preflight = _json(output / "external_source_preflight.json")
    chunks = _jsonl(output / "external_chunks.jsonl")
    trace = _json(output / "external_source_trace.json")
    evidence = _json(output / "external_evidence_map.json")
    metadata = _json(output / "external_metadata.json")
    run = _json(output / "run_manifest.json")
    progress = _jsonl(output / "progress_events.jsonl")

    assert result["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []
    assert manifest["integration_decision"] == "real_integration"
    assert manifest["decision_qualifier"] == "generic_web_url_ingestion_only"
    assert manifest["runtime_boundary"]["generic_web_url_ingestion_implemented"] is True
    assert manifest["runtime_boundary"]["platform_preflight_implemented"] is False
    assert manifest["runtime_boundary"]["opencli_runtime_integrated"] is False
    assert manifest["runtime_boundary"]["manual_evidence_processing_implemented"] is False
    assert manifest["runtime_boundary"]["campaign_3_3_0_accepted"] is False
    assert manifest["runtime_boundary"]["campaign_4_allowed"] is False
    assert preflight["public_readable"] is True
    assert preflight["readability_state"] == "public_readable"
    assert chunks[0]["chunk_type"] == "text"
    assert "preserves source attribution" in chunks[0]["text"]
    assert chunks[0]["content_hash"] == manifest["content_hash"]
    assert chunks[0]["backlink"].endswith("/docs/source-trace.html")
    assert trace["source_trace_required"] is True
    assert trace["sources"][0]["content_hash"] == manifest["content_hash"]
    assert evidence["evidence_map_required"] is True
    assert evidence["evidence"][0]["chunk_id"] == chunks[0]["chunk_id"]
    assert metadata["title"] == "Source Trace Guide"
    assert metadata["author"] == "HeiTang Tester"
    assert run["campaign_state_after_run"]["generic_web_url_ingestion_implemented"] is True
    assert run["campaign_state_after_run"]["platform_preflight_implemented"] is False
    assert run["campaign_state_after_run"]["campaign_3_3_0_accepted"] is False
    assert run["campaign_state_after_run"]["next_business_item"] == (
        "Campaign 3 Supplement 3.0 P0 Platform Link Preflight"
    )
    assert run["not_goal_complete"] is True
    assert [event["stage"] for event in progress] == [
        "url_preflight",
        "url_preflight",
        "public_html_fetch",
        "public_html_fetch",
        "content_extraction",
        "content_extraction",
        "trace_and_evidence",
        "external_link_import",
    ]
    assert progress[-1]["status"] == "passed"
    assert all(
        {"stage", "status", "timestamp", "message", "artifact_path"} <= event.keys()
        for event in progress
    )


def test_generic_web_url_ingestion_structures_unreadable_sources_without_overclaim(tmp_path):
    result = ingest_generic_web_url(
        tmp_path / "out",
        url="file:///tmp/source.html",
        retrieved_at="2026-06-13T00:00:00+08:00",
    )
    manifest = _json(tmp_path / "out" / "link_ingestion_report.json")
    chunks = _jsonl(tmp_path / "out" / "external_chunks.jsonl")
    run = _json(tmp_path / "out" / "run_manifest.json")
    progress = _jsonl(tmp_path / "out" / "progress_events.jsonl")

    assert result["status"] == "failed"
    assert result["error_code"] == "unsupported_url_scheme"
    assert manifest["integration_decision"] == "needs_strengthening"
    assert manifest["public_readable"] is False
    assert chunks == []
    assert run["campaign_state_after_run"]["generic_web_url_ingestion_implemented"] is False
    assert run["campaign_state_after_run"]["next_business_item"] == (
        "Retry Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion"
    )
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert manifest["repair_suggestion"] == "Use a public http:// or https:// URL."
    assert progress[-1]["stage"] == "external_link_import"
    assert progress[-1]["status"] == "failed"


def test_generic_web_url_validation_rejects_later_runtime_drift(tmp_path):
    site = tmp_path / "site"
    site.mkdir()
    (site / "index.html").write_text("<html><body><p>Traceable public HTML.</p></body></html>", encoding="utf-8")
    output = tmp_path / "out"
    with _serve(site) as base_url:
        ingest_generic_web_url(output, url=f"{base_url}/index.html")
    manifest_path = output / "link_ingestion_report.json"
    manifest = _json(manifest_path)
    manifest["runtime_boundary"]["opencli_runtime_integrated"] = True
    manifest["runtime_boundary"]["campaign_3_3_0_accepted"] = True
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    validation = validate_generic_web_url_ingestion(output)

    assert validation["status"] == "failed"
    assert "opencli_runtime_integrated_must_be_false" in validation["boundary_errors"]
    assert "campaign_3_3_0_accepted_must_be_false" in validation["boundary_errors"]


def test_generic_web_url_cli_ingest_and_validate(tmp_path):
    site = tmp_path / "site"
    site.mkdir()
    (site / "index.html").write_text("<html><body><p>Generic URL CLI smoke.</p></body></html>", encoding="utf-8")
    runner = CliRunner()

    with _serve(site) as base_url:
        ingest_result = runner.invoke(
            app,
            [
                "ingest-link",
                f"{base_url}/index.html",
                "--output",
                str(tmp_path / "library"),
            ],
        )
    validate_result = runner.invoke(
        app,
        [
            "validate-generic-web-url-ingestion",
            "--library",
            str(tmp_path / "library"),
            "--output",
            str(tmp_path / "validation"),
        ],
    )

    assert ingest_result.exit_code == 0, ingest_result.output
    assert "status=passed" in ingest_result.output
    assert validate_result.exit_code == 0, validate_result.output
    assert "status=passed" in validate_result.output
    assert _json(tmp_path / "validation" / "generic_web_url_ingestion_validation_report.json")[
        "status"
    ] == "passed"


def test_generic_web_url_cli_failure_is_structured_and_nonzero(tmp_path):
    runner = CliRunner()

    result = runner.invoke(
        app,
        [
            "ingest-link",
            "file:///C:/secret.txt",
            "--output",
            str(tmp_path / "library"),
        ],
    )

    structured = json.loads(result.output.splitlines()[1])
    assert result.exit_code == 1
    assert structured["status"] == "failed"
    assert structured["readability_state"] == "needs_manual_evidence"
    assert structured["failure_reason"]
    assert structured["repair_suggestion"] == "Use a public http:// or https:// URL."
    assert structured["source_trace"].endswith("external_source_trace.json")
    assert structured["progress_events"].endswith("progress_events.jsonl")
