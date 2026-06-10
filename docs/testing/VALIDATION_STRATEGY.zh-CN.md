# 验证策略

本策略属于 v4.1.0 Test Governance Emergency Hardening 的流程加固。它定义 development-time、phase closure 和最终 tag/release 前的 impact-based staged validation。

## Before Any Validation Phase

每个 validation phase 都必须从这里开始：

1. 阅读本策略。
2. 生成 changed-file impact map。
3. 选择 Fast / Medium / Full Gate。
4. 开发中只运行 impacted tests。
5. phase closure 时运行 Medium Gate。
6. tag/release 前运行 Chunked Full Gate。
7. 长时间 gate 必须保存 logs 和 exit codes。
8. skipped/deferred checks 必须说明 reason。
9. 绝不把 skipped/deferred checks 汇报为 passed。

## Gate Levels

### Fast Gate

开发过程中，当 changed-file impact 较窄且工作仍在进行时使用 Fast Gate。

Fast Gate 必须包含：

- 与改动文件直接相关的 unit 或 contract tests
- 当命令行为变化时，运行相关 CLI smoke tests
- `git diff --check`
- 记录 deferred tests 以及 deferred reason

Fast Gate 不足以用于 phase closure、tag 或 release。

### Medium Gate

关闭一个 phase、checkpoint 或 release-hardening slice 前使用 Medium Gate。

Medium Gate 必须包含：

- 所有 Fast Gate checks
- 被触及能力域的 focused tests
- 当 README、capability matrix、current truth、changelog、roadmap 或 audit docs 改动时，运行 docs/truth tests
- 当 parser/OCR files、contracts、fixtures 或 evidence 改动时，运行 parser backend focused tests
- 当 release metadata 或 setup instructions 改动时，运行 release-readiness 或 doctor checks

Medium Gate 可以用于 phase review，但不足以 tag 或 publish release。

### Full Gate

Full Gate 是 tag 或 release 前的强制门禁。

Full Gate 必须包含：

- 完整 Core `python -m pytest`
- P2.1 parser/OCR 工作对应的 focused parser backend tests
- release 准备时的 release-readiness、doctor 和 quickstart checks
- `git diff --check`
- secrets、build outputs、raw runtime outputs、local provider config 和 large generated artifacts 的 hygiene scans
- 当 Workbench fixtures、contracts、assets 或 visible surfaces 改动时，运行 UI validation
- 创建 tag 时，release commit 与 tag/release workflow 的 CI green

Full Gate 未通过前，不得创建或推送 release tag。

### Chunked Full Gate

长时间 Full Gate 必须可审计。不得把单个 opaque 的 40 分钟 `python -m pytest` 命令作为唯一 release evidence。

Chunked Full Gate 要求：

- 每个 chunk 单独运行
- 每个 chunk 在 `docs/audits/test_engineering/full_gate_logs/` 下保存 log
- 每个 chunk 捕获 exit code
- 全部 chunk 通过后才能把 Full Gate 汇报为 passed
- 如果工具超时导致 output 或 exit code 丢失，该 chunk 不能算 passed
- 如果 full suite 对单个可靠 chunk 仍然过慢，必须按测试领域继续拆分，直到每个 chunk 都有 log 和 exit code

推荐 Core chunks：

```powershell
python -m pytest tests/test_final_docs_truthfulness.py tests/test_final_bilingual_docs_parity.py tests/test_final_docs_structure.py tests/test_release_checklist_docs.py tests/test_readme_scope.py tests/test_version_alignment.py tests/test_version_matrix_docs.py -q
python -m pytest tests/test_v28_parser_backends.py tests/test_external_project_registry.py tests/test_planned_adapter_boundaries.py tests/test_s_a_contract_inclusion.py tests/test_post_v4_external_roadmap.py -q
python -m pytest -q
```

推荐 UI chunks：

```powershell
python -m pytest
flutter analyze
flutter test -r expanded
flutter build web
flutter build windows
```

最终 tag/release 前，必须在 validation report 中保存每个命令的 log 和 exit code。

