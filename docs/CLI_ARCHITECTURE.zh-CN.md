# CLI 架构

当前版本：`2.6.0-alpha.1`

## 目的

CLI 是 HeiTang KB Forge 的标准 headless 入口。它必须继续服务于本地用户、配置文件执行、pipeline、桌面 UI 控制层，以及 Agent / Skill 调用。

## 入口

`heitang_kb_forge/cli.py` 是小型兼容入口。它必须保持在 5 KB 以下，并继续支持：

- `python -m heitang_kb_forge.cli`
- `heitang-kb-forge` console script
- 既有 `app`、`_build_package`、`V21Options` import

## 命令模块

命令入口代码放在 `heitang_kb_forge/cli_commands/`。

每个模块应保持在 30 KB 以下：

- `build_commands.py`
- `batch_commands.py`
- `pipeline_commands.py`
- `quality_commands.py`
- `release_commands.py`
- `regression_commands.py`
- `platform_commands.py`
- `provider_commands.py`
- `workspace_commands.py`
- `skill_commands.py`
- `agent_commands.py`
- `rag_commands.py`
- `doctor_commands.py`

## 兼容 Runtime

`heitang_kb_forge/cli_runtime.py` 在 v2.5.1 收敛 checkpoint 中保留既有命令行为。它不是新增命令的位置。

后续命令工作必须继续把行为从兼容 runtime 迁移到对应的 `cli_commands/*.py` 模块。

## 新增命令规则

新增或修改命令时：

1. Typer command function 放入对应 `cli_commands` 模块。
2. 业务逻辑放在领域模块，不写死在 CLI 层。
3. 通过共享 CLI app 注册命令。
4. 新增或更新窄范围 CLI 测试。
5. `cli.py` 保持在 5 KB 以下。
6. 每个 `cli_commands/*.py` 保持在 30 KB 以下。
7. 不重新创建 `cli_commands/legacy.py`。

## Release Gate

`release-readiness` 在以下情况必须失败：

- 版本不一致
- capability docs 缺失
- CI workflows 缺失
- README 夸大 planned 能力
- 存在疑似 secrets
- quickstart 输出不完整
- doctor 输出失败
- `cli_commands/legacy.py` 存在且过大

## 边界

CLI 不得：

- 默认调用真实 LLM API
- 调用真实平台 runtime
- 发布到小红书 / XHS
- 启动真实 MCP Server
- 写入真实向量数据库
- 依赖桌面 UI

