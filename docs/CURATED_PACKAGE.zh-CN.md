# 人工治理知识包

v2.3 可以基于 review decisions 生成 curated package。

输出：

- `curated_manifest.json`
- `curated_chunks.jsonl`
- `curated_evidence_map.json`
- `curated_source_inventory.json`
- `governance_decisions.jsonl`
- `decision_audit_report.md`
- `curation_report.md`

被 reject 或 ignore 的 chunk 不会进入 `curated_chunks.jsonl`。
