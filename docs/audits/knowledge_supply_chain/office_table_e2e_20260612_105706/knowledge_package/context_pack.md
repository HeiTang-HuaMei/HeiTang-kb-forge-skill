# Context Pack

- Query: Summarize this knowledge package.
- Selected records: 5

## glossary_19

- Asset type: glossary
- Citation: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill/docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105706/document_understanding/normalized_sources/0001_001_table_claims.md#chunk=23cd46a53974710d5a2a00b0

Knowledge
Term candidate detected in D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill/docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105706/document_understanding/normalized_sources/0001_001_table_claims.md

## chunk_2

- Asset type: chunk
- Citation: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill/docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105706/document_understanding/normalized_sources/0003_003_methodology.md#chunk=6c9f55d32434bd1e56fd2d1a

# Evidence-led workflow

Use local evidence and prefer narrow scope. When evidence is missing, stop and request review. First inspect the source. Then apply the decision rule. Avoid unsupported claims. This method applies to local knowledge workflows.

## chunk_1

- Asset type: chunk
- Citation: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill/docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105706/document_understanding/normalized_sources/0002_002_table_claims.md#chunk=71c2aba2d55c92eef5f99660

Row 2. Capability: office_table_routing. Claim: CSV routing uses builtin parser for table documents. Method: Run batch import then DU. Evidence: CSV normalized output remains source traced.

## chunk_0

- Asset type: chunk
- Citation: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill/docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105706/document_understanding/normalized_sources/0001_001_table_claims.md#chunk=23cd46a53974710d5a2a00b0

Sheet: RoutingEvidence. Row 2. Capability: office_table_routing. Claim: HeiTang table routing must preserve source lineage and use builtin parser for XLSX.. Method: First inspect preflight recommendations, then run Document Understanding with builtin table parser.. Evidence: Source lineage is preserved when document_understanding_records links each normalized output to the original xlsx file..

Sheet: RoutingEvidence. Row 3. Capability: knowledge_verification. Claim: Knowledge verification should compare package claims against local source evidence without LLM or network calls.. Method: Use local verification_source text that repeats source-backed claims.. Evidence: The verification trace should cite package chunks and the local verification source..

Sheet: RoutingEvidence. Row 4. Capability: methodology_extraction. Claim: Methodology extraction must keep evidence windows and source trace for reusable workflow rules.. Method: Extract principles, decision rules, workflows, anti-pattern

## qa_pair_8

- Asset type: qa_pair
- Citation: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill/docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105706/document_understanding/normalized_sources/0003_003_methodology.md#chunk=6c9f55d32434bd1e56fd2d1a

Q: How does Evidence-led workflow work?
A: # Evidence-led workflow Use local evidence and prefer narrow scope.
