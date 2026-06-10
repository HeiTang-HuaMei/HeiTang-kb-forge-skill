# 测试瘦身登记表

版本：`v4.1.1`

本登记表用于让 obsolete test pruning 可审计。它不会默认把测试标记为已通过或已删除。只有明确 canonical replacement 并纳入 validation gate 后，测试才可以删除或合并。

## Canonical Truth Sources

| Surface | Canonical source | Guard test |
| --- | --- | --- |
| Version metadata | `pyproject.toml`、`skill.json`、`docs/VERSION_MATRIX.md` | `tests/test_version_alignment.py`、`tests/test_final_version_metadata.py` |
| Release checklist | `docs/RELEASE_CHECKLIST.md` 及中文同源文档 | `tests/test_release_checklist_docs.py` |
| Documentation structure | `docs/DOCS_INDEX.md` 与 `docs/DOCS_INDEX.zh-CN.md` | `tests/test_final_docs_structure.py` |
| Parser/OCR boundaries | `docs/audits/p2_1_parser_ocr_backends/` | `tests/test_v28_parser_backends.py` |
| Test governance | `docs/testing/VALIDATION_GATE_MANIFEST.json` | `tests/test_test_governance_manifest.py` |

## 当前瘦身候选

| Candidate pattern | Risk | Replacement before pruning | Status |
| --- | --- | --- | --- |
| 多个 docs tests 重复检查精确版本字符串 | release version 改动时维护成本高 | 保留一个 canonical version alignment test，其他位置检查语义角色 | tracked |
| README release boundary exact phrase 重复检查 | 纯文案调整也可能触发脆弱失败 | 优先检查结构化 release checklist 或 version matrix | tracked |
| docs index link checks 重复 | 一个链接缺失导致多处重复失败 | 保留一个 link-existence owner，并用 manifest impact rules 覆盖 docs 变更 | tracked |
| UI source exact-string checks | 无害布局重构也可能失败 | 优先使用 fixture / asset / model contract tests | tracked |
| parser boundary wording 被 broad docs tests 重复检查 | 与 parser backend focused tests 重叠 | parser backend capability boundaries 由 parser-focused gate 守护 | tracked |

## 瘦身规则

删除或合并任何候选前必须：

1. 指定 canonical owner test。
2. 指定 replacement invariant。
3. 如果影响面变化，更新 validation gate manifest。
4. 运行 impacted Fast Gate。
5. 在 release validation report 中记录删除或合并。

任何 skipped、deferred、blocked 或 unavailable test 都不能汇报为 passed。
