import json

from heitang_kb_forge.progress.reporter import make_progress_reporter


def test_progress_reporter_writes_jsonl_events(tmp_path):
    log_path = tmp_path / "progress_events.jsonl"
    reporter = make_progress_reporter(progress_jsonl=True, progress_log=log_path)

    assert reporter is not None
    reporter.emit("scan_sources", "success", "Found sources", total_files=1, metadata={"profile": "fast"})

    events = [json.loads(line) for line in log_path.read_text(encoding="utf-8").splitlines()]
    assert len(events) == 1
    assert events[0]["stage"] == "scan_sources"
    assert events[0]["status"] == "success"
    assert events[0]["metadata"]["profile"] == "fast"
