# 测试瘦身登记表

版本：`v4.1.1`

本登记表用于让过时测试瘦身可审计。它不会默认把测试标记为 passed 或 removed。只有明确 canonical replacement，并且 replacement 已被 validation gate 覆盖后，测试才能删除或合并。

## Canonical Truth Sources

| 表面 | Canonical source | Guard test |
| --- | --- | --- |
| Version metadata | `pyproject.toml`, `skill.json`, `docs/VERSION_MATRIX.md` | `tests/test_version_alignment.py`, `tests/test_skill_metadata.py` |
| Release checklist | `docs/RELEASE_CHECKLIST.md` 与 zh-CN peer | `tests/test_release_checklist_docs.py` |
| Workbench contract | `web/workbench/contracts.json` | `tests/test_workbench_ui_contract.py` |
| Parser/OCR evidence fixture | `examples/ui_mock_data/parser_backends/parser_backend_matrix.json` 与 Flutter asset peer | `tests/test_workbench_ui_mock_data.py` |
| Test governance | `docs/testing/VALIDATION_GATE_MANIFEST.json` | `tests/test_test_governance_manifest.py` |

## Current Pruning Candidates

| Candidate pattern | Risk | Replacement before pruning | Status |
| --- | --- | --- | --- |
| README、matrix、metadata tests 中重复 exact version string checks | release line 变化时维护成本高 | 保留一个 canonical version alignment test，其他地方用语义断言 release role | tracked |
| Workbench source exact-string checks | 无害布局重构也可能失败 | 优先使用 contract、fixture、model 与 asset drift tests | tracked |
| 重复 parser/OCR fixture checks | 同一个 fixture drift 被多处重复报告 | 保留一个 fixture parity owner 与一个 display contract owner | tracked |
| Flutter widget 长 evidence 文案断言 | copy edit 或 localization refine 时脆弱 | 优先检查稳定语义标签与 layout overflow | tracked |
| 与 release checklist 重复的 broad docs tests | 一个 release-line 小改触发重复失败 | release checklist 做 owner，docs changes 由 manifest impact rules 选择 gate | tracked |

## Pruning Rule

删除或合并任何 candidate 前：

1. 指定 canonical owner test。
2. 指定 replacement invariant。
3. 如果 impacted surface 改变，更新 validation gate manifest。
4. 运行 impacted Fast Gate。
5. 在 release validation report 中记录删除或合并。

任何 skipped、deferred、blocked、env-blocked 或 unavailable test 都不能汇报为 passed。
