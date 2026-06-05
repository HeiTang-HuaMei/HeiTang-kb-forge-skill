# 版本矩阵

当前项目版本：2.5.0-alpha.1

本矩阵用于区分已实现检查点与计划能力。本项目采用快速迭代检查点方式推进，部分 tag 可能包含相邻版本能力。

| Version | 状态 | 主要能力 | Checkpoint |
|---|---|---|---|
| v1.6 | 已实现 | 真实资料接入、多模态资产、Contract v2 | historical |
| v1.7 | 已实现 | Governance、Retrieval、Evidence Gate | v1.7.0 |
| v1.8 | 已实现 | Skill / Agent Package Generator | included in later checkpoint |
| v1.9 | 已实现 | Workspace、Registry、LLM Audit | included in later checkpoint |
| v2.0 | 已实现 | Stable foundation | included in later checkpoint |
| v2.1 | 已实现 | Input hardening、Quality、Review、Retrieval eval、Evidence benchmark | included in later checkpoint |
| v2.2 | 已实现 | Master Skill learning、Derived Skill、Skill / Agent / Workspace hardening | v2.3.1-dev |
| v2.3 | 已实现 | Batch、Lineage、Curation、Update impact | v2.3.0-dev |
| v2.3.1-dev | 已实现 | post-v2.3 工业级补强与实现复盘 | v2.3.1-dev |
| v2.4 | 已实现 | Platform distribution 与 mock publishing | v2.4.0-dev |
| v2.4.1-dev | 已实现 | post-v2.4 平台分发补强 | v2.4.1-dev |
| v2.5 | 进行中 | Release quality gate 与 regression certification | v2.5.0-dev / alpha 元数据对齐中 |
| v2.6 | 计划中 | 真实 LLM 治理与 Provider 安全 | planned |
| v2.7 | 计划中 | Runtime compatibility smoke | planned |
| v2.8 | 计划中 | 领域 Skill 工厂 | planned |
| v2.9 | 计划中 | 飞书、个人知识库、移动端 / 安装端 / iOS | planned |
| v3.x | 计划中 | SaaS、权限、团队协作 | planned |

## 说明

- v2.4 platform export 是离线导出包与 mock publishing 层，不是真实平台 runtime。
- XHS 支持是 mock / 本地 Skill package 流程，不是小红书官方上传 API。
- MCP 支持是 stub package，不是真实 MCP Server。
- v2.5 release quality gate 是本地发布认证，不是外部平台认证。
- 真实 LLM live smoke 计划在 v2.6。
- Runtime compatibility smoke 计划在 v2.7。
- 飞书、移动端、安装端和 iOS 计划在 v2.9。
