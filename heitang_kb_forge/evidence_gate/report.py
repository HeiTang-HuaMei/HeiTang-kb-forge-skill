from heitang_kb_forge.schemas.evidence_gate_schema import EvidenceGateResult


def render_evidence_gate_report(result: EvidenceGateResult) -> str:
    warnings = "\n".join(f"- {warning}" for warning in result.warnings) or "- None"
    evidence = "\n".join(f"- {item}" for item in result.evidence_ids) or "- None"
    return f"""# Evidence Gate Report

- Decision: {result.decision}
- Query: {result.query}
- Reason: {result.reason}

## Evidence IDs

{evidence}

## Warnings

{warnings}
"""
