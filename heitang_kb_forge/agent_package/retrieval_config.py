def make_retrieval_config() -> str:
    return """retrieval:
  index_file: retrieval_index.jsonl
  context_pack_file: context_pack.json
  evidence_gate_file: evidence_gate_result.json
  citation_required: true
"""
