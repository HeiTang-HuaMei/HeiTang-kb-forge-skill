import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.verification.agent_output import verify_agent_output


def test_verify_agent_output_against_approved_source(tmp_path):
    session = _session(tmp_path)
    source = tmp_path / "approved_source.md"
    source.write_text(
        "HeiTang table routing must preserve source lineage and use builtin parser for XLSX. "
        "Source lineage is preserved when document_understanding_records link outputs to the original xlsx file.",
        encoding="utf-8",
    )
    output = tmp_path / "verification"

    report = verify_agent_output(session, output, [source])

    assert report["status"] == "pass"
    assert report["claim_count"] >= 1
    assert report["trusted_claim_count"] >= 1
    assert report["unverified_claim_count"] == 0
    assert report["contradicted_claim_count"] == 0
    assert report["agent_llm_used"] is False
    assert report["agent_network_used"] is False
    assert report["allow_external_network"] is False
    assert report["llm_used"] is False
    assert (output / "agent_output_verification_report.md").exists()


def test_verify_agent_output_cli_requires_explicit_verification_source(tmp_path):
    session = _session(tmp_path)
    output = tmp_path / "verification"

    result = CliRunner().invoke(
        app,
        ["verify-agent-output", "--session", str(session), "--output", str(output)],
    )

    assert result.exit_code != 0
    assert "requires at least one verification source" in result.output


def test_verify_agent_output_cli_writes_report(tmp_path):
    session = _session(tmp_path)
    source = tmp_path / "source.jsonl"
    source.write_text(
        json.dumps(
            {
                "source_id": "approved_source",
                "source_path": "approved_source.md",
                "text": "HeiTang table routing must preserve source lineage and use builtin parser for XLSX.",
            }
        )
        + "\n",
        encoding="utf-8",
    )
    output = tmp_path / "verification"

    result = CliRunner().invoke(
        app,
        [
            "verify-agent-output",
            "--session",
            str(session),
            "--verification-source",
            str(source),
            "--output",
            str(output),
        ],
    )

    assert result.exit_code == 0, result.output
    report = json.loads(
        (output / "agent_output_verification_report.json").read_text(
            encoding="utf-8"
        )
    )
    assert report["status"] == "pass"
    assert report["verification_source_count"] == 1
    assert "Agent output verification: pass" in result.output


def test_verify_agent_output_ignores_structural_labels(tmp_path):
    session = _session(tmp_path)
    payload = json.loads(session.read_text(encoding="utf-8"))
    payload["response"]["text"] = (
        "Sheet: RoutingEvidence. Capability: office_table_routing. "
        "Claim: HeiTang table routing must preserve source lineage."
    )
    session.write_text(json.dumps(payload), encoding="utf-8")
    source = tmp_path / "approved_source.md"
    source.write_text(
        "HeiTang table routing must preserve source lineage.",
        encoding="utf-8",
    )

    report = verify_agent_output(session, tmp_path / "verification", [source])

    claim_texts = [
        item["claim_text"]
        for item in report["source_cross_check"]["results"]
    ]
    assert claim_texts == ["Claim: HeiTang table routing must preserve source lineage."]
    assert report["status"] == "pass"


def _session(tmp_path):
    session = tmp_path / "local_agent_runtime_session.json"
    write_json(
        session,
        {
            "session_id": "session-1",
            "task": "Explain lineage",
            "status": "pass",
            "selected_child_agent": "office-agent",
            "response": {
                "status": "pass",
                "text": "HeiTang table routing must preserve source lineage and use builtin parser for XLSX.",
            },
            "evidence": [],
            "llm_used": False,
            "network_used": False,
        },
    )
    return session
