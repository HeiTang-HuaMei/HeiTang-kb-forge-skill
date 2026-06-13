---
name: HeiTang Visual Evidence Skill
description: Use this skill when a package-grounded task needs multimodal evidence, visual state cards, or keyframe references.
skill_type: multimodal_reference
---

# HeiTang Visual Evidence Skill

Generated as a local MMSkills-inspired package contract.

## Trigger

Use when the answer or workflow needs visual evidence from package assets, layout cues, image-like sources, slide context, or state-conditioned references.

## Boundary

- Do not claim live GUI execution.
- Do not claim MMSkills repository runtime integration.
- Do not load raw demonstration trajectories.
- Use `visual_state_cards.jsonl` and `keyframe_index.jsonl` as reference evidence only.

## Runtime State Cards

State cards available: 3
