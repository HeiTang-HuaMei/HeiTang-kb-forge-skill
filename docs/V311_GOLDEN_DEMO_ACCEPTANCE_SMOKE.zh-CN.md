# v3.11 黄金演示与真实验收烟测

v3.11 增加一个确定性、本地优先的 Golden Demo 验收层。它不实现 UI、SaaS、云存储，也不要求真实 LLM 或真实 Agent Runtime。目标是在 v3.12 产品硬化之前，证明 Core 生成包可以支撑真实的本地演示链路。

## 范围

- 黄金演示就绪度
- 真实输入样本覆盖
- 生成产物可打开性
- 生成包兼容性
- 按需检查 v3.7、v3.8、v3.9、v3.10 输出，验证烟测真实性
- Workbench 合约暴露报告和动作

## 输出

- `golden_demo_manifest.json`
- `golden_demo_report.md`
- `real_acceptance_smoke_result.json`
- `real_acceptance_smoke_report.md`
- `sample_coverage_report.json`
- `sample_coverage_report.md`
- `artifact_openability_report.json`
- `artifact_openability_report.md`
- `generated_package_compatibility_report.json`
- `smoke_realism_report.json`
- `v311_acceptance_trace.json`

## CLI

```bash
heitang-kb-forge run-golden-demo-acceptance --package ./package --output ./acceptance
```

该命令只读取本地文件。`--allow-llm` 和 `--allow-network` 是保留开关，在 v3.11 必须保持 false。

## 配置

```yaml
golden_demo_acceptance:
  enabled: true
  require_v37: true
  require_v38: true
  require_v39: true
  require_v310: true
  allow_llm: false
  allow_network: false
```

默认 build 行为不变。只有显式启用该配置块，或直接调用 CLI 命令时，才会写入 v3.11 报告。

## 验收规则

产物可打开性会在本地解析 JSON、JSONL、Markdown、文本、YAML 输出，并在存在 Office/PDF 文件时检查本地容器或文件签名。它不会上传任何生成产物。

烟测真实性会检查必需的前序版本输出是否存在。v3.11 可以要求 v3.7 查询规划、v3.8 检索质量、v3.9 存储与记忆、v3.10 本地 Agent Runtime 输出，避免 Golden Demo 只靠空架子通过。

LLM 仍然只是可选辅助层。测试不需要真实 LLM、API 或网络访问。
