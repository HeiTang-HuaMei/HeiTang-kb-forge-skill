# v2.8 Parser Backend Reliability

v2.8.0-alpha.1 新增 opt-in parser backend 与知识可靠性层。

默认 `build`、`batch`、`run` 和 `pipeline` 行为不变，只有显式启用 parser backend mode 时才生成新增输出。

## 命令

```powershell
python -m heitang_kb_forge.cli parser-backend-list
python -m heitang_kb_forge.cli parse-with-backend --input .\input --output .\parser_output --backend builtin
python -m heitang_kb_forge.cli parse-compare --input .\input --output .\compare --backends builtin,docling,marker
python -m heitang_kb_forge.cli parse-quality-gate --input .\parser_output --output .\quality
python -m heitang_kb_forge.cli parse-reimport-corrected-text --corrected-text .\corrected --output .\reviewed
python -m heitang_kb_forge.cli trusted-kb-gate --package .\package --output .\gate
python -m heitang_kb_forge.cli build --input .\input --output .\package --parser-backend builtin
```

## Backend

- `builtin`：把 KB Forge 内置 parser 标准化为 parser backend contract。
- `docling`：可选边界 adapter。只有本地显式安装并接入 Docling integration 后才可作为外部 parser 使用。
- `marker`：可选边界 adapter。只有本地显式安装并接入 Marker integration 后才可作为外部 parser 使用。

Docling 和 Marker 不是默认依赖。v2.8 不调用网络 parser 服务。

## 输出

启用 parser backend mode 后，知识包可包含：

- `parser_backend_result.json`
- `parser_backend_output.md`
- `parser_backend_output.json`
- `parse_quality_report.json`
- `parse_quality_report.md`
- `ocr_risk_report.json`
- `high_risk_pages.jsonl`
- `high_risk_parse_pages.jsonl`
- `high_risk_chunks.jsonl`
- `manual_review_queue.jsonl`
- `kb_trust_status.json`
- `trusted_kb_gate.json`
- `knowledge_reliability_report.json`

Corrected text re-import 还会写出 `before_after_quality_diff.json`。

## Trust Flow

Parser-backed package 默认从 `draft_knowledge_package` 开始。

Trusted KB gate 默认阻断 draft 或 unknown trust status package 导出为 Skill、Agent 或平台包，除非显式使用 `--allow-untrusted`。没有 v2.8 parser trust metadata 的历史知识包仍以 `legacy_untracked` 兼容。

非空 corrected text re-import 可把状态提升为 `reviewed_knowledge_base`。

## 边界

- 不默认启用 parser backend mode。
- 不强制安装 Docling 或 Marker。
- 不调用网络 parser 服务。
- 不进入 v2.9 平台、移动端、安装端或 iOS 范围。
- 不做真实外部发布。
