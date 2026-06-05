# Skill 模板

v2.2 checkpoint 后补增加本地 enhanced Skill templates，覆盖常见 Skill 类型。

支持类型包括 `qa_skill`、`content_skill`、`product_manager_skill`、`shopping_guide_skill`、`education_tutor_skill`、`novel_writing_skill`、`customer_service_skill`、`enterprise_kb_skill`、`xiaohongshu_content_skill`、`longform_writing_skill` 和 `official_account_writing_skill`。

使用：

```powershell
python -m heitang_kb_forge.cli generate-skill --package .\package --output .\skill --skill-type qa_skill --enhanced-skill-template
```

该能力只生成本地 Skill 辅助文件，不导出到 OpenClaw、小红书、MCP、Codex 或 Claude Code 平台。
