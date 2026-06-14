# Campaign 4-9 验收矩阵

## Planning Gate 验收

| 验收项 | 命令或证据 | 通过条件 | 失败动作 |
| --- | --- | --- | --- |
| 8 个中文计划文档存在 | `Test-Path docs/治理/Campaign_*.md` | 8 个允许文档均存在且非空 | 停止，补齐计划文档 |
| 只使用中文治理目录 | `git status --short` 和路径审查 | 只新增或更新 `docs/治理/` 中允许文档 | 停止，移除越界变更 |
| v4.2 public reset 兼容 | `python -m pytest tests/test_v4_2_public_repository_reset.py -q` | passed | 停止，记录失败 |
| final docs structure 兼容 | `python -m pytest tests/test_final_docs_structure.py -q` | passed | 停止，记录失败 |
| `skill.json` 格式 | `python -m json.tool skill.json` | exit code 0 | 停止，修复 JSON |
| diff whitespace | `git diff --check` | 无输出 | 停止，修复 whitespace |
| forbidden legacy tracked paths | `git ls-files artifacts docs/audits .agents docs/governance docs/testing docs/product docs/bridge docs/roadmap` | 无输出 | 停止，不得恢复旧目录 |
| root-only JSON | `git ls-files \| Where-Object { $_ -match '^[^/\\]+\.json$' }` | 仅输出 `skill.json` | 停止，移除 forbidden root JSON |
| UI 仓库只读 | `git -C ..\kb-forge-skill-ui status --short` | 只记录现有 dirty 状态 | 停止，不得修改 UI 仓库 |
| GitHub Release 未创建 | `gh release view campaign-1-3-baseline` | release not found 视为通过 | 若存在 release，停止并上报 |
| product version tag 检查 | `git tag --list "v*"` | 只记录历史 tag，不因历史 tag 存在失败 | 若本次新增 tag，停止 |
| stable baseline tag 存在 | `git tag --list "campaign-1-3-baseline"` | 输出 `campaign-1-3-baseline` | 停止，不得重建 tag |

## JSON 验收规则

Root-level JSON is limited to skill.json. Nested JSON is allowed only for code, tests, examples, packaging, schema, or runtime-required contracts.

正确 root-only JSON 检查：

```powershell
git ls-files | Where-Object { $_ -match '^[^/\\]+\.json$' }
```

预期：

```text
skill.json
```

不得使用 `git ls-files *.json` 作为 root JSON 检查。嵌套 JSON 允许用于 desktop / Tauri config、package metadata、examples、schema、test fixture、runtime-required contracts。禁止新增历史 gate report、fix log、RC report 或 external absorption map 到 root。

## Campaign 级验收矩阵

| Campaign | Entry Gate | Acceptance Gate | Review / Handoff Gate | 不得替代验收 |
| --- | --- | --- | --- | --- |
| Campaign 4 | UI inventory、导航收敛方案、task-card flow 方案、UI dirty diff 审查 | UI focused tests、状态与进度条验证、无 runtime overclaim | UI handoff，不宣称 Bridge/Runtime/EXE complete | 截图、静态按钮页、计划文档 |
| Campaign 5 | Campaign 4 handoff accepted、Bridge allowlist 明确 | Core Bridge flow tests、no arbitrary shell execution | Bridge handoff，不宣称 Agent Runtime complete | 单个 CLI 调用 |
| Campaign 6 | Campaign 5 handoff accepted、runtime scope 明确 | Agent Runtime / Memory tests、isolation tests | Runtime handoff，不宣称 Configuration complete | Agent package spec |
| Campaign 7 | Campaign 6 handoff accepted、profile schema 明确 | configuration profile tests、secret boundary tests | Config handoff，不宣称 Full Review complete | 硬编码配置 |
| Campaign 8 | Campaign 7 handoff accepted、full gate plan 明确 | local full pytest、clean clone/worktree pytest、Windows runner parity、UI-Core consistency、docs consistency | Full Review handoff，不宣称 EXE complete | Fast Gate、局部 smoke |
| Campaign 9 | Campaign 8 handoff accepted、size budget、package plan | portable package、installer 评估、asset manifest、checksum、dependency inventory、optional dependency exclusion list、launch smoke、clean machine smoke | Release handoff，不自动创建 GitHub Release | 临时压缩包 |

## Evidence Gate 规则

每个 Campaign 的 Acceptance Gate 必须明确证据来源，禁止只写 `passed` 而不列证据。

证据来源至少包括适用项：

- 本地 full pytest。
- clean clone / clean worktree pytest。
- Windows runner parity。
- UI focused tests。
- public repository surface check。
- root-only JSON check。
- forbidden tracked paths check。
- Release Check 或对应 gate check。
- failure matrix。
- rollback plan。

本地 pytest green 不足以直接 tag。必须先做 CI-equivalent clean clone / worktree 验证。

## 长任务验收规则

长任务 checkpoint 必须包含：

- 当前 Campaign。
- 当前 Gate。
- 当前状态。
- 已完成内容。
- 未完成内容。
- 失败原因。
- 下一安全动作。
- 禁止动作。
- 是否允许恢复执行。

遇到 429、CI failure、Release Check failure、clean checkout mismatch、Windows runner parity mismatch 时必须停止并记录，不得继续扩展范围。

## Commit / Push 验收

验证通过后，只提交并推送 8 个允许的 Campaign 4-9 中文计划文档的新增或更新。

允许提交：

- `docs/治理/Campaign_4_9_总计划.md`
- `docs/治理/Campaign_4_9_顺序锁.md`
- `docs/治理/Campaign_4_9_验收矩阵.md`
- `docs/治理/Campaign_4_9_风险矩阵.md`
- `docs/治理/Campaign_4_入口计划.md`
- `docs/治理/Campaign_4_页面与任务卡规划.md`
- `docs/治理/Campaign_4_状态与进度条规范.md`
- `docs/治理/Campaign_6_外部运行时参考队列.md`

禁止提交 `artifacts/audits/current_run/*`、`docs/audits/*`、`docs/governance/*`、`docs/product/*`、`docs/bridge/*`、`docs/testing/*`、`docs/roadmap/*`、`.agents/*` 或 root-level JSON other than `skill.json`。
