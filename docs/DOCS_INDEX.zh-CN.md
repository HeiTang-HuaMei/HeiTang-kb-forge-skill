# 文档索引

当前 Core 版本：`3.12.0-alpha.1`

这是当前 main 分支的唯一主文档入口。历史版本细节通过 git history 和 tags 查看，不再作为过程文档堆放在 main。

## 从这里开始

- [README](../README.zh-CN.md)
- [当前真值](CURRENT_TRUTH.md)
- [能力矩阵](CAPABILITY_MATRIX.md)
- [AIGC 图书/内容生产场景](AIGC_BOOK_CONTENT_PIPELINE.md)
- [GitHub About 建议文案](GITHUB_PROFILE_COPY.md)
- [详细当前真值](00_overview/CURRENT_TRUTH.zh-CN.md)
- [详细能力矩阵](00_overview/CAPABILITY_MATRIX.zh-CN.md)
- [最终产品架构真值](FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md)
- [文档治理](DOCUMENTATION_GOVERNANCE.zh-CN.md)

## 使用 Core

- [用户手册](USER_MANUAL.zh-CN.md)
- [命令参考](COMMAND_REFERENCE.zh-CN.md)
- [故障排查](TROUBLESHOOTING.zh-CN.md)
- [版本矩阵](VERSION_MATRIX.zh-CN.md)

## Core 能力

- [Parser Backend Strategy](03_core_capabilities/PARSER_BACKEND_STRATEGY.zh-CN.md)
- [P1 Workbench Contract Pack](03_core_capabilities/WORKBENCH_CONTRACT_PACK.zh-CN.md)
- [P1 Workbench Template Registry](03_core_capabilities/WORKBENCH_TEMPLATE_REGISTRY.zh-CN.md)

## 发布状态

- [路线图](ROADMAP.zh-CN.md)
- [Release Notes](RELEASE_NOTES.zh-CN.md)
- 根目录 gate：`../final_v4_rc_gate_report.json`
- 根目录 gate alias：`../v4_rc_final_gate_report.json`
- 最新 P0 证明：`audits/local_acceptance/pre_v4_p0_after_live_llm/`
- 最新 P1 final gate re-run 证明：`audits/p1_final_gate_rerun/`

## 路线门禁

- [P1 UI Core Parity](10_roadmap/P1_UI_CORE_PARITY.zh-CN.md)
- [P2 Productization](10_roadmap/P2_PRODUCTIZATION.zh-CN.md)

## 边界

LLM 仍然只是 optional only；Core tests 不需要真实 LLM/API/network 调用。v4.0 尚未开始、未发布、未打 tag。P1 local Workbench gate 仅表示可进入 v4 RC preparation。
