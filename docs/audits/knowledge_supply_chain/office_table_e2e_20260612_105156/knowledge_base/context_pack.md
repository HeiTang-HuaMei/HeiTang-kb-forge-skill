# Context Pack

- Query: Summarize this knowledge package.
- Selected records: 5

## chunk_3

- Asset type: chunk
- Citation: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill/docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105156/document_understanding/normalized_sources/0004_verification_source.md#chunk=fd34f321b9ce4e0c1de45b79

# Verification Source

HeiTang table routing must preserve source lineage and use builtin parser for XLSX. Knowledge verification should compare package claims against local source evidence without LLM or network calls. Methodology extraction must keep evidence windows and source trace for reusable workflow rules. CSV routing uses builtin parser for table documents. Use local evidence and prefer narrow scope. When evidence is missing, stop and request review. First inspect the source. Then apply the decision rule. Avoid unsupported claims.

## glossary_22

- Asset type: glossary
- Citation: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill/docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105156/document_understanding/normalized_sources/0001_001_table_claims.md#chunk=43c6e2b5e71b27e7f84a2137

Knowledge
Term candidate detected in D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill/docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105156/document_understanding/normalized_sources/0001_001_table_claims.md

## chunk_2

- Asset type: chunk
- Citation: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill/docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105156/document_understanding/normalized_sources/0003_003_methodology.md#chunk=735d241590c90a9e47f00247

# Evidence-led workflow

Use local evidence and prefer narrow scope. When evidence is missing, stop and request review. First inspect the source. Then apply the decision rule. Avoid unsupported claims. This method applies to local knowledge workflows.

## chunk_1

- Asset type: chunk
- Citation: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill/docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105156/document_understanding/normalized_sources/0002_002_table_claims.md#chunk=a6466697146a6f8040406803

Row 2. Capability: office_table_routing. Claim: CSV routing uses builtin parser for table documents. Method: Run batch import then DU. Evidence: CSV normalized output remains source traced.

## chunk_0

- Asset type: chunk
- Citation: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill/docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105156/document_understanding/normalized_sources/0001_001_table_claims.md#chunk=43c6e2b5e71b27e7f84a2137

Sheet: RoutingEvidence. Row 2. Capability: office_table_routing. Claim: HeiTang table routing must preserve source lineage and use builtin parser for XLSX.. Method: First inspect preflight recommendations, then run Document Understanding with builtin table parser.. Evidence: Source lineage is preserved when document_understanding_records links each normalized output to the original xlsx file..

Sheet: RoutingEvidence. Row 3. Capability: knowledge_verification. Claim: Knowledge verification should compare package claims against local source evidence without LLM or network calls.. Method: Use local verification_source text that repeats source-backed claims.. Evidence: The verification trace should cite package chunks and the local verification source..

Sheet: RoutingEvidence. Row 4. Capability: methodology_extraction. Claim: Methodology extraction must keep evidence windows and source trace for reusable workflow rules.. Method: Extract principles, decision rules, workflows, anti-pattern
