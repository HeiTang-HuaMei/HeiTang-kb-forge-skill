# Multimodal Knowledge Assets

v1.6 adds opt-in multimodal asset preservation for real-world source folders.

## Purpose

Multimodal assets prevent images, charts, diagrams, mindmaps, formulas, and slides from being silently lost when they cannot be converted into reliable text.

## Enable

```powershell
heitang-kb-forge build --input .\input --output .\output --multimodal
```

## Outputs

- `multimodal_assets.jsonl`
- `multimodal_evidence_map.json`
- `multimodal_report.md`
- `slide_chunks.jsonl` when slide text is extracted

## Review Required

Fallback or low-confidence assets are marked:

```json
{
  "confidence": "low",
  "extraction_method": "fallback",
  "review_required": true
}
```

Best-effort assets are evidence for review, not model-asserted facts.
