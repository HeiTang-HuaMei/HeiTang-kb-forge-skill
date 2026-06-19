# 当前产品基线 2026-06-19

当前产品事实只以以下三份 v3 文档为准：

- [PRODUCT_ARCHITECTURE_V3_2026-06-19.md](../product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md)
- [PRD_V3_2026-06-19.md](../product/PRD_V3_2026-06-19.md)
- [FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md](../product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md)

其他文档只能引用、解释或落地这三份基线，不得再各说各话。

## 统一主链路

```text
文档库 → 知识库 → 索引层 → RAG → 编排层 → 文档/Skill/Agent/A2A
```

完整链路：

```text
工作区
  → 资料导入
  → 文档库
  → 标准知识包 / OKF 候选层
  → 知识库
  → 索引层
  → RAG 与验证层
  → 编排层
  → 文档 / Skill / Agent / A2A
  → 产物中心 / 审计 / 导出
```

## 边界锁定

- OKF 只作为标准知识包候选层，不作为当前 runtime、一级导航或用户主链路。
- 登记项目只能写成 `reference_only`、`needs_verification` 或经单独核验后的候选状态，不得写成已接入。
- 旧 rc、旧 campaign、旧验收报告、旧能力矩阵和旧 UI 调整计划只作历史追溯。
- 本轮 docs gate 不改 Core、UI、runtime，不新增功能，不 tag，不 release。

## 当前入口

- 用户文档：[../user/项目概览.md](../user/项目概览.md)、[../user/快速开始.md](../user/快速开始.md)、[../user/使用指南.md](../user/使用指南.md)
- 架构文档：[../architecture/系统架构.md](../architecture/系统架构.md)、[../architecture/知识供应链架构.md](../architecture/知识供应链架构.md)、[../architecture/路线图.md](../architecture/路线图.md)
- 验收文档：[../acceptance/测试与验收.md](../acceptance/测试与验收.md)、[../acceptance/Owner复验清单.md](../acceptance/Owner复验清单.md)
- 治理文档：[../governance/登记项目治理.md](../governance/登记项目治理.md)、[../governance/外部运行时参考队列.md](../governance/外部运行时参考队列.md)
