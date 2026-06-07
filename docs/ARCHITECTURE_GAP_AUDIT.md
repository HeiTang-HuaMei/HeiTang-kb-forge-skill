# v3.6 Architecture Gap Audit

This audit records capability gaps, risk, and future-version mapping only. It does not implement v3.7 features, modify UI, or copy external project code or prompts.

- Audit version: 3.6.0-alpha.1
- Core commit: cdfbb0e
- UI commit: 24dfa2b
- Risk summary: P0=16, P1=50, P2=20

## External Retrieval for Knowledge Accuracy Verification

External Retrieval for Knowledge Accuracy Verification is an S-level core gap. Its primary value is not unrestricted information acquisition. It verifies whether the existing KB is accurate, fresh, consistent, and sufficiently evidenced. v3.7 should define verification-oriented retrieval planning and distinguish retrieval for answering from retrieval for validation. v3.8 should implement the first real claim_check, source_cross_check, freshness_check, contradiction_detection, knowledge_accuracy_score, verification_retrieval_trace, and claim_verification_report. v4.3 should extend this into long-term local governance.

## Local Document Parsing & PDF Token Reduction

Raw PDF should not be sent wholesale to an LLM by default. The product should prefer local parsing -> structured Markdown/JSON -> chunking -> retrieval. This protects privacy and reduces token cost. LiteDoc is valuable as a 100% client-side PDF-to-Markdown and no-server-upload benchmark. HeiTang already has local PDF/OCR/parser backend foundations, but still lacks a LiteDoc-like PDF-to-Markdown intermediate artifact, parser backend benchmark report, and token cost reduction report.

## Optional LLM Assistive Layer

LLM must be treated as an optional assistive layer, not a required dependency. Every gap item records deterministic/local implementation path, optional LLM-assisted enhancement path, offline fallback, and tests_require_real_llm_api_network=false. Core features must remain usable without configured LLM providers, and tests must not depend on real LLM/API/network calls.

## Categories

- RAG Query Understanding: 6 items, P0=3, P1=3, P2=0
- RAG Retrieval Quality: 9 items, P0=2, P1=7, P2=0
- Agent / Skill System: 8 items, P0=0, P1=5, P2=3
- External Retrieval for Knowledge Accuracy Verification: 12 items, P0=9, P1=3, P2=0
- Local Document Parsing & PDF Token Reduction: 12 items, P0=0, P1=7, P2=5
- Agent Memory / Runtime: 12 items, P0=0, P1=7, P2=5
- Storage / Workspace: 12 items, P0=0, P1=7, P2=5
- Workbench / UI Contracts: 7 items, P0=1, P1=6, P2=0
- Product Readiness: 8 items, P0=1, P1=5, P2=2

## P0 Items

- RAG Query Understanding / Query Rewrite -> v3.7
- RAG Query Understanding / Multi-query Generation -> v3.7
- RAG Query Understanding / Retrieval Planning -> v3.7
- RAG Retrieval Quality / Multi-query Recall -> v3.8
- RAG Retrieval Quality / Rerank -> v3.8
- External Retrieval for Knowledge Accuracy Verification / claim extraction from a KB package -> v3.8
- External Retrieval for Knowledge Accuracy Verification / claim-level evidence mapping -> v3.8
- External Retrieval for Knowledge Accuracy Verification / external source retrieval for verification -> v3.8
- External Retrieval for Knowledge Accuracy Verification / source cross-checking -> v3.8
- External Retrieval for Knowledge Accuracy Verification / contradiction detection -> v3.8
- External Retrieval for Knowledge Accuracy Verification / knowledge accuracy scoring -> v3.8
- External Retrieval for Knowledge Accuracy Verification / verification retrieval trace -> v3.8
- External Retrieval for Knowledge Accuracy Verification / claim verification report -> v3.8
- External Retrieval for Knowledge Accuracy Verification / user-facing explanation of claim trust status -> v3.8
- Workbench / UI Contracts / Core/UI contract drift risk -> v4.0
- Product Readiness / Golden Demo readiness -> v3.11

See `architecture_gap_audit_report.json` for the full machine-readable audit.
