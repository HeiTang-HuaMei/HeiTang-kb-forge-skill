from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.verification.claim_extractor import _sentences
from heitang_kb_forge.verification.source_cross_check import (
    cross_check_claims,
    load_verification_sources,
)


AGENT_OUTPUT_VERIFICATION_FILES = [
    "agent_output_verification_report.json",
    "agent_output_verification_trace.json",
    "agent_output_verification_report.md",
]


def verify_agent_output(
    session: Path,
    output: Path,
    verification_sources: list[Path],
) -> dict:
    if not verification_sources:
        raise ValueError("Agent output verification requires at least one verification source")
    session_payload = _read_session(session)
    output.mkdir(parents=True, exist_ok=True)
    claims = _claims_from_session(session_payload)
    sources = load_verification_sources(session.parent, verification_sources)
    cross_check = cross_check_claims(claims, sources)
    trusted = [
        item
        for item in cross_check["results"]
        if item["comparison"] in {"agreement", "partial_agreement"}
    ]
    contradicted = [
        item for item in cross_check["results"] if item["comparison"] == "contradiction"
    ]
    unverified = [
        item
        for item in cross_check["results"]
        if item["comparison"] == "missing_external_evidence"
    ]
    status = "pass" if claims and trusted and not contradicted and not unverified else "warning"
    report = {
        "agent_output_verification_version": "target-mode.v1",
        "status": status,
        "agent_id": session_payload.get("selected_child_agent"),
        "session_id": session_payload.get("session_id"),
        "task": session_payload.get("task"),
        "claim_count": len(claims),
        "trusted_claim_count": len(trusted),
        "unverified_claim_count": len(unverified),
        "contradicted_claim_count": len(contradicted),
        "verification_source_count": len(sources),
        "verification_source_paths": [
            str(path).replace("\\", "/") for path in verification_sources
        ],
        "source_cross_check": cross_check,
        "agent_llm_used": bool(session_payload.get("llm_used")),
        "agent_network_used": bool(session_payload.get("network_used")),
        "allow_external_network": False,
        "llm_used": False,
        "tests_require_real_llm_api_network": False,
    }
    trace = {
        "agent_output_verification_trace_version": "target-mode.v1",
        "session": str(session).replace("\\", "/"),
        "steps": [
            {"name": "load_agent_runtime_session", "status": "pass"},
            {"name": "extract_agent_output_claims", "status": "pass", "count": len(claims)},
            {"name": "load_approved_verification_sources", "status": "pass", "count": len(sources)},
            {"name": "source_cross_check", "status": cross_check["status"]},
            {"name": "score_agent_output_verification", "status": status},
        ],
        "external_source_required": True,
        "allow_external_network": False,
        "llm_used": False,
    }
    write_json(output / "agent_output_verification_report.json", report)
    write_json(output / "agent_output_verification_trace.json", trace)
    (output / "agent_output_verification_report.md").write_text(
        _render_report(report), encoding="utf-8"
    )
    return report | {"output_files": AGENT_OUTPUT_VERIFICATION_FILES}


def _read_session(path: Path) -> dict:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("Agent runtime session must contain a JSON object")
    return payload


def _claims_from_session(session: dict) -> list[dict]:
    response = session.get("response", {})
    text = response.get("text", "") if isinstance(response, dict) else ""
    claims = []
    for sentence in _sentences(str(text)):
        if not _is_agent_output_claim(sentence):
            continue
        if len(sentence) < 12:
            continue
        claims.append(
            {
                "claim_id": f"agent_claim_{len(claims) + 1}",
                "claim_text": sentence,
                "source_path": "agent_runtime_session",
                "chunk_id": session.get("session_id", ""),
                "citation": str(session.get("session_id", "")),
                "evidence_text": sentence,
                "metadata": {
                    "agent_id": session.get("selected_child_agent"),
                    "task": session.get("task"),
                },
            }
        )
    return claims


def _is_agent_output_claim(sentence: str) -> bool:
    text = sentence.strip()
    lowered = text.casefold()
    if lowered.startswith(("sheet:", "capability:", "row ")):
        return False
    return any(
        marker in lowered
        for marker in [
            "claim:",
            "evidence:",
            "method:",
            " must ",
            " should ",
            " is ",
            " are ",
            "use ",
            "when ",
        ]
    )


def _render_report(report: dict) -> str:
    return f"""# Agent Output Verification Report

- Status: `{report['status']}`
- Agent: `{report['agent_id']}`
- Claims: `{report['claim_count']}`
- Trusted claims: `{report['trusted_claim_count']}`
- Unverified claims: `{report['unverified_claim_count']}`
- Contradicted claims: `{report['contradicted_claim_count']}`
- Verification sources: `{report['verification_source_count']}`
- Agent LLM used: `{str(report['agent_llm_used']).lower()}`
- Agent network used: `{str(report['agent_network_used']).lower()}`
- Verifier external network: `false`
- Verifier LLM used: `false`
"""