## Changed-File Impact Map

| Changed files | Required validation |
| --- | --- |
| `heitang_kb_forge/parser_backends/**`、parser CLI commands、parser contracts | Parser backend focused tests、CLI smoke、evidence generation、docs/truth checks；release 前必须 Full Gate |
| `heitang_kb_forge/cli*.py`、command modules、command docs | Command focused tests、CLI smoke、command reference checks、`git diff --check` |
| `docs/**`、`README*`、`CHANGELOG.md`、`CURRENT_TRUTH.md`、`CAPABILITY_MATRIX.md` | Docs truth tests、link checks、适用时 bilingual parity |
| `docs/audits/**`、evidence JSON/Markdown reports | Evidence schema/consistency tests、audit index link checks、no raw-output scan |
| `pyproject.toml`、`skill.json`、version metadata | Version alignment tests、doctor、release-readiness |
| Workbench contract/fixture/asset files | UI fixture drift tests、Flutter asset match tests；visible UI change 时运行 Flutter analyze/test/build |
| `.github/workflows/**`、release scripts | CI workflow validation、release-readiness；tag/release 前必须 Full Gate |
| Secret、provider、network、local config handling | Security/privacy focused tests、secret scan、provider config scan |

如果一次改动跨多个类别，必须运行这些类别要求验证的并集。

## Current Fast Gate Commands

Core docs/truth 改动：

```powershell
python -m pytest tests/test_final_docs_truthfulness.py tests/test_final_bilingual_docs_parity.py tests/test_final_docs_structure.py tests/test_release_checklist_docs.py tests/test_readme_scope.py tests/test_version_alignment.py tests/test_version_matrix_docs.py -q
git diff --check
```

Core parser/evidence 改动：

```powershell
python -m pytest tests/test_v28_parser_backends.py tests/test_external_project_registry.py tests/test_planned_adapter_boundaries.py tests/test_s_a_contract_inclusion.py tests/test_post_v4_external_roadmap.py -q
git diff --check
```

UI fixture/contract 改动时，运行受影响的 UI Python contract tests。Flutter UI 改动时运行：

```powershell
flutter analyze
flutter test -r expanded
```

Fast Gate 不运行 Core full pytest、`flutter build web` 或 `flutter build windows`。

## Skipped Or Deferred Test Reason Format

任何 skipped 或 deferred check 都必须按以下格式报告：

```text
check:
gate_level:
reason:
impact:
risk:
replacement_evidence:
owner:
must_run_before:
```

示例：

```text
check: full Core python -m pytest
gate_level: Full Gate
reason: still running in CI; local focused suite passed
impact: release tag is blocked until full result is green
risk: undiscovered cross-module regression
replacement_evidence: parser backend focused tests and docs truth tests passed locally
owner: release operator
must_run_before: v4.1.0 tag/release
```

Skipped、timed-out、deferred、blocked 或 unavailable checks 绝不能汇报为 passed。报告可以写 `not run`、`deferred`、`blocked` 或 `failed`，但不能写 `passed`。

合法 skipped/deferred reasons：

- `not impacted by current changed files`
- `inherited from last green full gate`
- `deferred to medium gate`
- `deferred to final full gate`
- `blocked by environment with explicit reason`

禁止 skipped/deferred reasons：

- `passed by default`
- `assumed passed`
- `probably unrelated`
- `skip because slow`

## Validation Report

Validation reports 位于 `docs/audits/test_engineering/`，必须包含：

- `selected_gate`
- `changed_files`
- `impacted_surfaces`
- `commands_run`
- `commands_deferred`
- `commands_skipped`
- `skip_reason`
- `exit_codes`
- `log_paths`
- `release_blocking`

## Release Rule

Full Gate 是任何 tag 或 release 前的强制要求。对 v4.1.0 而言，只有 Core 和 UI Chunked Full Gates 通过、CI green、hygiene scans clean，并且 stable `v4.0.0` tag 保持不变后，才能 tag 或 publish。
