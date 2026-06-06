# 演示脚本

## 目标

用 3 分钟在本地离线演示 HeiTang KB Forge。

## 命令

```powershell
python -m heitang_kb_forge.cli demo-e2e --output ./tmp_demo_e2e
```

## 要打开的文件

```text
tmp_demo_e2e/demo_e2e_result.json
tmp_demo_e2e/portfolio_demo_report.md
tmp_demo_e2e/demo_evidence_pack/
tmp_demo_e2e/runtime_limitations.md
```

## 演示顺序

### 1. 介绍项目

HeiTang KB Forge 是 Agent 知识供应链工具，负责把资料加工成可治理的知识资产，再交给后续 Agent / RAG 使用。

### 2. 运行 demo-e2e

这条命令会本地离线跑完整链路：

资料输入 → 知识包生成 → 质量门禁 → Provider 安全检查 → mock LLM 辅助质检 → 平台导出 → Release Readiness → 作品集报告。

### 3. 打开 demo_e2e_result.json

展示结构化结果。说明它适合给 CI、发布门禁或 UI 读取。

### 4. 打开 portfolio_demo_report.md

展示面向人的报告。说明它适合 PM、评审或面试官阅读。

### 5. 打开 demo_evidence_pack/

展示证据包。说明项目不是只声明成功，而是保留过程产物。

### 6. 打开 runtime_limitations.md

说明边界：不真实运行平台、不默认 live provider、不启动 MCP server、不真实发布。

## 清理

```powershell
Remove-Item -Recurse -Force ./tmp_demo_e2e -ErrorAction SilentlyContinue
```
