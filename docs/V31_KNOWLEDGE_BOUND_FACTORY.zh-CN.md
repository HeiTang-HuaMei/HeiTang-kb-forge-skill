# v3.1 Agent / Skill Factory

v3.1 新增可选本地 factory，用于 Agent 与 Skill package 生成。Hardening 目标是把 `kb_bound` 和 `standalone` 两种 Agent 创建模式都作为一等能力。

## 范围

- 复用已有 Skill 与 Agent package generator。
- 支持面向 RAG、知识服务、企业 KB 场景的 KB-bound Agent。
- 支持面向规划、教练、写作、运营策略、QA、项目管理、Prompt 优化等场景的 standalone Agent。
- KB-bound 生成默认执行 trusted KB gate。
- 校验生成的 Skill 与 Agent package。
- 写出 factory manifest、trace、quality 和 Markdown report。
- 未启用时默认 build、run 和 pipeline 行为不变。

## Agent 模式

### `kb_bound`

- Agent 绑定一个或多个知识包。
- retrieval binding 启用。
- citation、evidence、answer、refusal policy 基于绑定 KB。
- strict 模式下 untrusted KB 必须阻断，除非显式允许。
- 生成包必须暴露 `knowledge_binding.enabled: true`、package ID/path、trust status、retrieval config、citation policy、evidence policy 和 refusal policy。

### `standalone`

- Agent 可以在没有知识包的情况下创建。
- retrieval binding 默认关闭或可选。
- Agent 由 system prompt、soul/profile、capabilities、tools config、memory policy、output contract、answer policy、refusal policy 和 eval cases 定义。
- standalone Agent 不得伪装拥有 KB citation。
- 生成包必须暴露 `knowledge_binding.enabled: false`。

## 命令

```powershell
python -m heitang_kb_forge.cli generate-bound-agent --package .\tmp_package --output .\tmp_factory
python -m heitang_kb_forge.cli generate-agent --mode kb_bound --package .\tmp_package --output .\tmp_agent
python -m heitang_kb_forge.cli generate-agent --mode standalone --output .\tmp_agent
```

配置驱动运行支持：

```yaml
knowledge_bound_factory:
  enabled: true
  skill_name: Demo Knowledge Skill
  agent_name: Demo Knowledge Agent
  mode: kb_bound
```

## 输出文件

KB-bound 输出包括：

- `skill_package/SKILL.md`
- `agent_package/system_prompt.md`
- `skill_validation/skill_validation_result.json`
- `knowledge_bound_factory_manifest.json`
- `knowledge_bound_factory_trace.json`
- `knowledge_bound_factory_quality_report.json`
- `knowledge_bound_factory_report.md`

Standalone Agent package 必须包含：

- `agent_manifest.json`
- `agent_profile.yaml`
- `soul.md`
- `system_prompt.md`
- `capabilities.yaml`
- `tools.yaml`
- `memory_policy.yaml`
- `output_contract.yaml`
- `answer_policy.md`
- `refusal_policy.md`
- `eval_cases.jsonl`
- `smoke_test_report.json`
- `smoke_test_report.md`
- `validation_report.json`
- `validation_report.md`

## 校验要求

- `standalone` 模式不得要求 KB package。
- `standalone` 模式必须要求 answer policy、refusal policy、memory policy、capabilities、output contract 和 eval cases。
- `kb_bound` 模式必须要求 KB binding 与 retrieval policy。
- `kb_bound` strict 模式必须阻断 untrusted KB。
- 两种模式都必须支持离线 smoke test。

## 边界

v3.1 默认本地、确定性执行。它不部署 Agent，不调用真实 LLM API，也不调用外部 Agent 平台。
