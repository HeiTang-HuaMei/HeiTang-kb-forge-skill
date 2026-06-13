# Parser Backend Output

- Backend: builtin
- Status: success
- Source count: 1
- Trust status: raw_parse_output

## Source 1: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill/docs/audits/knowledge_supply_chain/office_table_e2e_20260612_105706/input/001_table_claims.xlsx

- Status: success
- Confidence: 0.95

Sheet: RoutingEvidence. Row 2. Capability: office_table_routing. Claim: HeiTang table routing must preserve source lineage and use builtin parser for XLSX.. Method: First inspect preflight recommendations, then run Document Understanding with builtin table parser.. Evidence: Source lineage is preserved when document_understanding_records links each normalized output to the original xlsx file..

Sheet: RoutingEvidence. Row 3. Capability: knowledge_verification. Claim: Knowledge verification should compare package claims against local source evidence without LLM or network calls.. Method: Use local verification_source text that repeats source-backed claims.. Evidence: The verification trace should cite package chunks and the local verification source..

Sheet: RoutingEvidence. Row 4. Capability: methodology_extraction. Claim: Methodology extraction must keep evidence windows and source trace for reusable workflow rules.. Method: Extract principles, decision rules, workflows, anti-patterns, and applicability boundaries from chunks.. Evidence: The source_trace report must set source_trace_preserved true..
