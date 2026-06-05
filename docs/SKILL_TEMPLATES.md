# Skill Templates

v2.2 checkpoint fill adds local enhanced Skill templates for common Skill types.

Supported types include `qa_skill`, `content_skill`, `product_manager_skill`, `shopping_guide_skill`, `education_tutor_skill`, `novel_writing_skill`, `customer_service_skill`, `enterprise_kb_skill`, `xiaohongshu_content_skill`, `longform_writing_skill`, and `official_account_writing_skill`.

Use:

```powershell
python -m heitang_kb_forge.cli generate-skill --package .\package --output .\skill --skill-type qa_skill --enhanced-skill-template
```

This generates local Skill helper files only. It does not export to OpenClaw, XHS, MCP, Codex, or Claude Code platforms.
