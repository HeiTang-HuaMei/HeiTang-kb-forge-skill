# Knowledge Base Build Module Defect Registry

## Scope

- Module: Module 5 Knowledge Base Build
- Current repair round: S0/S1 stabilization first
- Boundary: no Final Owner Review Gate, no package candidate build, no P2 reopen, no `capability_chain_status.json` change

## KBBUILD-S1-001

```text
status = fixed
severity = S1
module = knowledge_base
page = 知识库
user_path = import sources -> parse documents -> build selected KB -> inspect chunks/source trace
expected_behavior = KB chunks are OKF semantic chunks from ParsedDocument blocks, filtered to selected SourceDoc, and traceable through source_trace.jsonl
actual_behavior = KB chunks were copied from core output with legacy source_path-only shape; selected-source builds could retain unrelated source chunks; source trace was only summary JSON
root_cause_category = invariant_violation
root_cause_evidence = web/workbench/flutter_app/output/module_repair/module5_kb_build/module5_okf_semantic_chunking_repro.log
minimal_fix_scope = add knowledge_base service for OKF semantic chunk materialization and let Rc6RuntimeController call it from legacy KB build/materialize entry points
white_box_result = pass
black_box_result = controller/runtime product-flow test pass
regression_result = pass for Phase1B import -> parse -> build -> merge/delete/restart chain; legacy multi-KB catalog test still needs separate active-workbook fixture alignment
commit_id = pending
```

## Evidence

```text
repro_log = web/workbench/flutter_app/output/module_repair/module5_kb_build/module5_okf_semantic_chunking_repro.log
fix_test_log = web/workbench/flutter_app/output/module_repair/module5_kb_build/module5_okf_semantic_chunking_parsed_doc_test.log
analyze_log = web/workbench/flutter_app/output/module_repair/module5_kb_build/module5_okf_semantic_chunking_flutter_analyze.log
```

## Remaining Items

```text
Module 5 not closed yet.
S0/S1 count for the whole project not zero.
Architecture Debt Repayment Phase not started.
```
