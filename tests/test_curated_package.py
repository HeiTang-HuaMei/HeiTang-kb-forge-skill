import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_curate_package_excludes_rejected_chunks(tmp_path):
    package = tmp_path / "package"
    output = tmp_path / "curated_package"
    decisions = tmp_path / "review_decisions.jsonl"
    package.mkdir()
    (package / "chunks.jsonl").write_text(
        '{"chunk_id":"c1","text":"Keep me","source_path":"a.md"}\n{"chunk_id":"c2","text":"Reject me","source_path":"b.md"}\n',
        encoding="utf-8",
    )
    decisions.write_text(
        '{"decision_id":"d1","item_id":"c1","decision":"accept","reason":"ok"}\n{"decision_id":"d2","item_id":"c2","decision":"reject","reason":"bad"}\n',
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["curate-package", "--package", str(package), "--review-decisions", str(decisions), "--output", str(output)])

    assert result.exit_code == 0, result.output
    chunks = [json.loads(line) for line in (output / "curated_chunks.jsonl").read_text(encoding="utf-8").splitlines()]
    assert [chunk["chunk_id"] for chunk in chunks] == ["c1"]
    assert (output / "curated_manifest.json").exists()
    assert (output / "curated_evidence_map.json").exists()
    assert (output / "governance_decisions.jsonl").exists()
    assert (output / "decision_audit_report.md").exists()

