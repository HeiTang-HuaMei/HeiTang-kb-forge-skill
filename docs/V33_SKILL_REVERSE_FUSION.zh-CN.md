# v3.3 Skill Reverse and Fusion

v3.3 新增可选本地 reverse-and-fusion pass，用于已有 Skill package。

## 范围

- 将已有 Skill folder 反向解析为结构化 profile。
- 合并 capabilities 和 boundary rules，生成 fused Skill package。
- 写出 fusion plan、trace、quality、manifest 和 Markdown report。
- 要求输入 Skill package 包含 `SKILL.md`。
- 未启用时默认 build、run 和 pipeline 行为不变。

## 命令

```powershell
python -m heitang_kb_forge.cli reverse-fuse-skills --skills .\skill_a,.\skill_b --output .\tmp_fusion --fused-name "Fused Knowledge Skill"
```

配置驱动运行支持：

```yaml
skill_reverse_fusion:
  enabled: true
  fused_name: Fused Knowledge Skill
```

## 输出文件

- `skill_reverse_profiles.json`
- `skill_fusion_plan.json`
- `fused_skill/SKILL.md`
- `fused_skill/skill_manifest.yaml`
- `skill_reverse_fusion_trace.json`
- `skill_reverse_fusion_quality_report.json`
- `skill_reverse_fusion_report.md`

## 边界

v3.3 本地、确定性执行。它不把外部 Skill code 装入 runtime，不执行工具，不调用 LLM API，也不发布 fused Skill。
