# S/A Contract Inclusion

本 pass 把 S/A 外部项目从 roadmap-only registry 纳入 Core contract visibility、Workbench capability mapping、blocked reasons、planned/future adapter registry、provider boundary 和 docs/tests。

这是合同加入，不是功能实现。

输出入口：[../../audits/s_a_contract_inclusion/](../../audits/s_a_contract_inclusion/)

## 汇总

- S 级项目：7
- A 级项目：16
- 内部能力方向：8
- 实现外部项目功能：false
- planned_adapter 标为 ready：false
- provider/network/API 能力标为 ready：false
- 改变 P1 gate：false
- v4.0 started：false
- tag created：false
- release written：false

## 边界

- S/A 项目在 v4 前不是 local-ready。
- 外部项目功能仍属于 post-v4。
- API、network、provider、secret 相关能力必须要求用户显式配置。
- n8n 不打包 runtime。
- WeKnora 不内嵌。
- 原始 S/A 纳入快照未调用 AnySearchSkill；当前 Section 5 item 5.3 证据单独登记在 `artifacts/audits/section_5/anysearchskill_provider_adapter/`。
- LLM Wiki memory engine 不实现。
- planned_adapter 和 future_adapter 都不是 ready。

## 只读 CLI

```powershell
python -m heitang_kb_forge.cli external-capability-registry --output .\tmp_s_a_contract
python -m heitang_kb_forge.cli external-capability-inspect --project-id anysearchskill
python -m heitang_kb_forge.cli external-capability-matrix --output .\tmp_s_a_matrix
python -m heitang_kb_forge.cli planned-adapter-status --output .\tmp_adapter_status
```

这些命令只写入或查看 registry/report 文件，不执行外部项目。
