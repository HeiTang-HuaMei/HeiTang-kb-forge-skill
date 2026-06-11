# P2.2 补充版本计划

## 状态

用户已批准以下项目作为 v4.2.0 / P2.2 Core integration supplement：

- Anything2Skill
- SkillX
- Anthropic Skills / skill-creator

本补充只增强既有 P2.2 目标，不替换原路线、不创建独立版本线、不启动 P2.3+。

## P2.2 目标

```text
Existing Knowledge Asset
-> Evidence Window
-> Methodology Module
-> Skill Candidate
-> Skill Hierarchy
-> Skill Suite / Skill Pack
-> Validation / Diff / Installability / Governance
-> UI + CLI Industrial Closure
```

## 接入层级

| 参考项目 | 接入层级 | 融入能力 | 明确排除 |
| --- | --- | --- | --- |
| Anything2Skill | L3 `contract_absorbed` + L4 `capability_fused` | evidence-to-candidate contract、supporting evidence、confidence、risk flags、unsupported-claim detection | 不复现论文、训练流程、外部 benchmark runtime，不做 L5 runtime integration |
| SkillX | L3 `contract_absorbed` + L4 `capability_fused` | Planning / Functional / Atomic 层级、routing、dependency graph、重复/冲突检测、merge/split 建议 | 不做 trajectory mining、自进化 Skill runtime、完整 SkillX runtime |
| Anthropic Skills / skill-creator | L3 `contract_absorbed` + 局部 L4 `packaging_governance_fused` | SKILL.md packaging、description/trigger 检查、allowed-file boundary、installability、评估与优化说明 | 不绑定 Anthropic 平台，不接 Claude Skills runtime、上传流程、账号依赖或 provider API |

## 原路线保持

既有 external-project roadmap 继续有效：

- LLM Wiki v2 仍归 Living Knowledge / Memory Lifecycle。
- WeKnora 仍归 Auto Wiki / Knowledge Graph。
- n8n 仍归 Workflow Export / Automation Boundary。
- AnySearchSkill / last30days 仍归 External Retrieval / Trend Radar。
- Jellyfish / MMSkills / story-flicks / seedance2-skill 仍归 AIGC / Multimodal。
- andrej-karpathy-skills / skill-prompt-generator 的既有 Skill Governance 路线保留。

## Slice 落点

- Slice 4：Evidence Windows + Methodology Module。
- Slice 5：Skill Candidates + Anything2Skill contract。
- Slice 6：Skill Hierarchy + SkillX contract。
- Slice 7：Skill Pack / SKILL.md packaging + Anthropic skill-creator contract。
- Slice 8：Suite-level validation / diff / installability。
- Slice 9：UI industrial closure。
- Slice 10：docs / release / v4.2.0。

## 硬边界

- 不做 L5 external runtime integration。
- 不 vendoring runtime，不复制外部项目代码。
- 不接真实外部 provider、API、账号、上传流程、Docker 或数据库。
- 不新增这三个用户批准项目之外的外部项目。
- 不启动 P2.3+。
- Slice 10 前不发布 v4.2.0。
- 不修改历史 tag。
