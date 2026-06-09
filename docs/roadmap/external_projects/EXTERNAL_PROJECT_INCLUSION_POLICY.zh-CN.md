# 外部项目纳入策略

本策略约束 pre-v4 阶段的外部项目登记。

## v4 前允许

- 记录项目身份、评级、当前仓库状态、映射能力和 post-v4 目标。
- 当仓库已有 benchmark 或 planned-adapter 证据时，记录对应文件。
- 标注 provider、network、external runtime、license review、security review 边界。
- 增加文档和测试，证明本轮只是 registry。

## v4 前禁止

- 实现外部项目功能。
- 复制外部项目代码、prompt、配置或 raw outputs。
- 新增外部依赖。
- 调用外部 API 或 provider。
- 打包 n8n 或任何外部 runtime。
- 把 planned_adapter、future_adapter、provider_required 或 needs_verification 标为 ready。
- 改 P1 real workflow evidence 或 final gate status。
- 启动 v4.0、打 tag 或写 release。

## 审查规则

每个 S/A 项目在未来 contract inclusion 前都必须有 post-v4 target 和明确边界。任何 provider、network、external-runtime 项目都必须保持 `can_be_ready_before_v4=false`。
