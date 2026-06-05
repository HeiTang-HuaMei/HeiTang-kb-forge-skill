# 故障排查

## Contract Check Failed

检查：

- `contract_check_result.json`
- `contract_check_report.md`

常见原因：

- 缺少 `manifest.json`
- 缺少 `chunks.jsonl`
- 缺少 `evidence_map.json`
- 启用了 multimodal 但缺少 `multimodal_assets.jsonl`

## 多模态资产需要复核

`review_required: true` 表示该 asset 是低置信或 fallback 结果，需要人工复核。它不会被当作可靠原文事实。

## 大文件或 OCR 太慢

使用：

```powershell
heitang-kb-forge build --input .\input --output .\output --progress-jsonl --profile fast --ocr-mode first-pages --max-ocr-pages 10 --ocr-cache --resume
```

查看：

- `progress_events.jsonl`
- `large_file_performance_report.md`
- `ocr_resume_report.md`
# v1.7 排障

如果 Evidence Gate 拒绝某个问题，请检查 `context_pack.md`、`retrieval_trace.json` 和 `evidence_gate_report.md`。

如果启用了 mock LLM 校验，请检查 `llm_call_log.jsonl`。API key 会从调用日志中脱敏。

# v1.8 排障

如果 Skill Validation 不是 release ready，请检查 `skill_validation_result.json` 和 Skill Package 中的规则文件。

如果 LLM 辅助生成发生 fallback，请检查 `llm_skill_generation_report.md`、`llm_agent_generation_report.md` 和 `llm_call_log.jsonl`。

# v1.9 排障

如果 workspace health 是 warning，请检查 `reports/workspace_health_report.md` 和缺失的登记路径。Provider registry 问题请检查 `registries/provider_registry.json`。

# v2.0 稳定版排障

如果 `stable-check` 出现 warning，先查看 `stable_check_report.md`。母版 Skill 学习、平台分发等后续扩展在 v2.0 应保持 `not_enabled`，这不是失败。

如果 `provider-health` 在禁用网络时提示非 mock provider warning，本地验证请使用 mock provider。

# v2.1 质量排障

如果质量评分为 warning，请检查 `knowledge_quality_report.md`、`chunk_quality_scores.jsonl` 和 `source_inventory_enhanced.json`。

LLM quality assist 应保持可选，并使用 mock/fallback 安全路径。它不能被当作人工复核。
# v2.3 批量治理排查

- 缺少 `batch_job_manifest.json`：运行 `batch-run` 或带 v2.3 输出的 batch config。
- 缺少 `batch_item_status.jsonl`：检查是否存在带编号的输入文件。
- curated package 包含 rejected 内容：检查 `governance_decisions.jsonl` 和 decision 值。
- update impact 过宽：检查 workspace 中的 Skill 和 Agent 注册情况。
