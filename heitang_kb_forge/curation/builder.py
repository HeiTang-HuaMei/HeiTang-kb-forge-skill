from pathlib import Path
from datetime import datetime, timezone
import json

from heitang_kb_forge.curation.decisions import default_decision, load_decisions
from heitang_kb_forge.curation.merge import accepted_decision
from heitang_kb_forge.curation.report import render_curation_report, render_decision_audit
from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


def _load_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def build_curated_package(package: Path, review_decisions: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    source_chunks = _load_jsonl(package / "chunks.jsonl")
    decisions_by_id = load_decisions(review_decisions)
    curated_chunks = []
    decisions = []
    evidence_map = {}
    for chunk in source_chunks:
        chunk_id = chunk.get("chunk_id") or chunk.get("id") or f"chunk-{len(curated_chunks) + 1}"
        decision = decisions_by_id.get(chunk_id) or default_decision(chunk_id, chunk_id)
        decisions.append(decision)
        if not accepted_decision(decision):
            continue
        curated_chunks.append(chunk)
        evidence_map[chunk_id] = {
            "source_path": chunk.get("source_path"),
            "source_file": chunk.get("source_file"),
            "decision_id": decision.get("decision_id"),
        }
    manifest = {
        "curation_version": "2.3",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_package": str(package).replace("\\", "/"),
        "curated_chunk_count": len(curated_chunks),
        "decision_count": len(decisions),
    }
    write_json(output / "curated_manifest.json", manifest)
    write_jsonl(output / "curated_chunks.jsonl", curated_chunks)
    write_json(output / "curated_evidence_map.json", evidence_map)
    write_json(output / "curated_source_inventory.json", {"sources": sorted({chunk.get("source_path") or chunk.get("source_file") for chunk in curated_chunks if chunk.get("source_path") or chunk.get("source_file")})})
    write_jsonl(output / "governance_decisions.jsonl", decisions)
    (output / "decision_audit_report.md").write_text(render_decision_audit(decisions), encoding="utf-8")
    (output / "curation_report.md").write_text(render_curation_report(manifest), encoding="utf-8")
    return manifest
