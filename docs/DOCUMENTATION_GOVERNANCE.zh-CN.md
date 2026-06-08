# 文档治理

main 分支只保留当前产品文档。

## 策略

- GitHub 读者应从 `README.zh-CN.md` 和 `docs/DOCS_INDEX.zh-CN.md` 开始。
- 历史版本细节、旧实现说明、legacy drafts 和过程型 roadmaps 通过 git history 与 tags 查看。
- Final gate evidence 和 latest Core P0 proof 继续提交保留。
- 本地 provider configs、API keys、raw local acceptance outputs、大型私有样本、完整 chunk dumps 不得提交。

## 当前保留入口

- `README.md`
- `README.zh-CN.md`
- `CHANGELOG.md`
- `docs/DOCS_INDEX.md`
- `docs/DOCS_INDEX.zh-CN.md`
- `docs/USER_MANUAL.md`
- `docs/USER_MANUAL.zh-CN.md`
- `docs/COMMAND_REFERENCE.md`
- `docs/COMMAND_REFERENCE.zh-CN.md`
- `docs/AGENT_INTEGRATION.md`
- `docs/AGENT_TOOL_INTERFACE_GUIDE.md`
- `docs/MCP_READINESS_GUIDE.md`
- `docs/ICON_GUIDELINES.md`
- `docs/OUTPUT_REPORT_GUIDE.md`
- `docs/OUTPUT_REPORT_GUIDE.zh-CN.md`
- `docs/GOLDEN_DEMO_GUIDE.md`
- `docs/GOLDEN_DEMO_GUIDE.zh-CN.md`
- `docs/VERSION_MATRIX.md`
- `docs/VERSION_MATRIX.zh-CN.md`
- `docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md`
- `docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md`
- `docs/ROADMAP.md`
- `docs/ROADMAP.zh-CN.md`
- `docs/RELEASE_NOTES.md`
- `docs/RELEASE_NOTES.zh-CN.md`
- `docs/00_overview/CURRENT_TRUTH.md`
- `docs/00_overview/CURRENT_TRUTH.zh-CN.md`
- `docs/00_overview/CAPABILITY_MATRIX.md`
- `docs/00_overview/CAPABILITY_MATRIX.zh-CN.md`
- `docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.md`
- `docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.zh-CN.md`
- `docs/10_roadmap/P1_UI_CORE_PARITY.md`
- `docs/10_roadmap/P1_UI_CORE_PARITY.zh-CN.md`
- `docs/10_roadmap/P2_PRODUCTIZATION.md`
- `docs/10_roadmap/P2_PRODUCTIZATION.zh-CN.md`

## 根目录证据

仓库根目录只保留当前 final Core truth surface 所需 gate JSON：

- `final_v4_rc_gate_report.json`
- `v4_rc_final_gate_report.json`
- `v310_external_absorption_map.json`
- `v38_external_absorption_map.json`
- `v39_external_absorption_map.json`
- `v312_external_absorption_map.json`

Latest P0 proof 保留在：

- `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`

## 不再作为 main 文档保留

- 旧 `V*` version process notes
- 旧 implementation plans 和 checkpoints
- legacy draft roadmaps
- 已被当前入口文档覆盖的重复 capability descriptions
- 当前 final gate 或当前测试不需要的根目录历史 audit/report markdown 和 JSON 文件
