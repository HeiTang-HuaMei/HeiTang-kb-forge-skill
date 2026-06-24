# P0-8 Settings / Path / Export Blackbox Report

状态：settings_export_basic_completed_needs_owner_review

## 黑盒路径

1. 启动真实 Windows EXE，并通过 HEITANG_P0_SETTINGS_EXPORT_E2E=1 执行设置、路径与导出基础验收。
2. 保存并验证 Provider 设置，检查密钥只保留掩码或引用。
3. 保存并验证 Exporter 设置，检查 export_root 在当前工作区内。
4. 执行 Redis / Qdrant 连接 Gate，未配置时不得假成功。
5. 执行 Project Config Profile 持久化 smoke。
6. 检查 config_test_log、runtime status、summary 产物。
7. 重启 EXE 后复核配置和验收产物仍存在。

## 数据文件路径

- workspace: C:\Users\Administrator\AppData\Local\HeiTangKBForge\rc10_product_flow_workspace
- matrix: D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui\web\workbench\flutter_app\output\capability_blackbox\settings_export_matrix.json
- run dir: D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui\web\workbench\flutter_app\output\capability_blackbox\settings_export\settings_export_20260624_212137
- summary: C:\Users\Administrator\AppData\Local\HeiTangKBForge\rc10_product_flow_workspace\acceptance\settings_export_basic_summary.json
- provider settings: C:\Users\Administrator\AppData\Local\HeiTangKBForge\rc10_product_flow_workspace\config\provider_runtime_settings.json
- exporter settings: C:\Users\Administrator\AppData\Local\HeiTangKBForge\rc10_product_flow_workspace\config\exporter_settings.json
- storage settings: C:\Users\Administrator\AppData\Local\HeiTangKBForge\rc10_product_flow_workspace\config\storage_provider_settings.json
- config log: C:\Users\Administrator\AppData\Local\HeiTangKBForge\rc10_product_flow_workspace\config\config_test_log.jsonl
- profile smoke: C:\Users\Administrator\AppData\Local\HeiTangKBForge\rc10_product_flow_workspace\acceptance\stage3_profile_persistence_smoke_report.json

## 截图路径

- initial: D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui\web\workbench\flutter_app\output\capability_blackbox\settings_export\settings_export_20260624_212137\screenshots\settings_export_initial.png
- after e2e: D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui\web\workbench\flutter_app\output\capability_blackbox\settings_export\settings_export_20260624_212137\screenshots\settings_export_after_e2e.png
- after restart: D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui\web\workbench\flutter_app\output\capability_blackbox\settings_export\settings_export_20260624_212137\screenshots\settings_export_after_restart.png

## 验证结论

- blocked rows: 0
- current status: settings_export_basic_completed_needs_owner_review

## 补充计划动态合并检查

本 Gate 只合并与 P0-8 设置、路径、导出基础能力直接重叠的内容：配置持久化、导出路径、连接 Gate、密钥掩码、重启恢复和审计记录。

延后内容：连接配置工业化、Credential Proxy、Policy Governance、Office Adapter、远程控制、多模型调度和发布 Gate 均未在本 Gate 实现。

## 未验证内容

- 未验证真实外部 Redis/Qdrant 服务连接成功；未配置时只验证 Gate 和失败记录。
- 未接入 OfficeCLI 或外部 Office Adapter。
- 未做 Release / Tag / Push。

## 仍阻断项

- 无 P0-8 直接阻断项，等待 Owner 复核。
