# User Path First UI Governance

Status: `planning_pending_owner_review`

This document protects the accepted HeiTang Workbench UI from becoming complex again as new capabilities are planned.

## 1. Purpose

Future features must serve the user path before they expose technical control surfaces.

The accepted ordinary-user main path is:

```text
我的资料
-> 我的知识库
-> 测试知识库
-> 生成文档
-> 生成 Skill
-> 我的助手
-> 成果中心
-> 使用记录
-> 设置
```

## 2. Governance Rule

Do not add a new ordinary-user primary entry unless it represents a real user task that cannot fit the existing path.

Before adding UI, answer:

1. Which user task does this simplify?
2. Which existing page cannot host it?
3. Which runtime method or artifact backs it?
4. What happens when the capability is unconfigured?
5. Does it increase the number of decisions for first-time users?

If these questions cannot be answered, do not add the UI.

## 3. Disallowed Ordinary Primary Entries

These terms must not become ordinary-user primary navigation, hero actions, or main buttons:

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

Allowed locations:

- Advanced settings.
- Developer diagnostics.
- Audit reports.
- Code.
- Test fixtures.
- Internal state mappings.

## 4. Button Rules

Every visible enabled button must map to one of:

- Navigation.
- Real runtime action.
- Real artifact action.
- Real configuration save/test.
- View or inspect action.
- Destructive action with confirmation.

If the capability is not configured, the button must be disabled or gated with user-facing language:

```text
需要设置
暂不可用
本地模式
连接失败
```

Do not show a fake success state.

## 5. Page Rules

Every ordinary product page must have:

- One clear primary task.
- Secondary actions grouped below or aside.
- Empty state.
- Loading state where applicable.
- Success state.
- Failure state with user-facing language.
- Config-gated state where applicable.
- Artifact or record trace where the page produces output.

Pages must not rely on long explanatory text to make the workflow understandable.

## 6. Settings Boundary

Settings ordinary categories:

- 模型服务.
- 本地/专业模式.
- 导出设置.
- 网络权限.
- 存储位置.
- 记忆服务.
- 安全与合规.

Advanced-only details:

- Provider.
- Gateway.
- ModelRoute.
- Redis.
- Vector DB.
- Qdrant.
- Profile lifecycle.
- Developer diagnostics.

## 7. Review Checklist

Before merging future UI changes:

- [ ] The ordinary path remains visible.
- [ ] No forbidden technical term was promoted to primary UI.
- [ ] Unconfigured abilities are gated.
- [ ] Buttons have real backing behavior.
- [ ] Artifact-producing pages write traceable artifacts.
- [ ] Usage-record-producing pages write real usage records.
- [ ] Workspace boundaries remain visible and true.
- [ ] Agent memory boundaries remain visible and true.
- [ ] Product Verifier can black-box verify the path.

## 8. Relation To Lazy Builder Gate

All UI changes must pass `docs/dev/HEITANG_LAZY_BUILDER_GATE.md` before implementation.

The default UI decision is:

```text
reuse existing page, component, and runtime binding
```

Only add a new surface when the user path requires it and Product Verifier can verify it.
