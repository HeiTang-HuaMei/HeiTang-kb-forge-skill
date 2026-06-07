# v3.3 Skill Reverse and Fusion

v3.3 adds an opt-in local reverse-and-fusion pass for existing Skill packages.

## Scope

- Reverse existing Skill folders into structured profiles.
- Merge capabilities and boundary rules into a fused Skill package.
- Write fusion plan, trace, quality, manifest, and Markdown reports.
- Require valid Skill package inputs with `SKILL.md`.
- Keep default build, run, and pipeline behavior unchanged unless enabled.

## Commands

```powershell
python -m heitang_kb_forge.cli reverse-fuse-skills --skills .\skill_a,.\skill_b --output .\tmp_fusion --fused-name "Fused Knowledge Skill"
```

Config-driven runs support:

```yaml
skill_reverse_fusion:
  enabled: true
  fused_name: Fused Knowledge Skill
```

## Output Files

- `skill_reverse_profiles.json`
- `skill_fusion_plan.json`
- `fused_skill/SKILL.md`
- `fused_skill/skill_manifest.yaml`
- `skill_reverse_fusion_trace.json`
- `skill_reverse_fusion_quality_report.json`
- `skill_reverse_fusion_report.md`

## Boundaries

v3.3 is local and deterministic. It does not copy external Skill code into a runtime, execute tools, call LLM APIs, or publish fused Skills.
