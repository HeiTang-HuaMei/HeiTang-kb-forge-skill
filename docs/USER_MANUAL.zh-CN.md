# 用户手册

本文说明 `3.12.0-alpha.1` 的本地 Core 工作流。v4.0 尚未发布。

## 1. 本地安装

```powershell
python -m pip install -e ".[dev]"
python -m heitang_kb_forge.cli doctor --output .\tmp_doctor
```

可选本地 parser extras：

```powershell
python -m pip install -e ".[ocr,pdf-table,parser-docling,parser-marker,web]"
```

## 2. 准备输入文件

把源文件放到本地目录，例如 `.\examples\quickstart\input`。

支持的本地输入路径包括 Markdown、TXT、DOCX、文本型 PDF、安装 extras 后的图片/OCR 路由、CSV、TSV、XLSX、HTML、EPUB 和 ZIP。

## 3. 构建知识包

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_package
```

预期文件包括 `manifest.json`、`chunks.jsonl`、`cards.jsonl`、`qa_pairs.jsonl`、`glossary.jsonl`、`quality_report.json` 和 `ingest_report.md`。

## 4. 验证 package contract

```powershell
python -m heitang_kb_forge.cli check-contract --package .\tmp_package --output .\tmp_contract
```

## 5. 本地查询 KB

```powershell
python -m heitang_kb_forge.cli kb-index --package .\tmp_package --output .\tmp_kb_index
python -m heitang_kb_forge.cli kb-query --package .\tmp_package --query "Summarize this package" --output .\tmp_kb_query
python -m heitang_kb_forge.cli kb-answer --package .\tmp_package --query "What is the main topic?" --output .\tmp_kb_answer
```

## 6. 运行 Query Rewrite 和 Retrieval Planning

```powershell
python -m heitang_kb_forge.cli rewrite-query --query "summarize it" --output .\tmp_query_rewrite
python -m heitang_kb_forge.cli plan-retrieval --query "Summarize this package" --purpose answering --package .\tmp_package --output .\tmp_plan_answering
python -m heitang_kb_forge.cli plan-retrieval --query "Verify whether this package is current" --purpose validation --package .\tmp_package --output .\tmp_plan_validation
```

`answering` 和 `validation` 是严格分开的目的。v3.7 不执行外部检索或 claim verification。

## 7. 运行 Retrieval Quality 和 Knowledge Verification

```powershell
python -m heitang_kb_forge.cli eval-retrieval --package .\tmp_package --output .\tmp_retrieval_eval
python -m heitang_kb_forge.cli rerank-results --package .\tmp_package --query "main topic" --output .\tmp_rerank
python -m heitang_kb_forge.cli select-evidence --package .\tmp_package --query "main topic" --output .\tmp_evidence
python -m heitang_kb_forge.cli verify-claims --package .\tmp_package --output .\tmp_claims
python -m heitang_kb_forge.cli check-knowledge-accuracy --package .\tmp_package --output .\tmp_accuracy
```

这些命令使用本地 package 数据，不需要真实 LLM/API/network 调用。

## 8. 生成文档

```powershell
python -m heitang_kb_forge.cli generate-documents --package .\tmp_package --output .\tmp_documents
python -m heitang_kb_forge.cli generate-md --package .\tmp_package --output .\tmp_md
python -m heitang_kb_forge.cli generate-docx --package .\tmp_package --output .\tmp_docx
python -m heitang_kb_forge.cli generate-pdf --package .\tmp_package --output .\tmp_pdf
python -m heitang_kb_forge.cli generate-pptx --package .\tmp_package --output .\tmp_pptx
```

## 9. 生成 Skill 和 Agent Packages

```powershell
python -m heitang_kb_forge.cli generate-skill --package .\tmp_package --output .\tmp_skill
python -m heitang_kb_forge.cli generate-agent --mode standalone --output .\tmp_agent_standalone
python -m heitang_kb_forge.cli generate-agent --mode kb_bound --package .\tmp_package --skill .\tmp_skill --output .\tmp_agent_bound
```

`kb_bound` mode 必须提供 `--package` 和 `--skill`。

## 10. 运行本地 Agent Runtime Smoke

```powershell
python -m heitang_kb_forge.cli run-local-agent --package .\tmp_package --agent .\tmp_agent_bound --task "Summarize the package" --output .\tmp_agent_runtime
```

这是确定性的本地 runtime smoke，不是 SaaS service，也不是完整 autonomous Agent Runtime。

## 11. 检查 Workspace、Storage 与 Memory Lifecycle

```powershell
python -m heitang_kb_forge.cli init-workspace --workspace .\tmp_workspace --output .\tmp_workspace_init
python -m heitang_kb_forge.cli scan-workspace --workspace .\tmp_workspace --output .\tmp_workspace_scan
python -m heitang_kb_forge.cli report-storage --workspace .\tmp_workspace --output .\tmp_storage
python -m heitang_kb_forge.cli plan-cleanup --workspace .\tmp_workspace --output .\tmp_cleanup
python -m heitang_kb_forge.cli plan-memory-lifecycle --output .\tmp_memory
```

cleanup plan 默认不执行破坏性删除。

## 12. 运行 Golden Demo Acceptance

```powershell
python -m heitang_kb_forge.cli run-golden-demo-acceptance --package .\tmp_package --output .\tmp_golden --no-require-v37 --no-require-v38 --no-require-v39 --no-require-v310
```

准备 release evidence 时，应使用默认 `--require-*` 检查，并提供所有 prior artifacts。

## 13. 运行 Product Hardening

```powershell
python -m heitang_kb_forge.cli product-hardening --workspace . --package .\tmp_package --output .\tmp_hardening --no-require-v37 --no-require-v38 --no-require-v39 --no-require-v310 --no-require-v311
```

准备 release evidence 时，应使用默认 `--require-*` 检查。

## 14. 运行最终 Pre-v4 审计

```powershell
python -m heitang_kb_forge.cli final-pre-v4-audit --core-repo . --output .\tmp_final_audit
```

该审计可能返回 `blocked`。当 P0/P1 证据缺失时，这是正确结果。

## 15. 阅读报告

在 `.\tmp_final_audit` 输出目录中，优先阅读：

- `final_v4_rc_gate_report.json`
- `final_product_capability_proof_report.md`
- `final_functionality_truth_matrix.md`
- `final_industrial_red_team_report.md`
- `final_security_privacy_report.md`
- `final_user_workflow_acceptance_report.md`

## 故障排查

见 [故障排查](TROUBLESHOOTING.zh-CN.md)。常见处理包括安装可选 parser extras、检查 package path、阅读 stable error text、重新运行 doctor。
