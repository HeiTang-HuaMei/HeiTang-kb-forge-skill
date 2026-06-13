# Methodology Map

- Source package: `pkg_knowledge_base`
- Modules: 4
- Confidence: 0.838
- Risk flags: missing_principle_evidence

## Sheet: RoutingEvidence. Row 2. Capability: office_table_routing. Claim: HeiTang table routing must preserve source linea

Evidence: window_001

### Concepts
- Sheet: RoutingEvidence. Row 2. Capability: office_table_routing. Claim: HeiTang table routing must preserve source linea (`window_001`)

### Principles
- Claim: HeiTang table routing must preserve source lineage and use builtin parser for XLSX.. (`window_001`)
- Claim: Knowledge verification should compare package claims against local source evidence without LLM or network calls.. (`window_001`)
- Method: Use local verification_source text that repeats source-backed claims.. (`window_001`)
- Evidence: The verification trace should cite package chunks and the local verification source.. (`window_001`)
- Claim: Methodology extraction must keep evidence windows and source trace for reusable workflow rules.. (`window_001`)
- Method: Extract principles, decision rules, workflows, anti-patterns, and applicability boundaries from chunks.. (`window_001`)
- Evidence: The source_trace report must set source_trace_preserved true.. (`window_001`)

### Decision Rules
- Evidence: Source lineage is preserved when document_understanding_records links each normalized output to the original xlsx file.. (`window_001`)

### Workflows
- Method: First inspect preflight recommendations, then run Document Understanding with builtin table parser.. (`window_001`)
- Claim: Methodology extraction must keep evidence windows and source trace for reusable workflow rules.. (`window_001`)
- Method: Extract principles, decision rules, workflows, anti-patterns, and applicability boundaries from chunks.. (`window_001`)

## Row 2. Capability: office_table_routing. Claim: CSV routing uses builtin parser for table documents. Method: Run batch i

Evidence: window_002

### Concepts
- Row 2. Capability: office_table_routing. Claim: CSV routing uses builtin parser for table documents. Method: Run batch i (`window_002`)

### Workflows
- Method: Run batch import then DU. (`window_002`)

## Evidence-led workflow

Evidence: window_003

### Concepts
- Evidence-led workflow (`window_003`)

### Principles
- Use local evidence and prefer narrow scope. (`window_003`)
- This method applies to local knowledge workflows. (`window_003`)

### Decision Rules
- When evidence is missing, stop and request review. (`window_003`)

### Workflows
- # Evidence-led workflow (`window_003`)
- First inspect the source. (`window_003`)
- Then apply the decision rule. (`window_003`)
- This method applies to local knowledge workflows. (`window_003`)

### Anti-patterns
- Avoid unsupported claims. (`window_003`)

### Constraints
- Use local evidence and prefer narrow scope. (`window_003`)

### Applicability Boundary
- This method applies to local knowledge workflows. (`window_003`)

### Failure Modes
- When evidence is missing, stop and request review. (`window_003`)
- Avoid unsupported claims. (`window_003`)

## Verification Source

Evidence: window_004

### Concepts
- Verification Source (`window_004`)

### Principles
- HeiTang table routing must preserve source lineage and use builtin parser for XLSX. (`window_004`)
- Knowledge verification should compare package claims against local source evidence without LLM or network calls. (`window_004`)
- Methodology extraction must keep evidence windows and source trace for reusable workflow rules. (`window_004`)
- Use local evidence and prefer narrow scope. (`window_004`)

### Decision Rules
- When evidence is missing, stop and request review. (`window_004`)

### Workflows
- Methodology extraction must keep evidence windows and source trace for reusable workflow rules. (`window_004`)
- First inspect the source. (`window_004`)
- Then apply the decision rule. (`window_004`)

### Anti-patterns
- Avoid unsupported claims. (`window_004`)

### Constraints
- Use local evidence and prefer narrow scope. (`window_004`)

### Failure Modes
- When evidence is missing, stop and request review. (`window_004`)
- Avoid unsupported claims. (`window_004`)
