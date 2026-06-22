# HeiTang Lazy Builder Gate

Status: `planning_pending_owner_review`

This gate defines the engineering discipline for future HeiTang Knowledge Workbench changes. It is a planning and governance document only. It does not change UI code, runtime semantics, dependencies, or feature behavior.

## 1. Core Rule

```text
先删重复，再补缺口。
先复用现有能力，再新增能力。
先保证真实调用，再做 UI 展示。
先普通用户路径，再技术按钮。
先最小闭环，再扩展架构。
能不写代码就不写。
能配置解决就不新增功能。
能复用组件就不新建组件。
能用现有 runtime 就不新增 runtime。
```

The default answer to a proposed change is not "build it". The default answer is:

```text
Can this be solved by deleting duplication, reusing existing capability, or making a smaller change?
```

## 2. Mandatory Pre-Change Questions

Before Codex changes code, the task owner or implementer must answer:

1. Is this change truly necessary?
2. Does a similar capability already exist?
3. Can the issue be solved by deleting duplicate functionality?
4. Can it be solved by configuration instead of new behavior?
5. Can existing components be reused?
6. Will this increase UI complexity?
7. Will this introduce a new dependency?
8. Will this expose technical concepts to ordinary users?
9. Will this break real input / output / CRUD acceptance?
10. Can the same outcome be achieved with a smaller change?

If any answer is unknown, the implementer must stop and output a risk note before editing code.

## 3. Decision Rules

| Situation | Preferred decision |
| --- | --- |
| Duplicate UI path exists | Remove or merge the duplicate path before adding new UI. |
| Existing runtime method can satisfy the task | Reuse it. |
| Missing state can be represented through current config | Use config. |
| New dependency is optional | Do not add it in the current release line. |
| User path is unclear | Write acceptance criteria before implementation. |
| UI needs explanation text to make sense | Rework the path or gate the action; do not cover confusion with copy. |
| Capability is unconfigured | Show "需要设置", "暂不可用", or "本地模式"; do not show success. |
| Product behavior cannot be verified | Do not mark accepted. |

## 4. UI Discipline

Future UI changes must preserve the accepted user path:

```text
我的资料 -> 我的知识库 -> 测试知识库 -> 生成文档 -> 生成 Skill -> 我的助手 -> 成果中心 -> 使用记录 -> 设置
```

Do not add ordinary-user primary entries for:

```text
Provider
Gateway
ModelRoute
Runtime
Audit
Campaign
Operation Gate
Capability Matrix
OKF
A2A
Embedding
Qdrant
Redis
```

These terms are allowed only in advanced settings, developer diagnostics, audit reports, code, tests, fixtures, or internal state mappings.

## 5. Runtime Discipline

Future runtime changes must:

- Preserve existing runtime method semantics.
- Prefer extending verified real actions over adding parallel action families.
- Keep unconfigured capabilities gated.
- Keep real input, real output, artifact trace, usage record, and CRUD verification intact.
- Keep workspace isolation intact.
- Keep Agent memory isolation intact.

## 6. Stop Conditions

Stop implementation and produce a risk note if:

- The user path is missing.
- Acceptance criteria are missing for a non-trivial feature.
- The change requires a new dependency but the gate did not authorize dependencies.
- The change creates fake success.
- The change makes technical concepts ordinary-user primary UI.
- The change risks breaking real IO or CRUD evidence.
- The change cannot be validated.

## 7. Gate Usage

All future repair or implementation tasks must reference this document before code changes.

The expected short form is:

```text
Lazy Builder check:
- Necessary:
- Existing capability:
- Smaller alternative:
- Runtime impact:
- UI complexity:
- Validation:
```

This gate does not replace Product Verifier acceptance. It only prevents unnecessary implementation before verification.
