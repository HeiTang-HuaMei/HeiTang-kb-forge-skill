# 命令参考

当前 Core package 版本：`4.0.0`
当前 stable release：`v4.0.0`

当前阶段：v4.0.0 stable release，已完成 rc.1 acceptance 与 hardening evidence。

所有命令都是本地 Core 命令。Core tests 不需要真实 LLM/API/network，默认也不会调用。

## Diagnostics and Gates

```powershell
python -m heitang_kb_forge.cli doctor --output .\tmp_doctor
python -m heitang_kb_forge.cli quality-gate --workspace .\tmp_package --output .\tmp_quality
python -m heitang_kb_forge.cli release-blockers --workspace . --output .\tmp_blockers
python -m heitang_kb_forge.cli regression-check --workspace . --output .\tmp_regression
python -m heitang_kb_forge.cli product-hardening --workspace . --package .\tmp_package --output .\tmp_hardening
python -m heitang_kb_forge.cli final-pre-v4-audit --core-repo . --output .\tmp_final_audit
```

## Package Build and Validation

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_package
python -m heitang_kb_forge.cli batch --input .\examples\quickstart\input --output .\tmp_batch --domain general --mode qa
python -m heitang_kb_forge.cli pipeline --config .\examples\configs\kb_forge.v25.yaml
python -m heitang_kb_forge.cli check-contract --package .\tmp_package --output .\tmp_contract
```

## Parser and PDF Token Reduction

```powershell
python -m heitang_kb_forge.cli parser-backend-list
python -m heitang_kb_forge.cli parse-with-backend --backend builtin --input .\examples\quickstart\input --output .\tmp_parse
python -m heitang_kb_forge.cli parse-quality-gate --package .\tmp_package --output .\tmp_parse_quality
python -m heitang_kb_forge.cli preprocess-pdf-markdown --source .\examples\quickstart\input --output .\tmp_pdf_md
python -m heitang_kb_forge.cli benchmark-parser-backends --source .\examples\quickstart\input --output .\tmp_parser_benchmark
python -m heitang_kb_forge.cli report-pdf-token-reduction --source .\examples\quickstart\input --output .\tmp_token
```

## Knowledge Runtime and Query Planning

```powershell
python -m heitang_kb_forge.cli kb-index --package .\tmp_package --output .\tmp_kb_index
python -m heitang_kb_forge.cli kb-query --package .\tmp_package --query "Summarize this package" --output .\tmp_kb_query
python -m heitang_kb_forge.cli kb-answer --package .\tmp_package --query "What is the main topic?" --output .\tmp_kb_answer
python -m heitang_kb_forge.cli rewrite-query --query "summarize it" --output .\tmp_query_rewrite
python -m heitang_kb_forge.cli plan-retrieval --query "Summarize this package" --purpose answering --package .\tmp_package --output .\tmp_plan
python -m heitang_kb_forge.cli eval-query-rewrite --cases .\examples\query_rewrite_cases.json --output .\tmp_query_eval
```

## Retrieval Quality and Accuracy

```powershell
python -m heitang_kb_forge.cli eval-retrieval --package .\tmp_package --output .\tmp_retrieval
python -m heitang_kb_forge.cli rerank-results --package .\tmp_package --query "main topic" --output .\tmp_rerank
python -m heitang_kb_forge.cli select-evidence --package .\tmp_package --query "main topic" --output .\tmp_evidence
python -m heitang_kb_forge.cli diagnose-retrieval-failure --package .\tmp_package --query "missing topic" --output .\tmp_diagnostics
python -m heitang_kb_forge.cli verify-claims --package .\tmp_package --output .\tmp_claims
python -m heitang_kb_forge.cli check-knowledge-accuracy --package .\tmp_package --output .\tmp_accuracy
```

## Document Generation

```powershell
python -m heitang_kb_forge.cli generate-documents --package .\tmp_package --output .\tmp_documents
python -m heitang_kb_forge.cli generate-md --package .\tmp_package --output .\tmp_md
python -m heitang_kb_forge.cli generate-docx --package .\tmp_package --output .\tmp_docx
python -m heitang_kb_forge.cli generate-pdf --package .\tmp_package --output .\tmp_pdf
python -m heitang_kb_forge.cli generate-pptx --package .\tmp_package --output .\tmp_pptx
```

## Skill, Agent, and Workbench Contracts

```powershell
python -m heitang_kb_forge.cli generate-skill --package .\tmp_package --output .\tmp_skill
python -m heitang_kb_forge.cli validate-skill --skill .\tmp_skill --output .\tmp_skill_validation
python -m heitang_kb_forge.cli generate-agent --mode standalone --output .\tmp_agent_standalone
python -m heitang_kb_forge.cli generate-agent --mode kb_bound --package .\tmp_package --skill .\tmp_skill --output .\tmp_agent_bound
python -m heitang_kb_forge.cli generate-bound-agent --package .\tmp_package --output .\tmp_bound_agent
python -m heitang_kb_forge.cli orchestrate-multi-kb --packages .\tmp_package --output .\tmp_orchestration
python -m heitang_kb_forge.cli run-local-agent --package .\tmp_package --agent .\tmp_agent_bound --task "Summarize the package" --output .\tmp_runtime
python -m heitang_kb_forge.cli workbench-contracts --core-output .\tmp_package --output .\tmp_workbench_contracts
```

## Workspace and Memory Lifecycle

```powershell
python -m heitang_kb_forge.cli init-workspace --workspace .\tmp_workspace --output .\tmp_workspace_init
python -m heitang_kb_forge.cli scan-workspace --workspace .\tmp_workspace --output .\tmp_workspace_scan
python -m heitang_kb_forge.cli report-storage --workspace .\tmp_workspace --output .\tmp_storage
python -m heitang_kb_forge.cli plan-cleanup --workspace .\tmp_workspace --output .\tmp_cleanup
python -m heitang_kb_forge.cli plan-memory-lifecycle --output .\tmp_memory
python -m heitang_kb_forge.cli estimate-token-budget --output .\tmp_token_budget
```

## Golden Demo

```powershell
python -m heitang_kb_forge.cli run-golden-demo-acceptance --package .\tmp_package --output .\tmp_golden
```
