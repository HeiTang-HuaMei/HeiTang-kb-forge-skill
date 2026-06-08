# Book-to-Skill 结构化 Skill Package

这个 pre-v4 P0 门禁把 HeiTang 从“知识包导出”升级为“结构化 Skill package 生成”。

生成的 Skill 不是原书全文倾倒。`SKILL.md` 是紧凑入口，详细内容被拆到 `chapters/`、`concepts/`、`frameworks/`、`techniques/`、`patterns/`、`anti_patterns/` 等按需加载文件中。

## 命令

```powershell
python -m heitang_kb_forge.cli book-to-skill --package .\tmp_package --output .\tmp_skill --skill-name "Demo Skill" --target codex
python -m heitang_kb_forge.cli validate-skill-package --skill .\tmp_skill --output .\tmp_skill_validation
python -m heitang_kb_forge.cli diff-skill-package --old-skill .\old_skill --new-skill .\tmp_skill --output .\tmp_skill_diff
```

`book-to-skill` 也支持 `--input`，可以传入文件、文件夹或 glob；命令会先生成本地 KB package，再生成结构化 Skill。

## 必需输出

- `SKILL.md`
- `skill_manifest.json`
- `skill_index.json`
- `on_demand_load_manifest.json`
- `source_inventory.json`
- `evidence_map.json`
- `token_budget_report.json`
- `safety_boundary.md`
- `usage_examples.md`
- `install_instructions.md`
- chapters、concepts、frameworks、techniques、patterns、anti-patterns 结构化目录
- Claude Code、Codex、OpenClaw installability reports
- `skill_agent_kb_compatibility_report.json`

## 产品边界

- 不复制外部代码或 prompt。
- 不允许隐藏上传。
- 测试不需要真实 LLM/API/network 调用。
- 不支持的格式必须标为 unsupported，不能静默宣称支持。
- 私有原始输入和完整抽取 chunks 不应作为 proof artifacts 提交。

只要仍有任何 P0 未解决，最终 v4 gate 就必须保持 blocked。在最新 `pre_v4_p0_after_live_llm` Core 证明中，Book-to-Skill 与 live LLM P0 checks 已通过；v4.0 前仍需要单独执行 UI Full Operation Acceptance Gate。
