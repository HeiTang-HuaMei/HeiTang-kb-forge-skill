# Book-to-Skill Structured Package

This pre-v4 P0 gate upgrades HeiTang from knowledge package export to structured Skill package generation.

The generated Skill is not a raw book dump. `SKILL.md` is a compact entry point. Detailed material is split into on-demand files under `chapters/`, `concepts/`, `frameworks/`, `techniques/`, `patterns/`, and `anti_patterns/`.

## Commands

```powershell
python -m heitang_kb_forge.cli book-to-skill --package .\tmp_package --output .\tmp_skill --skill-name "Demo Skill" --target codex
python -m heitang_kb_forge.cli validate-skill-package --skill .\tmp_skill --output .\tmp_skill_validation
python -m heitang_kb_forge.cli diff-skill-package --old-skill .\old_skill --new-skill .\tmp_skill --output .\tmp_skill_diff
```

`book-to-skill` also accepts `--input` as a file, folder, or glob and builds a local KB package before generating the Skill.

## Required Outputs

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
- structured directories for chapters, concepts, frameworks, techniques, patterns, and anti-patterns
- installability reports for Claude Code, Codex, and OpenClaw
- `skill_agent_kb_compatibility_report.json`

## Product Boundary

- No external code or prompts are copied.
- No hidden upload is allowed.
- No real LLM/API/network call is required by tests.
- Unsupported formats are listed as unsupported, not silently claimed.
- Raw private source text and full extracted chunks must not be committed as proof artifacts.

The final v4 gate remains blocked while any P0 remains open, including live LLM provider acceptance failures.
